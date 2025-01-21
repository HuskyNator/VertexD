module vertexd.util.templates.buffer_struct;
public import vertexd.memory.buffer;

mixin template BufferStruct(alias instance, bool tracked) {
    Buffer buffer;

    void initBuffer() {
        buffer = new Buffer(bytes(), Buffer.DynamicStorage);
    }

    ubyte[typeof(instance).sizeof] bytes() {
        return *cast(ubyte[typeof(instance).sizeof]*)&instance;
    }

    void upload() {
        static if (tracked) {
            if (changed) {
                changed = false;
                buffer.upload(bytes());
            }
        } else
            buffer.upload(bytes());
    }
}
