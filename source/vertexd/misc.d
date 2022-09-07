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
size_t attributeTypeSize(GLenum type) {
	switch (type) {
		case GL_UNSIGNED_BYTE:
			return ubyte.sizeof;
		case GL_BYTE:
			return byte.sizeof;
		case GL_UNSIGNED_SHORT:
			return ushort.sizeof;
		case GL_SHORT:
			return short.sizeof;
		case GL_UNSIGNED_INT:
			return uint.sizeof;
		case GL_FLOAT:
			return float.sizeof;
		default:
			assert(0, "Unsupported acessor.componentType: " ~ type.to!string);
	}
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
