module hoekjed.wereld.licht;

import hoekjed.net.buffer;
import hoekjed.kern.mat;
import hoekjed.ververs.verver;
import hoekjed.wereld.voorwerp;
import hoekjed.wereld.wereld;
import std.conv : to;
import std.exception : enforce;

enum max_lichten = 512;

class LichtVerzameling {
	private uint[Licht] lichten;
	private Buffer uniformBuffer;

	invariant (lichten.length <= max_lichten);

	static this() {
		Verver.vervangers["MAX_LICHTEN"] = max_lichten.to!string;
	}

	this() {
		uniformBuffer = new Buffer(true);
		Verver.zetUniformBuffer(1, uniformBuffer);
	}

	auto opOpAssign(string op)(Licht l) if (op == "+") {
		lichten[l] = cast(uint) lichten.length;
		zetUniform(l, cast(uint) (lichten.length - 1));
		return this;
	}

	auto opOpAssign(string op)(Licht l) if (op == "-") {
		uint oud = lichten[l];
		lichten.remove(l);
		zetUniform(Licht.LichtS(Soort.ONGELDIG), oud);
		return this;
	}

	void krimp() {
		uniformBuffer.zetGrootte(uint.sizeof + lichten.length * Licht.LichtS.sizeof);
		uint[Licht] nieuw_lichten;
		uint i = 0;
		foreach (l; lichten.byKey()) {
			nieuw_lichten[l] = i;
			zetUniform(l.lichtS, i);
			i += 1;
		}
		uniformBuffer.zetInhoud(&i, uint.sizeof, 0);
		this.lichten = nieuw_lichten;
	}

	void zetUniform(Licht l) {
		assert(l in lichten, "Licht niet in LichtVerzameling");
		zetUniform(l.lichtS, lichten[l]);
	}

	void zetUniform(Licht.LichtS l, uint index) {
		uint aantal = cast(uint) lichten.length;
		uniformBuffer.zetInhoud(&aantal, uint.sizeof, 0);
		uniformBuffer.zetInhoud(&l, l.sizeof, cast(int) (uint.sizeof + index * l.sizeof));
	}
}

class Licht : Voorwerp.Eigenschap {
	static enum Soort {
		PUNT,
		STRAAL,
		SCHIJNWERPER,
		ONGELDIG // Puur voor ongeldigverklaring
	}

	struct LichtS {
		Soort soort;
		Vec!3 kleur;
		nauwkeurigheid sterkte;
		nauwkeurigheid rijkweidte;
		nauwkeurigheid binnenhoek;
		nauwkeurigheid buitenhoek;

		Vec!3 plek;
		Vec!3 richting;
	}

	LichtS lichtS;
	alias lichtS this;

	this(Soort soort, Vec!3 kleur,
		nauwkeurigheid sterkte,
		nauwkeurigheid rijkweidte = nauwkeurigheid.infinity,
		nauwkeurigheid binnenhoek = nauwkeurigheid.nan,
		nauwkeurigheid buitenhoek = nauwkeurigheid.nan) {
		this.soort = soort;
		this.kleur = kleur;
		this.sterkte = sterkte;
		this.rijkweidte = rijkweidte;
		this.binnenhoek = binnenhoek;
		this.buitenhoek = buitenhoek;
	}

	void werkBij(Wereld wereld, Voorwerp ouder) {
		plek = Vec!3(ouder.voorwerpMatrix.kol(3)[0 .. 3]);
		richting = Vec!3(ouder.voorwerpMatrix.maal(Vec!4([0, 0, -1, 0]))[0 .. 3]).normaliseer();
		wereld.lichtVerzameling.zetUniform(this);
	}
}
