module vertexd.input.gltf_reader;

import bindbc.opengl;
import vertexd;
import std.algorithm.searching : countUntil;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.file : readText;
import std.math : PI_4;
import std.path : dirName;
import std.stdio;
import std.typecons : Nullable;

final class GltfReader {
	World main_world;
	World[] worlds;
	Node[] nodes;

	private Node.Attribute[][Node] attributeAssignments;

	GltfMesh[][] meshes;
	Material[] materials;

	// Texture[] textureBases;

	Light[] lights;
	Camera[] cameras;

private:
	Json json;

	Sampler[] samplers;
	Image[] images;
	TextureHandle[] textureHandles;

	alias Image = Texture;
	// alias BindlessTexture = TextureHandle;
	// alias TextureInfo = BindlessTexture;

	ubyte[][] buffers;
	BufferView[] gltfBufferViews;
	Accessor[] gltfAccessors;

	struct BufferView {
		ubyte[] content;
		size_t stride;
	}

	alias Accessor = Mesh.Attribute;

	public this(string file, ShaderProgram shader = ShaderProgram.gltfShaderProgram()) {
		string dir = dirName(file);
		this.json = JsonReader.readJsonFile(file);
		enforce(json["asset"].object["version"].string_ == "2.0");

		readBuffers(dir);
		readBufferViews();
		readAccessors();

		readLights(); // KHR_lights_punctual extension

		readSamplers();
		debug {
			import std.datetime.stopwatch;

			StopWatch s = StopWatch(AutoStart.yes);
		}
		readImages(dir);

		debug {
			s.stop();
			File logFile = File("log.txt", "a");
			logFile.write("Time To Read Images: ");
			logFile.write(s.peek().total!"msecs");
			logFile.write("msecs");
			version (MultiThreadImageLoad)
				logFile.write(" (MultiThreadImageLoad)");
			logFile.writeln();
		}
		readTextures();

		readMaterials();
		readMeshes(shader);
		readCameras();
		readNodes();
		readWorlds();
		assignAttributes();
	}

	void assignAttributes() {
		foreach (node, attrs; attributeAssignments) {
			foreach (attr; attrs) {
				node.addAttribute(attr);
			}
		}
	}

	void readWorlds() {
		JsonVal[] worlds_json = json["scenes"].list;
		foreach (JsonVal world; worlds_json)
			worlds ~= readWorld(world.object);

		if (JsonVal* j = "scene" in json)
			main_world = worlds[j.long_];
		else
			main_world = null;
	}

	World readWorld(Json world_json) {
		string name = null;
		if (JsonVal* j = "name" in world_json)
			name = j.string_;
		World world = new World(name);

		JsonVal[] children = world_json.get("nodes", JsonVal(cast(JsonVal[])[])).list;
		foreach (JsonVal child; children)
			world.addNode(nodes[child.long_]);

		return world;
	}

	void readNodes() {
		JsonVal[] nodes_json = json["nodes"].list;
		nodes = new Node[nodes_json.length];

		foreach (i, JsonVal node; nodes_json) {
			string name = null;
			if (JsonVal* j = "name" in node.object)
				name = j.string_;
			nodes[i] = new Node(name); // Preinitialize to permit child references
		}

		foreach (i, JsonVal node; nodes_json)
			readNode(nodes[i], node.object);
	}

	Node readNode(ref Node node, Json node_json) {
		if (JsonVal* j = "mesh" in node_json)
			node.meshes = cast(Mesh[]) this.meshes[j.long_];

		if (JsonVal* j = "camera" in node_json) {
			long z = j.long_;
			attributeAssignments[node] ~= cameras[z];
		}

		if (JsonVal* e = "extensions" in node_json)
			if (JsonVal* el = "KHR_lights_punctual" in e.object) {
				long l = el.object["light"].long_;
				attributeAssignments[node] ~= lights[l];
			}

		if (JsonVal* j = "children" in node_json)
			foreach (JsonVal childj; j.list) {
				Node child = nodes[childj.long_];
				node.children ~= child;
				child.parent = node;
			}

		Pose pose;
		if (JsonVal* j = "translation" in node_json) {
			pose.location = j.vec!(3, precision);
		}
		if (JsonVal* j = "rotation" in node_json) {
			Vec!4 r = j.vec!(4, precision);
			pose.rotation = Quat(r.w, r.x, r.y, r.z);
		}
		if (JsonVal* j = "scale" in node_json) {
			pose.size = j.vec!(3, precision);
		}

		node.pose = pose;
		return node;
	}

