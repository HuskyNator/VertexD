module vertexd.shaders.material;

import vertexd.core.mat;
import vertexd.shaders.texture;
import vertexd.shaders.shader;
import std.conv;
import std.typecons : Nullable;

struct Material {
	enum AlphaBehaviour {
		OPAQUE,
		MASK,
		BLEND
	}

	string name;
	PBR pbr;
	alias pbr this;
	Vec!3 emission_factor = Vec!3(0);
	AlphaBehaviour alpha_behaviour = AlphaBehaviour.OPAQUE;
	prec alpha_threshold = 0.5;
	bool twosided = false;
	Nullable!NormalTextureInfo normal_texture;
	Nullable!OcclusionTextureInfo occlusion_texture;
	Nullable!TextureInfo emission_texture;

	void use(Shader shader) {
		shader.setUniform("u_color_factor", color_factor);
		if (!color_texture.isNull)
			color_texture.get.use(2);
		shader.setUniform("u_metal", metalFactor);
		shader.setUniform("u_roughness", roughness);
		if (!metal_roughness_texture.isNull)
			metal_roughness_texture.get.use(3);

		if (!normal_texture.isNull)
			normal_texture.get.use(shader, 4);
		if (!occlusion_texture.isNull)
			occlusion_texture.get.use(shader, 5);
		if (!emission_texture.isNull)
			emission_texture.get.use(6);
		shader.setUniform("u_emission_factor", emission_factor);
	}
}

struct PBR {
	Vec!4 color_factor = Vec!4(1);
	precision metalFactor = 1;
	precision roughness = 1;
	Nullable!TextureInfo color_texture; // TOOD: Potentially SRGB
	Nullable!TextureInfo metal_roughness_texture;
}
