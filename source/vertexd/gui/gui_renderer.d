module vertexd.gui.gui_renderer;

import bindbc.opengl;
import vdmath;
import vertexd.core.window;
import vertexd.gui.ui_block;
import vertexd.gui.ui_node;
import vertexd.memory.buffer;
import vertexd.mesh.primitive;
import vertexd.renderer.renderer;
import vertexd.shaders.shaderprogram;

class GuiRenderer {
    static StaticShaderProgram blockShader = StaticShaderProgram(
        "shaders/gui/block.vert", "shaders/gui/block.frag");
    Mesh quad;
    // Buffer windowUBO;

    this() {
        quad = Primitive.createQuad(true);
        // windowUBO = new Buffer(4 * double.sizeof, Buffer.DynamicStorage);
    }

    void render(Window window, UiNode root) {
        // windowUBO.upload(window.bounds);
        if (UiBlock block = cast(UiBlock) root)
            renderNode(window, block);

        foreach (UiNode child; root.children) // Todo: can replace with queue
            render(window, child);
    }

    void renderNode(Window window, UiBlock block) {
        ShaderProgram shader = blockShader.get();
        shader.use();

        Vec!(2, float) anchor = cast(Vec!(2, float))(
            (block.globalBound.topLeft - window.windowPosition) / window.size);
        Vec!(2, double) globalSize = block.globalBound.size();
        Vec!(2, float) size = cast(Vec!(2, float))(globalSize / window.size);
        float aspectRatio = window.aspectRatio();

        // shader.setUniformBuffer(0, windowUBO);
        shader.setUniform(0, anchor);
        shader.setUniform(1, size);
        shader.setUniform(2, block.zDepth);

        float radius;
        if (block.radiusRelative)
            radius = ((globalSize.x <= globalSize.y) ? size.x * aspectRatio : size.y) / 2;
        else
            radius = radius / window.pixelHeight;

        shader.setUniform(3, radius);
        shader.setUniform(4, block.color);
        shader.setUniform(5, aspectRatio);
        // shader.setUniform(6, window.pixelSize);

        quad.bind();
        glDrawElements(GL_TRIANGLES, quad.indexBinding.elementCount,
            quad.indexBinding.elementType, cast(void*)
            quad.indexBinding.bufferOffset);
    }
}
