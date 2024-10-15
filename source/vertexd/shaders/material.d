module vertexd.shaders.material;

import std.conv;
import std.typecons : Nullable;
import vertexd.core;
import vertexd.mesh.buffer;
import vertexd.misc;
import vertexd.shaders.shaderprogram;
import vertexd.shaders.texture;

class Material {
	mixin ID;

	enum AlphaBehaviour {
		OPAQUE,
		MASK,
		BLEND
	}

	string name;
	Buffer buffer;

	// notation: allignment-padding
	Vec!(4, float) baseColor_factor = Vec!(4, float)(1); // 0-16
	float metalFactor = 1; // 16-20
	float roughnessFactor = 1; // 20-24
	// padding (24-32)
	Vec!(3, float) emission_factor = Vec!(3, float)(0); // 32 - 44
	// padding (44-48)

	// 48 - 128
	union {
		struct {
			BindlessTexture baseColor_texture = null; // TODO: Potentially SRGB
			BindlessTexture metal_roughness_texture = null;
			BindlessTexture normal_texture = null;
			BindlessTexture occlusion_texture = null;
			BindlessTexture emission_texture = null;
		}

		BindlessTexture[5] textures;
	}

	// TODO
	AlphaBehaviour alpha_behaviour = AlphaBehaviour.OPAQUE;
	float alpha_threshold = 0.5;
	bool twosided = false;

	private static Material _defaultMaterial = null;
	static Material defaultMaterial() {
		if (_defaultMaterial is null)
			_defaultMaterial = new Material().initialize();
		return _defaultMaterial;
	}

	this(string name = null) {
		this.name = (name is null) ? idName() : name;
		buffer = new Buffer(false);
	}

	Material initialize() {
		if (baseColor_texture !is null)
			baseColor_texture.initialize(true, true);
		if (metal_roughness_texture !is null)
			metal_roughness_texture.initialize(false, true);
		if (normal_texture !is null)
			normal_texture.initialize(false, true);
		if (occlusion_texture !is null)
			occlusion_texture.initialize(false, true);
		if (emission_texture !is null)
			emission_texture.initialize(true, true);

		ubyte[] content;
		content ~= toBytes(baseColor_factor);
		content ~= toBytes(metalFactor);
		content ~= toBytes(roughnessFactor);
		content ~= padding(8);
		content ~= toBytes(emission_factor);
		content ~= padding(4);
		foreach (texture; textures)
			content ~= BindlessTexture.bufferBytes(texture);
		buffer.setContent(content);
		return this;
	}

	void use() {
		ShaderProgram.setUniformBuffer(2, buffer);

		foreach (texture; textures)
			if (texture !is null)
				texture.load();
	}
}
