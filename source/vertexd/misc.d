module vertexd.misc;

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

// a.isType!B
bool isType(B, A)(A a) {
	return is(A == B);
}

// a.isType(b)
bool isType(A, B)(A a, B b) {
	return is(A == B);
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
