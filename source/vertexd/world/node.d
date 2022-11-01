module vertexd.world.node;

import std.conv : to;
import std.datetime : Duration;
import vertexd.core.mat;
import vertexd.core.quaternions;
import vertexd.mesh.mesh;
import vertexd.misc;
import vertexd.world.world;

struct Pose {
	Vec!3 location = Vec!3([0, 0, 0]);
	// Vec!3 draai = Vec!3([0, 0, 0]);
	Quat rotation = Quat(1.0f, 0.0f, 0.0f, 0.0f);
	Vec!3 size = Vec!3([1, 1, 1]);
}

class Node {
	static ulong nodeCount = 0;
	interface Attribute {
		void update(World world, Node parent);
	}

	string name;
	Node parent;
	Node[] children = [];
	Pose pose;
	Mesh[] meshes = [];

	Attribute[] attributes = [];

	Mat!4 localMatrix = Mat!4(1);
	Mat!4 modelMatrix = Mat!4(1);

	private bool modified = true;

	this() {
		this.name = "Node#" ~ nodeCount.to!string;
	}

	public @property {
		Vec!3 location() nothrow {
			return pose.location;
		}

		Quat rotation() nothrow {
			return pose.rotation;
		}

		Vec!3 size() nothrow {
			return pose.size;
		}

		void location(Vec!3 location) nothrow {
			pose.location = location;
			modified = true;
		}

		void rotation(Quat rotation) nothrow {
			pose.rotation = rotation;
			modified = true;
		}

		void size(Vec!3 size) nothrow {
			pose.size = size;
			modified = true;
		}
	}

	Vec!3 worldLocation() {
		return Vec!3([modelMatrix[0][3], modelMatrix[1][3], modelMatrix[2][3]]);
	}

	void draw() {
		foreach (Mesh mesh; meshes) {
			mesh.draw(this);
		}
		foreach (Node child; children)
			child.draw();
	}

	// TODO
	void logicStep(Duration deltaT) {
		foreach (Node child; children) {
			child.logicStep(deltaT);
		}
	}

	void updateLocalMatrix() {
		this.localMatrix = Mat!4();
		localMatrix[0][0] = pose.size.x;
		localMatrix[1][1] = pose.size.y;
		localMatrix[2][2] = pose.size.z;
		localMatrix[3][3] = 1;

		localMatrix = rotation.toMat!4() ^ localMatrix;

		localMatrix[0][3] = pose.location.x;
		localMatrix[1][3] = pose.location.y;
		localMatrix[2][3] = pose.location.z;
	}

	void update(World world, bool parentModified) {
		bool update = modified || parentModified;

		if (modified)
			updateLocalMatrix();
		if (update) {
			modelMatrix = (parent is null) ? localMatrix : parent.modelMatrix.mult(localMatrix);
			foreach (Node.Attribute e; attributes)
				e.update(world, this);
		}

		foreach (Node child; children)
			child.update(world, update);

		modified = false;
	}

	public void addChild(Node child)
	in (child !is null)
	in (child.parent is null) {
		child.parent = this;
		this.children ~= child;
	}

	public void removeChild(Node child)
	in (child !is null) {
		remove(children, child);
		child.parent = null;
	}
}