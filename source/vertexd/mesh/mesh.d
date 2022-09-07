module vertexd.mesh.mesh;

import bindbc.opengl;
import vertexd;
import std.conv : to;
import std.stdio : writeln;
import std.typecons : Nullable;
import std.math : signbit;
import std.exception : enforce;

final class Mesh {
	struct AttributeSet {
		Attribute position, normal, tangent;
		Attribute[2] texCoord; // TODO: static list of max_texCoord_count
		Attribute[1] color; // TODO: static list of max_color_count
		// Attribute[] joints;
		// Attribute[] weights;
		// Attribute[] custom;
	}

	struct Attribute {
		Binding binding;
		GLenum type;
		ubyte typeCount; // 1-4 / 9 / 16
		bool matrix;
		bool normalised;
		size_t elementCount = 0; // must be >= 1
		size_t beginning; // byte offset

		bool present() {
			return elementCount >= 1;
		}

		size_t elementSize() {
			return typeCount * attributeTypeSize(type);
		}

		ubyte[] getContent() {
			ubyte[] bindingContent = binding.getContent(elementSize);
			return bindingContent[beginning .. beginning + elementCount * elementSize];
		}
	}

	struct Binding {
		Buffer buffer = null;
		size_t size; // bytes
		size_t beginning; // bytes
		int stride = 0; //bytes >= 1

		ubyte[] getContent(size_t elementSize) {
			assert(buffer !is null);
			if (stride == 0) { // Non vertex attribute data
				stride = 1;
				elementSize = 1;
			} else if (elementSize == 0)
				elementSize = stride;
			assert(elementSize <= stride);

			ubyte[] content;
			content.reserve(size); // buffer may be padded
			for (size_t i = beginning; i < beginning + size; i += stride) {
				content ~= buffer.content[i .. i + elementSize];
			}
			return content;
		}
	}

	struct VertexIndex {
		Buffer buffer = null;
		size_t indexCount;
		int beginning; // bytes
		GLenum type; // ubyte/ushort/uint

		uint[3][] getContent() {
			ubyte[] content = buffer.content[beginning .. beginning + indexCount * attributeTypeSize(type)];
			switch (type) {
				case GL_UNSIGNED_BYTE:
					return (cast(ubyte[3][]) content).to!(uint[3][]);
				case GL_UNSIGNED_SHORT:
					return (cast(ushort[3][]) content).to!(uint[3][]);
				case GL_UNSIGNED_INT:
					return (cast(uint[3][]) content);
				default:
					assert(0, "VertexIndex type incorrect: " ~ type.to!string);
			}
		}
	}

	string name;
	private uint vao;
	private VertexIndex vertexIndex;
	Shader shader;
	Material material;
	AttributeSet attributes;
	uint[Binding] bindings;

	@property size_t vertexCount() {
		return attributes.position.elementCount;
	}

	public this(string name, AttributeSet attributes, VertexIndex vertexIndex, Shader shader, Material material) {
		this.name = name;
		this.attributes = attributes;
		this.vertexIndex = vertexIndex;
		this.shader = shader;
		this.material = material;

		glCreateVertexArrays(1, &vao);
		writeln("Mesh created: " ~ vao.to!string);

		enforce(setAttribute(attributes.position, 0));

		if (!attributes.normal.present()) {
		attributes.normal = generateNormals();
		attributes.tangent = generateTangents();
		} else if (!attributes.tangent.present()) {
			attributes.tangent = generateTangents();
		}

		setAttribute(attributes.normal, 1);
		setAttribute(attributes.tangent, 2); // ignored when no normal texture is defined.

		assert(attributes.texCoord.length <= 2); // TODO: have max_texCoord_count (ensuring layout-location)
		foreach (uint i, a; attributes.texCoord)
			setAttribute(a, 3 + i);
		assert(attributes.color.length <= 1); // TODO: have max_color_count (ensuring layout-location)
		foreach (uint i, a; attributes.color)
			setAttribute(a, 5 + i);

		if (vertexIndex.buffer !is null)
			glVertexArrayElementBuffer(vao, vertexIndex.buffer.buffer);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteVertexArrays(1, &vao);
		printf("Mesh removed: %u\n", vao);
	}

	uint ensureBinding(Binding b) {
		assert(b.stride > 0, "Stride should be higher than 0 but was: " ~ b.stride.to!string);

		return bindings.require(b, {
			glVertexArrayVertexBuffer(vao, cast(uint) bindings.length, b.buffer.buffer, b.beginning, b.stride);
			return cast(uint) bindings.length;
		}());
	}

