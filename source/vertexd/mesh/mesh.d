module vertexd.mesh.mesh;

import bindbc.opengl;
import std.conv : to;
import std.exception : enforce;
import std.math : signbit;
import std.stdio : write, writeln;
import std.typecons : Nullable;
import std.traits : isIntegral;
import vertexd;

abstract class Mesh {
	alias Attr = Attribute;
	static struct Attribute {
		uint type; // GLuint
		ubyte typeCount; // 1-4 / 9 / 16
		bool matrix;
		bool normalised = false;
		ubyte[] content;

		GLsizei elementCount; // Redundant
		GLsizei elementSize; // Redudant
		invariant {
			if (content !is null && content.length > 0) {
				assert(elementSize == typeCount * getGLenumTypeSize(type));
				assert(content.length % elementSize == 0);
			}
		}

		this(M : T[R], T, uint R)(M[] content, bool normalised = false) if (!isList!T) {
			this(cast(T[1][R][]) content, normalised);
		}

		this(M : T[C][R], T, uint R, uint C)(M[] content, bool normalised = false) if (!isList!T) {
			this.type = getGLenum!T;
			this.typeCount = R * C;
			// writeln("TYPECOUNT R" ~ R.to!string ~ " * C" ~ C.to!string ~ " = " ~ typeCount.to!string);
			this.matrix = C > 1;
			this.normalised = normalised;
			assert(!normalised || (type != GL_FLOAT && type != GL_UNSIGNED_INT));
			this.content = cast(ubyte[]) content;

			this.elementCount = cast(GLsizei) content.length;
			this.elementSize = cast(GLsizei) M.sizeof;
		}

		bool present() const {
			return content.length > 0;
		}

		size_t size() const {
			return content.length;
		}

	}

	alias IndexAttr = IndexAttribute;
	static struct IndexAttribute {
		GLenum type; // ubyte/ushort/uint
		GLsizei indexCount = 0;
		GLint offset = 0;
		ubyte[] content;

		this(T)(T[] content) if (__traits(compiles, (getGLenum!T))) { // not isIntegral!T
			// assert(content.length % 3 == 0);
			this.indexCount = content.length.to!GLsizei;
			this.type = getGLenum!T;
			this.offset = 0;
			this.content = cast(ubyte[]) content;
		}

		this(Mesh.Attribute attr) {
			// assert(attr.elementCount % 3 == 0); // WARNING: move check elsewhere.
			this.indexCount = attr.elementCount;
			assert(attr.typeCount == 1);
			this.type = attr.type;
			this.offset = 0;
			this.content = attr.content;
		}

		bool present() {
			return content.ptr !is null;
		}

		uint[T][] getContent(uint T)() {
			// assert(T == getGLenumDrawModeCount(drawMode));
			switch (type) {
				case GL_UNSIGNED_BYTE:
					return (cast(ubyte[T][]) content).to!(uint[T][]);
				case GL_UNSIGNED_SHORT:
					return (cast(ushort[T][]) content).to!(uint[T][]);
				case GL_UNSIGNED_INT:
					return (cast(uint[T][]) content);
				default:
					assert(0, "IndexAttribute type incorrect: " ~ type.to!string);
			}
		}
	}

	string name;
	ShaderProgram shaderProgram;
	GLenum drawMode;
	protected uint vao;

	Index index;

	/// Associations correlate Attributes to Bindings.
	/// See_Also: [glVertexAttribBinding](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glVertexAttribBinding.xhtml)
	Association[uint] associations; // associates attributes to bindings

	/// Bindings are indexed by their corresponding binding point.
	/// See_Also: [glBindVertexBuffer](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindVertexBuffer.xhtml)
	Binding[uint] bindings;

	bool indexed() {
		bool b = index.attr.present();
		assert(b == (index.buffer !is null));
		return b;
	}

	protected struct Association {
		Mesh.Attribute attr;
		GLuint relativeOffset;
		uint bindingIndex;
	}

	protected struct Index {
		IndexAttribute attr;
		Buffer buffer;

		this(IndexAttribute attr) {
			this.attr = attr;
			if (attr.present())
				this.buffer = new Buffer(attr.content);
		}
	}

	protected void setIndex(IndexAttribute attr) {
		this.index = Index(attr);
		if (attr.present())
			glVertexArrayElementBuffer(vao, index.buffer.buffer);
	}

	protected void setIndexCount(GLsizei count) {
		this.index.attr.indexCount = count;
	}

