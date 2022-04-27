module hoekjed.opengl.overig;

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