	void readCameras() {
		if (JsonVal* j = "cameras" in json) {
			JsonVal[] cameras_json = json["cameras"].list;
			foreach (JsonVal camera; cameras_json)
				cameras ~= readCamera(camera.object);
		}
	}

	Camera readCamera(Json camera_json) {
		string name = null;
		if (JsonVal* j = "name" in camera_json)
			name = j.string_;

		string type = camera_json["type"].string_;
		if (type == "perspective") {
			Json setting = camera_json["perspective"].object;
			precision aspect = setting["aspectRatio"].getType!double();

			double yfov = setting["yfov"].getType!double();
			precision xfov = yfov * aspect;

			precision nearplane = setting["znear"].getType!double();
			precision backplane = setting["zfar"].getType!double();

			Mat!4 projectionMatrix = Camera.perspectiveProjection(aspect, xfov, nearplane, backplane);
			// Mat!4 projectionMatrix = Camera.perspectiveProjection(1920.0 / 1080.0, 2.1118483949, 0.1, 100);
			// Mat!4 projectionMatrix = Camera.perspectiveProjection();
			return new Camera(projectionMatrix, name);
		} else {
			enforce(type == "orthographic");
			Json setting = camera_json["orthographic"].object;
			precision width = setting["xmag"].getType!double();
			precision height = setting["ymag"].getType!double();
			precision nearplane = setting["znear"].getType!double();
			precision farplane = setting["zfar"].getType!double();

			Mat!4 projectionMatrix = Camera.orthographicProjection(width, height, nearplane, farplane);
			return new Camera(projectionMatrix, name);
		}
	}

	void readMeshes(ShaderProgram shader) {
		JsonVal[] meshes_json = json["meshes"].list;
		this.meshes.reserve(meshes_json.length);

		foreach (JsonVal mesh; meshes_json) {
			Json mesh_json = mesh.object;
			string name = null;
			if (JsonVal* j = "name" in mesh_json)
				name = j.string_;

			GltfMesh[] primitives;
			JsonVal[] primitives_json = mesh_json["primitives"].list;
			foreach (i; 0 .. primitives_json.length)
				primitives ~= readPrimitive(primitives_json[i].object, name, shader);

			this.meshes ~= primitives;
		}
	}

