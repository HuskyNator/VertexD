module vertexd.world.world;

import std.datetime : Duration;
import vertexd.world.light;
import vertexd.world.node;
import vertexd.world.camera;
import std.conv : to;

class World {
	static World[] worlds;

	string name;
	Node[] children = [];
	Camera camera;
	LightSet lightSet;

	this() {
		this.name = "World#" ~ worlds.length.to!string;
		worlds ~= this;
		lightSet = new LightSet();
	}

	public void draw() {
		camera.use();
		foreach (Node child; children)
			child.draw();
	}

	public void logicStep(Duration deltaT) {
		foreach (Node child; children)
			child.logicStep(deltaT);
	}

	public void update(bool force = false) {
		foreach (Node child; children)
			child.update(this, force);
	}
}