	protected struct Binding {
		Buffer buffer;
		size_t size;
		size_t offset;
		GLsizei stride; // >= 1

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
			for (size_t i = offset; i < offset + size; i += stride)
				content ~= buffer.content[i .. i + elementSize];
			return content;
		}
	}

	this(ShaderProgram shaderProgram, string name = null, GLenum drawMode = GL_TRIANGLES) {
		glCreateVertexArrays(1, &vao);
		writeln("Mesh created: " ~ vao.to!string);

		this.name = (name is null) ? vdName!Mesh : name;
		this.shaderProgram = shaderProgram;
		this.drawMode = drawMode;
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteVertexArrays(1, &vao);
		printf("Mesh removed: %u\n", vao);
	}

	abstract void drawSetup(Node node);

	void draw(Node node) {
		shaderProgram.use();
		// shader.setUniform("modelMatrix", node.modelMatrix);
		shaderProgram.setUniform(0, node.modelMatrix); // modelMatrix
		glBindVertexArray(vao);
		drawSetup(node);

		assert(index.attr.indexCount > 0);
		if (indexed())
			glDrawElements(drawMode, index.attr.indexCount, index.attr.type, cast(void*) index.attr.offset);
		else
			glDrawArrays(drawMode, index.attr.offset, index.attr.indexCount);
	}

	enum AttributeLayout {
		SEPERATE,
		INTERLEAVED
	}

	void setAttributes(Mesh.Attribute[] attributes, uint[] attributeindices, AttributeLayout layout) {
		assert(attributes.length > 0);
		assert(attributes.length == attributeindices.length);

		if (layout == AttributeLayout.SEPERATE) {
			foreach (attrIndex, attr; attributes)
				setAttribute(attr, attributeindices[attrIndex]);
		} else if (layout == AttributeLayout.INTERLEAVED) {
			GLsizei elementCount = attributes[0].elementCount;
			size_t size = 0;
			foreach (attr; attributes) {
				assert(attr.elementCount == elementCount);
				size += attr.size;
			}
			GLsizei elementSize = (size / elementCount).to!GLsizei;

			ubyte[] content;
			content.reserve(size);
			foreach (i; 0 .. elementCount) {
				foreach (attr; attributes) {
					size_t attrOffset = i * attr.elementSize;
					content ~= attr.content[attrOffset .. attrOffset + attr.elementSize];
				}
			}

			Buffer buffer = new Buffer(content);
			Binding binding = Binding(buffer, content.length, 0, elementSize);
			uint bindingIndex = setBinding(binding);

			GLuint relativeOffset = 0;
			foreach (attrIndex, attr; attributes) {
				setAssociation(Association(attr, relativeOffset, bindingIndex), cast(uint) attrIndex);
				relativeOffset += attr.elementSize;
			}
		} else
			assert(0);
	}

	void setAttribute(Mesh.Attribute attr, uint attrIndex) {
		Buffer buffer = new Buffer(attr.content);
		Binding binding = Binding(buffer, attr.size(), 0, attr.elementSize);
		uint bindingIndex = setBinding(binding);
		setAssociation(Association(attr, 0, bindingIndex), attrIndex);
	}

	static void setWireframe(bool on = false) {
		glPolygonMode(GL_FRONT_AND_BACK, on ? GL_LINE : GL_FILL);
	}

	static void setPointSize(float size = 1) {
		glPointSize(size);
	}

	static void setLineWidth(float size = 1) {
		glLineWidth(size);
	}