	GltfMesh readPrimitive(Json primitive, string name, ShaderProgram shader) {
		Json attributes_json = primitive["attributes"].object;
		enforce("POSITION" in attributes_json, "Presence of POSITION attribute assumed");

		GltfMesh.AttributeSet attributeSet;
		attributeSet.position = this.gltfAccessors[attributes_json["POSITION"].long_];
		assert(attributeSet.position.typeCount == 3);
		assert(attributeSet.position.type == GL_FLOAT);

		if (JsonVal* js = "NORMAL" in attributes_json) {
			attributeSet.normal = this.gltfAccessors[js.long_];
			assert(attributeSet.normal.typeCount == 3);
			assert(attributeSet.normal.type == GL_FLOAT);
		}

		if (JsonVal* js = "TANGENT" in attributes_json) {
			attributeSet.tangent = this.gltfAccessors[js.long_];
			assert(attributeSet.tangent.typeCount == 4);
			assert(attributeSet.tangent.type == GL_FLOAT);
		}

		for (uint i = 0; 16u; i++) { // TODO: decide on max #coords
			string s = "TEXCOORD_" ~ i.to!string;
			if (s !in attributes_json)
				break;
			Mesh.Attribute attr = this.gltfAccessors[attributes_json[s].long_];
			attributeSet.texCoord[i] = attr;
			assert(attr.typeCount == 2);
			assert(attr.type == GL_FLOAT || ((attr.type == GL_UNSIGNED_BYTE
					|| attr.type == GL_UNSIGNED_SHORT) && attr.normalised));
		}

		for (uint i = 0; 16u; i++) { // TODO: idem
			string s = "COLOR_" ~ i.to!string;
			if (s !in attributes_json)
				break;
			enforce(i == 0, "COLOR_n only supports n = 0"); //TODO: properly use COLOR_0 & determine what to do with more

			Mesh.Attribute colorAttribute = this.gltfAccessors[attributes_json[s].long_];
			enforce(colorAttribute.typeCount == 4, "COLOR_n attribute only supports typecount 4"); // TODO support 3.
			assert(colorAttribute.typeCount == 3 || colorAttribute.typeCount == 4);
			assert(colorAttribute.type == GL_FLOAT || ((colorAttribute.type == GL_UNSIGNED_BYTE
					|| colorAttribute.type == GL_UNSIGNED_SHORT) && colorAttribute.normalised));
			attributeSet.color[i] = colorAttribute;
		}

		//TODO: Joints & Weights

		Mesh.IndexAttribute indexAttribute;
		if ("indices" !in primitive) {
			assert(attributeSet.position.elementCount % 3 == 0);
			indexAttribute.indexCount = attributeSet.position.elementCount;
			indexAttribute.offset = 0;
		} else {
			indexAttribute = Mesh.IndexAttribute(this.gltfAccessors[primitive["indices"].long_]);
		}

		Material material;
		if (JsonVal* j = "material" in primitive)
			material = this.materials[j.long_];
		else
			material = Material.defaultMaterial;

		GLenum drawMode = getRenderTypeGLenum(primitive.get("mode", JsonVal(4L)).getType!uint);
		return new GltfMesh(material, attributeSet, indexAttribute, name, shader, drawMode);
	}

	GLenum getRenderTypeGLenum(uint drawMode) {
		switch (drawMode) {
			case 0:
				return GL_POINTS;
			case 1:
				return GL_LINES;
			case 2:
				return GL_LINE_LOOP;
			case 3:
				return GL_LINE_STRIP;
			case 4:
				return GL_TRIANGLES;
			case 5:
				return GL_TRIANGLE_STRIP;
			case 6:
				return GL_TRIANGLE_FAN;
			default:
				assert(0, "Not a gltf primitive.mode: " ~ drawMode.to!string);
		}
	}

	void readSamplers() {
		if (JsonVal* ss_json = "samplers" in json) {
			JsonVal[] ss = ss_json.list;
			samplers = new Sampler[ss.length + 1];
			foreach (long i; 0 .. ss.length)
				samplers[i] = readSampler(ss[i].object);
		}
	}

	Sampler readSampler(Json s_json) {
		//TODO: decide on defaults
		uint minFilter = GL_NEAREST;
		uint magFilter = GL_NEAREST;

		if (JsonVal* j = "minFilter" in s_json)
			minFilter = gltfToGlFilter(j.long_, true);
		if (JsonVal* j = "magFilter" in s_json)
			magFilter = gltfToGlFilter(j.long_, false);

		uint wrapS = gltfToGLWrap(s_json.get("wrapS", JsonVal(10_497)).long_);
		uint wrapT = gltfToGLWrap(s_json.get("wrapT", JsonVal(10_497)).long_);
		string name = s_json.get("name", JsonVal.NULL).string_;

		return new Sampler(wrapS, wrapT, minFilter, magFilter, true, name); //TODO: anisotroic true/false?
	}

	uint gltfToGLWrap(long gltfWrap) {
		switch (gltfWrap) {
			case 33_071:
				return GL_CLAMP_TO_EDGE;
			case 33_648:
				return GL_MIRRORED_REPEAT;
			case 10_497:
				return GL_REPEAT;
			default:
				assert(0, "Incorrect value for wrapS/T: " ~ gltfWrap.to!string);
		}
	}

