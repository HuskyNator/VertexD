module vertexd.renderer.simple.simple_renderer;

import bindbc.opengl;
import std.stdio: stderr, writeln;
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

    enum uint cameraBindIndex = 0;
    enum uint materialBindIndex = 1;
    enum uint modelMatrixUniformIndex = 0;

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
        void setShader(ShaderProgram newShader) {
            shader = newShader;
            newShader.use();
        }

        void setMaterial(Material newMaterial) {
            material = newMaterial;
            material.upload();
            shader.setUniformBuffer(materialBindIndex, material.buffer);
        }

        // Render queue
        setShader(renderQueue[0].mesh.shader);
        setMaterial(renderQueue[0].mesh.material);
        foreach (Camera camera; cameraQueue) {
            camera.upload();
            shader.setUniformBuffer(cameraBindIndex, camera.buffer);
            foreach (RenderQueue.Element instance; renderQueue) {
                // Update state
                if (instance.mesh.shader !is shader)
                    setShader(instance.mesh.shader);
                if (instance.mesh.material !is material)
                    setMaterial(instance.mesh.material);

                // Render mesh
                VAO vao = instance.mesh.vertexArray;
                vao.bind();
                shader.setUniform(modelMatrixUniformIndex, instance.owner.modelMatrix);
                glDrawElements(GL_TRIANGLES, instance.mesh.indexBinding.elementCount, instance.mesh.indexBinding.elementType, cast(void*) 0);
            }
        }

        // Output to window
        window.swapBuffers();
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); // clear old buffer
    }
}
