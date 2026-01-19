module vertexd.mesh.mesh;

import vdmath;
import vertexd.memory.vao;
import vertexd.mesh.material;
import vertexd.shaders.shaderprogram;
import vertexd.world.components;
import vertexd.gl;
import vertexd.memory.buffer;

struct IndexBinding {
    int elementCount;
    size_t bufferOffset;
    GL.Type elementType;

    this(int elementCount, size_t bufferOffset, GL.Type elementType) {
        assert(elementType == GL.Type.UByte || elementType == GL.Type.UShort || elementType == GL
                .Type.UInt);
        this.elementCount = elementCount;
        this.bufferOffset = bufferOffset;
        this.elementType = elementType;
    }

    this(T)(const T[] indices) if (is(T == ubyte) || is(T == ushort) || is(T == uint)) {
        assert(indices.length < int.max);
        this.elementCount = cast(int) indices.length;
        this.bufferOffset = 0;
        this.elementType = GL.getType!T;
    }
}

/// Simple Mesh Implementation
class Mesh : Component { // TODO: struct not class?
    Material material;
    VAO vertexArray;
    IndexBinding indexBinding;

    void setIndices(T)(const T[] data, bool dynamic = false) {
        assert(vertexArray !is null);
        this.indexBinding = IndexBinding(cast(int) data.length, 0, IndexBinding.getType!T);
        Buffer indexBuffer = new Buffer(cast(ubyte[]) data, dynamic ? Buffer.DynamicStorage
                : Buffer.StaticStorage);
        vertexArray.setIndexBuffer(indexBuffer);
    }

    final void setIndices(Buffer indexBuffer, int elementCount, size_t bufferOffset, GL
            .Type elementType) {
        vertexArray.setIndexBuffer(indexBuffer);
        this.indexBinding = IndexBinding(elementCount, bufferOffset, elementType);
    }

    override void update(Node caller) {
    }

    override void postUpdate(Node caller) {
    }

    this(Material material) {
        this.vertexArray = new VAO();
        this.material = material;
    }

    this(const float[3][] vertex, const uint[] indices, Material material) {
        assert(indices.length % 3 == 0);
        vertexArray = new VAO();
        vertexArray.setAttribute(vertex, 0u, 0u, false);
        setIndices(indices);
        this.material = material;
    }
}
