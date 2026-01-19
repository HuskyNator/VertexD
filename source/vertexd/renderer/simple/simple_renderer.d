module vertexd.renderer.simple.simple_renderer;

import bindbc.opengl;
import std.stdio : stderr, writeln;
import vdmath;
import vertexd.core.window;
import vertexd.memory;
import vertexd.memory.vao;
import vertexd.mesh.material;
import vertexd.mesh.mesh;
import vertexd.renderer.renderer;
import vertexd.renderer.simple.render_queue;
import vertexd.shaders.shaderprogram;
import vertexd.world.components.camera;
import vertexd.world.node;

class SimpleRenderer : Renderer {
    // Setup dispatcher
    mixin Renderer.RenderDispatcher!(Mesh, Camera) Dispatched;

    RenderQueue renderQueue;
    Camera[] cameraQueue; // Todo: support multiple

    // Queue camera for rendering
    void render(Window window, Node owner, Camera camera) {
        cameraQueue ~= camera;
    }

    // Queue mesh for rendering
    void render(Window window, Node owner, Mesh mesh) {
        if (mesh.material is null)
            return stderr.writeln("Material missing");
        if (mesh.material.shader is null)
            return stderr.writeln("Shader missing");
        renderQueue.enqueue(owner, mesh);
    }

    override void render(Window window, Node tree) {
        // Reset queues
        cameraQueue.length = 0;
        renderQueue.length = 0;

        // Fill queues
        super.renderDispatch(window, tree);
        if (renderQueue.length == 0 || cameraQueue.length == 0) {
            writeln("Nothing to render, ", renderQueue.length == 0 ? renderQueue.stringof
                    : cameraQueue.stringof, " empty.");
            return;
        }

        // Minimize state changes
        renderQueue.sort();

        // Define utility functions
        ShaderProgram shader;
        Material material;
        void setShader(ShaderProgram newShader, Camera camera) {
            shader = newShader;
            newShader.use();
            camera.upload(newShader);
        }

        void setMaterial(Material newMaterial) {
            material = newMaterial;
            newMaterial.upload();
        }

        // Render queue
        foreach (Camera camera; cameraQueue) {
            setShader(renderQueue[0].mesh.material.shader, camera);
            setMaterial(renderQueue[0].mesh.material);
            foreach (RenderQueue.Element instance; renderQueue) {
                // Update state
                if (instance.mesh.material.shader !is shader)
                    setShader(instance.mesh.material.shader, camera);
                if (instance.mesh.material !is material)
                    setMaterial(instance.mesh.material);
                // Render mesh
                Mesh mesh = instance.mesh;
                mesh.vertexArray.bind();
                shader.setUniform(ShaderProgram.modelMatrixUniformIndex, instance.owner.modelMatrix);
                glDrawElements(GL_TRIANGLES, mesh.indexBinding.elementCount,
                    mesh.indexBinding.elementType, cast(void*)
                    mesh.indexBinding.bufferOffset);
            }
        }
    }
}
