module vertexd.mesh.material;

import vertexd.memory.buffer;
import vdmath;
import vertexd.util.templates;
import vertexd.core.ids;

abstract class Material {
    mixin ID;
    void upload();
    Buffer buffer();
}

//TODO: textures
class ObjMaterial : Material {
    mixin TrackedBufferStruct!(Data, "data", true);
    string name;
    struct Data {
        align(16) Vec!3 ka = Vec!3(0.2, 0.2, 0.2);
        align(16) Vec!3 kd = Vec!3(0.8, 0.8, 0.8);
        align(16) Vec!3 ks = Vec!3(1, 1, 1);
        float ns = 1;
        uint illum = 2;
    }

    this(string name) {
        this.name = name;
        setID();
        initBuffer();
    }

    this(string name, Vec!3 ka, Vec!3 kd, Vec!3 ks, float ns, uint illum) {
        this.ka = ka;
        this.kd = kd;
        this.ks = ks;
        this.ns = ns;
        this.illum = illum;
    }
}
