module vertexd.shaders.sampler;
import bindbc.opengl;
import std.conv;
import std.stdio;
import std.typecons : Nullable;

class Sampler {
	string name;
	uint id;

	uint wrapS;
	uint wrapT;
	uint minFilter;
	uint magFilter;

	@disable this();

	this(string name, uint wrapS = GL_REPEAT, uint wrapT = GL_REPEAT, uint minFilter = GL_NEAREST,
		uint magFilter = GL_NEAREST) {
		assert(minFilter == GL_NEAREST || minFilter == GL_LINEAR
				|| minFilter == GL_NEAREST_MIPMAP_NEAREST || minFilter == GL_LINEAR_MIPMAP_NEAREST
				|| minFilter == GL_NEAREST_MIPMAP_LINEAR
				|| minFilter == GL_LINEAR_MIPMAP_LINEAR, "Invalid minFilter:" ~ minFilter.to!string);
		assert(magFilter == GL_NEAREST || magFilter == GL_LINEAR, "Invalid magFilter:" ~ magFilter.to!string);

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

		writeln("Sampler created: " ~ id.to!string);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteSamplers(1, &id);
		printf("Sampler removed: %u\n", id);
	}

	void use(uint location) {
		glBindSampler(location, id);
	}

	bool usesMipmap() {
		return (minFilter == GL_NEAREST_MIPMAP_NEAREST || minFilter == GL_LINEAR_MIPMAP_NEAREST
				|| minFilter == GL_NEAREST_MIPMAP_LINEAR || minFilter == GL_LINEAR_MIPMAP_LINEAR);
	}

}
