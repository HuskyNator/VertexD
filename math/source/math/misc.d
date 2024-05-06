module math.misc;

alias Result(A, string operator, B) = typeof(mixin("A.init" ~ operator ~ "B.init"));

/**
 * Geeft aan of T een lijst is, waarbij alles met een index gezien wordt als een lijst.
 * Dit is anders dan traits.isArray, welk een toewijzingstabel als uint[uint] niet ziet als lijst.
 * (Blijkbaar is een associatieve lijst in het duits een Zuordnungstabelle, oftewel een toeördeningstabel).
*/
bool isList(T, uint n = 1)() if (n > 0) {
	import std.array : replicate;

	return is(typeof(mixin("T.init" ~ "[0]".replicate(n))));
}
