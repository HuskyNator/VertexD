module vertexd.mesh.material;

import vertexd.util.ids;
import vertexd.memory.buffer;
import vertexd.shaders.shaderprogram;

abstract class Material {
    mixin ID;
    Buffer buffer();
    void uploadData(ShaderProgram);

    void upload(ShaderProgram shader) {
        uploadData(shader);
        shader.setUniformBuffer(ShaderProgram.materialBindIndex, buffer());
    }
}
