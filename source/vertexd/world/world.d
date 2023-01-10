module vertexd.world.world;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.datetime : Duration;
import vertexd.misc : remove;
import vertexd.world.camera;
import vertexd.world.light;
import vertexd.world.node;

class World {
	static World[] worlds;

	string name;
	Node[] roots = [];
	Camera[] cameras = [];
	LightSet lightSet;

	Camera currentCamera = null;
	Camera getCurrentCamera() {
		assert(cameras.length >= 1);
		if (currentCamera is null)
			currentCamera = cameras[0];
		return currentCamera;
	}

	this() {
		this.name = "World#" ~ worlds.length.to!string;
		World.worlds ~= this;
		lightSet = new LightSet();
	}

	public void draw() {
		assert(cameras.length >= 1);
		getCurrentCamera.use();
		foreach (Node root; roots)
			root.draw();
	}

	public void logicStep(Duration deltaT) {
		foreach (Node root; roots)
			root.logicStep(deltaT);
	}

	public void update(bool force = false) {
		foreach (Node root; roots)
			root.update(force);
	}

	void addNode(Node n) {
		assert(n.parent is null);
		assert(n.root is n);
		this.roots ~= n;
		n.origin.worlds ~= this;
		n.propogateOrigin(n.origin);
	}

	void removeNode(Node n) {
		assert(n.root is n && n.worlds.canFind(this));
		remove(roots, n);
		remove(n.origin.worlds, this);
		n.propogateOrigin(n.origin);
	}
}
