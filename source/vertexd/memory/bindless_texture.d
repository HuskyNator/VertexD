module vertexd.memory.bindless_texture;

import bindbc.opengl;
import vertexd.memory.texture;
import vertexd.memory.sampler;

class BindlessTexture {
    ulong handle = 0;
    bool resident = false;
    Texture backingTexture;
    Sampler backingSampler;

    this(Texture texture) {
        this.backingTexture = texture;
        this.handle = glGetTextureHandleARB(texture.texture);
    }

    this(Texture texture, Sampler sampler) {
        this.backingTexture = texture;
        this.backingSampler = sampler;
        this.handle = glGetTextureSamplerHandleARB(texture.texture, sampler.sampler);
    }

    this(Args...)(Args args) {
        Texture texture = new Texture(args);
        this(texture);
    }

    alias this = backingTexture;

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
