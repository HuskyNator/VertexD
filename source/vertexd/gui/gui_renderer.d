module vertexd.gui.gui_renderer;

import bindbc.opengl;
import vdmath;
import vertexd.core.window;
import vertexd.gui.node;
import vertexd.memory.buffer;
import vertexd.mesh.primitive;
import vertexd.renderer.renderer;
import vertexd.shaders.shaderprogram;

// TODO: add scissor test
class GuiRenderer {
    static StaticShaderProgram blockShader = StaticShaderProgram(
        "shaders/gui/block.vert", "shaders/gui/block.frag");
    Mesh quad;
    // Buffer windowUBO;

    this() {
        quad = Primitive.createQuad(true);
        // windowUBO = new Buffer(4 * double.sizeof, Buffer.DynamicStorage);
    }

    void render(const Window window, UiNode root) {
        // windowUBO.upload(window.bounds);
        // if (UiBlock node = cast(UiBlock) root)
        if (root.renderNodeStyle)
            renderNode(window, root);

        foreach (UiNode contentNode; root.getContent())
            if (contentNode !is null)
                render(window, contentNode);

        foreach (UiNode child; root.children) // Todo: can replace with queue
            render(window, child);
    }

    void renderNode(const Window window, UiNode node) {
        if (node is null)
            return;

        ShaderProgram shader = blockShader.get();
        shader.use();

        Vec!(2, float) anchor = cast(Vec!(2, float))(
            (node.bounds.topLeft - window.windowPosition) / window.size);
        Vec!(2, double) globalSize = node.bounds.size();
        Vec!(2, float) size = cast(Vec!(2, float))(globalSize / window.size);
        float aspectRatio = window.aspectRatio();

        // shader.setUniformBuffer(0, windowUBO);
        shader.setUniform(0, anchor);
        shader.setUniform(1, size);
        shader.setUniform(2, node.zDepth);

        float radius;
        if (node.radius.relative)
            radius = node.radius.value * ((globalSize.x <= globalSize.y) ? size.x * aspectRatio : size.y) / 2;
        else
            radius = node.radius.value / window.pixelHeight;

        shader.setUniform(3, radius);
        node.style.texture.bind(0);
        shader.setUniform(4, node.style.color);
        shader.setUniform(5, aspectRatio);
        // shader.setUniform(6, window.pixelSize);

        quad.vertexArray.bind();
        glDrawElements(GL_TRIANGLES, quad.indexBinding.elementCount,
            quad.indexBinding.elementType, cast(void*)
            quad.indexBinding.bufferOffset);
    }
}
