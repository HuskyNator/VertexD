module vertexd.mesh.material;

import vdmath;
import vertexd.memory.buffer;
import vertexd.shaders.shaderprogram;
import vertexd.util.ids;
import vertexd.util.tracked_buffer;

import vertexd.memory.texture;
import vertexd.memory.bindless_texture;

abstract class Material {
    mixin ID;
    ShaderProgram shader;

    Buffer materialBuffer();
    void uploadData();

    final void upload() {
        uploadData();
        Buffer buffer = materialBuffer();
        if (materialBuffer !is null && shader !is null)
            shader.setUniformBuffer(ShaderProgram.materialBindIndex, buffer);
    }
}

final class FlatMaterial : Material {
    this() {
        setID();
        this.shader = ShaderProgram.flatShaderProgram.get();
    }

    override Buffer materialBuffer() {
        return null;
    }

    override void uploadData() {
    }
}

final class TexturedMaterial : Material {
    version (OpenGLBindless)
        BindlessTexture texture;
    else
        Texture texture;

    this() {
        setID();
        this.shader = ShaderProgram.texturedShaderProgram.get();
    }

    this(Texture texture) {
        this();
        this.texture = texture;
    }

    override Buffer materialBuffer() {
        return null;
    }

    override void uploadData() {
        if (texture is null)
            return;
        version (OpenGLBindless) {
            texture.makeResident();
            shader.setUniformHandle(0, texture.handle);
        } else {
            texture.bind(0);
        }
    }
}
