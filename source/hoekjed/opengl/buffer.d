module hoekjed.opengl.buffer;

import bindbc.opengl;

alias VBO = Buffer!(GL_ARRAY_BUFFER);
alias EBO = Buffer!(GL_ELEMENT_ARRAY_BUFFER);

// VERBETER: voeg inhoud van type M[] aan template toe zonder dat Uiterlijk hier last van heeft.
class Buffer(GLenum Buffer_Soort) {
	private uint bo;

	public this(M)(M[] inhoud) {
		glGenBuffers(1, &bo);
		zet(inhoud);
	}

	public ~this() {
		import std.stdio;

		glDeleteBuffers(1, &bo);
		stderr.write("Buffer ");
		stderr.write(bo);
		stderr.writeln(" is verwijderd.");
	}

	public void zet(M)(M[] inhoud) {
		glBindBuffer(Buffer_Soort, bo);
		glBufferData(Buffer_Soort, inhoud.length * M.sizeof, inhoud.ptr, GL_STATIC_DRAW);
	}
}
