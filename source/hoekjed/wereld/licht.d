module hoekjed.wereld.licht;

import hoekjed.kern.wiskunde;

alias StraalLicht = Licht.StraalLicht;
alias PuntLicht = Licht.PuntLicht;
alias SchijnWerper = Licht.SchijnWerper;

class Licht {
	static enum Soort {
		PUNT,
		STRAAL,
		SCHIJNWERPER
	}

	static foreach (string soort; __traits(allMembers, Soort)) // TODO 
		mixin("alias ", soort, " = Soort.", soort, ";");

	Soort soort;
	string naam;
	Vec!3 kleur;
	nauwkeurigheid sterkte;
	nauwkeurigheid rijkweidte;
	nauwkeurigheid binnenhoek;
	nauwkeurigheid buitenhoek;

	this(Soort soort, string naam, Vec!3 kleur, nauwkeurigheid sterkte,
		nauwkeurigheid rijkweidte = nauwkeurigheid.infinity,
		nauwkeurigheid binnenhoek = nauwkeurigheid.nan,
		nauwkeurigheid buitenhoek = nauwkeurigheid.nan) {
		this.soort = soort;
		this.naam = naam;
		this.kleur = kleur;
		this.sterkte = sterkte;
		this.rijkweidte = rijkweidte;
		this.binnenhoek = binnenhoek;
		this.buitenhoek = buitenhoek;
	}

	protected static Licht StraalLicht(string naam, Vec!3 kleur, nauwkeurigheid sterkte,
		nauwkeurigheid rijkweidte = nauwkeurigheid.infinity,
		nauwkeurigheid binnenhoek = nauwkeurigheid.nan,
		nauwkeurigheid buitenhoek = nauwkeurigheid.nan) {
		return new Licht(Licht.Soort.STRAAL, naam, kleur, sterkte, rijkweidte, binnenhoek, buitenhoek);
		pragma(inline, true);
	}

	protected static Licht PuntLicht(string naam, Vec!3 kleur, nauwkeurigheid sterkte,
		nauwkeurigheid rijkweidte = nauwkeurigheid.infinity,
		nauwkeurigheid binnenhoek = nauwkeurigheid.nan,
		nauwkeurigheid buitenhoek = nauwkeurigheid.nan) {
		return new Licht(Licht.Soort.PUNT, naam, kleur, sterkte, rijkweidte, binnenhoek, buitenhoek);
		pragma(inline, true);
	}

	protected static Licht SchijnWerper(string naam, Vec!3 kleur, nauwkeurigheid sterkte,
		nauwkeurigheid rijkweidte = nauwkeurigheid.infinity,
		nauwkeurigheid binnenhoek = nauwkeurigheid.nan,
		nauwkeurigheid buitenhoek = nauwkeurigheid.nan) {
		return new Licht(Licht.Soort.SCHIJNWERPER, naam, kleur, sterkte, rijkweidte, binnenhoek, buitenhoek);
		pragma(inline, true);
	}
}
