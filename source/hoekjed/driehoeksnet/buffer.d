module hoekjed.driehoeksnet.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;
import std.stdio;

class Buffer {
	uint buffer;
	// ubyte[] inhoud; // Mogelijk opslaan.
	// private size_t grootte; Andere mogelijkheid.

	public this(ubyte[] inhoud) {
		// this.inhoud = inhoud;
		glCreateBuffers(1, &buffer);
		glNamedBufferStorage(buffer, inhoud.length * ubyte.sizeof, inhoud.ptr, 0);
		writeln("Buffer aangemaakt: " ~ buffer.to!string);
	}

	public ~this() {
		import core.stdc.stdio : printf;

		glDeleteBuffers(1, &buffer);
		printf("Buffer verwijderd: %u\n", buffer);
	}

}
