module vertexd.memory.buffer;

import bindbc.opengl;

final class Buffer {
    uint buffer = 0;
    const size_t size;
    const uint flags;

    /// Buffer usage flags. Can be combined combined using bitwise or (`|`).
    enum StorageFlag : uint {
        None = 0u,
        Static = 0u, // alias
        DynamicStorage = GL_DYNAMIC_STORAGE_BIT, /// Allow client-side updating ($(LREF Buffer.upload) & glNamedBufferSubData)
        ClientStorage = GL_CLIENT_STORAGE_BIT,
        MapRead = GL_MAP_READ_BIT,
        MapWrite = GL_MAP_WRITE_BIT,
        MapPersistent = GL_MAP_PERSISTENT_BIT,
        MapCoherent = GL_MAP_COHERENT_BIT
    }

    this(const size_t byteSize, const StorageFlag flags = StorageFlag.None) {
        this.size = byteSize;
        this.flags = flags;
        glCreateBuffers(1, &this.buffer);
        glNamedBufferStorage(this.buffer, byteSize, null, flags);
    }

    this(T)(const T[] data, const StorageFlag flags = StorageFlag.None) {
        this.size = data.length * T.sizeof;
        this.flags = flags;
        glCreateBuffers(1, &this.buffer);
        glNamedBufferStorage(this.buffer, this.size, data.ptr, flags);
    }

    void upload(T)(const T[] data, size_t offset = 0) {
        assert(offset + (data.length * T.sizeof) <= this.size);
        assert(this.flags & StorageFlag.DynamicStorage);
        glNamedBufferSubData(buffer, offset, data.length, data.ptr);
    }

    // TODO
    // ubyte[] download(size_t offset = 0, size_t downloadSize = this.size) {
    //     ubyte[] ret;
    //     glGetNamedBufferSubData(this.buffer, offset, downloadSize, ret.ptr);
    // }

    void download(ref ubyte[] downloadBuffer, size_t offset = 0, size_t downloadSize = this.size) {
        // if(downloadBuffer.length)
        // TODO
        glGetNamedBufferSubData(this.buffer, offset, downloadSize, downloadBuffer.ptr);
    }

    // TODO: editing/getting (slice/index overloads)
    // TODO: mapping

    ~this() {
        glDeleteBuffers(1, &buffer);
    }
}