	uint gltfToGlFilter(long gltfFilter, bool isMinFilter) {
		switch (gltfFilter) {
			case 9728:
				return GL_NEAREST;
			case 9729:
				return GL_LINEAR;
			default:
		}
		enforce(isMinFilter, "Incorrect value for magFilter: " ~ gltfFilter.to!string);
		switch (gltfFilter) {
			case 9984:
				return GL_NEAREST_MIPMAP_NEAREST;
			case 9985:
				return GL_LINEAR_MIPMAP_NEAREST;
			case 9986:
				return GL_NEAREST_MIPMAP_LINEAR;
			case 9987:
				return GL_LINEAR_MIPMAP_LINEAR;
			default:
				assert(0, "Incorrect value for minFilter: " ~ gltfFilter.to!string);
		}
	}

	void readImages(string dir) {
		if (JsonVal* j = "images" in json) {
			images.reserve(j.list.length);

			version (MultiThreadImageLoad) {
				import std.parallelism;
				import imageformats;

				auto tasks = taskPool();
				__gshared IFImage[] sharedIFImages;
				__gshared string[] sharedNames;
				sharedIFImages = new IFImage[j.list.length];
				sharedNames = new string[j.list.length];
			}

			foreach (size_t index, JsonVal image_val; j.list) {
				Json image_json = image_val.object;
				ubyte[] content;
				if (JsonVal* uri_json = "uri" in image_json) {
					assert("bufferView" !in image_json);
					content = readURI(uri_json.string_, dir);
				} else {
					content = this.gltfBufferViews[image_json["bufferView"].long_].content;
				}
				string name = image_json.get("name", JsonVal.NULL).string_;

				version (MultiThreadImageLoad) {
					auto readImage = (ubyte[] content, string name, size_t index) {
						sharedIFImages[index] = Image.readImage(content);
						sharedNames[index] = name;
					};
					tasks.put(task(readImage, content, name, index));
				} else {
					images ~= new Image(content, name);
				}
			}

			version (MultiThreadImageLoad) {
				tasks.finish(true);
				foreach (i; 0 .. sharedIFImages.length)
					images ~= new Image(sharedIFImages[i], sharedNames[i]);
			}
		}
	}

	void readTextures() {
		if (JsonVal* ts_json = "textures" in json) {
			JsonVal[] ts = ts_json.list;
			textureHandles = new TextureHandle[ts.length];
			foreach (long i; 0 .. ts.length) {
				Json t_json = ts[i].object;

				string name = t_json.get("name", JsonVal.NULL).string_;

				assert("source" in t_json, "BindlessTexture has no image");
				Texture base = images[t_json["source"].long_];

				Sampler sampler;
				if (JsonVal* s = "sampler" in t_json)
					sampler = samplers[s.long_];
				else
					sampler = samplers[$ - 1];

				textureHandles[i] = new TextureHandle(base, sampler, name);
			}
		}
	}

	void readMaterials() {
		if (JsonVal* j = "materials" in json)
			foreach (JsonVal m_json; j.list)
				materials ~= readMaterial(m_json.object);
	}

	BindlessTexture readTexture(Json t_json) {
		BindlessTexture t;
		t.handle = textureHandles[t_json["index"].long_];
		t.texCoord = cast(int) t_json.get("texCoord", JsonVal(0)).long_;
		return t;
	}

	BindlessTexture readNormalTexture(Json t_json) {
		BindlessTexture t = readTexture(t_json);
		t.factor = cast(float) t_json.get("scale", JsonVal(1.0)).getType!double();
		return t;
	}

	BindlessTexture readOcclusionTexture(Json t_json) {
		BindlessTexture t = readTexture(t_json);
		t.factor = cast(float) t_json.get("strength", JsonVal(1.0)).getType!double();
		return t;
	}

