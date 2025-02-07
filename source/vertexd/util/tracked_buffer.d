module vertexd.util.tracked_buffer;

import vertexd.memory.buffer;
import vertexd.util.tracked_struct;

struct TrackedBuffer(T) {
    TrackedStruct!(T) trackedStruct;
    alias this = trackedStruct;

    Buffer buffer;
    void initBuffer() {
        buffer = new Buffer(bytes(), Buffer.DynamicStorage);
    }

    ubyte[T.sizeof] bytes() {
        return *cast(ubyte[T.sizeof]*)&trackedStruct.value;
    }

    void upload() {
        if (trackedStruct.changed) {
            buffer.upload(bytes());
            trackedStruct.changed = false;
        }
    }
}
