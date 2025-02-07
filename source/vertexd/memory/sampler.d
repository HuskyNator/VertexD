module vertexd.memory.sampler;

import bindbc.opengl;
import vertexd.core.core;
import vertexd.core.ids;

class Sampler {
	mixin ID!();
	uint sampler;
	/// Beware parameters become immutable once used with bindless textures.
	Parameters parameters;
	alias this = parameters;

	/// Beware only certain colors can be used in combination with bindless textures.
	struct Parameters {
		Wrap wrapS = Wrap.REPEAT;
		Wrap wrapT = Wrap.REPEAT;
		MinFilter minFilter = MinFilter.NEAREST_MIPMAP_LINEAR;
		MagFilter magFilter = MagFilter.LINEAR;
		float[4] borderColor = [0, 0, 0, 0];
		version (OpenGL46) float anisotropic = 1.0f;
	}

	enum Wrap : uint {
		REPEAT = GL_REPEAT,
		MIRRORED_REPEAT = GL_MIRRORED_REPEAT,
		CLAMP_TO_EDGE = GL_CLAMP_TO_EDGE,
		CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER,
		MIRROR_CLAMP_TO_EDGE = GL_MIRROR_CLAMP_TO_EDGE,
	}

	enum MinFilter : uint {
		NEAREST = GL_NEAREST,
		LINEAR = GL_LINEAR,
		NEAREST_MIPMAP_NEAREST = GL_NEAREST_MIPMAP_NEAREST,
		LINEAR_MIPMAP_NEAREST = GL_LINEAR_MIPMAP_NEAREST,
		NEAREST_MIPMAP_LINEAR = GL_NEAREST_MIPMAP_LINEAR,
		LINEAR_MIPMAP_LINEAR = GL_LINEAR_MIPMAP_LINEAR
	}

	enum MagFilter : uint {
		NEAREST = GL_NEAREST,
		LINEAR = GL_LINEAR
	}

	@disable this();

	this(Parameters parameters = Parameters()) {
		this.parameters = parameters;

		glCreateSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_WRAP_S, parameters.wrapS);
		glSamplerParameteri(sampler, GL_TEXTURE_WRAP_T, parameters.wrapT);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, parameters.minFilter);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, parameters.magFilter);
		glSamplerParameterfv(sampler, GL_TEXTURE_BORDER_COLOR, parameters.borderColor.ptr);

		version (OpenGL46) {
			float maxAnisotropic;
			glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY, &maxAnisotropic);
			if (parameters.anisotropic > maxAnisotropic)
				this.parameters.anisotropic = maxAnisotropic;
			glSamplerParameterf(sampler, GL_TEXTURE_MAX_ANISOTROPY, this.parameters.anisotropic);
		}
	}

	~this() {
		glDeleteSamplers(1, &sampler);
	}

	void bind(uint textureUnit) {
		glBindSampler(textureUnit, sampler);
	}
}
