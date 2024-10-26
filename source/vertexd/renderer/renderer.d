module vertexd.renderer.renderer;

import vertexd.core.window;
import vertexd.world.node;
import vertexd.world.components;
import vertexd.mesh.mesh;

abstract class Renderer {
    void render(Window window, Node tree) {
        foreach (Node node; tree) {
            foreach (Component component; node.components) {
                render(window, node, component);
            }
        }
    }

    void render(Window window, Node owner, Component component);

    /// Templated render call dispatcher\
    /// Resolves Components to Types and calls their matching render functions in the order provided.
    mixin template RenderDispatcher(Types...) {
        override void render(Window window, Node owner, Component component) {
            static foreach (T; Types) {
                if (T val = cast(T) component)
                    return render(window, owner, component);
            }
        }
    }
}