	bool setAttribute(Attribute attrib, uint attribIndex) {
		if (!attrib.present())
			return false;

		Binding b = attrib.binding;
		uint bindingIndex = ensureBinding(b);

		glEnableVertexArrayAttrib(vao, attribIndex);
		glVertexArrayAttribFormat(vao, attribIndex, attrib.typeCount, attrib.type,
			attrib.normalised, cast(uint) attrib.beginning);
		glVertexArrayAttribBinding(vao, attribIndex, bindingIndex);
		return true;
	}

	/// Calculates a normal attribute using the positions attribute.
	/// Indexed meshes result in surface-weighted per-vertex normals.
	/// Non-indexed meshes merely result in flat per-face normals.
	/// Assumes counter-clockwise front-facing surfaces.
	Attribute generateNormals() { // TODO: version with non-surface-weighted per-vertex calculations.
		Vec!3[] normals;

		if (vertexIndex.buffer is null) { // Tightly packed flat normals
			Vec!3[3][] positions = cast(Vec!3[3][]) attributes.position.getContent();
			normals.reserve(vertexCount);
			foreach (Vec!3[3] pos; positions) {
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[1];
				Vec!3 n = a.cross(b).normalize();
				normals ~= [n, n, n];
			}
		} else { // Indexed smooth normals
			uint[3][] indices = vertexIndex.getContent();
			Vec!3[] positions = cast(Vec!3[]) attributes.position.getContent();
			normals = new Vec!3[vertexCount];
			foreach (uint[3] triangle; indices) {
				Vec!3[3] pos = [
					positions[triangle[0]], positions[triangle[1]], positions[triangle[2]],
				];
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[0];
				Vec!3 n = a.cross(b);
				normals[triangle[0]] += n;
				normals[triangle[1]] += n;
				normals[triangle[2]] += n;
			}
			foreach (ref Vec!3 normal; normals) {
				normal = normal.normalize();
			}
		}

		size_t size = normals.length * Vec!3.sizeof;
		Buffer normalBuffer = new Buffer(normals.ptr, size);
		Binding binding = Binding(normalBuffer, size, 0, Vec!3.sizeof);
		return Attribute(binding, GL_FLOAT, 3, false, false, normals.length, 0);
	}

