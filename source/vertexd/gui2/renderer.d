module vertexd.gui2.renderer;
import vertexd.shaders;
import vertexd.gui2.ui_element;
import vertexd.core.window;
import vertexd.memory.buffer;
import vertexd.memory.vao;
import vertexd.mesh.primitive;
import bindbc.opengl;
import vdmath;
import vertexd.gui2.image;
import vertexd.memory.bindless_texture;
import std.algorithm.comparison : min;
import vertexd.util : toBytes;
import vertexd.gui.font;
import vertexd.gui2.text;

// TODO: parse through ui tree: split into seperate render commands/shaders
// maybe sort by zDepth (top first->reduce overdraw).
// render opaque first
// render transparent back->front (correctness).

class GuiRenderer {
    static StaticShaderProgram _shaderProgram = StaticShaderProgram(
        "./shaders/gui2/vert.vert", "./shaders/gui2/frag.frag");
    static StaticShaderProgram _textShaderProgram = StaticShaderProgram(
        "./shaders/gui2/text.vert", "./shaders/gui2/text.frag");

    Mesh quad;
    ShaderProgram uiElementShader;
    ShaderProgram textShader;
    float automaticDepthDelta;

    Buffer uiElementInstanceDataBuffer;
    ubyte[] uiElementInstanceData;
    int uiElementInstanceCount;

    Buffer glyphInstanceDataBuffer;
    ubyte[] glyphInstanceData;
    int glyphInstanceCount;

    Buffer debugBuffer;

    this(float automaticDepthDelta = 0) {
        this.quad = Primitive.createQuad(true, null);
        this.uiElementInstanceDataBuffer = new Buffer(UiElementInstanceData.sizeof * 16, Buffer
                .StorageFlag.DynamicStorage);
        this.glyphInstanceDataBuffer = new Buffer(GlyphInstanceData.sizeof * 1024, Buffer
                .StorageFlag.DynamicStorage);
        this.debugBuffer = new Buffer(Vec!(2).sizeof * 6, Buffer.StorageFlag.DynamicStorage);
        this.uiElementShader = GuiRenderer._shaderProgram.get();
        this.textShader = GuiRenderer._textShaderProgram.get();
        this.automaticDepthDelta = automaticDepthDelta;
    }

    struct UiElementInstanceData { // std340
        // all sizes/coordinates normalized
        Vec!(2, float) topLeft;
        Vec!(2, float) size;
        Vec!(4, float) backgroundColor;
        float cornerRadius;
        float zDepth;
        ulong textureHandle;
    }

    struct GlyphInstanceData { // std340
        Vec!(2, int) bottomLeft;
        ulong textureHandle;
        float zDepth;
        int _padding;
    }

