module vertexd.shaders.sampler;
import bindbc.opengl;
import std.conv;
import std.stdio;
import std.typecons : Nullable;

class Sampler {
	string name;
	uint sampler;

	@disable this();

	this(string name, uint wrapS = GL_REPEAT, uint wrapT = GL_REPEAT,
		uint minFilter = GL_NEAREST_MIPMAP_LINEAR, uint magFilter = GL_NEAREST) {
		this.name = name;
		glCreateSamplers(1, &sampler);
		glSamplerParameteri(sampler, GL_TEXTURE_WRAP_S, wrapS);
		glSamplerParameteri(sampler, GL_TEXTURE_WRAP_T, wrapT);
		glSamplerParameteri(sampler, GL_TEXTURE_MIN_FILTER, minFilter);
		glSamplerParameteri(sampler, GL_TEXTURE_MAG_FILTER, magFilter);

		writeln("Sampler created: " ~ sampler.to!string);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteSamplers(1, &sampler);
		printf("Sampler removed: %u\n", sampler);
	}

	void use(uint location) {
		glBindSampler(location, sampler);
	}

}
