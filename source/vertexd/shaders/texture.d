module vertexd.shaders.texture;
import vertexd.core.mat;
import vertexd.shaders;

struct TextureInfo {
	Texture texture;
	uint textureCoord;

	void use(uint location) {
		texture.use(location);
	}
}

struct NormalTextureInfo {
	TextureInfo textureInfo;
	alias textureInfo this;
	prec normal_scale;

	void use(Shader shader,uint location) {
		shader.setUniform("u_normal_scale", normal_scale);
		textureInfo.use(location);
	}
}

struct OcclusionTextureInfo {
	TextureInfo textureInfo;
	alias textureInfo this;
	prec occlusion_strength;

	void use(Shader shader, uint location) {
		shader.setUniform("u_occlusion_strength", occlusion_strength);
		textureInfo.use(location);
	}
}

struct Texture {
	string name;
	Sampler sampler;
	Image image;

	void use(uint location) {
		sampler.use(location);
		image.use(location);
	}
}
