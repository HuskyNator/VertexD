module vertexd.world.components.camera;

import std.math.trigonometry : tan;
import vdmath;
import vdmath.misc : degreesToRadians;
import vertexd.core.ids;
import vertexd.util.tracked_buffer;
import vertexd.world.components.component;
import vertexd.shaders.shaderprogram;

class Camera : Component {
    align(4) struct Data {
    align(4):
        Mat!4 projectionMatrix = Mat!4(1);
        Mat!4 cameraMatrix = Mat!4(1);
        Vec!3 cameraPosition;
    }

    mixin ID;
    TrackedBuffer!Data trackedBuffer;

    this() {
        setID();
        trackedBuffer.initBuffer();
    }

    this(Mat!4 projectionMatrix) {
        this.trackedBuffer.value.projectionMatrix = projectionMatrix;
        this.trackedBuffer.value.cameraMatrix = Mat!4(1); // Bug: compiler
        this();
    }

    void upload(ShaderProgram shader, uint cameraBindIndex) {
        trackedBuffer.upload();
        shader.setUniformBuffer(cameraBindIndex, trackedBuffer.buffer);
    }

    override void update(Node caller) {
    }

    override void postUpdate(Node caller) {
        this.trackedBuffer.cameraPosition = caller.worldPosition();
        this.trackedBuffer.cameraMatrix = caller.modelMatrix.inverse();
    }

    static Mat!4 perspectiveProjection(float aspectRatio = (1920.0 / 1080.0),
        float horizontalFov = degreesToRadians(90.0), // vertical fov 90°
        float nearplane = 0.1, float farplane = 1000) {
        float hSlope = tan(horizontalFov / 2.0);
        float vSlope = hSlope / aspectRatio;
        float zConstant = (farplane + nearplane) / (farplane - nearplane);
        float zNuminator = (2.0 * farplane * nearplane) / (farplane - nearplane);
        return Mat!4([
            [1 / hSlope, 0.0, 0.0, 0.0],
            [0.0, 1 / vSlope, 0.0, 0.0],
            [0.0, 0.0, -zConstant, -zNuminator],
            [0.0, 0.0, -1.0, 0.0]
        ]);
    }

    static Mat!4 orthographicProjection(float width = 100, float height = 100,
        float nearplane = 0.1, float farplane = 100) {
        float zConstant = -(farplane + nearplane) / (farplane - nearplane);
        return Mat!4([
            [1.0 / width, 0.0, 0.0, 0.0],
            [0.0, 1.0 / height, 0.0, 0.0],
            [0, 0, 2.0 / (farplane - nearplane), zConstant],
            [0.0, 0.0, 0.0, 1.0]
        ]);
    }
}
