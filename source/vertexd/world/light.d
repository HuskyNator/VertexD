module vertexd.world.light;

import vertexd.mesh.buffer;
import vertexd.core.mat;
import vertexd.shaders.shader;
import vertexd.world.node;
import vertexd.world.world;
import std.conv : to;
import std.exception : enforce;
import vertexd.misc;

enum max_lights = 512;

class LightSet { // TODO: rework lights ubo's & seperate different light types
	private uint[Light] lights;
	private Buffer uniformBuffer;

	invariant (lights.length <= max_lights);

	this() {
		uniformBuffer = new Buffer(true);
		Shader.setShaderStorageBuffer(1, uniformBuffer);
	}

	void add(Light l) {
		uint index = cast(uint) lights.length;
		lights[l] = index;
		setBuffer(l);
	}

	void remove(Light l) {
		uint index = lights[l];
		lights.remove(l);
		removeBuffer(index);
	}

	void setBuffer(Light l) {
		uint index = lights[l];
		ubyte[] content = l.getBytes();
		uniformBuffer.changeContent(&l.lightS, index * Light.byteSize, Light.byteSize);
	}

	void removeBuffer(uint index) {
		uniformBuffer.cutContent(index * Light.lightS.byteSize, Light.lightS.byteSize);
	}
}

class Light : Node.Attribute {
	static enum Type : uint {
		FRAGMENT = 0,
		DIRECTIONAL = 1,
		SPOTLIGHT = 2
	}

	struct LightS {
		Type type; // 0-4
		float strength; // 4-8
		float range; // 8-12
		float innerAngle; // 12-16
		float outerAngle; // 16-20
		// pading (20-32)
		Vec!3 color; // 32-44 padding (44-48)
		Vec!3 location; // 48-60 padding (60-64)
		Vec!3 direction; // 64-76 padding (76-80)

		enum byteSize = 80;
		ubyte[] getBytes() {
			ubyte[] bytes;
			bytes ~= toBytes(type);
			bytes ~= toBytes(strength);
			bytes ~= toBytes(range);
			bytes ~= toBytes(innerAngle);
			bytes ~= toBytes(outerAngle);

			bytes ~= padding(12);
			bytes ~= toBytes(color);
			bytes ~= padding(4);
			bytes ~= toBytes(location);
			bytes ~= padding(4);
			bytes ~= toBytes(direction);
			bytes ~= padding(4);
			assert(bytes.length == byteSize,
				"Light bytes expected " ~ byteSize.to!string ~ " but got " ~ bytes.length.to!string);
			return bytes;
		}
	}

	LightS lightS;
	alias lightS this;

	this(Type type, Vec!3 color, precision strength, precision range = precision.infinity,
		precision innerAngle = precision.nan, precision outerAngle = precision.nan) {
		this.type = type;
		this.color = color;
		this.strength = strength;
		this.range = range;
		this.innerAngle = innerAngle;
		this.outerAngle = outerAngle;
	}

	void update(World world, Node parent) {
		location = Vec!3(parent.modelMatrix.col(3)[0 .. 3]);
		direction = Vec!3(parent.modelMatrix.mult(Vec!4([0, 0, -1, 0]))[0 .. 3]).normalize();
		world.lightSet.setBuffer(this);
	}
}
