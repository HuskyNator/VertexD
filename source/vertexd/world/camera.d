module vertexd.world.camera;

import vertexd.mesh.buffer;
import vertexd.core;
import vertexd.shaders.shader;
import vertexd.world;
import std.math : tan;

class Camera : Node.Attribute {
	struct CameraS {
		Mat!4 projectionMatrix = Mat!4(1);
		Mat!4 cameraMatrix = Mat!4(1);
		Vec!3 location = Vec!3(0);
	}

	static Buffer uniformBuffer;

	CameraS cameraS;
	alias cameraS this;

	this(Mat!4 projectionMatrix) {
		this.projectionMatrix = projectionMatrix;

		if (uniformBuffer is null) {
			uniformBuffer = new Buffer(&cameraS, cameraS.sizeof, true);
			Shader.setUniformBuffer(0, uniformBuffer);
		}
	}

	void update(World world, Node parent) {
		this.location = Vec!3(parent.nodeMatrix.col(3)[0 .. 3]);
		this.cameraMatrix = parent.nodeMatrix.inverse();
	}

	void use() {
		uniformBuffer.setContent(&cameraS, cameraS.sizeof);
	}

	static Mat!4 perspectiveProjection(
		precision aspectRatio = (1920.0 / 1080.0),
		precision horizontalFov = 3.14 / 2.0,
		precision nearplane = 0.1,
		precision backplane = 100) {
		precision a = 1.0 / tan(horizontalFov / 2.0);
		alias V = nearplane;
		alias A = backplane;
		alias s = aspectRatio;
		precision z = -(A + V) / (A - V);
		precision y = -(2.0 * A * V) / (A - V);
		return Mat!4([
			[a, 0.0, 0.0, 0.0],
			[0.0, a * s, 0.0, 0.0],
			[0.0, 0.0, z, y],
			[0.0, 0.0, -1.0, 0.0]
		]);
	}
}
