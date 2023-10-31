module vertexd.world.light;

import std.conv : to;
import std.exception : enforce;
import vertexd.core;
import vertexd.mesh.buffer;
import vertexd.misc;
import vertexd.shaders.shaderprogram;
import vertexd.world.node;
import vertexd.world.world;

enum max_lights = 512;

class LightSet { // TODO: rework lights ubo's & seperate different light types
	private uint[Light] lights;
	private Buffer shaderStorageBuffer;

	invariant (lights.length <= max_lights);

	this() {
		shaderStorageBuffer = new Buffer(true);
		ShaderProgram.setShaderStorageBuffer(1, shaderStorageBuffer);
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

	void setBuffer(Light l) { //TODO: single uniform update after changes.
		uint index = lights[l];
		ubyte[] content = l.getBytes();
		shaderStorageBuffer.changeContent(content.ptr, index * Light.byteSize, Light.byteSize);
	}

	void removeBuffer(uint index) {
		shaderStorageBuffer.cutContent(index * Light.lightS.byteSize, Light.lightS.byteSize);
	}
}

class Light : Node.Attribute {
	static enum Type : uint {
		POINT = 0,
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
				"Light bytes expected " ~ byteSize.to!string ~ " but got " ~ bytes
					.length.to!string);
			return bytes;
		}
	}

	string name;
	LightS lightS;
	alias lightS this;

	// TODO: rename strength to intensity
	this(Type type, Vec!3 color, string name = null, precision strength = 1.0,
		precision range = precision.infinity, precision innerAngle = precision.nan, precision outerAngle = precision
		.nan) {
		this.name = (name is null) ? vdName!Light : name;
		this.type = type;
		this.color = color;
		this.strength = strength;
		this.range = range;
		this.innerAngle = innerAngle;
		this.outerAngle = outerAngle;
	}

	override void addUpdate() {
		owner.world.lightSet.add(this);
	}

	override void removeUpdate() {
		owner.world.lightSet.remove(this);
	}

	override void logicUpdate() {
	}

	override void originUpdate(Node.Origin newOrigin) {
		bool removed = newOrigin.world is null;
		if (removed)
			owner.world.lightSet.remove(this);
		else
			newOrigin.world.lightSet.add(this);
	}

	override void update() {
		location = owner.worldLocation;
		direction = Vec!3(owner.modelMatrix.mult(Vec!4([0, 0, -1, 0]))[0 .. 3]).normalize();
		owner.world.lightSet.setBuffer(this);
	}
}
