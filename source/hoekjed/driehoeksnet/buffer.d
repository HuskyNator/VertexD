module hoekjed.driehoeksnet.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;
import std.stdio;

final class Buffer {
	uint buffer;
	size_t grootte = 0;
	private GLenum soort;
	debug private bool wijzigbaar;

public:
	this(bool wijzigbaar = false) {
		debug this.wijzigbaar = wijzigbaar;
		this.soort = wijzigbaar ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW;

		glCreateBuffers(1, &buffer);
		writeln("Buffer(" ~ (wijzigbaar ? "wijzigbaar" : "onwijzigbaar") ~ ") aangemaakt: " ~ buffer
				.to!string);
	}

	this(ubyte[] inhoud, bool wijzigbaar = false) {
		this(wijzigbaar);
		zetInhoud(inhoud);
	}

	this(void* inhoud, size_t grootte, bool wijzigbaar = false) {
		this(wijzigbaar);
		zetInhoud(inhoud, grootte, 0);
	}

	~this() {
		import core.stdc.stdio : printf;

		glDeleteBuffers(1, &buffer);
		printf("Buffer verwijderd: %u\n", buffer);
	}

	void zetGrootte(size_t grootte) {
		glNamedBufferData(buffer, grootte, null, soort);
		this.grootte = grootte;
	}

	void zetInhoud(ubyte[] inhoud, int offset = 0) {
		zetInhoud(inhoud.ptr, inhoud.length * ubyte.sizeof, offset);
	}

	void zetInhoud(void* inhoud, size_t grootte, int offset = 0) {
		debug assert(wijzigbaar || this.grootte == 0, "Kan inhoud van onwijzigbare buffer niet aanpassen.");
		if (grootte + offset > this.grootte) {
			if (offset == 0)
				return glNamedBufferData(buffer, grootte, inhoud, soort);
			Buffer kopie = this.kopie(0, offset, true);
			zetGrootte(grootte + offset);
			zetInhoudKopie(kopie, 0, 0, offset);
		}
		glNamedBufferSubData(buffer, offset, grootte, inhoud);
	}

	void zetInhoudKopie(Buffer bron, int bron_offset, int offset, size_t grootte) {
		glCopyNamedBufferSubData(bron.buffer, buffer, bron_offset, offset, grootte);
	}

	Buffer kopie(int offset = 0, size_t grootte = grootte, bool tijdelijk = false) {
		Buffer kopie = new Buffer();
		kopie.soort = tijdelijk ? GL_STATIC_COPY : soort;
		kopie.zetGrootte(offset + grootte);
		kopie.zetInhoudKopie(this, offset, 0, grootte);
		return kopie;
	}

}
