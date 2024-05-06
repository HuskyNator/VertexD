module vertexd.shaders.texture;

import bindbc.opengl;
import gamut;
import std.conv : to;
import std.exception : enforce;
import std.math;
import std.stdio;
import math.mat;
import vertexd.misc : bitWidth;
import vertexd.shaders;

class BindlessTexture { // TextureHandle
	Texture base;
	Sampler sampler;
	GLuint64 handleID = 0; // no handle
	private bool loaded = false;

	string name;

	int texCoord;
	float factor = 1;

	static ubyte[] bufferBytes(BindlessTexture texture) {
		ubyte[] bytes = new ubyte[16]; // 16 '0 bytes'
		if (texture is null)
			return bytes;

		bytes[0 .. 8] = (cast(ubyte*)&texture.handleID)[0 .. GLuint64.sizeof];
		bytes[8 .. 12] = (cast(ubyte*)&texture.texCoord)[0 .. int.sizeof];
		bytes[12 .. 16] = (cast(ubyte*)&texture.factor)[0 .. float.sizeof];
		return bytes;
	}

	@disable this();

	this(Texture base, Sampler sampler, string name = "BindlessTexture") {
		this.base = base;
		this.sampler = sampler;
		this.name = name;
	}

	~this() {
		unload();
		write("TextureHandle removed (remains till base & sampler are removed): ");
		writeln(handleID);
	}

	void initialize(bool srgb, bool mipmap) {
		if (this.handleID != 0) {
			writeln("TextureHandle cannot be re-initialized!");
			return;
		}

		if (!base.initialized) {
			base.initialize(srgb, mipmap);
			base.upload();
		}

		this.handleID = glGetTextureSamplerHandleARB(base.id, sampler.id);
		enforce(handleID != 0, "An error occurred while creating a texture handle");

		writeln("TextureHandle created: " ~ handleID.to!string);
	}

	void load() {
		if (!loaded)
			glMakeTextureHandleResidentARB(handleID);
		this.loaded = true;
	}

	void unload() {
		if (loaded)
			glMakeTextureHandleNonResidentARB(handleID);
		this.loaded = false;
	}
}

class Texture {
	static ushort constraints = LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT;
	static int loadConstraint = LOAD_8BIT | LOAD_RGB | LOAD_ALPHA;

	string name;
	uint id;
	Vec!(4, ubyte)[] pixels;
	uint width;
	uint height;

	bool srgb;
	bool mipmap;
	GLsizei levels = 0;

	private this() {
		this.name = name;
		glCreateTextures(GL_TEXTURE_2D, 1, &id);
		writeln("Texture created: " ~ id.to!string);
	}

	this(uint W, uint H, Vec!(4, ubyte)[] pixels = null, string name = "Texture") {
		this();
		this.name = name;
		this.width = W;
		this.height = H;

		this.pixels = pixels.dup;
		if (pixels is null)
			this.pixels = new Vec!(4, ubyte)[W * H];

		assert(this.pixels.length == W * H);
	}

	this(Image img, string name = "Texture") {
		this(img.width(), img.height(), cast(Vec!(4, ubyte)[])(img.allPixelsAtOnce()), name);
	}

	this(string file, string name = "") {
		this(this.readImage(file), name);
	}

	static Image readImage(string file) {
		Image image;
		enforce(image.loadFromFile(file, constraints | loadConstraint), "Could not load image from file: " ~ file); // rgba8
		return image;
	}

	static Image readImage(ubyte[] content) {
		Image image;
		enforce(image.loadFromMemory(content, constraints | loadConstraint), "Could not load image from memory."); // rgba8
		return image;
	}

	~this() {
		glDeleteTextures(1, &id);
		write("Texture removed: ");
		writeln(id);
	}

	/// Samples the texture bilinearly
	///
	/// Params:
	///   uv = The uv coordinates applicable
	/// Returns: The bilinear sampled texture value
	Vec!4 sampleTexture(Vec!2 uv) {
		// TODO mipmaps?
		Vec!(2, uint) size = Vec!(2, uint)(width, height);
		uv *= size;
		Vec!(2, uint) low = cast(Vec!(2, uint))((uv.each!floor) % size);
		Vec!(2, uint) high = (low + 1) % size;
		Vec!2 delta = uv - low;
		Vec!(4, float) sample;
		sample += (cast(Vec!(4, float)) pixels[low.x + low.y * width]) / 256.0f * (1 - delta.x) * (1 - delta.y);
		sample += (cast(Vec!(4, float)) pixels[low.x + high.y * width]) / 256.0f * (1 - delta.x) * delta.y;
		sample += (cast(Vec!(4, float)) pixels[high.x + low.y * width]) / 256.0f * delta.x * (1 - delta.y);
		sample += (cast(Vec!(4, float)) pixels[high.x + high.y * width]) / 256.0f * delta.x * delta.y;
		return sample;
	}

	// enum Access {
	// 	READ = GL_READ_ONLY,
	// 	WRITE = GL_WRITE_ONLY,
	// 	READWRITE = GL_READ_WRITE
	// }

	// void bindImage(GLuint index, Access access, GLint level = 0) {
	// 	assert(!srgb); // Note srgb can't be used for image load/store operations
	// 	glBindImageTexture(index, id, level, false, 0, access, GL_RGBA8);
	// }

	// void bind() {
	// 	glBindTexture(GL_TEXTURE_2D, id);
	// }

	void saveImage(string path) {
		Image image;
		image.createViewFromData(cast(ubyte*) pixels.ptr, cast(int) width, cast(int) height,
			PixelType.rgba8, cast(int)(width * 4 * ubyte.sizeof));
		image.flipVertical();
		enforce(image.saveToFile(ImageFormat.PNG, path), "Could not save image to file.");
	}

	bool initialized() {
		return levels > 0;
	}

	// Note mipmap map depend on sampler.usesMipMap()
	void initialize(bool srgb, bool mipmap) { // Can't reinitialize while using texture handle.
		assert(!initialized());
		this.srgb = srgb;
		this.levels = 1;
		if (mipmap) { //TODO: decide on default mipmap level or make it configurable. (minimum grootte van laagste level?)
			int maxImageSize = (width > height) ? width : height;
			this.levels = cast(GLsizei) bitWidth(maxImageSize);
		}
		glTextureStorage2D(id, levels, (srgb ? GL_SRGB8_ALPHA8 : GL_RGBA8), width, height);
	}

	void upload() { // (re)upload pixel data
		glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels.ptr);
		if (mipmap)
			glGenerateTextureMipmap(id);
	}

	void download(GLint level = 0) { // oposite of upload()
		glMemoryBarrier(GL_TEXTURE_FETCH_BARRIER_BIT); // TODO: check vs update bit
		glGetTextureImage(id, level, GL_RGBA, GL_UNSIGNED_BYTE, cast(int)(width * height * 4 * ubyte.sizeof),
			pixels.ptr);
	}
}
