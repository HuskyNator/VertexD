///
module vertexd.memory.vao;

import vertexd.gl;
import vertexd.memory.buffer;
import bindbc.opengl;
import vdmath;

class VAO {
    static VAO current;
    uint vao;
    Buffer[16] vbos; // or Buffer[uint]?
    Buffer indexBuffer;

    this() {
        glCreateVertexArrays(1, &vao);
    }

    ~this() {
        glDeleteVertexArrays(1, &vao);
    }

    void bind() {
        if (current is this)
            return;
        glBindVertexArray(vao);
        current = this;
    }

    /// Sets attribute format
    /// Params:
    ///   index = attribute index
    ///   size = type size, one of: 1,2,3,4
    ///   type = type of attribute: https://www.khronos.org/opengl/wiki/vertex_Specification#Component_type
    ///   bufferOffset = starting offset of attribute in buffer storage
    ///   normalize = whether data should be normalized
    /// TODO: No support for packed values yet.
    void setAttributeFormat(uint index, ubyte size, GL.Type type, uint bufferOffset, bool normalize = false) {
        assert(size >= 1 && size <= 4);
        if (type == GL.Type.Bool)
            type = GL.Type.UByte;
        glEnableVertexArrayAttrib(vao, index);

        if (type == GL.Type.Double)
            glVertexArrayAttribLFormat(vao, index, size, type, bufferOffset);
        else if (type == GL.Type.Float || type == GL.Type.HalfFloat)
            glVertexArrayAttribFormat(vao, index, size, type, normalize, bufferOffset);
        else
            glVertexArrayAttribIFormat(vao, index, size, type, bufferOffset);
        return;
    }

    /// Binds a buffer to the vao.
    /// Params:
    ///   buffer = buffer to bind
    ///   bufferIndex = vao buffer binding point
    ///   startOffset = start offset into the buffer
    ///   stride = stride between elements in buffer
    void bindBuffer(Buffer buffer, uint bufferIndex, size_t startOffset, int stride) {
        assert(bufferIndex < 16);
        vbos[bufferIndex] = buffer;
        glVertexArrayVertexBuffer(vao, bufferIndex, buffer.buffer, startOffset, stride);

    }

    void bindAttributeToBuffer(uint attribIndex, uint bufferIndex) {
        glVertexArrayAttribBinding(vao, attribIndex, bufferIndex);
    }

    /// Utility function, creates a constant buffer for `data`, sets the attribute format & binds the buffer.
    /// Params:
    ///   data = data to bind to attribute
    ///   bufferIndex = vao buffer binding point
    ///   attribIndex = attribute to set and bind to
    ///   normalize = whether data should be normalized
    void setAttribute(ubyte L, T)(const T[L][] data, uint bufferIndex, uint attribIndex, bool normalize = false) {
        Buffer buffer = new Buffer(cast(ubyte[]) data);
        bindBuffer(buffer, bufferIndex, 0, Vec!(L, T).sizeof);

        setAttributeFormat(attribIndex, L, GL.getType!T, 0, normalize);
        bindAttributeToBuffer(attribIndex, bufferIndex);
    }

    /// Utility function, creates a constant buffer for `data`, sets the attribute format & binds the buffer.
    /// Specialized to create an interleaved buffer.
    /// Params:
    ///   data = data to bind to attribute
    ///   bufferIndex = vao buffer binding point
    ///   attribIndeces = attributes to set and bind to
    void setAttributes(T)(const T[] data, uint bufferIndex, uint[T.tupleof.length] attributeIndices)
            if (is(T == struct)) {
        // Create & Bind Buffer
        Buffer buffer = new Buffer(cast(ubyte[]) data);
        bindBuffer(buffer, bufferIndex, 0, T.sizeof);

        // Set all field attributes.
        setAttributes!T(bufferIndex, attributeIndices);
    }

    void setAttributes(T)(uint bufferIndex, uint[T.tupleof.length] attributeIndices)
            if (is(T == struct)) {
        static foreach (i, Field; T.tupleof) {
            {
                static if (is(typeof(Field) : FT[L], FT, size_t L))
                    setAttributeFormat(attributeIndices[i], L, GL.getType!FT, Field.offsetof, false);
                else
                    setAttributeFormat(attributeIndices[i], 1, GL.getType!(typeof(Field)), 0, false);
            }
            bindAttributeToBuffer(vao, attributeIndices[i], bufferIndex);
        }
    }

    void setIndexBuffer(Buffer indexBuffer) {
        this.indexBuffer = indexBuffer;
        glVertexArrayElementBuffer(vao, indexBuffer.buffer);
    }
}