private:
	void setAssociation(Association assoc, uint attrIndex) {
		assert(attrIndex !in associations, "Mesh.Attribute index already set");
		assert(assoc.bindingIndex in bindings, "Required binding not present");
		Mesh.Attribute attr = assoc.attr;

		glEnableVertexArrayAttrib(vao, attrIndex);
		glVertexArrayAttribFormat(vao, attrIndex, attr.typeCount, attr.type, attr.normalised, assoc.relativeOffset);
		glVertexArrayAttribBinding(vao, attrIndex, assoc.bindingIndex);

		this.associations[attrIndex] = assoc;
	}

	void unsetAssociation(uint attrIndex) {
		Association assoc = associations[attrIndex];
		glDisableVertexArrayAttrib(vao, attrIndex);
		associations.remove(attrIndex);

		uint bindingIndex = assoc.bindingIndex;
		foreach (a; associations) {
			if (a.bindingIndex == bindingIndex)
				return; // Binding still in use.
		}
		removeBinding(bindingIndex); // Binding no longer in use.
	}

	static int _maxBindings = -1;
	int getMaxBindings() { // Generally 16
		if (_maxBindings == -1) {
			glGetIntegerv(GL_MAX_VERTEX_ATTRIB_BINDINGS, &_maxBindings);
			debug writeln("MAX attrib point # found to be:" ~ _maxBindings.to!string);
		}
		return _maxBindings;
	}

	uint setBinding(Binding binding) {
		assert(binding.stride > 0, "Stride should be higher than 0 but was: " ~ binding.stride.to!string);

		uint bindingIndex = 0;
		int maxBindings = getMaxBindings();
		while (bindingIndex < maxBindings) { // Linear search for first unoccupied binding point.
			if (bindingIndex !in bindings)
				break;
			if (bindingIndex == maxBindings - 1)
				assert(0, "All binding points occupied");
			bindingIndex += 1;
		}

		glVertexArrayVertexBuffer(vao, bindingIndex, binding.buffer.buffer, binding.offset, binding.stride);
		this.bindings[bindingIndex] = binding;
		return bindingIndex;
	}

	void removeBinding(uint bindingIndex) {
		glVertexArrayVertexBuffer(vao, bindingIndex, 0, 0, 0);
		this.bindings.remove(bindingIndex);
	}

	// TODO: adopt below for non GL_TRIANGLES draw mode? Or exclude?

	public static Vec!3[] generateNormals(Mesh.Attribute positions, IndexAttribute indices) {
		return generateNormals(cast(Vec!3[]) positions.content, indices.present() ? indices.getContent!3() : null);
	}

	/// Calculates a normal attribute using the positions attribute.
	/// Indexed meshes result in surface-weighted per-vertex normals.
	/// Non-indexed meshes merely result in flat per-face normals.
	/// Assumes counter-clockwise front-facing surfaces.
	public static Vec!3[] generateNormals(Vec!3[] positions, uint[3][] indices = null) { // TODO: version with non-surface-weighted per-vertex calculations.
		Vec!3[] normals;

		if (indices is null) { // Tightly packed flat normals
			Vec!3[3][] positionsTriple = cast(Vec!3[3][]) positions;
			normals.reserve(positionsTriple.length);
			foreach (Vec!3[3] pos; positionsTriple) {
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[0];
				Vec!3 n = a.cross(b).normalize();
				normals ~= [n, n, n];
			}
		} else { // Indexed smooth normals
			normals = new Vec!3[positions.length];
			foreach (uint[3] triangle; indices) {
				Vec!3[3] pos = [
					positions[triangle[0]], positions[triangle[1]], positions[triangle[2]],
				];
				Vec!3 a = pos[1] - pos[0];
				Vec!3 b = pos[2] - pos[0];
				Vec!3 n = a.cross(b); // not normalised
				normals[triangle[0]] += n;
				normals[triangle[1]] += n;
				normals[triangle[2]] += n;
			}
			foreach (ref Vec!3 normal; normals)
				normal = normal.normalize();
		}
		return normals;
	}

	public static Vec!4[] generateTangents(Mesh.Attribute positions, Mesh.Attribute normals,
		Mesh.Attribute texCoords, Mesh.IndexAttribute indices) {
		return generateTangents(cast(Vec!3[]) positions.content, cast(Vec!3[]) normals.content,
			cast(Vec!2[]) texCoords.content, indices.present() ? indices.getContent!3() : null);
	}

	/// Calculates a tangent attribute based on the position and normal attributes,
	/// alongside the normal texture corresponding texture coordinate attribute.
	/// As with normals, indexed meshes result in surface-weighted per-vertex tangents.
	/// Nonindexed meshes result in flat per-face tangents.
	/// No tangents are generated when this texture is abscent.
	public static Vec!4[] generateTangents(Vec!3[] positions, Vec!3[] normals, Vec!2[] texCoords,
		uint[3][] indices = null) { // TODO: version with non-surface-weighted per-vertex calculations.
		assert(positions.length == normals.length);
		assert(positions.length == texCoords.length);
		Vec!4[] tangents;

		if (indices is null) { // Tightly packed flat tangents
			Vec!3[3][] positionsTriple = cast(Vec!3[3][]) positions;
			Vec!2[3][] texCoordsTriple = cast(Vec!2[3][]) texCoords;

			tangents.reserve(positionsTriple.length);
			foreach (i; 0 .. positionsTriple.length) {
				// TODO merge tangent calculation repetitions (indexed version)
				Vec!3[3] pos = positionsTriple[i];
				Vec!2[3] uv = texCoordsTriple[i];

				Vec!3 AB = pos[1] - pos[0];
				Vec!3 AC = pos[2] - pos[0];
				Mat!(2, 3) deltaPosM = [AB, AC];

				Vec!2 ABUV = uv[1] - uv[0];
				Vec!2 ACUV = uv[2] - uv[0];
				Mat!2 deltaUVM = [ABUV, ACUV];
				deltaUVM = deltaUVM.inverse();

				Mat!(2, 3) TBM = deltaUVM.mult(deltaPosM);
				Vec!3 T = Vec!3(TBM[0]).normalize();
				Vec!3 B = Vec!3(TBM[1]).normalize();
				assert(T.length == 1, T.toString);
				assert(B.length == 1, B.toString);

				Vec!3 normal = AB.cross(AC); //.normalize();
				float sign = normal.cross(T).dot(B).signbit;

				Vec!4 tangent = T ~ sign;
				tangents ~= [tangent, tangent, tangent];
			}
		} else {
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
				float sign = normal.cross(T).dot(B).signbit;

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
		return tangents;
	}
}