	Material readMaterial(Json m_json) {
		Material.AlphaBehaviour translateAlphaBehaviour(string behaviour) {
			switch (behaviour) {
				case "OPAQUE":
					return Material.AlphaBehaviour.OPAQUE;
				case "MASK":
					return Material.AlphaBehaviour.MASK;
				case "BLEND":
					return Material.AlphaBehaviour.BLEND;
				default:
					assert(0, "Invalid alphabehaviour: " ~ behaviour);
			}
		}

		string name = m_json.get("name", JsonVal.NULL).string_;
		Material material = new Material(name);

		if (JsonVal* pbr_jval = "pbrMetallicRoughness" in m_json) {
			Json pbr_j = pbr_jval.object;
			if (JsonVal* j = "baseColorFactor" in pbr_j)
				material.baseColor_factor = j.vec!(4, precision);
			if (JsonVal* j = "baseColorTexture" in pbr_j)
				material.baseColor_texture = readTexture(j.object);
			if (JsonVal* j = "metallicFactor" in pbr_j)
				material.metalFactor = j.getType!double();
			if (JsonVal* j = "roughnessFactor" in pbr_j)
				material.roughnessFactor = j.getType!double();
			if (JsonVal* j = "metallicRoughnessTexture" in pbr_j)
				material.metal_roughness_texture = readTexture(j.object);
		}

		if (JsonVal* j = "normalTexture" in m_json)
			material.normal_texture = readNormalTexture(j.object);
		if (JsonVal* j = "occlusionTexture" in m_json)
			material.occlusion_texture = readOcclusionTexture(j.object);
		if (JsonVal* j = "emissiveTexture" in m_json)
			material.emission_texture = readTexture(j.object);
		if (JsonVal* j = "emissiveFactor" in m_json)
			material.emission_factor = j.vec!(3, prec);
		if (JsonVal* j = "alphaMode" in m_json)
			material.alpha_behaviour = translateAlphaBehaviour(j.string_);
		if (JsonVal* j = "alphaCutoff" in m_json)
			material.alpha_threshold = cast(prec) j.getType!double();
		if (JsonVal* j = "doubleSided" in m_json)
			material.twosided = j.bool_;

		material.initialize();
		return material;
	}

	void readLights() {
		if (JsonVal* e = "extensions" in json)
			if (JsonVal* el = "KHR_lights_punctual" in e.object) {
				foreach (JsonVal l_jv; el.object["lights"].list) {
					lights ~= readLight(l_jv.object);
				}
			}
	}

	Light readLight(Json lj) {
		string name = null;
		Vec!3 color = Vec!3(1);
		precision strength = 1;

		if (JsonVal* nj = "name" in lj)
			name = nj.string_;
		if (JsonVal* cj = "color" in lj)
			color = cj.vec!(3, precision);
		if (JsonVal* sj = "intensity" in lj)
			strength = sj.getType!double();

		precision range = lj.get("range", JsonVal(double.infinity)).getType!double();

		string type = lj["type"].string_;
		switch (type) {
			case "directional":
				return new Light(Light.Type.DIRECTIONAL, color, name, strength, range);
			case "point":
				return new Light(Light.Type.POINT, color, name, strength, range);
			case "spot":
				Json spotj = lj["spot"].object;
				precision innerAngle = spotj.get("innerConeAngle", JsonVal(0.0)).getType!double();
				precision outerAngle = spotj.get("outerConeAngle", JsonVal(PI_4)).getType!double();
				return new Light(Light.Type.SPOTLIGHT, color, name, strength, range, innerAngle, outerAngle);
			default:
				assert(0, "Light type unknown: " ~ type);
		}
	}

