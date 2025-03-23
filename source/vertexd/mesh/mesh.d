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

    alias getType = GL.getType;
    alias getTypeSize = GL.getTypeSize;

    this(int elementCount, size_t bufferOffset, GL.Type elementType) {
        assert(elementType == GL.Type.UByte || elementType == GL.Type.UShort || elementType == GL
                .Type.UInt);
        this.elementCount = elementCount;
        this.bufferOffset = bufferOffset;
        this.elementType = elementType;
    }

    this(T)(const T[] indices) if (is(T == ubyte) || is(T == ushort) || is(T == uint)) {
        this.elementCount = cast(int) indices.length;
        this.bufferOffset = 0;
        this.elementType = GL.getType!T;
    }
}

/// Simple Mesh Implementation
class Mesh : Component { // TODO: struct not class?
    ShaderProgram shader;
    Material material;
    VAO vertexArray;
    IndexBinding indexBinding;

    void setIndices(T)(T[] data, bool dynamic = false) {
        assert(vertexArray !is null);
        this.indexBinding = IndexBinding(cast(int) data.length, 0, IndexBinding.getType!T);
        Buffer indexBuffer = new Buffer(cast(ubyte[]) data, dynamic ? Buffer.DynamicStorage
                : Buffer.StaticStorage);
        vertexArray.setIndexBuffer(indexBuffer);
    }

    void setIndices(Buffer indexBuffer, int elementCount, size_t bufferOffset, GL.Type elementType) {
        vertexArray.setIndexBuffer(indexBuffer);
        this.indexBinding = IndexBinding(elementCount, bufferOffset, elementType);
    }

    alias this = vertexArray;

    static ShaderProgram _flatShader;
    static ShaderProgram flatShader() {
        if (_flatShader is null)
            _flatShader = new ShaderProgram("./shaders/flat.vert", "./shaders/flat.geom", "./shaders/flat.frag");
        return _flatShader;
    }

    override void update(Node caller) {
    }

    override void postUpdate(Node caller) {
    }

    this(Material material, ShaderProgram shader) {
        this.vertexArray = new VAO();
        this.material = material;
        this.shader = shader;
    }

    this(float[3][] vertex, uint[] indices, Material material, ShaderProgram shader = null) {
        assert(indices.length % 3 == 0);
        vertexArray = new VAO();
        vertexArray.setAttribute(vertex, 0u, 0u, false);
        setIndices(indices);

        if (shader is null)
            shader = flatShader;

        this.material = material;
        this.shader = flatShader;
    }
}
