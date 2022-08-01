module hoekjed.ververs.afbeelding;
import bindbc.opengl;
import imageformats;
import std.conv;
import std.stdio;

class Afbeelding {
	uint tex;
	string naam;
	ubyte[] inhoud;
	// TODO

	this(IFImage i, string naam = "") {
		this.naam = naam;
		glCreateTextures(GL_TEXTURE_2D, 1, &tex);
		glTextureStorage2D(tex, 1, GL_RGBA8, i.h, i.h);
		glTextureSubImage2D(tex, 0, 0, 0, i.w, i.h, GL_RGBA, GL_UNSIGNED_BYTE, i.pixels.ptr);
		// TODO
		glTextureParameteri(tex, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTextureParameteri(tex, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		writeln("Textuur aangemaakt: " ~ tex.to!string);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteTextures(1, &tex);
		printf("Textuur verwijderd: %u\n", tex);
	}

	this(string bestand, string naam = "") {
		this(read_image(bestand, ColFmt.RGBA), naam);
	}

	this(ubyte[] inhoud, string naam = "") {
		this(read_image_from_mem(inhoud, ColFmt.RGBA), naam);
	}

	void gebruik(uint plek) {
		glBindTextureUnit(plek, tex);
	}

}
