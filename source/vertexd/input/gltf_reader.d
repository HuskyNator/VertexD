module vertexd.input.gltf_reader;

import bindbc.opengl;
import vertexd;
import vertexd.input.gltf;
import std.algorithm.searching : countUntil;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.file : readText;
import std.math : PI_4;
import std.path : dirName;
import std.stdio;
import std.typecons : Nullable;

class GltfReader {
	Json json;
	World main_world;
	World[] worlds;
	Node[] nodes;
	Material[] materials;

	Texture[] textures;
	Image[] images;
	Sampler[] samplers;

	Light[] lights;

	Buffer[] buffers;
	ubyte[][] buffers_content;
	Mesh.Binding[] bindings;
	Mesh.Attribute[] attributes;
	Mesh[][] meshes;

	Camera[] cameras;

	private ulong[] sought_stride;

	this(string file) {
		string dir = dirName(file);
		this.json = JsonReader.readJsonFile(file);
		enforce(json["asset"].node["version"].string_ == "2.0");

		readBuffers(dir);
		readBindings();
		readAttributes();
		determineStrides();

		readLights(); // KHR_lights_punctual extension

		readSamplers();
		readImages(dir);
		readTextures();

		readMaterials();
		readMeshes();
		readCameras();
		readNodes();
		readWorlds();
	}

	private void readWorlds() {
		JsonVal[] worlds_json = json["scenes"].list;
		foreach (JsonVal world; worlds_json)
			worlds ~= readWorld(world.node);

		if (JsonVal* j = "scene" in json)
			main_world = worlds[j.long_];
		else
			main_world = null;
	}

	private World readWorld(Json world_json) {
		string name = world_json["name"].string_;
		World world = new World(name);
		JsonVal[] children = world_json["nodes"].list;

		void addAttribute(Node v) {
			foreach (Node.Attribute e; v.attributes) {
				if (Light l = cast(Light) e) {
					world.lightSet += l;
				}
			}
			foreach (Node child; v.children)
				addAttribute(child);
		}

		foreach (JsonVal child; children) {
			Node v = nodes[child.long_];
			world.children ~= v;
			addAttribute(v);
		}
		return world;
	}

	private void readNodes() {
		JsonVal[] nodes_json = json["nodes"].list;
		foreach (JsonVal node; nodes_json)
			nodes ~= readNode(node.node);
	}

