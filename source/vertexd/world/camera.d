module vertexd.world.camera;

import vertexd;
import std.math : tan;

class Camera : Node.Attribute {
	mixin ID;

	struct CameraS {
		Mat!4 projectionMatrix = Mat!4(1); // 0-64
		Mat!4 cameraMatrix = Mat!4(1); // 64-128
		Vec!3 location = Vec!3(0); // 128-140 padding(140-144)
	}

	static Buffer uniformBuffer;

	string name;
	CameraS cameraS;
	alias cameraS this;

	this(Mat!4 projectionMatrix, string name = null) {
		this.name = (name is null) ? idName() : name;
		this.projectionMatrix = projectionMatrix;

		if (uniformBuffer is null) {
			uniformBuffer = new Buffer(&cameraS, cameraS.sizeof, true);
			ShaderProgram.setUniformBuffer(0, uniformBuffer);
		}
	}

	override void addUpdate() {
		if (owner.world !is null)
			owner.world.cameras ~= this;
	}

	override void removeUpdate() {
		if (owner.world !is null)
			owner.world.cameras.removeElement(this);
	}

	override void logicUpdate() {
	}

	override void originUpdate(Node.Origin newOrigin) { // WARNING: assuming no transplanting worlds (only remove or add)
		bool removed = newOrigin.world is null;
		if (removed)
			removeElement(owner.world.cameras, this);
		else
			newOrigin.world.cameras ~= this;
	}

	override void update() {
		this.location = Vec!3(owner.modelMatrix.col(3)[0 .. 3]);
		this.cameraMatrix = owner.modelMatrix.inverse();
	}

	void use() {
		uniformBuffer.changeContent(&cameraS, 0, cameraS.sizeof);
	}

	static Mat!4 perspectiveProjection(float aspectRatio = (1920.0 / 1080.0),
		float horizontalFov = degreesToRadians(121.0), // vertical fov 90°
		float nearplane = 0.1, float farplane = 100) {
		float a = 1.0 / tan(horizontalFov / 2.0);
		alias V = nearplane;
		alias A = farplane;
		alias s = aspectRatio;
		float z = -(A + V) / (A - V);
		float y = -(2.0 * A * V) / (A - V);
		return Mat!4([
			[a, 0.0, 0.0, 0.0], [0.0, a * s, 0.0, 0.0], [0.0, 0.0, z, y],
			[0.0, 0.0, -1.0, 0.0]
		]);
	}

	static Mat!4 orthographicProjection(float width = 100, float height = 100,
		float nearplane = 0.1, float farplane = 100) {
		return Mat!4([
			[1 / width, 0, 0, 0], [0, 1 / height, 0, 0],
			[0, 0, 2 / (farplane - nearplane), -(farplane + nearplane) / (farplane - nearplane)],
			[0, 0, 0, cast(float) 1.0]
		]);
	}
}
