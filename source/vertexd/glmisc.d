module vertexd.glmisc;

import bindbc.opengl;
import std.conv : to;

// OpenGL type enum to size
GLsizei getGLenumTypeSize(GLenum type) {
	switch (type) {
		case GL_BOOL:
			return ubyte.sizeof;
		case GL_BYTE:
			return byte.sizeof;
		case GL_SHORT:
			return short.sizeof;
		case GL_INT:
			return int.sizeof;
		case GL_UNSIGNED_BYTE:
			return ubyte.sizeof;
		case GL_UNSIGNED_SHORT:
			return ushort.sizeof;
		case GL_UNSIGNED_INT:
			return uint.sizeof;
		case GL_FLOAT:
			return float.sizeof;
		case GL_DOUBLE:
			return double.sizeof;
		default:
			assert(0, "Unsupported GLenum to type: " ~ type.to!string);
	}
}

uint getGLenumDrawModeCount(GLenum drawMode) {
	switch (drawMode) {
		case GL_POINTS:
			return 1;
		case GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP:
			return 2;
		case GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN:
			return 3;
		default:
			assert(0, "DrawMode unknown: " ~ drawMode.to!string);
	}
}

GLenum getGLenum(T)() {
	static if (is(T == bool))
		return GL_BOOL;
	// else static if (is(T == char))
	// 	return GLchar;
	else static if (is(T == byte))
		return GL_BYTE;
	else static if (is(T == short))
		return GL_SHORT;
	else static if (is(T == int))
		return GL_INT;
	else static if (is(T == ubyte))
		return GL_UNSIGNED_BYTE;
	else static if (is(T == ushort))
		return GL_UNSIGNED_SHORT;
	else static if (is(T == uint))
		return GL_UNSIGNED_INT;
	else static if (is(T == float))
		return GL_FLOAT;
	else static if (is(T == double))
		return GL_DOUBLE;
	// else static if (is(T == long))
	// 	return  GLint64;
	// else static if (is(T == ulong))
	// 	return GLuint64;
	else
		static assert(0, "Type conversion to GLenum not supported: " ~ T.stringof);
}