	private Node readNode(Json node_json) {
		string name = "";
		if (JsonVal* j = "name" in node_json)
			name = j.string_;

		Mesh[] meshes = [];
		if (JsonVal* j = "mesh" in node_json)
			meshes = this.meshes[j.long_];

		Node node = new Node(name, meshes);

		if (JsonVal* j = "camera" in node_json) {
			long z = j.long_;
			node.attributes ~= cameras[z];
		}

		if (JsonVal* e = "extensions" in node_json)
			if (JsonVal* el = "KHR_lights_punctual" in e.node) {
				long l = el.node["light"].long_;
				node.attributes ~= lights[l];
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

	private void readCameras() {
		if (JsonVal* j = "cameras" in json) {
			JsonVal[] cameras_json = json["cameras"].list;
			foreach (JsonVal camera; cameras_json)
				cameras ~= readCamera(camera.node);
		}
	}

	private Camera readCamera(Json camera_json) {
		string name = "";
		if (JsonVal* j = "name" in camera_json)
			name = j.string_;

		string type = camera_json["type"].string_;
		if (type == "perspective") {
			Json setting = camera_json["perspective"].node;
			precision aspect = 1 / setting["aspectRatio"].double_;

			double yfov = setting["yfov"].double_;
			precision xfov = yfov / aspect;

			precision nearplane = setting["znear"].double_;
			precision backplane = setting["zfar"].double_;

			Mat!4 projectionMatrix = Camera.perspectiveProjection(aspect, xfov, nearplane, backplane);
			return new Camera(projectionMatrix);
		} else {
			enforce(type == "orthographic");
			assert(0, "Orthographic camera not yet implemented");
			// TODO Orthographic camera
		}
	}

	private void readMeshes() {
		JsonVal[] meshes_json = json["meshes"].list;
		foreach (JsonVal mesh; meshes_json)
			meshes ~= readMesh(mesh.node);
	}

	private Mesh[] readMesh(Json mesh_json) {
		string name = mesh_json.get("name", JsonVal("")).string_;

		Mesh[] meshes;
		JsonVal[] primitives = mesh_json["primitives"].list;
		foreach (i; 0 .. primitives.length) {
			meshes ~= readPrimitive(primitives[i].node, name ~ "#" ~ i.to!string);
		}

		return meshes;
	}

	private Mesh readPrimitive(Json primitive, string name) {
		Mesh.Binding translateBinding(Mesh.Binding k) {
			k.buffer = this.buffers[k.buffer].buffer;
			return k;
		}

		Json attributes = primitive["attributes"].node;
		enforce("POSITION" in attributes && "NORMAL" in attributes,
			"Presence of POSITION/NORMAL attribute assumed");

		Mesh.Attribute[] mesh_attributes;
		string[] mesh_attribute_names;
		mesh_attributes ~= this.attributes[attributes["POSITION"].long_];
		mesh_attributes ~= this.attributes[attributes["NORMAL"].long_];
		mesh_attribute_names ~= "POSITION";
		mesh_attribute_names ~= "NORMAL";
		for (uint i = 0; 16u; i++) {
			string s = "TEXCOORD_" ~ i.to!string;
			if (s !in attributes)
				break;
			mesh_attributes ~= this.attributes[attributes[s].long_];
			mesh_attribute_names ~= s;
		}
		for (uint i = 0; 16u; i++) {
			string s = "COLOR_" ~ i.to!string;
			if (s !in attributes)
				break;
			mesh_attributes ~= this.attributes[attributes[s].long_];
			mesh_attribute_names ~= s;
		}

		Mesh.Binding[] mesh_binding;
		uint[uint] binding_translations;
		foreach (ref Mesh.Attribute attribute; mesh_attributes) {
			uint i = attribute.binding;
			if (i !in binding_translations) {
				binding_translations[i] = cast(uint) binding_translations.length;
				mesh_binding ~= translateBinding(this.bindings[i]);
			}
			attribute.binding = binding_translations[i];
		}

		Mesh.VertexIndex vertexIndex;
		if ("indices" !in primitive) {
			vertexIndex.buffer.nullify();
			vertexIndex.vertexCount = cast(int) mesh_attributes[0].elementCount;
			vertexIndex.beginning = 0;
		} else {
			Mesh.Attribute attribute = this.attributes[primitive["indices"].long_];
			Mesh.Binding binding = translateBinding(
				this.bindings[attribute.binding]);

			vertexIndex.buffer = binding.buffer;
			vertexIndex.vertexCount = cast(int) attribute.elementCount;
			vertexIndex.beginning = cast(uint)(attribute.beginning + binding.beginning);
			vertexIndex.type = attribute.type;
		}

		Material material = Gltf.standard_material;
		if (JsonVal* j = "material" in primitive)
			material = this.materials[j.long_];

		Shader shader = Gltf.generateShader(mesh_attributes, mesh_attribute_names, material);

		return new Mesh(name, mesh_attributes, mesh_binding, vertexIndex, shader, material);
	}

	private void readSamplers() {
		if (JsonVal* ss_json = "samplers" in json) {
			JsonVal[] ss = ss_json.list;
			samplers = new Sampler[ss.length + 1];
			foreach (long i; 0 .. ss.length)
				samplers[i] = readSampler(ss[i].node);
		}
	}

	private Sampler readSampler(Json s_json) {
		uint minFilter = GL_NEAREST_MIPMAP_LINEAR;
		uint magFilter = GL_NEAREST;
		if (JsonVal* j = "minFilter" in s_json)
			minFilter = gltfToGlFilter(j.long_, true);
		if (JsonVal* j = "magFilter" in s_json)
			magFilter = gltfToGlFilter(j.long_, false);

		uint wrapS = gltfToGLWrap(s_json.get("wrapS", JsonVal(10497)).long_);
		uint wrapT = gltfToGLWrap(s_json.get("wrapT", JsonVal(10497)).long_);
		string name = s_json.get("name", JsonVal("")).string_;

		return new Sampler(name, wrapS, wrapT, minFilter, magFilter);
	}

	private uint gltfToGLWrap(long gltfWrap) {
		switch (gltfWrap) {
		case 33071:
			return GL_CLAMP_TO_EDGE;
		case 33648:
			return GL_MIRRORED_REPEAT;
		case 10497:
			return GL_REPEAT;
		default:
			assert(0, "Incorrect value for wrapS/T: " ~ gltfWrap.to!string);
		}
	}

	private uint gltfToGlFilter(long gltfFilter, bool isMinFilter) {
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

	private void readImages(string dir) {
		if (JsonVal* j = "images" in json)
			foreach (JsonVal a_json; j.list)
				images ~= readImage(a_json.node, dir);
	}

	private Image readImage(Json a_json, string dir) {
		ubyte[] content;
		if (JsonVal* uri_json = "uri" in a_json) {
			assert("bufferView" !in a_json);
			content = readURI(uri_json.string_, dir);
		} else {
			content = readBindingContent(cast(uint) a_json["bufferView"].long_);
		}
		string name = a_json.get("name", JsonVal("")).string_;
		return new Image(content, name);
	}

	private void readTextures() {
		if (JsonVal* ts_json = "textures" in json) {
			JsonVal[] ts = ts_json.list;
			textures = new Texture[ts.length];
			foreach (long i; 0 .. ts.length) {
				Json t_json = ts[i].node;
				Texture t;
				t.name = t_json.get("sampler", JsonVal("")).string_;
				if (JsonVal* s = "sampler" in t_json)
					t.sampler = samplers[s.long_];
				else
					t.sampler = samplers[$ - 1];
				assert("source" in t_json, "Texture has no image");
				t.image = images[t_json["source"].long_];
				textures[i] = t;
			}
		}
	}

	private void readMaterials() {
		if (JsonVal* j = "materials" in json)
			foreach (JsonVal m_json; j.list)
				materials ~= readMaterial(m_json.node);
	}

	private TextureInfo readTextureInfo(Json ti_json) {
		TextureInfo ti;
		ti.texture = textures[ti_json["index"].long_];
		ti.textureCoord = cast(uint) ti_json.get("texCoord", JsonVal(0)).long_;
		return ti;
	}

	private NormalTextureInfo readNormalTextureInfo(Json ti_json) {
		NormalTextureInfo ti;
		ti.textureInfo = readTextureInfo(ti_json);
		ti.normal_scale = cast(prec) ti_json.get("scale", JsonVal(1.0)).double_;
		return ti;
	}

	private OcclusionTextureInfo readOcclusionTextureInfo(Json ti_json) {
		OcclusionTextureInfo ti;
		ti.textureInfo = readTextureInfo(ti_json);
		ti.occlusion_strength = cast(prec) ti_json.get("strength", JsonVal(1.0)).double_;
		return ti;
	}

	private Material readMaterial(Json m_json) {
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

		Material material = Gltf.standard_material;
		material.name = m_json.get("name", JsonVal("")).string_;

		material.pbr = Gltf.standard_pbr;
		if (JsonVal* pbr_jval = "pbrMetallicRoughness" in m_json)
			material.pbr = readPBR(pbr_jval.node);

		if (JsonVal* j = "normalTexture" in m_json)
			material.normal_texture = readNormalTextureInfo(j.node);
		if (JsonVal* j = "occlusionTexture" in m_json)
			material.occlusion_texture = readOcclusionTextureInfo(j.node);
		if (JsonVal* j = "emissiveTexture" in m_json)
			material.emission_texture = readTextureInfo(j.node);
		if (JsonVal* j = "emissiveFactor" in m_json)
			material.emission_factor = j.vec!(3, prec);
		if (JsonVal* j = "alphaMode" in m_json)
			material.alpha_behaviour = translateAlphaBehaviour(j.string_);
		if (JsonVal* j = "alphaCutoff" in m_json)
			material.alpha_threshold = cast(prec) j.double_;
		if (JsonVal* j = "doubleSided" in m_json)
			material.twosided = j.bool_;
		return material;
	}

	private PBR readPBR(Json pbr_j) {
		PBR pbr = Gltf.standard_pbr;
		if (JsonVal* j = "baseColorFactor" in pbr_j)
			pbr.color_factor = j.vec!(4, precision);
		if (JsonVal* j = "baseColorTexture" in pbr_j)
			pbr.color_texture = readTextureInfo(j.node);
		if (JsonVal* j = "metallicFactor" in pbr_j)
			pbr.metalFactor = j.double_;
		if (JsonVal* j = "roughnessFactor" in pbr_j)
			pbr.roughness = j.double_;
		if (JsonVal* j = "metallicRoughnessTexture" in pbr_j)
			pbr.metal_roughness_texture = readTextureInfo(j.node);
		return pbr;
	}

	private void readLights() {
		if (JsonVal* e = "extensions" in json)
			if (JsonVal* el = "KHR_lights_punctual" in e.node) {
				foreach (JsonVal l_jv; el.node["lights"].list) {
					lights ~= readLight(l_jv.node);
				}
			}
	}

	private Light readLight(Json lj) {
		string name = "";
		Vec!3 color = Vec!3(1);
		precision strength = 1;

		if (JsonVal* nj = "name" in lj)
			name = nj.string_;
		if (JsonVal* cj = "color" in lj)
			color = cj.vec!(3, precision);
		if (JsonVal* sj = "intensity" in lj)
			strength = sj.double_;

		precision range = lj.get("range", JsonVal(double.infinity)).double_;

		string type = lj["type"].string_;
		switch (type) {
		case "directional":
			return new Light(Light.Type.DIRECTIONAL, color, strength, range);
		case "point":
			return new Light(Light.Type.FRAGMENT, color, strength, range);
		case "spot":
			Json spotj = lj["spot"].node;
			precision innerAngle = spotj.get("innerConeAngle", JsonVal(0.0)).double_;
			precision outerAngle = spotj.get("outerConeAngle", JsonVal(PI_4)).double_;
			return new Light(Light.Type.SPOTLIGHT, color, strength, range, innerAngle, outerAngle);
		default:
			assert(0, "Light type unknown: " ~ type);
		}
	}

	private void determineStrides() {
		stride_loop: foreach (ulong i; 0 .. sought_stride.length) {
			foreach (Mesh.Attribute e; attributes) {
				if (e.binding != i)
					continue;
				bindings[i].stride = cast(int) determineStride(e);
				continue stride_loop;
			}
			bindings[i].stride = 0;
			writeln(
				"Could not find accessor to determine stride of binding#" ~ i.to!string ~ " ");
		}
	}

	private size_t determineStride(Mesh.Attribute e) {
		return e.typeCount * attributeTypeSize(e.type);
	}

	private size_t attributeTypeSize(GLenum type) {
		switch (type) {
		case GL_UNSIGNED_BYTE:
			return ubyte.sizeof;
		case GL_BYTE:
			return byte.sizeof;
		case GL_UNSIGNED_SHORT:
			return ushort.sizeof;
		case GL_SHORT:
			return short.sizeof;
		case GL_UNSIGNED_INT:
			return uint.sizeof;
		case GL_FLOAT:
			return float.sizeof;
		default:
			assert(0, "Unsupported acessor.componentType: " ~ type.to!string);
		}
	}

	private void readAttributes() {
		JsonVal[] attributes_json = json["accessors"].list;
		foreach (JsonVal attribute_json; attributes_json)
			attributes ~= readAttribute(attribute_json.node);
	}

	private uint translateAttributeType(int type) {
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

	private ubyte translateAttribyteTypeCount(string type) {
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

	private Mesh.Attribute readAttribute(Json attribute_json) {
		Mesh.Attribute attribute;
		if ("sparse" in attribute_json || "bufferView" !in attribute_json)
			assert(0, "Sparse accessor / empty bufferview not implemented");
		attribute.binding = cast(uint) attribute_json["bufferView"].long_;
		attribute.type = translateAttributeType(
			cast(int) attribute_json["componentType"].long_);
		attribute.typeCount = translateAttribyteTypeCount(attribute_json["type"].string_);
		attribute.matrix = (attribute_json["type"].string_[0 .. 3] == "MAT");
		attribute.normalised = attribute_json.get("normalized", JsonVal(false)).bool_;
		attribute.elementCount = attribute_json["count"].long_;
		attribute.beginning = cast(uint) attribute_json.get("byteOffset", JsonVal(0L)).long_;
		return attribute;
	}

	private void readBindings() {
		JsonVal[] bindings_json = json["bufferViews"].list;
		bindings = new Mesh.Binding[bindings_json.length];
		for (int i = 0; i < bindings_json.length; i++) {
			Json binding_json = bindings_json[i].node;
			Mesh.Binding binding;
			binding.buffer = cast(uint) binding_json["buffer"].long_;
			binding.size = binding_json["byteLength"].long_;
			binding.beginning = binding_json.get("byteOffset", JsonVal(0L)).long_;
			if (JsonVal* j = "byteStride" in binding_json)
				binding.stride = cast(int) j.long_;
			else
				sought_stride ~= i;
			bindings[i] = binding;
		}
	}

	private void readBuffers(string dir) {
		JsonVal[] list = json["buffers"].list;
		buffers = new Buffer[list.length];
		buffers_content = new ubyte[][list.length];
		for (uint i = 0; i < list.length; i++) {
			Json buffer = list[i].node;
			const long size = buffer["byteLength"].long_;
			string uri = buffer["uri"].string_;
			ubyte[] content = readURI(uri, dir);

			enforce(content.length == size, "Buffer size incorrect: "
					~ content.length.to!string ~ " in stead of " ~ size.to!string);

			buffers[i] = new Buffer(content);
			buffers_content[i] = content;
		}
	}

	private ubyte[] readURI(string uri, string dir) {
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

	private ubyte[] readBindingContent(uint binding_index) {
		Mesh.Binding binding = bindings[binding_index];
		ubyte[] source = buffers_content[binding.buffer];
		assert(binding.stride == 0 || binding.stride == 1,
			"Stride problem with reading from binding");
		return source[binding.beginning .. binding.beginning + binding.size].dup;
	}
}
