module hoekjed.opengl.vao;

import bindbc.opengl;
import hoekjed;

class VAO {
	private uint vao;
	private VBO[uint] vbos;
	private EBO ebo;
	private uint hoekAantal;

	public this() {
		glGenVertexArrays(1, &vao);
	}

	public ~this() {
		import std.stdio;

		glDeleteVertexArrays(1, &vao);
		stderr.write("VAO ");
		stderr.write(vao);
		stderr.writeln(" is verwijderd.");
	}

	public void teken() {
		this.koppel();
		glDrawElements(GL_TRIANGLES, this.hoekAantal, GL_UNSIGNED_INT, null);
		import std.stdio;

		write("VAO ");
		write(vao);
		writeln(" is getekend.");
	}

	public void zetInhoud(M : Mat!(L, 1, S), uint L, S)(uint plek, M[] inhoud)
			if (L > 0 && L <= 4) {
		assert(plek !in vbos);
		this.koppel();
		this.vbos[plek] = new VBO(inhoud);
		glVertexAttribPointer(plek, L, ctGLenum!(S)(), false, M.sizeof, null);
		glEnableVertexAttribArray(plek);
	}

	public void zetVolgorde(Vec!(3, uint)[] volgorde) {
		this.koppel();
		this.ebo = new EBO(volgorde);
		this.hoekAantal = 3 * cast(uint) volgorde.length;
	}

	private void koppel() {
		glBindVertexArray(vao);
	}
}

private GLenum ctGLenum(S)() {
	static if (is(S == byte))
		return GL_BYTE;
	else static if (is(S == ubyte))
		return GL_UNSIGNED_BYTE;
	else static if (is(S == short))
		return GL_SHORT;
	else static if (is(S == ushort))
		return GL_UNSIGNED_SHORT;
	else static if (is(S == int))
		return GL_INT;
	else static if (is(S == uint))
		return GL_UNSIGNED_INT;
	else static if (is(S == float))
		return GL_FLOAT;
	else static if (is(S == double))
		return GL_DOUBLE;
	else
		static assert(0, "Soort " ~ S.stringof ~ " niet ondersteund.");
}
