module hoekjed.overig;

import std.algorithm : countUntil, remove;

void verwijder(Soort)(ref Soort[] lijst, Soort onderdeel) {
	const long i = lijst.countUntil(onderdeel);
	assert(i >= 0, "Onderdeel niet in lijst.");
	lijst = lijst.remove(i);
}

alias Resultaat(A, string operatie, B) = typeof(mixin("A.init" ~ operatie ~ "B.init"));

// a.isSoort!B
bool isSoort(B, A)(A a) {
	return is(A == B);
}

// a.isSoort(b)
bool isSoort(A, B)(A a, B b){
	return is(A == B);
}

// Geeft aan of T een lijst is, waarbij alles met een index gezien wordt als een lijst.
// Dit is anders dan traits.isArray, welk een toewijzingstabel als uint[uint] niet ziet als lijst.
// (Blijkbaar is een associatieve lijst in het duits een Zuordnungstabelle, oftewel een toeördeningstabel).
bool isLijst(T, uint n = 1)() if(n>0) {
	import std.array : replicate;
	return is(typeof(mixin("T.init"~"[0]".replicate(n))));
}
