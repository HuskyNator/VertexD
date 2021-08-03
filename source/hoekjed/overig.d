module hoekjed.overig;

import std.algorithm : countUntil, remove;

void verwijder(Soort)(ref Soort[] lijst, Soort onderdeel) {
	const long i = lijst.countUntil(onderdeel);
	assert(i >= 0, "Onderdeel niet in lijst.");
	lijst = lijst.remove(i);
}

alias Resultaat(A, string operatie, B) = typeof(mixin("A.init" ~ operatie ~ "B.init"));
