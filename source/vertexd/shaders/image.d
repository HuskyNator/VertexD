module vertexd.shaders.image;
import bindbc.opengl;
import imageformats;
import std.conv;
import std.stdio;

class Image {
	uint tex;
	string name;
	ubyte[] content;
	// TODO

	this(IFImage i, string name = "") {
		this.name = name;
		glCreateTextures(GL_TEXTURE_2D, 1, &tex);
		glTextureStorage2D(tex, 1, GL_RGBA8, i.h, i.h);
		glTextureSubImage2D(tex, 0, 0, 0, i.w, i.h, GL_RGBA, GL_UNSIGNED_BYTE, i.pixels.ptr);
		// TODO
		glTextureParameteri(tex, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTextureParameteri(tex, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		writeln("Texture created: " ~ tex.to!string);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteTextures(1, &tex);
		printf("Texture removed: %u\n", tex);
	}

	this(string file, string name = "") {
		this(read_image(file, ColFmt.RGBA), name);
	}

	this(ubyte[] content, string name = "") {
		this(read_image_from_mem(content, ColFmt.RGBA), name);
	}

	void use(uint location) {
		glBindTextureUnit(location, tex);
	}

}
