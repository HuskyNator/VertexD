module vertexd.misc;

import bindbc.opengl;
import std.algorithm : countUntil, removeAt = remove;
import std.conv : to;
import std.math : abs, PI;
import std.traits : isFloatingPoint, isScalarType;

void tryWriteln(T)(T output) nothrow {
	import std.stdio : writeln;

	try {
		writeln(output);
	} catch (Exception e) {
	}
}

void remove(Type)(ref Type[] list, Type element) {
	const long i = list.countUntil(element);
	assert(i >= 0, "Element not in list");
	list = list.removeAt(i);
}

bool tryRemove(Type)(ref Type[] list, Type element) {
	const long i = list.countUntil(element);
	if (i < 0)
		return false; // Element not in list
	list = list.removeAt(i);
	return true;
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

D degreesToRadians(D)(D degrees) if (isFloatingPoint!D) {
	static real factor = PI / 180;
	return cast(D)(degrees * factor);
}

R radiansToDegrees(R)(R radians) if (isFloatingPoint!D) {
	static real factor = 180 / PI;
	return cast(R)(radians * factor);
}

// Based on std::bit_width (c++20) and https://stackoverflow.com/a/63987820.
// Identical to floor(log2(x))+1.
auto bitWidth(T)(T x) if (isScalarType!T) {
	assert(x >= 0);
	T result = 0;
	while (x > 0) {
		x >>= 1;
		result += 1;
	}
	return result;
}

void assertEqual(T)(T left, T right) {
	assert(left == right, "Expected " ~ left.to!string ~ " == " ~ right.to!string);
}

void assertAlmostEqual(T)(T left, T right, float delta = 1e-5) {
	assert(abs(left - right) < delta,
		"Expected abs(" ~ left.to!string ~ " - " ~ right.to!string ~ ") = " ~ (left - right)
		.to!string ~ " < " ~ delta.to!string);
}
