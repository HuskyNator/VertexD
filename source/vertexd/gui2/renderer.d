module vertexd.gui2.renderer;
import vertexd.shaders;
import vertexd.gui2.ui_element;
import vertexd.core.window;
import vertexd.memory.buffer;
import vertexd.memory.vao;
import vertexd.mesh.primitive;


// TODO: parse through ui tree: split into seperate render commands/shaders
// maybe sort by zDepth (top first->reduce overdraw).
// render opaque first
// render transparent back->front (correctness).

class GuiRenderer {
    bool automaticDepthDelta;
    Mesh quad;
    Buffer instanceData;

    this(float automaticDepthDelta = 0){
        this.automaticDepth = automaticDepth;
        this.quad = Primitive.createQuad(true, null);
    }

    struct InstanceData {
        Vec!(2, float) topLeft;
        Vec!(2, float) bottomRight;
        Vec!(4, float) color;
        float cornerRadius;
        float zDepth;
    }

    void render(Window window, UiElement root) {
        + delta
        

    }
}
