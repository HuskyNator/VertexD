module vertexd.renderer.renderer;

import vertexd.core.window;
import vertexd.mesh.mesh;
import vertexd.world.components.component;
import vertexd.world.node;

abstract class Renderer {
    void renderDispatch(Window window, Node tree) {
        foreach (Node node; tree) {
            foreach (Component component; node.components) {
                renderDispatch(window, node, component);
            }
        }
    }

    void render(Window window, Node owner);

    void renderDispatch(Window window, Node owner, Component component);

    /// Templated render call dispatcher\
    /// Resolves Components to Types and calls their matching render functions in the order provided.
    mixin template RenderDispatcher(Types...) {
        import vertexd.world.components.component;

        override void renderDispatch(Window window, Node owner, Component component) {
            static foreach (T; Types) {
                if (T val = cast(T) component)
                    return render(window, owner, val);
            }
        }
    }
}
