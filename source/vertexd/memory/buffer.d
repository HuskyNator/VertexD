module vertexd.memory.buffer;

import bindbc.opengl;

final class Buffer {
    uint buffer = 0;
    const size_t size;
    const uint flags;

    // Note modification can always be done 'server side'
    // Even clear and invalidate work.
    enum StaticStorage = 0u;
    alias DynamicStorage = GL_DYNAMIC_STORAGE_BIT;
    alias ClientStorage = GL_CLIENT_STORAGE_BIT;
    alias MapRead = GL_MAP_READ_BIT;
    alias MapWrite = GL_MAP_WRITE_BIT;
    alias MapPersistent = GL_MAP_PERSISTENT_BIT;
    alias MapCoherent = GL_MAP_COHERENT_BIT;

    this(size_t byteSize, uint flags) {
        this.size = byteSize;
        this.flags = flags;
        glCreateBuffers(1, &buffer);
        glNamedBufferStorage(buffer, byteSize, null, flags);
    }

    this(ubyte[] data, uint flags = 0u) {
        this.size = data.length;
        this.flags = flags;
        glCreateBuffers(1, &buffer);
        glNamedBufferStorage(buffer, data.length, data.ptr, flags);
    }

    void upload(ubyte[] data, size_t offset = 0) {
        assert(offset + data.length <= size);
        assert(flags & DynamicStorage);
        glNamedBufferSubData(buffer, offset, data.length, data.ptr);
    }

    // TODO: editing/getting (slice/index overloads)
    // TODO: mapping

    ~this() {
        glDeleteBuffers(1, &buffer);
    }
}