    private void queueUiElement(const UiElement element, Window window, float automaticDepth) {
        // Ensure children are queued afterward
        scope (success) {
            foreach (child; element.getChildren())
                queueUiElement(child, window, automaticDepth);
        }

        ulong uiElementTextureHandle = 0;
        if (Image image = cast(Image) element) { // Queue Image render
            BindlessTexture texture = image.texture;
            texture.makeResident();
            uiElementTextureHandle = texture.handle;
        } else if (Text text = cast(Text) element) { // Queue text render
            Font font = text.font;
            Vec!(2, int)[] placements = text.placements;
            assert(placements.length == text.text.length);
            foreach (i, dchar codepoint; text.text) {
                Glyph glyph = font.loadGlyph(codepoint);
                BindlessTexture texture = glyph.texture;
                ulong textureHandle = 0;
                if (texture !is null && codepoint != cast(dchar) '\r' && codepoint != cast(dchar) '\n') {
                    textureHandle = texture.handle;
                    texture.makeResident();
                }

                Vec!(2, int) screenPlacement = Vec!(2, int)(placements[i].x, window.pixelSize.y - placements[i]
                        .y);
                GlyphInstanceData glyphData = GlyphInstanceData(screenPlacement, textureHandle, element.zDepth + automaticDepth);
                automaticDepth += automaticDepthDelta;
                glyphInstanceData ~= toBytes(glyphData);
                glyphInstanceCount += 1;
            }
        }

        // Queue UiElement box render
        if (element.backgroundColor.w == 0 && uiElementTextureHandle == 0)
            return; // Don't render self if invisible. Still renders children.

        // Add UiElement to instancing buffer.
        float width = element.bounds.width();
        float height = element.bounds.height();
        float minSize = (width < height) ? width : height;

        Vec!(2, int) windowSize = window.pixelSize;
        int minWindowSize = (windowSize.x < windowSize.y) ? windowSize.x : windowSize.y;

        float cornerRadius = element.cornerRadius.getAbsolute(minSize);
        if (cornerRadius > minWindowSize / 2.0)
            cornerRadius = minWindowSize / 2.0;

        // Create instance data
        UiElementInstanceData UiElementInstance = UiElementInstanceData(
    topLeft: Vec!2(element.bounds.left, element.bounds.top) / windowSize,
    size: Vec!2(element.bounds.width(), element.bounds.height()) / windowSize,
    backgroundColor: element.backgroundColor,
    cornerRadius: cornerRadius,
    zDepth: element.zDepth + automaticDepth,
    textureHandle: uiElementTextureHandle
        );

        // Add to data array
        automaticDepth += automaticDepthDelta;
        uiElementInstanceData ~= toBytes(UiElementInstance);
        uiElementInstanceCount += 1;
    }

    void render(Window window, UiElement root) {
        uiElementShader.use();
        quad.vertexArray.bind();

        // Prepare box instance data
        this.uiElementInstanceData.length = 0;
        this.uiElementInstanceCount = 0;

        uiElementInstanceData ~= toBytes(window.pixelSize);
        uiElementInstanceData ~= toBytes(cast(int) 0); // std430 padding
        uiElementInstanceData ~= toBytes(cast(int) 0); // std430 padding

        // Prepare text instance data
        this.glyphInstanceData.length = 0;
        this.glyphInstanceCount = 0;

        glyphInstanceData ~= toBytes(window.pixelSize);
        // glyphInstanceData ~= toBytes(cast(int) 0); // std430 padding

        // Queue all elements
        float automaticStartDepth = 0;
        queueUiElement(root, window, automaticStartDepth);

        // Prepare box instance data buffer
        if (this.uiElementInstanceDataBuffer.size < uiElementInstanceData.length)
            this.uiElementInstanceDataBuffer = new Buffer(uiElementInstanceData.length * UiElementInstanceData.sizeof, Buffer
                    .StorageFlag.DynamicStorage);
        else
            uiElementInstanceDataBuffer.upload(uiElementInstanceData);
        uiElementShader.setShaderStorageBuffer(0, uiElementInstanceDataBuffer);

        // Render UiElement boxes
        glDrawElementsInstanced(GL_TRIANGLES,
            quad.indexBinding.elementCount, quad.indexBinding.elementType,
            cast(void*) quad.indexBinding.bufferOffset, uiElementInstanceCount);

        // Prepare text instance buffer
        if (glyphInstanceCount == 0)
            return;
        textShader.use();
        quad.vertexArray.bind();

        if (this.glyphInstanceDataBuffer.size < glyphInstanceData.length) {
            this.glyphInstanceDataBuffer = new Buffer(glyphInstanceData.length, Buffer
                    .StorageFlag.DynamicStorage);
            this.debugBuffer = new Buffer(glyphInstanceCount * Vec!(2).sizeof * 6, Buffer
                    .StorageFlag.DynamicStorage);
        } else
            glyphInstanceDataBuffer.upload(glyphInstanceData);
        textShader.setShaderStorageBuffer(0, glyphInstanceDataBuffer);
        textShader.setShaderStorageBuffer(1, debugBuffer);

        // Render text
        glDrawElementsInstanced(GL_TRIANGLES,
            quad.indexBinding.elementCount, quad.indexBinding.elementType,
            cast(void*) quad.indexBinding.bufferOffset, glyphInstanceCount);
    }
}
