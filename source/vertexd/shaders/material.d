module vertexd.shaders.material;

import std.conv;
import std.typecons : Nullable;
import vertexd.core.mat;
import vertexd.mesh.buffer;
import vertexd.misc;
import vertexd.shaders.shader;
import vertexd.shaders.texture;

class Material {
	enum AlphaBehaviour {
		OPAQUE,
		MASK,
		BLEND
	}

	string name = "Default Material";
	Buffer buffer;

	// notation: allignment-padding
	Vec!(4, float) baseColor_factor = Vec!(4, float)(1); // 0-16
	float metalFactor = 1; // 16-20
	float roughnessFactor = 1; // 20-24
	// padding (24-32)
	Vec!(3, float) emission_factor = Vec!(3, float)(0); // 32 - 44
	// padding (44-48)

	// 48 - 128
	Texture baseColor_texture; // TODO: Potentially SRGB
	Texture metal_roughness_texture;
	Texture normal_texture;
	Texture occlusion_texture;
	Texture emission_texture;

	// TODO
	AlphaBehaviour alpha_behaviour = AlphaBehaviour.OPAQUE;
	prec alpha_threshold = 0.5;
	bool twosided = false;

	private static Material _defaultMaterial = null;
	static Material defaultMaterial() {
		if (_defaultMaterial is null)
			_defaultMaterial = new Material().initialize();
		return _defaultMaterial;
	}

	this() {
		buffer = new Buffer(false);
	}

	Material initialize() {
		baseColor_texture.initialize(true);
		metal_roughness_texture.initialize(false);
		normal_texture.initialize(false);
		occlusion_texture.initialize(false);
		emission_texture.initialize(true);

		ubyte[] content;
		content ~= toBytes(baseColor_factor);
		content ~= toBytes(metalFactor);
		content ~= toBytes(roughnessFactor);
		content ~= padding(8);
		content ~= toBytes(emission_factor);
		content ~= padding(4);
		content ~= baseColor_texture.bufferBytes();
		content ~= metal_roughness_texture.bufferBytes();
		content ~= normal_texture.bufferBytes();
		content ~= occlusion_texture.bufferBytes();
		content ~= emission_texture.bufferBytes();
		buffer.setContent(content);
		return this;
	}

	void use() {
		Shader.setUniformBuffer(2, buffer);

		baseColor_texture.load();
		metal_roughness_texture.load();
		normal_texture.load();
		occlusion_texture.load();
		emission_texture.load();
	}
}
