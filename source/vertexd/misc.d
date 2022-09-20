module vertexd.misc;

import bindbc.opengl;
import std.algorithm : countUntil, removeAt = remove;
import std.conv : to;

void remove(Type)(ref Type[] list, Type element) {
	const long i = list.countUntil(element);
	assert(i >= 0, "Element not in list");
	list = list.removeAt(i);
}

alias Result(A, string operator, B) = typeof(mixin("A.init" ~ operator ~ "B.init"));

// a.isType!B
bool isType(B, A)(A a) {
	return is(A == B);
}

// a.isType(b)
bool isType(A, B)(A a, B b) {
	return is(A == B);
}

/**
 * Geeft aan of T een lijst is, waarbij alles met een index gezien wordt als een lijst.
 * Dit is anders dan traits.isArray, welk een toewijzingstabel als uint[uint] niet ziet als lijst.
 * (Blijkbaar is een associatieve lijst in het duits een Zuordnungstabelle, oftewel een toeördeningstabel).
*/
bool isList(T, uint n = 1)() if (n > 0) {
	import std.array : replicate;

	return is(typeof(mixin("T.init" ~ "[0]".replicate(n))));
}

// OpenGL type enum to size
size_t getGLenumTypeSize(GLenum type) {
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

GLenum getGLenum(T)() {
	static if (is(T == ubyte))
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

alias Set(T) = void[0][T];
enum unit = (void[0]).init;
void add(T)(ref Set!T set, T place) {
	set[place] = unit;
}

ubyte[] toBytes(T)(ref T t) {
	return (cast(ubyte*)&t)[0 .. T.sizeof];
}

ubyte[] padding(size_t size) {
	import std.array : replicate;

	static ubyte[] b = [0];
	return (b).replicate(size);
}
