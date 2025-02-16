module vertexd.memory.bindless_texture;

import bindbc.opengl;
import vertexd.memory.texture;
import vertexd.memory.sampler;

version (OpenGLBindless) class BindlessTexture {
    ulong handle = 0;
    bool resident = false;

    this(Texture texture) {
        this.handle = glGetTextureHandleARB(texture.texture);
    }

    this(Texture texture, Sampler sampler) {
        this.handle = glGetTextureSamplerHandleARB(texture.texture, sampler.sampler);
    }

    ~this() {
        makeNonResident();
    }

    void makeResident() {
        if (!resident) {
            glMakeTextureHandleResidentARB(handle);
            resident = true;
        }
    }

    void makeNonResident() {
        if (resident) {
            glMakeTextureHandleNonResidentARB(handle);
            resident = false;
        }
    }
}
