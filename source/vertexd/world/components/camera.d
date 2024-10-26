module vertexd.world.components.camera;

import vdmath;
import vdmath.misc : degreesToRadians;
import vertexd.core.ids;
import vertexd.world.components.component;
import vertexd.renderer.renderable;
import std.math.trigonometry : tan;

class Camera : Component {
    mixin ID;

    Mat!4 projectionMatrix = Mat!4(1);
    Mat!4 cameraMatrix = Mat!4(1);

    this(Mat!4 projectionMatrix) {
        this.projectionMatrix = projectionMatrix;
    }

    override void update(Node owner) {
    }

    override void postUpdate(Node owner) {
        this.cameraMatrix = owner.modelMatrix.inverse();
    }

    static Mat!4 perspectiveProjection(float aspectRatio = (1920.0 / 1080.0),
        float horizontalFov = degreesToRadians(121.0), // vertical fov 90°
        float nearplane = 0.1, float farplane = 100) {
        float hSlope = 1.0 / tan(horizontalFov / 2.0);
        float vSlope = hSlope * aspectRatio;
        float zConstant = -(farplane + nearplane) / (farplane - nearplane);
        float zNuminator = -(2.0 * farplane * nearplane) / (farplane - nearplane);
        return Mat!4([
            [hSlope, 0.0, 0.0, 0.0],
            [0.0, vSlope, 0.0, 0.0],
            [0.0, 0.0, zConstant, zNuminator],
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
