module vertexd.shaders.sampler;
import bindbc.opengl;
import std.conv;
import std.stdio;
import std.typecons : Nullable;
import vertexd.core.core;

class Sampler {
	string name;
	uint id;

	uint wrapS;
	uint wrapT;
	uint minFilter;
	uint magFilter;

	this(uint wrapS = GL_REPEAT, uint wrapT = GL_REPEAT, uint minFilter = GL_NEAREST,
		uint magFilter = GL_NEAREST, bool anisotropic = true, string name = null) {
		assert(minFilter == GL_NEAREST || minFilter == GL_LINEAR
				|| minFilter == GL_NEAREST_MIPMAP_NEAREST || minFilter == GL_LINEAR_MIPMAP_NEAREST
				|| minFilter == GL_NEAREST_MIPMAP_LINEAR
				|| minFilter == GL_LINEAR_MIPMAP_LINEAR, "Invalid minFilter:" ~ minFilter.to!string);
		assert(magFilter == GL_NEAREST || magFilter == GL_LINEAR, "Invalid magFilter:" ~ magFilter.to!string);

		this.name = (name is null) ? vdName!Sampler : name;
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
