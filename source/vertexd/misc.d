module vertexd.misc;

import std.algorithm : countUntil, removeAt = remove;

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