	/// Calculates a tangent attribute based on the position and normal attributes,
	/// alongside the normal texture corresponding texture coordinate attribute.
	/// As with normals, indexed meshes result in surface-weighted per-vertex tangents.
	/// Nonindexed meshes result in flat per-face tangents.
	/// No tangents are generated when this texture is abscent.
	Attribute generateTangents() { // TODO: version with non-surface-weighted per-vertex calculations.
		if (!material.normal_texture.present)
			return Attribute();
		Vec!4[] tangents;

		if (vertexIndex.buffer is null) { // Tightly packed flat tangents
			Vec!3[3][] positions = cast(Vec!3[3][]) attributes.position.getContent();
			Vec!2[3][] texCoords = cast(Vec!2[3][]) attributes.texCoord[material.normal_texture.texCoord].getContent();
			Vec!4[3][] colors;

			tangents.reserve(vertexCount);
			foreach (i; 0 .. vertexCount) {
				Vec!3[3] pos = positions[i];
				Vec!2[3] uv = texCoords[i];

				Vec!3 AB = pos[1] - pos[0];
				Vec!3 AC = pos[2] - pos[1];
				Mat!(2, 3) deltaPosM = [AB, AC];

				Vec!2 ABUV = uv[1] - uv[0];
				Vec!2 ACUV = uv[2] - uv[0];
				Mat!2 deltaUVM = [ABUV, ACUV];
				deltaUVM = deltaUVM.inverse();

				Mat!(2, 3) TBM = deltaUVM.mult(deltaPosM);
				Vec!3 T = TBM[0];
				Vec!3 B = TBM[1];
				assert(T.length == 1);
				assert(B.length == 1);

				Vec!3 normal = AB.cross(AC); //.normalize();
				float sign = normal.cross(T).dot(B).signbit;

				Vec!4 tangent = T ~ sign;
				tangents ~= [tangent, tangent, tangent];
				Vec!4 color = Vec!4([0, 1, 0, 1]);
				colors ~= [color, color, color];
			}
		} else {
			uint[3][] indices = vertexIndex.getContent();
			Vec!3[] positions = cast(Vec!3[]) attributes.position.getContent();
			Vec!3[] normals = cast(Vec!3[]) attributes.normal.getContent();
			Vec!2[] texCoord = cast(Vec!2[]) attributes.texCoord[material.normal_texture.texCoord].getContent();
			Vec!4[] colors = new Vec!4[positions.length];
			assert(vertexCount == texCoord.length);

			tangents = new Vec!4[vertexCount];
			writeln(vertexIndex);
			writeln(attributes.position);
			foreach (uint[3] triangle; indices) {
				Vec!3[3] pos = [
					positions[triangle[0]], positions[triangle[1]], positions[triangle[2]]
				];
				Vec!3 AB = pos[1] - pos[0];
				Vec!3 AC = pos[2] - pos[0];
				Mat!(2, 3) deltaPosM = [AB, AC];

				Vec!2[3] uv = [texCoord[triangle[0]], texCoord[triangle[1]], texCoord[triangle[2]]];
				Vec!2 ABUV = uv[1] - uv[0];
				Vec!2 ACUV = uv[2] - uv[0];
				Mat!2 deltaUVM = [ABUV, ACUV];
				try {
					deltaUVM = deltaUVM.inverse();
					colors[triangle[0]] = Vec!4([1, 1, 0, 1]);
					colors[triangle[1]] = Vec!4([1, 1, 0, 1]);
					colors[triangle[2]] = Vec!4([1, 1, 0, 1]);
				} catch (Exception e) {
					writeln("Coult not invert triangle delta UV matrix:" ~ triangle.to!string);
					writeln("Matrix:" ~ deltaUVM.to!string);
					colors[triangle[0]] = Vec!4([0, 1, 0, 1]);
					colors[triangle[1]] = Vec!4([0, 1, 0, 1]);
					colors[triangle[2]] = Vec!4([0, 1, 0, 1]);
					continue;
				}

				// Normalize shouldn't need to be necessary, but the error seems somewhat large.
				Mat!(2, 3) TBM = deltaUVM.mult(deltaPosM);
				Vec!3 T = Vec!3(TBM[0]).normalize();
				Vec!3 B = Vec!3(TBM[1]).normalize();

				Vec!3 normal = AB.cross(AC); //.normalize();
				float sign = normal.cross(T).dot(B).signbit ? -1 : 1;

				Vec!4 tangent = T * normal.length() ~ sign; // surface weighted
				void addTangent(ref Vec!4 oldT, Vec!4 newT, uint index) {
					if (oldT.w == 0)
						oldT.w = newT.w;
					// assert(oldT.w == newT.w, "Can't average across tangents with opposite handedness");
					if(oldT.w!=newT.w){
						writeln("Can't average across tangents with opposite handedness");
						colors[index] = Vec!4([0,1,0,1]);
					}
					oldT[0 .. 3] += newT[0 .. 3];
				}

				addTangent(tangents[triangle[0]], tangent, triangle[0]);
				addTangent(tangents[triangle[1]], tangent, triangle[1]);
				addTangent(tangents[triangle[2]], tangent, triangle[2]);
			}

			foreach (i; 0 .. vertexCount) {
				Vec!3 tangent = Vec!3(tangents[i][0 .. 3]).normalize();
				Vec!3 normal = normals[i];
				tangent = tangent - normal * normal.dot(tangent);
				tangents[i][0 .. 3] = tangent.normalize();
			}

			Buffer newColor = new Buffer(colors.ptr, colors.length * Vec!4.sizeof);
			Binding binding = Binding(newColor, colors.length * Vec!4.sizeof, 0, Vec!4.sizeof);
			this.attributes.color[0] = Attribute(binding, GL_FLOAT, 4, false, false, colors.length, 0);
		}

		size_t size = tangents.length * Vec!4.sizeof;
		Buffer tangentBuffer = new Buffer(tangents.ptr, size);
		Binding binding = Binding(tangentBuffer, size, 0, Vec!4.sizeof);
		return Attribute(binding, GL_FLOAT, 4, false, false, tangents.length, 0);
	}

	private void setMissingVertexAttributes() {
		if (!attributes.position.present())
			assert(0); // glVertexAttrib3f(0, float.nan, float.nan, float.nan);
		if (!attributes.normal.present())
			glVertexAttrib3f(1, float.nan, float.nan, float.nan);
		if (!attributes.tangent.present())
			glVertexAttrib3f(2, float.nan, float.nan, float.nan);
		if (!attributes.texCoord[0].present())
			glVertexAttrib2f(3, float.nan, float.nan);
		if (!attributes.texCoord[1].present())
			glVertexAttrib2f(4, float.nan, float.nan);
		if (!attributes.color[0].present())
			glVertexAttrib4f(5, 1, 1, 1, 1); // behaviour when abscent.
	}

	public void draw(Node node) {
		shader.use();
		shader.setUniform("modelMatrix", node.modelMatrix);
		material.use();
		setMissingVertexAttributes();
		glBindVertexArray(vao);
		if (vertexIndex.buffer is null)
			glDrawArrays(GL_TRIANGLES, vertexIndex.beginning, cast(int) vertexIndex.indexCount);
		else
			glDrawElements(GL_TRIANGLES, cast(int) vertexIndex.indexCount, vertexIndex.type,
				cast(void*) vertexIndex.beginning);
	}
}
