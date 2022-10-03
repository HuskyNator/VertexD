module vertexd.mesh.mesh;

import bindbc.opengl;
import std.conv : to;
import std.exception : enforce;
import std.math : signbit;
import std.stdio : writeln;
import std.typecons : Nullable;
import std.traits : isIntegral;
import vertexd;

abstract class Mesh {
	struct Attribute {
		Binding binding;
		GLenum type;
		ubyte typeCount; // 1-4 / 9 / 16
		bool matrix;
		bool normalised = false;
		size_t elementCount = 0; // must be >= 1 (initialized)
		size_t beginning = 0; // byte offset

		static Attribute create(M : T[R], T, uint R)(M[] content, bool normalized = false)
				if (!isList!T) {
			return create(cast(T[1][R][]) content, normalized);
		}

		static Attribute create(M : T[C][R], T, uint R, uint C)(M[] content, bool normalized = false)
				if (!isList!T) {
			size_t size = content.length * M.sizeof;
			Buffer buffer = new Buffer(content.ptr, size);
			Binding binding = Binding(buffer, size, 0, M.sizeof);
			return Attribute(binding, getGLenum!(T), R * C, C > 1, normalized, content.length, 0);
		}

		bool present() {
			return elementCount >= 1;
		}

		size_t elementSize() {
			return typeCount * getGLenumTypeSize(type);
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

	struct IndexAttribute {
		size_t indexCount;
		int beginning = 0; // bytes
		Buffer buffer = null;
		GLenum type; // ubyte/ushort/uint

		static IndexAttribute create(T)(T[] content, bool normalized = false)
				if (__traits(compiles, (getGLenum!T))) { // not isIntegral!T
			size_t size = content.length * T.sizeof;
			Buffer buffer = new Buffer(content.ptr, size);
			return IndexAttribute(content.length, 0, buffer, getGLenum!(T));
		}

		bool present() {
			return buffer !is null;
		}

		uint[3][] getContent() {
			ubyte[] content = buffer.content[beginning .. beginning + indexCount * getGLenumTypeSize(type)];
			switch (type) {
				case GL_UNSIGNED_BYTE:
					return (cast(ubyte[3][]) content).to!(uint[3][]);
				case GL_UNSIGNED_SHORT:
					return (cast(ushort[3][]) content).to!(uint[3][]);
				case GL_UNSIGNED_INT:
					return (cast(uint[3][]) content);
				default:
					assert(0, "IndexAttribute type incorrect: " ~ type.to!string);
			}
		}
	}

	string name;
	Shader shader;
	protected uint vao;
	IndexAttribute indexAttribute;
	Attribute[uint] attributes; // Must match shader usage!
	uint[Binding] bindings;

	public this(string name, Shader shader, IndexAttribute indexAttribute) {
		glCreateVertexArrays(1, &vao);
		writeln("Mesh created: " ~ vao.to!string);

		this.name = name.length > 0 ? name : "Mesh#" ~ vao.to!string;
		this.shader = shader;
		this.indexAttribute = indexAttribute;

		if (indexAttribute.present)
			glVertexArrayElementBuffer(vao, indexAttribute.buffer.buffer);
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
		assert(attribIndex !in this.attributes);
		this.attributes[attribIndex] = attrib;
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
	static Attribute generateNormals(Attribute positionsAttr, IndexAttribute indexAttribute = IndexAttribute()) { // TODO: version with non-surface-weighted per-vertex calculations.
		Vec!3[] normals;

		if (indexAttribute.buffer is null) { // Tightly packed flat normals
			Vec!3[3][] positions = cast(Vec!3[3][]) positionsAttr.getContent();
			normals.reserve(positions.length);
			foreach (Vec!3[3] pos; positions) {
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[0];
				Vec!3 n = a.cross(b).normalize();
				normals ~= [n, n, n];
			}
		} else { // Indexed smooth normals
			uint[3][] indices = indexAttribute.getContent();
			Vec!3[] positions = cast(Vec!3[]) positionsAttr.getContent();
			normals = new Vec!3[positions.length];
			foreach (uint[3] triangle; indices) {
				Vec!3[3] pos = [
					positions[triangle[0]], positions[triangle[1]], positions[triangle[2]],
				];
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[0];
				Vec!3 n = a.cross(b); // not normalized
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
	static Attribute generateTangents(Attribute positionsAtt, Attribute normalsAtt,
		Attribute texCoordsAtt, IndexAttribute indexAttribute = IndexAttribute()) { // TODO: version with non-surface-weighted per-vertex calculations.
		Vec!4[] tangents;

		if (indexAttribute.buffer is null) { // Tightly packed flat tangents
			Vec!3[3][] positions = cast(Vec!3[3][]) positionsAtt.getContent();
			Vec!2[3][] texCoords = cast(Vec!2[3][]) texCoordsAtt.getContent();
			assert(positions.length == texCoords.length);

			tangents.reserve(positions.length);
			foreach (i; 0 .. positions.length) {
				Vec!3[3] pos = positions[i];
				Vec!2[3] uv = texCoords[i];

				Vec!3 AB = pos[1] - pos[0];
				Vec!3 AC = pos[2] - pos[0];
				Mat!(2, 3) deltaPosM = [AB, AC];

				Vec!2 ABUV = uv[1] - uv[0];
				Vec!2 ACUV = uv[2] - uv[0];
				Mat!2 deltaUVM = [ABUV, ACUV];
				deltaUVM = deltaUVM.inverse();

				Mat!(2, 3) TBM = deltaUVM.mult(deltaPosM);
				Vec!3 T = Vec!3(TBM[0]);
				Vec!3 B = Vec!3(TBM[1]);
				assert(T.length == 1, T.toString);
				assert(B.length == 1, B.toString);

				Vec!3 normal = AB.cross(AC); //.normalize();
				float sign = normal.cross(T).dot(B).signbit;

				Vec!4 tangent = T ~ sign;
				tangents ~= [tangent, tangent, tangent];
			}
		} else {
			uint[3][] indices = indexAttribute.getContent();
			Vec!3[] positions = cast(Vec!3[]) positionsAtt.getContent();
			Vec!3[] normals = cast(Vec!3[]) normalsAtt.getContent();
			Vec!2[] texCoords = cast(Vec!2[]) texCoordsAtt.getContent();
			assert(positions.length == normals.length);
			assert(positions.length == texCoords.length);

			tangents = new Vec!4[positions.length];
			foreach (uint[3] triangle; indices) {
				Vec!3[3] pos = [
					positions[triangle[0]], positions[triangle[1]], positions[triangle[2]]
				];
				Vec!3 AB = pos[1] - pos[0];
				Vec!3 AC = pos[2] - pos[0];
				Mat!(2, 3) deltaPosM = [AB, AC];

				Vec!2[3] uv = [
					texCoords[triangle[0]], texCoords[triangle[1]], texCoords[triangle[2]]
				];
				Vec!2 ABUV = uv[1] - uv[0];
				Vec!2 ACUV = uv[2] - uv[0];
				Mat!2 deltaUVM = [ABUV, ACUV];
				try {
					deltaUVM = deltaUVM.inverse();
				} catch (Exception e) {
					writeln("Coult not invert triangle delta UV matrix:" ~ triangle.to!string);
					writeln("Matrix:" ~ deltaUVM.to!string);
					continue;
				}

				// Normalize shouldn't need to be necessary, but the error seems somewhat large.
				Mat!(2, 3) TBM = deltaUVM.mult(deltaPosM);
				Vec!3 T = Vec!3(TBM[0]).normalize();
				Vec!3 B = Vec!3(TBM[1]).normalize();

				Vec!3 normal = AB.cross(AC); //.normalize();
				float sign = normal.cross(T).dot(B).signbit ? -1 : 1;

				Vec!4 tangent = T * normal.length() ~ sign; // TODO surface weighted, could use 'uv surface area' instead?
				void addTangent(ref Vec!4 oldT, Vec!4 newT, uint index) {
					if (oldT.w == 0)
						oldT.w = newT.w;
					if (oldT.w != newT.w)
						writeln("Can't average across tangents with opposite handedness");
					else
						oldT[0 .. 3] += newT[0 .. 3];
				}

				addTangent(tangents[triangle[0]], tangent, triangle[0]);
				addTangent(tangents[triangle[1]], tangent, triangle[1]);
				addTangent(tangents[triangle[2]], tangent, triangle[2]);
			}

			foreach (i; 0 .. positions.length) {
				Vec!3 tangent = Vec!3(tangents[i][0 .. 3]).normalize();
				Vec!3 normal = normals[i];
				tangent = tangent - normal * normal.dot(tangent);
				tangents[i][0 .. 3] = tangent.normalize();
			}
		}

		size_t size = tangents.length * Vec!4.sizeof;
		Buffer tangentBuffer = new Buffer(tangents.ptr, size);
		Binding binding = Binding(tangentBuffer, size, 0, Vec!4.sizeof);
		return Attribute(binding, GL_FLOAT, 4, false, false, tangents.length, 0);
	}

	public void draw(Node node) {
		shader.use();
		shader.setUniform("modelMatrix", node.modelMatrix);
		glBindVertexArray(vao);
		drawSetup(node);

		if (indexAttribute.present)
			glDrawElements(drawMode, cast(int) indexAttribute.indexCount, indexAttribute.type,
				cast(void*) indexAttribute.beginning);
		else
			glDrawArrays(drawMode, indexAttribute.beginning, cast(int) indexAttribute.indexCount);
	}

	abstract GLenum drawMode();

	abstract void drawSetup(Node node);
}
