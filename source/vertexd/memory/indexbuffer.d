module vertexd.memory.indexbuffer;
import vertexd.gl;
import vertexd.memory.buffer;

struct IndexBuffer {
    Buffer buffer;
    int elementCount;
    size_t bufferOffset;
    GL.Type elementType;

    this(Buffer buffer, int elementCount, size_t bufferOffset, GL.Type type) {
        this.buffer = buffer;
        this.elementCount = elementCount;
        this.bufferOffset = bufferOffset;
        this.elementType = elementType;
    }

    this(T)(const T[] indices, uint flags = 0u)
            if (is(T == ubyte) || is(T == ushort) || is(T == uint)) {
        this.elementCount = cast(int) indices.length;
        this.bufferOffset = 0;
        this.elementType = GL.getType!T;
        this.buffer = new Buffer(cast(ubyte[]) indices, flags);
    }

    this(ubyte[] data, GL.Type type, uint flags = 0u) {
        assert(type == GL.Type.UByte || type == GL.Type.UShort || type == GL.Type.UInt);
        assert(data.length % GL.getTypeSize(type) == 0);
        this.elementCount = cast(int)(data.length / GL.getTypeSize(type));
        this.bufferOffset = 0;
        this.buffer = new Buffer(data, flags);
    }
}
