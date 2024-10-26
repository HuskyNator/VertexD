module vertexd.mesh.mesh;
import vertexd.shaders.shaderprogram;
import vertexd.shaders.material;

class Mesh : Component {
    VAO vertexArray;
    Buffer vertexBuffer;
    IndexBuffer indexBuffer;

    ShaderProgram shader;
    Material material;
}
