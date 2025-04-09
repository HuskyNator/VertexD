module vertexd.memory.texture;

import bindbc.opengl;
import gamut;
import vertexd.gl;
import vertexd.shaders.shaderprogram;
import vertexd.util.ids;

import std.algorithm.comparison;
import std.conv : to;
import std.file : exists, FileException;
import std.math.exponential;
import std.math.rounding;
import std.meta;

class Texture {
	mixin ID!();
	uint texture;

	static Texture[4] _emptyTextures;
	static Texture empty(Type type) {
		immutable ubyte[4] pixels = [255, 255, 255, 0];
		if (_emptyTextures[type - 1] is null)
			static foreach (i; 1 .. 5)
				if (type == i)
					_emptyTextures[type - 1] = new Texture(1, 1, cast(ubyte[i][]) pixels[0 .. i], false);
		return _emptyTextures[type - 1];
	}

	static int _glUnpackAlignment = 4;
	static void setUnpackAlignment(int newAlignment) {
		assert(newAlignment == 1 || newAlignment == 2 || newAlignment == 4 || newAlignment == 8);
		if (newAlignment == _glUnpackAlignment)
			return;
		Texture._glUnpackAlignment = newAlignment;
		glPixelStorei(GL_UNPACK_ALIGNMENT, newAlignment);
	}

	private enum GLenum getInternalFormat(T, uint L) = mixin("GL_", "RGBA"[0 .. L], (T.sizeof * 8)
				.to!string, is(typeof(T) == float) ? "f" : "");

