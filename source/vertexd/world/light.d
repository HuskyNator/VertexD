module vertexd.world.light;

import vertexd.mesh.buffer;
import vertexd.core.mat;
import vertexd.shaders.shader;
import vertexd.world.node;
import vertexd.world.world;
import std.conv : to;
import std.exception : enforce;

enum max_lights = 512;

class LightSet {
	private uint[Light] lights;
	private Buffer uniformBuffer;

	invariant (lights.length <= max_lights);

	static this() {
		Shader.placeholders["MAX_LIGHTS"] = max_lights.to!string;
	}

	this() {
		uniformBuffer = new Buffer(true);
		Shader.setUniformBuffer(1, uniformBuffer);
	}

	auto opOpAssign(string op)(Light l) if (op == "+") {
		lights[l] = cast(uint) lights.length;
		setUniform(l, cast(uint) (lights.length - 1));
		return this;
	}

	auto opOpAssign(string op)(Light l) if (op == "-") {
		uint old = lights[l];
		lights.remove(l);
		setUniform(Light.LightS(Type.INVALID), old);
		return this;
	}

	void shrink() {
		uniformBuffer.setSize(uint.sizeof + lights.length * Light.LightS.sizeof);
		uint[Light] new_lights;
		uint i = 0;
		foreach (l; lights.byKey()) {
			new_lights[l] = i;
			setUniform(l.lightS, i);
			i += 1;
		}
		uniformBuffer.setContent(&i, uint.sizeof, 0);
		this.lights = new_lights;
	}

	void setUniform(Light l) {
		assert(l in lights, "Light not in LightSet");
		setUniform(l.lightS, lights[l]);
	}

	void setUniform(Light.LightS l, uint index) {
		uint count = cast(uint) lights.length;
		uniformBuffer.setContent(&count, uint.sizeof, 0);
		uniformBuffer.setContent(&l, l.sizeof, cast(int) (uint.sizeof + index * l.sizeof));
	}
}

class Light : Node.Attribute {
	static enum Type {
		FRAGMENT,
		DIRECTIONAL,
		SPOTLIGHT,
		INVALID // __
	}

	struct LightS {
		Type type;
		Vec!3 color;
		precision strength;
		precision range;
		precision innerAngle;
		precision outerAngle;

		Vec!3 location;
		Vec!3 direction;
	}

	LightS lightS;
	alias lightS this;

	this(Type type, Vec!3 color,
		precision strength,
		precision range = precision.infinity,
		precision innerAngle = precision.nan,
		precision outerAngle = precision.nan) {
		this.type = type;
		this.color = color;
		this.strength = strength;
		this.range = range;
		this.innerAngle = innerAngle;
		this.outerAngle = outerAngle;
	}

	void update(World world, Node parent) {
		location = Vec!3(parent.nodeMatrix.col(3)[0 .. 3]);
		direction = Vec!3(parent.nodeMatrix.mult(Vec!4([0, 0, -1, 0]))[0 .. 3]).normalize();
		world.lightSet.setUniform(this);
	}
}
