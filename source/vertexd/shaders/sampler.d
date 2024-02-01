module vertexd.shaders.sampler;
import bindbc.opengl;
import std.conv;
import std.stdio;
import std.typecons : Nullable;
import vertexd.core.core;

class Sampler {
	uint id;
	string name;

	Wrap wrapS;
	Wrap wrapT;
	MinFilter minFilter;
	MagFilter magFilter;

	enum Wrap : uint {
		CLAMP_TO_EDGE = GL_CLAMP_TO_EDGE,
		MIRROR_CLAMP_TO_EDGE = GL_MIRROR_CLAMP_TO_EDGE,
		CLAMP_TO_BORDER = GL_CLAMP_TO_BORDER,
		REPEAT = GL_REPEAT,
		MIRRORED_REPEAT = GL_MIRRORED_REPEAT
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

	this(string name, Wrap wrapS = Wrap.REPEAT, Wrap wrapT = Wrap.REPEAT,
		MinFilter minFilter = MinFilter.NEAREST, MagFilter magFilter = MagFilter.NEAREST, bool anisotropic = false) {
		this.name = name;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.minFilter = minFilter;
		this.magFilter = magFilter;

		glCreateSamplers(1, &id);
		glSamplerParameteri(id, GL_TEXTURE_WRAP_S, wrapS);
		glSamplerParameteri(id, GL_TEXTURE_WRAP_T, wrapT);
		glSamplerParameteri(id, GL_TEXTURE_MIN_FILTER, minFilter);
		glSamplerParameteri(id, GL_TEXTURE_MAG_FILTER, magFilter);

		if (anisotropic) {
			static float maxAnisotripic;
			glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY, &maxAnisotripic);
			glSamplerParameterf(id, GL_TEXTURE_MAX_ANISOTROPY, maxAnisotripic);
		}

		writeln("Sampler created: " ~ id.to!string);
	}

	~this() {
		glDeleteSamplers(1, &id);
		write("Sampler removed: ");
		writeln(id);
	}

	void use(uint location) {
		glBindSampler(location, id);
	}

	bool usesMipmap() {
		return (minFilter == GL_NEAREST_MIPMAP_NEAREST || minFilter == GL_LINEAR_MIPMAP_NEAREST
				|| minFilter == GL_NEAREST_MIPMAP_LINEAR || minFilter == GL_LINEAR_MIPMAP_LINEAR);
	}

}
