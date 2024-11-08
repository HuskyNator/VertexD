module vertexd.mesh.material;

import vertexd.memory.buffer;
import vdmath;
import vertexd.util.templates;
import vertexd.core.ids;

class Material {
    struct Data {
        Vec!4 color;
    }

    mixin ID;
    mixin TrackedProperties!(Data, "data");
    mixin BufferStruct!(_data, true);

    this() {
        setID();
        initBuffer();
    }

    this(Vec!4 color) {
        this._data.color = color;
        this();
    }
}