	void readAccessors() {
		JsonVal[] accessors_json = json["accessors"].list;
		this.gltfAccessors = new Accessor[accessors_json.length];
		foreach (i, ref accessor; gltfAccessors) {
			Json accessor_json = accessors_json[i].object;

			if ("sparse" in accessor_json || "bufferView" !in accessor_json)
				assert(0, "Sparse accessor / empty bufferview not implemented");

			accessor.type = translateAttributeType(cast(int) accessor_json["componentType"].long_);
			accessor.typeCount = translateAttribyteTypeCount(accessor_json["type"].string_);
			accessor.matrix = (accessor_json["type"].string_[0 .. 3] == "MAT");
			accessor.normalised = accessor_json.get("normalized", JsonVal(false)).bool_;

			accessor.elementCount = cast(GLsizei) accessor_json["count"].long_;
			long relativeOffset = accessor_json.get("byteOffset", JsonVal(0L)).long_;
			BufferView bufferView = this.gltfBufferViews[accessor_json["bufferView"].long_];

			accessor.elementSize = accessor.typeCount * getGLenumTypeSize(accessor.type);
			long stride = bufferView.stride;
			if (stride == 0)
				stride = accessor.elementSize;
			accessor.content = new ubyte[accessor.elementCount * accessor.elementSize];
			for (size_t j = 0; j < accessor.elementCount; j += 1) {
				auto je = j * accessor.elementSize;
				auto js = j * stride + relativeOffset;
				accessor.content[je .. je + accessor.elementSize] = bufferView.content[js .. js + accessor.elementSize];
			}
		}
	}

	uint translateAttributeType(int type) {
		switch (type) {
			case 5120:
				return GL_BYTE;
			case 5121:
				return GL_UNSIGNED_BYTE;
			case 5122:
				return GL_SHORT;
			case 5123:
				return GL_UNSIGNED_SHORT;
			case 5125:
				return GL_UNSIGNED_INT;
			case 5126:
				return GL_FLOAT;
			default:
				assert(0, "Unsupported acessor.componentType: " ~ type.to!string);
		}
	}

	ubyte translateAttribyteTypeCount(string type) {
		switch (type) {
			case "SCALAR":
				return 1;
			case "VEC2":
				return 2;
			case "VEC3":
				return 3;
			case "VEC4":
				return 4;
			case "MAT2":
				return 4;
			case "MAT3":
				return 9;
			case "MAT4":
				return 16;
			default:
				assert(0, "Unsupported accessor.type: " ~ type);
		}
	}

	void readBufferViews() {
		JsonVal[] bufferviews_json = json["bufferViews"].list;
		this.gltfBufferViews = new BufferView[bufferviews_json.length];

		foreach (i; 0 .. bufferviews_json.length) {
			Json bufferview_json = bufferviews_json[i].object;

			ubyte[] buffer = buffers[bufferview_json["buffer"].long_];
			long size = bufferview_json["byteLength"].long_;
			long offset = bufferview_json.get("byteOffset", JsonVal(0L)).long_;
			long stride = bufferview_json.get("byteStride", JsonVal(0)).long_;

			ubyte[] content = buffer[offset .. offset + size].dup;
			this.gltfBufferViews[i] = BufferView(content, stride);
		}
	}

	void readBuffers(string dir) { //TODO: support GLB files
		JsonVal[] buffers_json = json["buffers"].list;
		this.buffers = new ubyte[][buffers_json.length];
		foreach (i; 0 .. buffers_json.length) {
			Json buffer_json = buffers_json[i].object;
			const long size = buffer_json["byteLength"].long_;
			string uri = buffer_json["uri"].string_;

			ubyte[] content = readURI(uri, dir);
			enforce(content.length == size,
				"Buffer size incorrect: " ~ content.length.to!string ~ " in stead of " ~ size.to!string); // May result in padding issues (GLB).
			buffers[i] = content;
		}
	}

	ubyte[] readURI(string uri, string dir) {
		if (uri.length > 5 && uri[0 .. 5] == "data:") {
			import std.base64;

			uint char_p = 5;
			while (uri[char_p] != ',') {
				char_p++;
				enforce(char_p < uri.length, "Incorrect data uri does not contain ','");
			}
			return Base64.decode(uri[(char_p + 1) .. $]);
		} else {
			import std.uri;
			import std.file;

			string uri_decoded = dir ~ `\` ~ decode(uri);
			return cast(ubyte[]) read(uri_decoded);
		}
	}
}
