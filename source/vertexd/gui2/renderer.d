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

// TODO: parse through ui tree: split into seperate render commands/shaders
// maybe sort by zDepth (top first->reduce overdraw).
// render opaque first
// render transparent back->front (correctness).

class GuiRenderer {
    static StaticShaderProgram _shaderProgram = StaticShaderProgram(
        "./shaders/gui2/vert.vert", "./shaders/gui2/frag.frag");

    Mesh quad;
    ShaderProgram shader;
    float automaticDepthDelta;

    Buffer instanceDataBuffer;
    ubyte[] instanceData;
    int instanceCount;

    this(float automaticDepthDelta = 0) {
        this.quad = Primitive.createQuad(true, null);
        this.instanceDataBuffer = new Buffer(InstanceData.sizeof * 16, Buffer
                .StorageFlag.DynamicStorage);
        this.shader = GuiRenderer._shaderProgram.get();
        this.automaticDepthDelta = automaticDepthDelta;
    }

    struct InstanceData { // std340
        // all sizes/coordinates normalized
        Vec!(2, float) topLeft;
        Vec!(2, float) size;
        Vec!(4, float) backgroundColor;
        float cornerRadius;
        float zDepth;
        ulong textureHandle;
    }

    void render(Window window, UiElement root) {
        float automaticDepth = automaticDepthDelta;
        shader.use();
        quad.vertexArray.bind();

        this.instanceData.length = 0;
        this.instanceCount = 0;
        import std.stdio;

        writeln(window.pixelSize.sizeof);
        instanceData ~= toBytes(window.pixelSize);
        instanceData ~= toBytes(cast(int) 0); // std430 padding
        instanceData ~= toBytes(cast(int) 0); // std430 padding

        void addInstance(const UiElement element) {
            scope (exit) {
                foreach (child; element.getChildren())
                    addInstance(child);
            }

            ulong textureHandle = 0;
            if (Image image = cast(Image) element) {
                BindlessTexture texture = image.texture;
                texture.makeResident();
                textureHandle = texture.handle;
            }

            if (element.backgroundColor.w == 0 && textureHandle == 0)
                return; // Don't render self. Still renders children.

            float width = element.bounds.width();
            float height = element.bounds.height();
            float minSize = (width < height) ? width : height;

            Vec!(2, int) windowSize = window.pixelSize;
            int minWindowSize = (windowSize.x < windowSize.y) ? windowSize.x : windowSize.y;

            float cornerRadius = element.cornerRadius.getAbsolute(minSize);
            if (cornerRadius > minWindowSize / 2.0)
                cornerRadius = minWindowSize / 2.0;

            InstanceData instance = InstanceData(
        topLeft: Vec!2(element.bounds.left, element.bounds.top) / windowSize,
        size: Vec!2(element.bounds.width(), element.bounds.height()) / windowSize,
        backgroundColor: element.backgroundColor,
        cornerRadius: cornerRadius,
        zDepth: element.zDepth + automaticDepth,
        textureHandle: textureHandle
            );

            automaticDepth += automaticDepthDelta;
            instanceData ~= toBytes(instance);
            instanceCount += 1;
        }

        addInstance(root);

        if (this.instanceDataBuffer.size < instanceData.length)
            this.instanceDataBuffer = new Buffer(instanceData.length, Buffer
                    .StorageFlag.DynamicStorage);
        else
            instanceDataBuffer.upload(instanceData);
        shader.setShaderStorageBuffer(0, instanceDataBuffer);

        glDrawElementsInstanced(GL_TRIANGLES,
            quad.indexBinding.elementCount, quad.indexBinding.elementType,
            cast(void*) quad.indexBinding.bufferOffset, instanceCount);
    }
}
