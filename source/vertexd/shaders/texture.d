module vertexd.shaders.texture;
import bindbc.opengl;
import std.conv : to;
import std.exception : enforce;
import std.stdio;
import vertexd.core.mat;
import vertexd.misc : bitWidth;
import vertexd.shaders;

// TODO: consider merging TextureHandle & Texture
struct BindlessTexture {
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
	Texture base;
	Sampler sampler;
	GLuint64 handle = 0; // no handle
	private bool loaded = false;

	@disable this();

	this(string name, Texture base, Sampler sampler) {
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
			assert(Vec!4(borderColor) == Vec!4([0, 0, 0, 0]), "BindlessTexture handle border color should not be used");
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

class Texture {
	import imageformats;

	string name;
	IFImage img;
	uint id;

	GLsizei levels;
	bool srgb;

	this(IFImage img, string name = "") {
		this(name);
		this.img = img;
	}

	this(string name) {
		this.name = name;
		glCreateTextures(GL_TEXTURE_2D, 1, &id);
		writeln("Texture created: " ~ id.to!string);
	}

	this(string file, string name = "") {
		this(read_image(file, ColFmt.RGBA), name);
	}

	this(ubyte[] content, string name = "") {
		this(read_image_from_mem(content, ColFmt.RGBA), name);
	}

	static IFImage readImage(string file) {
		return read_image(file, ColFmt.RGBA);
	}

	static IFImage readImage(ubyte[] content) {
		return read_image_from_mem(content, ColFmt.RGBA);
	}

	enum Access {
		READ = GL_READ_ONLY,
		WRITE = GL_WRITE_ONLY,
		READWRITE = GL_READ_WRITE
	}

	// TODO: ???
	void bindImage(GLuint index, Access access, GLint level = 0) {
		assert(!srgb); // Note srgb can't be used for image load/store operations
		glBindImageTexture(index, id, level, false, 0, access, GL_RGBA8);
	}

	void bind() {
		glBindTexture(GL_TEXTURE_2D, id);
	}

	void saveImage(string path, GLint level = 0) {
		glMemoryBarrier(GL_TEXTURE_FETCH_BARRIER_BIT); // TODO: check vs update bit

		auto L = img.pixels;
		auto L2 = img.pixels.length;
		glGetTextureImage(id, level, GL_RGBA, GL_UNSIGNED_BYTE,
			cast(int)(img.pixels.length * ubyte.sizeof), img.pixels.ptr);
		write_png(path, img.w, img.h, img.pixels, ColFmt.RGBA);
	}

	void allocate(bool srgb, GLsizei levels, GLsizei width, GLsizei height, bool params, bool newImg) {
		this.srgb = srgb;
		this.levels = levels;
		glTextureStorage2D(id, levels, (srgb ? GL_SRGB8_ALPHA8 : GL_RGBA8), width, height);

		if (newImg) {
			img.w = width;
			img.h = height;
			img.pixels = new ubyte[4 * width * height];
		}

		// Already defined by Sampler
		if (!params)
			return;
		glTextureParameteri(id, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTextureParameteri(id, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}

	void initialize(bool srgb, GLsizei mipmapLevels, bool params = false) {
		allocate(srgb, mipmapLevels, img.w, img.h, params, false);
		glTextureSubImage2D(id, 0, 0, 0, img.w, img.h, GL_RGBA, GL_UNSIGNED_BYTE, img.pixels.ptr);

		if (mipmapLevels > 1) //TODO: What happens when the sampler defines mipmap filtering but the texture is only lage enough for 1 level?
			glGenerateTextureMipmap(id);
	}

	~this() {
		glDeleteTextures(1, &id);
		write("Texture removed: ");
		writeln(id);
	}
}
