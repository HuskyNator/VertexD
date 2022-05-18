module hoekjed.driehoeksnet.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;
import std.stdio;

class Buffer {
	uint buffer;
	debug private bool wijzigbaar;

	public this(ubyte[] inhoud, bool wijzigbaar = false) {
		debug this.wijzigbaar = wijzigbaar;

		glCreateBuffers(1, &buffer);
		glNamedBufferData(buffer, inhoud.length * ubyte.sizeof, inhoud.ptr, wijzigbaar ? GL_DYNAMIC_DRAW
				: GL_STATIC_DRAW);
		writeln("Buffer(" ~ (wijzigbaar ? "wijzigbaar" : "onwijzigbaar") ~ ") aangemaakt: " ~ buffer
				.to!string);
	}

	public void zetInhoud(ubyte[] inhoud) {
		assert(wijzigbaar, "Kan inhoud van onwijzigbare buffer niet aanpassen.");
		glNamedBufferSubData(buffer, 0, inhoud.length * ubyte.sizeof, inhoud.ptr);
	}

	public ~this() {
		import core.stdc.stdio : printf;

		glDeleteBuffers(1, &buffer);
		printf("Buffer verwijderd: %u\n", buffer);
	}

}
