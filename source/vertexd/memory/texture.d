module vertexd.memory.texture;

import bindbc.opengl;
import gamut;
import std.algorithm.comparison;
import std.file : exists;
import std.math.exponential;
import std.math.rounding;
import vertexd.core.ids;
import vertexd.shaders.shaderprogram;
import std.file : FileException;

class Texture {
	mixin ID!();
	uint texture;

	static Texture _emptyGray;
	static Texture _emptyRGB;
	static Texture _emptyRGBA;
	static Texture empty(Type type) {
		Image image;
		ubyte[4] pixels = [255, 255, 255, 255];
		final switch (type) {
			case Type.Grey:
				if (_emptyGray is null) {
					image.createViewFromData(pixels.ptr, 1, 1, PixelType.l8, ubyte.sizeof);
					image.setLayout(LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
					_emptyGray = new Texture(image, type, false);
				}
				return _emptyGray;
				break;
			case Type.RGB:
				if (_emptyRGB is null) {
					image.createViewFromData(pixels.ptr, 1, 1, PixelType.rgb8, 3 * ubyte.sizeof);
					image.setLayout(LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
					_emptyRGB = new Texture(image, type, false);
				}
				return _emptyRGB;
				break;
			case Type.RGBA:
				if (_emptyRGBA is null) {
					image.createViewFromData(pixels.ptr, 1, 1, PixelType.rgba8, 4 * ubyte.sizeof);
					image.setLayout(LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
					_emptyRGBA = new Texture(image, type, false);
				}
				return _emptyRGBA;
				break;
		}
	}

	enum Type {
		Grey,
		RGB,
		RGBA
	}

	static immutable int loadFlags = LOAD_NO_PREMUL | LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS;
	static immutable int loadFlagsGrey = loadFlags | LOAD_GREYSCALE | LOAD_NO_ALPHA;
	static immutable int loadFlagsRGB = loadFlags | LOAD_RGB | LOAD_NO_ALPHA;
	static immutable int loadFlagsRGBA = loadFlags | LOAD_RGB | LOAD_ALPHA;
	static int _glUnpackAlignment = 4;

	static void setUnpackAlignment(int newAlignment) {
		assert(newAlignment == 1 || newAlignment == 2 || newAlignment == 4 || newAlignment == 8);
		if (newAlignment == _glUnpackAlignment)
			return;
		Texture._glUnpackAlignment = newAlignment;
		glPixelStorei(GL_UNPACK_ALIGNMENT, newAlignment);
	}

	static int getFlags(Type type) {
		final switch (type) {
			case Type.Grey:
				return loadFlagsGrey;
			case Type.RGB:
				return loadFlagsRGB;
			case Type.RGBA:
				return loadFlagsRGBA;
		}
	}

	this(string path, Type type, bool mipmaps = true) {
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
