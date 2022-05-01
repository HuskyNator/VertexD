module hoekjed.opengl.buffer;

import bindbc.opengl;
import std.stdio : writeln;
import std.conv : to;

class Buffer {
	uint buffer;
	// private byte[] inhoud; Mogelijk opslaan.
	// private size_t grootte; Andere mogelijkheid.

	public this(ubyte[] inhoud) {
		glCreateBuffers(1, &buffer);
		glNamedBufferStorage(buffer, inhoud.sizeof, inhoud.ptr, 0);

		writeln("Buffer aangemaakt: " ~ buffer.to!string);
	}

	public ~this() {
		glDeleteBuffers(1, &buffer);

		writeln("Buffer verwijderd: " ~ buffer.to!string);
	}

}
