module vertexd.world.node;

import vdmath;
import vertexd.core;
import vertexd.util.misc : removeElement, tryRemove;
import vertexd.world.components.component;
import vertexd.world.transform;

class Node {
	mixin ID;

	Node parent;
	Node[] children;
	Transform _transform;
	Component[] components;

	Mat!4 modelMatrix = Mat!4(1);
	Mat!4 localMatrix = Mat!4(1);
	private bool transformModified = true;
	ulong lastUpdateFrame = 0;
	bool physicsControlled = false;

	this() {
		setID();
	}

	this(Vec!3 position, Vec!3 size = Vec!3(1), Quat rotation = Quat()) {
		this();
		this._transform = Transform(position, size, rotation);
	}

	public nothrow @property {
		Vec!3 position() {
			return _transform.position;
		}

		Quat rotation() {
			return _transform.rotation;
		}

		Vec!3 size() {
			return _transform.size;
		}

		void position(Vec!3 position) {
			_transform.position = position;
			transformModified = true;
		}

		void rotation(Quat rotation) {
			_transform.rotation = rotation;
			transformModified = true;
		}

		void size(Vec!3 size) {
			_transform.size = size;
			transformModified = true;
		}
	}

	/// Returns cached worldPosition.
	/// May be outdated.
	/// See_Also: updateTransformation
	Vec!3 worldPosition() nothrow {
		return Vec!3([modelMatrix[0][3], modelMatrix[1][3], modelMatrix[2][3]]);
	}

	void runUpdates() {
		update();
		updateTransformation(false);
		postUpdate();
	}

	void physicsUpdate() {
		foreach (Component component; components)
			component.physicsUpdate();
		foreach (Node child; children)
			child.physicsUpdate();
	}

	/// Run all components in (sub)tree
	void update() {
		foreach (Component component; components)
			component.update(this);
		foreach (Node child; children)
			child.update();
	}

	void postUpdate() {
		foreach (Component component; components)
			component.postUpdate(this);
		foreach (Node child; children)
			child.postUpdate();
	}

	void updateLocalMatrix() {
		this.localMatrix = Mat!4(0);
		localMatrix[0][0] = _transform.size.x;
		localMatrix[1][1] = _transform.size.y;
		localMatrix[2][2] = _transform.size.z;
		localMatrix[3][3] = 1;

		localMatrix = rotation.toMat!4() ^ localMatrix;

		localMatrix[0][3] = _transform.position.x;
		localMatrix[1][3] = _transform.position.y;
		localMatrix[2][3] = _transform.position.z;
	}

	void updateTransformation(bool parentModified = false, bool parentPhysicsControlled = false) {
		bool update = transformModified || parentModified;
		bool physicsControlled = this.physicsControlled || parentPhysicsControlled;

		if (transformModified)
			updateLocalMatrix();
		if (update) {
			this.modelMatrix = (parent is null || physicsControlled) ? localMatrix
				: parent.modelMatrix.mult(localMatrix);
			this.lastUpdateFrame = Time.frameID();
		}

		foreach (Node child; children)
			child.updateTransformation(update, physicsControlled);

		transformModified = false;
	}

	public void addChild(Node child)
	in (child !is null)
	in (child.parent is null) {
		child.parent = this;
		this.children ~= child;
	}

	public void removeChild(Node child)
	in (child !is null)
	in (child.parent is this) {
		removeElement(children, child);
		child.parent = null;
	}

	public bool tryRemoveChild(Node child) {
		if (child !is null && tryRemoveElement(children, child)) {
			assert(child.parent is this);
			child.parent = null;
			return true;
		}
		return false;
	}

	public void addComponent(Component component) {
		this.components ~= component;
	}

	public void removeComponent(Component component) {
		this.components.removeElement(component);
	}

	// Includes this.
	int opApply(scope int delegate(Node) dg) {
		if (dg(this))
			return 1;
		foreach (Node child; children) // recursion
			if (child.opApply(dg))
				return 1;
		return 0;
	}
}
