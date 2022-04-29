module hoekjed.opengl.buffer;

import bindbc.opengl;

class Buffer {
	private uint buffer;
	// private byte[] inhoud; Mogelijk opslaan.
	// private size_t grootte; Andere mogelijkheid.

	public this(ubyte[] inhoud) {
		glCreateBuffers(1, &buffer);
		glNamedBufferStorage(buffer, inhoud.sizeof, inhoud.ptr, 0);
	}

	public ~this() {
		glDeleteBuffers(1, &buffer);
	}

}
