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
    // alias render = Dispatched.renderDispatch;

    static immutable uint cameraBindIndex = 0;
    static immutable uint modelMatrixUniformIndex = 0;
    static immutable uint materialBindIndex = 1;

    RenderQueue renderQueue;
    Camera[] cameraQueue; // Todo: support multiple

    // Queue camera for rendering
    void render(Window window, Node owner, Camera camera) {
        cameraQueue ~= camera;
    }

    // Queue mesh for rendering
    void render(Window window, Node owner, Mesh mesh) {
        if (mesh.shader is null) {
            stderr.writeln("Shader missing");
            return;
        }
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
            camera.upload(shader, cameraBindIndex);
        }

        void setMaterial(ShaderProgram shader, Material newMaterial) {
            material = newMaterial;
            material.upload(shader, materialBindIndex);
        }

        // Render queue
        foreach (Camera camera; cameraQueue) {
            setShader(renderQueue[0].mesh.shader, camera);
            setMaterial(shader, renderQueue[0].mesh.material);
            foreach (RenderQueue.Element instance; renderQueue) {
                // Update state
                if (instance.mesh.shader !is shader)
                    setShader(instance.mesh.shader, camera);
                if (instance.mesh.material !is material)
                    setMaterial(shader, instance.mesh.material);
                // Render mesh
                VAO vao = instance.mesh.vertexArray;
                vao.bind();
                shader.setUniform(modelMatrixUniformIndex, instance.owner.modelMatrix);
                glDrawElements(GL_TRIANGLES, instance.mesh.indexBinding.elementCount, instance
                        .mesh.indexBinding.elementType, cast(void*) instance
                        .mesh.indexBinding.bufferOffset);
            }
        }
    }
}