	this(int width, int height, GLenum internalFormat, bool mipmapLevels = 1) {
		setID();
		glCreateTextures(GL_TEXTURE_2D, 1, &texture);
		glTextureStorage2D(texture, mipmapLevels, internalFormat, width, height);

		if (mipmapLevels == 1)
			glTextureParameteri(texture, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	}

	this(T, uint L)(int width, int height, T[L][] pixels, bool mipmaps = true) {
		static assert(L >= 1 && L <= 4);
		static assert(staticIndexOf!(T, AliasSeq!(ubyte, ushort, float)) != -1);
		assert(width > 0 && height > 0);
		assert(pixels.length == width * height);

		GLenum format = [GL_RED, GL_RG, GL_RGB, GL_RGBA][L - 1];

		GLenum pixelType = GL.getType!T;
		setUnpackAlignment(T.sizeof);

		GLenum internalFormat = getInternalFormat!(T, L);

		int mipmapLevels = 1;
		if (mipmaps)
			mipmapLevels = cast(int) floor(log2(cast(double) max(width, height))) + 1;

		// Create Texture
		setID();
		glCreateTextures(GL_TEXTURE_2D, 1, &texture);
		glTextureStorage2D(texture, mipmapLevels, internalFormat, width, height);
		glTextureSubImage2D(texture, 0, 0, 0, width, height, format, pixelType, pixels.ptr);

		if (mipmaps)
			glGenerateTextureMipmap(texture);
		else
			glTextureParameteri(texture, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	}

	void generateMipmaps() {
		glGenerateTextureMipmap(texture);
	}

	void uploadData(T, uint L)(int level, int xOffset, int yOffset, uint width, uint height, T[L][] data) {
		GLenum internalFormat = getInternalFormat!T;
		GLenum pixelType = GL.getType!T;
		setUnpackAlignment(T.sizeof);
		glTextureSubImage2D(texture, level, xOffset, yOffset, width, height, internalFormat, pixelType, data
				.ptr);
	}

	enum Type : ubyte {
		Grey = 1,
		RG = 2,
		RGB = 3,
		RGBA = 4
	}

	static immutable int loadFlags = LOAD_NO_PREMUL | LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS;
	static immutable int loadFlagsGrey = loadFlags | LOAD_GREYSCALE | LOAD_NO_ALPHA;
	static immutable int loadFlagsRGB = loadFlags | LOAD_RGB | LOAD_NO_ALPHA;
	static immutable int loadFlagsRGBA = loadFlags | LOAD_RGB | LOAD_ALPHA;

	static int getFlags(Type type) {
		final switch (type) {
			case Type.Grey:
				return loadFlagsGrey;
			case Type.RG:
				assert(0, "Gamut has no RG loading flags.");
			case Type.RGB:
				return loadFlagsRGB;
			case Type.RGBA:
				return loadFlagsRGBA;
		}
	}

	this(string path, Type type = Type.RGBA, bool mipmaps = true) {
		if (!exists(path))
			throw new FileException(path, "File not found");
		Image image;
		int flags = getFlags(type);
		image.loadFromFile(path, flags);
		this(image, type, mipmaps);
	}

	this(ref Image image, Type type, bool mipmaps = true) {
		if (image.isError()) // Check image is valid
			throw new Exception(cast(string) image.errorMessage());
		image.flipVertical();
		if (image.isError()) // Check if flip is valid
			throw new Exception(cast(string) image.errorMessage());

		// Determine proper texture format
		int width = image.width();
		int height = image.height();
		GLenum pixelType;
		GLenum format;
		GLenum internalFormat;
		PixelType sourceType = image.type();
		ubyte[] pixels = image.allPixelsAtOnce();

		final switch (type) {
			case Type.Grey:
				format = GL_RED;
				switch (sourceType) {
					case PixelType.l8:
						pixelType = GL_UNSIGNED_BYTE;
						internalFormat = GL_R8;
						setUnpackAlignment(1);
						break;
					case PixelType.l16:
						pixelType = GL_UNSIGNED_SHORT;
						internalFormat = GL_R16;
						setUnpackAlignment(2);
						break;
					case PixelType.lf32:
						pixelType = GL_FLOAT;
						internalFormat = GL_R32F;
						setUnpackAlignment(4);
						break;
					default:
						assert(0, "Pixel Type invalid: " ~ sourceType.stringof);
				}
				break;
			case Type.RG:
				assert(0, "Gamut has no RG pixel types.");
			case Type.RGB:
				format = GL_RGB;
				switch (sourceType) {
					case PixelType.rgb8:
						pixelType = GL_UNSIGNED_BYTE;
						internalFormat = GL_RGB8;
						setUnpackAlignment(1);
						break;
					case PixelType.rgb16:
						pixelType = GL_UNSIGNED_SHORT;
						internalFormat = GL_RGB16;
						setUnpackAlignment(2);
						break;
					case PixelType.rgbf32:
						pixelType = GL_FLOAT;
						internalFormat = GL_RGB32F;
						setUnpackAlignment(4);
						break;
					default:
						assert(0, "Pixel Type invalid: " ~ sourceType.stringof);
				}
				break;
			case Type.RGBA:
				format = GL_RGBA;
				setUnpackAlignment(4);
				switch (sourceType) {
					case PixelType.rgba8:
						pixelType = GL_UNSIGNED_BYTE;
						internalFormat = GL_RGBA8;
						break;
					case PixelType.rgba16:
						pixelType = GL_UNSIGNED_SHORT;
						internalFormat = GL_RGBA16;
						break;
					case PixelType.rgbaf32:
						pixelType = GL_FLOAT;
						internalFormat = GL_RGBA32F;
						break;
					default:
						assert(0, "Pixel Type invalid: " ~ sourceType.stringof);
				}
				break;
		}

		int mipmapLevels = 1;
		if (mipmaps)
			mipmapLevels = cast(int) floor(log2(cast(double) max(width, height))) + 1;

		// Create Texture
		setID();
		glCreateTextures(GL_TEXTURE_2D, 1, &texture);
		glTextureStorage2D(texture, mipmapLevels, internalFormat, width, height);
		glTextureSubImage2D(texture, 0, 0, 0, width, height, format, pixelType, pixels.ptr);

		if (mipmaps)
			glGenerateTextureMipmap(texture);
		else
			glTextureParameteri(texture, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	}

	~this() {
		glDeleteTextures(1, &texture);
	}

	void bind(GLuint textureUnit) {
		glBindTextureUnit(textureUnit, texture);
	}
}
