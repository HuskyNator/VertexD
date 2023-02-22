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
	static abstract class Attribute { //TODO: add originUpdate? see propogateOrigin todo
		Node owner;
		void addUpdate();
		void removeUpdate();
		void update();
		void logicUpdate();
		void originUpdate(Origin newOrigin);
	}

	static ulong nodeCount = 0;

	string name;
	Node parent;
	Node[] children = [];
	Pose pose;
	Mesh[] meshes = [];

	struct Origin {
		Node root;
		World world;
	}

	Origin origin;
	alias origin this;

	private Node.Attribute[] attributes = [];

	Mat!4 localMatrix = Mat!4(1);
	Mat!4 modelMatrix = Mat!4(1);

	private bool modified = true;

	this(Mesh[] meshes){
		this();
		this.meshes = meshes;
	}

	this() {
		this.name = "Node#" ~ nodeCount.to!string;
		nodeCount += 1;
		this.origin = Origin(this, null);
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

	void update(bool parentModified) {
		bool update = modified || parentModified;

		if (modified)
			updateLocalMatrix();
		if (update) {
			modelMatrix = (parent is null) ? localMatrix : parent.modelMatrix.mult(localMatrix);
			foreach (Node.Attribute e; attributes)
				e.update();
		}

		foreach (Node child; children)
			child.update(update);

		modified = false;
	}

	public void addChild(Node child)
	in (child !is null)
	in (child.parent is null)
	in (child.world is null) {
		child.parent = this;
		child.propogateOrigin(this.origin);
		this.children ~= child;
	}

	public void removeChild(Node child)
	in (child !is null)
	in (child.parent is this)
	in (child.root == root)
	in (child.world == world) {
		remove(children, child);
		child.propogateOrigin(Origin(child, null));
		child.parent = null;
	}

	void propogateOrigin(Origin newOrigin) { //TODO: provide old & new see attribute todo
		foreach (Node.Attribute attribute; attributes)
			attribute.originUpdate(newOrigin); // Perform before overwriting old origin

		this.origin = newOrigin;

		foreach (child; children)
			child.propogateOrigin(newOrigin);
	}

	void addAttribute(Node.Attribute attr) {
		assert(attr.owner is null);
		attr.owner = this;
		this.attributes ~= attr;

		attr.addUpdate();
	}

	void removeAttribute(Node.Attribute attr) {
		assert(attr.owner is this);
		attr.removeUpdate();

		remove(attributes, attr);
		attr.owner = null;
	}
}
