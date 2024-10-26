module vertexd.renderer.simple_renderer;

import vertexd.mesh.mesh;
import vertexd.renderer.renderer;
import vertexd.world.node;
import vertexd.core.window : Window;
import vertexd.world.components;
import bindbc.opengl;
import vertexd.shaders.shaderprogram;

class SimpleRenderer : Renderer {
    // Setup dispatcher
    mixin Renderer.RenderDispatcher!(Mesh, Camera) Dispatched;
    alias render = Dispatched.render;

    struct RenderInstance {
        Mesh mesh;
        Mat!4* modelMatrix;
        Hash hash;

        union Hash {
            struct {
                uint shaderID;
                uint materialID;
            }

            ulong hash;
        }

        this(Mesh mesh, Mat!4* modelMatrix) {
            this.mesh = mesh;
            this.modelMatrix = modelMatrix;
            this.hash.shaderID = mesh.shader.id;
            this.hash.materialID = mesh.material.id;
        }
    }

    RenderInstance[] renderQueue;
    Camera[] cameraQueue; // Todo: support multiple

    // Queue mesh for rendering
    void render(Window window, Node owner, Mesh mesh) {
        renderQueue ~= RenderInstances(mesh, &owner.modelMatrix);
    }

    // Queue camera for rendering
    void render(Window window, Node owner, Camera camera) {
        cameras ~= camera;
    }

    override void render(Window window, Node tree) {
        // Reset queues
        renderQueue.length = 0;
        cameraQueue.length = 0;

        // Fill queues
        super.render(window, tree);
        if (renderQueue.length == 0 || cameraQueue.length == 0)
            return;

        // Minimize state changes
        renderQueue.sort!"a.hash<b.hash"();

        // Initialize state
        RenderInstance.Hash currentHash = renderQueue[0].hash;
        ShaderProgram shader = renderQueue[0].mesh.shader;
        shader.use();
        // TODO: set first material

        // Rander queue
        foreach (Camera cam; cameraQueue) {
            foreach (RenderInstance instance; renderQueue) {
                // Update state
                if (instance.hash.hash != currentHash.hash) {
                    currentHash = instance.hash;
                    if (instance.hash.shaderID != currentHash.shaderID) {
                        shader = instance.mesh.shader;
                        shader.use();
                    }
                    //TODO: SET material HERE
                }

                // Render mesh
                // TODO: optimize by moving modelMatrix someplace else (& minimize changing)
                shader.setUniform("modelMatrix", instance.modelMatrix);
                gldrawElements(GL_TRIANGLES, instance.mesh.indexBuffer.elementCount, GL_UNSIGNED_INT, 0);
            }
        }
    }
}
