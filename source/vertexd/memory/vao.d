///
module vertexd.memory.vao;

import vertexd.gl;
import vertexd.memory.buffer;
import bindbc.opengl;
import vdmath;

class VAO {
    static VAO current;
    uint vao;
    size_t elementCount;

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

    /// Binds a buffer to the vao.
    /// Params:
    ///   buffer = buffer to bind
    ///   bufferIndex = vao buffer binding point
    ///   startOffset = start offset into the buffer
    ///   stride = stride between elements in buffer
    void bindBuffer(const Buffer buffer, const uint bufferIndex, const size_t startOffset, const int stride) {
        glVertexArrayVertexBuffer(vao, bufferIndex, buffer.buffer, startOffset, stride);
    }

    void bindAttributeToBuffer(const uint attribIndex, const uint bufferIndex) {
        glVertexArrayAttribBinding(vao, attribIndex, bufferIndex);
    }

    /// Sets attribute format
    /// Params:
    ///   index = attribute index
    ///   size = type size, one of: 1,2,3,4
    ///   type = type of attribute: https://www.khronos.org/opengl/wiki/vertex_Specification#Component_type
    ///   bufferOffset = starting offset of attribute in buffer storage
    ///   normalize = whether data should be normalized
    /// TODO: No support for packed values yet.
    void setAttributeFormat(const uint attribIndex, const ubyte size, GL.Type type, const uint bufferOffset, const bool normalize = false) {
        assert(size >= 1 && size <= 4);
        if (type == GL.Type.Bool) // accept booleans as ubytes
            type = GL.Type.UByte;
        glEnableVertexArrayAttrib(vao, attribIndex);

        if (type == GL.Type.Double)
            glVertexArrayAttribLFormat(vao, attribIndex, size, type, bufferOffset);
        else if (type == GL.Type.Float || type == GL.Type.HalfFloat)
            glVertexArrayAttribFormat(vao, attribIndex, size, type, normalize, bufferOffset);
        else
            glVertexArrayAttribIFormat(vao, attribIndex, size, type, bufferOffset);
        return;
    }

    /// Utility function, creates a constant buffer for `data`, sets the attribute format & binds the buffer.
    /// Params:
    ///   data = data to bind to attribute
    ///   bufferIndex = vao buffer binding point
    ///   attribIndex = attribute to set and bind to
    ///   normalize = whether data should be normalized
    void setAttribute(ubyte L, T)(const T[L][] data, const uint bufferIndex, const uint attribIndex, const bool normalize = false) {
        Buffer buffer = new Buffer(data);
        bindBuffer(buffer, bufferIndex, 0, L * T.sizeof);

        setAttributeFormat(attribIndex, L, GL.getType!T, 0, normalize);
        bindAttributeToBuffer(attribIndex, bufferIndex);
    }

    /// Utility function, creates a constant interleaved buffer for (array of structs AoS) `data`, sets the attribute formats & binds the buffer.
    /// Params:
    ///   data = data to bind to attribute
    ///   bufferIndex = vao buffer binding point
    ///   attribIndeces = attributes to set and bind to
    void setAttributes(T)(const T[] data, const uint bufferIndex, const uint[T.tupleof.length] attributeIndices)
            if (is(T == struct)) {
        // Create & Bind Buffer
        Buffer buffer = new Buffer(data);
        bindBuffer(buffer, bufferIndex, 0, T.sizeof);

        // Set all field attributes.
        static foreach (i, Field; T.tupleof) {
            uint attributeIndex = attributeIndices[i];

            static if (is(typeof(Field) : FT[L], FT, size_t L)) // if field type is array
                setAttributeFormat(attributeIndex, L, GL.getType!FT, Field.offsetof, false);
            else
                setAttributeFormat(attributeIndex, 1, GL.getType!(typeof(Field)), 0, false);

            bindAttributeToBuffer(vao, attributeIndex, bufferIndex);
        }
    }

    // TODO: INTERNAL??
    void setIndexBuffer(const Buffer indexBuffer) {
        glVertexArrayElementBuffer(vao, indexBuffer.buffer);
    }

    // TODO: ADD??
    // void setIndices(const uint[] indices) {
    //     Buffer indicesBuffer = new Buffer(indices);
    //     setIndexBuffer(indicesBuffer);
    // }
}
