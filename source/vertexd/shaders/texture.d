module vertexd.shaders.texture;
import bindbc.opengl;
import imageformats;
import std.conv : to;
import std.exception : enforce;
import std.stdio;
import vertexd.core.mat;
import vertexd.misc : bitWidth;
import vertexd.shaders;

// TODO: consider merging TextureHandle & TextureBase
struct Texture {
	TextureHandle handle = null;
	int texCoord;
	float factor = 1;

	bool present() {
		return handle !is null;
	}

	ubyte[] bufferBytes() {
		ubyte[] bytes;
		GLuint64 handleID = (handle is null) ? 0.to!GLuint64 : handle.handle;
		bytes ~= (cast(ubyte*)&handleID)[0 .. GLuint64.sizeof];
		bytes ~= (cast(ubyte*)&texCoord)[0 .. int.sizeof];
		bytes ~= (cast(ubyte*)&factor)[0 .. float.sizeof];
		return bytes;
	}

	void initialize(bool srgb) {
		if (handle !is null)
			handle.initialize(srgb);
	}

	void load() {
		if (handle !is null)
			handle.load();
	}

	void unload() {
		if (handle !is null)
			handle.unload();
	}
}

class TextureHandle {
	string name;
	TextureBase base;
	Sampler sampler;
	GLuint64 handle = 0; // no handle
	private bool loaded = false;

	@disable this();

	this(string name, TextureBase base, Sampler sampler) {
		this.name = name;
		this.base = base;
		this.sampler = sampler;
	}

	void initialize(bool srgb) {
		if (this.handle != 0)
			return; // already initialized

		//TODO: decide on default mipmap level or make it configurable.
		int maxImageSize = (base.img.w > base.img.h) ? base.img.w : base.img.h;
		GLsizei maxMipmapLevels = cast(GLsizei) bitWidth(maxImageSize);
		base.initialize(srgb, maxMipmapLevels);

		this.handle = glGetTextureSamplerHandleARB(base.id, sampler.id);
		enforce(handle != 0, "An error occurred while creating a texture handle");

		writeln("TextureHandle created: " ~ handle.to!string ~ "(" ~ name ~ ")");

		debug {
			float[4] borderColor;
			glGetSamplerParameterfv(sampler.id, GL_TEXTURE_BORDER_COLOR, &borderColor[0]);
			assert(Vec!4(borderColor) == Vec!4([0, 0, 0, 0]), "Texture handle border color should not be used");
		}
	}

	~this() {
		unload();
		write("TextureHandle removed (remains till base & sampler are removed): ");
		write(handle);
		write("(");
		write(name);
		writeln(")");
	}

	void load() {
		if (!loaded)
			glMakeTextureHandleResidentARB(handle);
		this.loaded = true;
	}

	void unload() {
		if (loaded)
			glMakeTextureHandleNonResidentARB(handle);
		this.loaded = false;
	}
}

class TextureBase {
	string name;
	uint id;
	IFImage img;
	bool initialized = false;

	this(IFImage img, string name = "") {
		this.name = name;
		this.img = img;
	}

	void initialize(bool srgb, GLsizei mipmapLevels) {
		if (initialized)
			return;

		glCreateTextures(GL_TEXTURE_2D, 1, &id);
		glTextureStorage2D(id, mipmapLevels, (srgb ? GL_SRGB8_ALPHA8 : GL_RGBA8), img.w, img.h);
		glTextureSubImage2D(id, 0, 0, 0, img.w, img.h, GL_RGBA, GL_UNSIGNED_BYTE, img.pixels.ptr);

		if (mipmapLevels > 1) //TODO: What happens when the sampler defines mipmap filtering but the texture is only lage enough for 1 level?
			glGenerateTextureMipmap(id);

		// Already defined by Sampler
		// glTextureParameteri(id, GL_TEXTURE_WRAP_S, GL_REPEAT);
		// glTextureParameteri(id, GL_TEXTURE_WRAP_T, GL_REPEAT);
		// glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		// glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		writeln("Texture created: " ~ id.to!string);
		this.initialized = true;
	}

	this(string file, string name = "") {
		this(read_image(file, ColFmt.RGBA), name);
	}

	this(ubyte[] content, string name = "") {
		this(read_image_from_mem(content, ColFmt.RGBA), name);
	}

	~this() {
		if (!initialized)
			return;
		import core.stdc.stdio : printf;

		glDeleteTextures(1, &id);
		printf("Texture removed: %u\n", id);
	}
}
