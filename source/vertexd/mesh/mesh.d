module vertexd.mesh.mesh;

import bindbc.opengl;
import vertexd.shaders.material;
import vertexd.shaders.shader;
import vertexd.world.node;
import std.conv : to;
import std.stdio : writeln;
import std.typecons : Nullable;

final class Mesh {
	struct Attribute {
		uint binding;
		GLenum type;
		ubyte typeCount; // 1-4 / 9 / 16
		bool matrix;
		bool normalised;
		size_t elementCount;
		uint beginning;
	}

	struct Binding {
		uint buffer;
		size_t size; // bytes
		size_t beginning; // bytes
		int stride; //bytes
	}

	struct VertexIndex {
		Nullable!uint buffer;
		int vertexCount;
		int beginning; // bytes
		GLenum type; // ubyte/ushort/uint
	}

	string name;
	private uint vao;
	private VertexIndex vertexIndex;
	Shader shader;
	Material material;

	public this(string name, Attribute[] attributes, Binding[] bindings,
		VertexIndex vertexIndex, Shader shader, Material material) {
		this.name = name;
		this.shader = shader;
		this.material = material;

		glCreateVertexArrays(1, &vao);
		writeln("Mesh created: " ~ vao.to!string);

		for (uint i = 0; i < attributes.length; i++) {
			Attribute e = attributes[i];
			glEnableVertexArrayAttrib(vao, i);
			glVertexArrayAttribFormat(vao, i, e.typeCount, e.type, e.normalised, e.beginning);
			glVertexArrayAttribBinding(vao, i, e.binding);
		}

		for (uint i = 0; i < bindings.length; i++) {
			Binding k = bindings[i];
			assert(k.stride > 0,
				"Stride should be higher than 0 but was: " ~ k.stride.to!string);
			glVertexArrayVertexBuffer(vao, i, k.buffer, k.beginning, k.stride);
		}

		this.vertexIndex = vertexIndex;
		if (!vertexIndex.buffer.isNull())
			glVertexArrayElementBuffer(vao, vertexIndex.buffer.get());
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteVertexArrays(1, &vao);
		printf("Mesh removed: %u\n", vao);
	}

	public void draw(Node node) {
		shader.use();
		shader.setUniform("nodeMatrix", node.nodeMatrix);
		glBindVertexArray(vao);
		if (vertexIndex.buffer.isNull())
			glDrawArrays(GL_TRIANGLES, vertexIndex.beginning, vertexIndex.vertexCount);
		else
			glDrawElements(GL_TRIANGLES, vertexIndex.vertexCount, vertexIndex.type, cast(void*) vertexIndex
					.beginning);
	}
}
