module vertexd.mesh.mesh;

import vdmath;
import vertexd.memory.vao;
import vertexd.mesh.material;
import vertexd.shaders.shaderprogram;
import vertexd.world.components;

/// Simple Mesh Implementation
class Mesh : Component {
    VAO vertexArray;
    ShaderProgram shader;
    Material material;

    static ShaderProgram _flatShader;
    static ShaderProgram flatShader() {
        if (_flatShader is null)
            _flatShader = new ShaderProgram("./flat.vert", "./flat.frag");
        return _flatShader;
    }

    override void update(Node caller) {
    }

    override void postUpdate(Node caller) {
    }

    override void postUpdate(Node owner) {
    }

    this(Vec!3[] vertex, uint[] indices, Material material, ShaderProgram shader = null) {
        assert(indices.length % 3 == 0);
        vertexArray = new VAO();
        vertexArray.setAttribute(vertex, 0u, 0u, false);
        vertexArray.setIndices(indices);

        if (shader is null)
            shader = flatShader;

        this.material = material;
        this.shader = flatShader;
    }
}
