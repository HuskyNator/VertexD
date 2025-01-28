module vertexd.util.templates.buffer_struct;
public import vertexd.memory.buffer;
import vertexd.util.templates.tracked_properties;

/// Template for a data-dedicated buffer.
/// Be sure to call `initBuffer` before using.
/// Params:
///   instance = instance to dedicate buffer to
///   bufferIdentifier = buffer identifier to use
mixin template BufferStruct(alias instance) {
    Buffer _buffer;

    @property Buffer buffer() {
        return _buffer;
    }

    void initBuffer() {
        mixin(bufferIdentifier) = new Buffer(bytes(), Buffer.DynamicStorage);
    }

    ubyte[typeof(instance).sizeof] bytes() {
        return *cast(ubyte[typeof(instance).sizeof]*)&instance;
    }

    void upload() {
        _buffer.upload(bytes());
    }
}

/// Template for a buffer that declares & tracks data.
/// Be sure to call `initBuffer` before using.
/// Params:
/// Type = Type of the data used
/// identifier = data identifier to use
mixin template TrackedBufferStruct(Type, string identifier, bool overrides = false) {
    mixin TrackedProperties!(Type, identifier);
    Buffer _buffer;

    static if (overrides)
        override @property Buffer buffer() {
            return _buffer;
        }
    else
        @property Buffer buffer() {
            return _buffer;
        }

    void initBuffer() {
        _buffer = new Buffer(bytes(), Buffer.DynamicStorage);
    }

    ubyte[Type.sizeof] bytes() {
        return *cast(ubyte[Type.sizeof]*)&mixin('_', identifier);
    }

    static if (overrides) {
        override void upload() {
            if (_changed) {
                _buffer.upload(bytes());
                _changed = false;
            }
        }
    } else
        void upload() {
        if (_changed) {
            _buffer.upload(bytes());
            _changed = false;
        }
    }
}
