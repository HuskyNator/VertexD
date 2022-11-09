module vertexd.shaders.sampler;
import bindbc.opengl;
import std.conv;
import std.stdio;
import std.typecons : Nullable;

class Sampler {
	string name;
	uint id;

	@disable this();

	this(string name, uint wrapS = GL_REPEAT, uint wrapT = GL_REPEAT,
		uint minFilter, uint magFilter) {
		this.name = name;
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

}
