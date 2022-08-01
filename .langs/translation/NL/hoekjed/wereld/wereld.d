module hoekjed.wereld.wereld;

import std.datetime : Duration;
import hoekjed.wereld.licht;
import hoekjed.wereld.voorwerp;
import hoekjed.wereld.zicht;

class Wereld {
	static Wereld[] werelden;

	string naam;
	Voorwerp[] kinderen = [];
	Zicht zicht;
	LichtVerzameling lichtVerzameling;

	this(string naam) {
		this.naam = naam;
		werelden ~= this;
		lichtVerzameling = new LichtVerzameling();
	}

	public void teken() {
		zicht.gebruik();
		foreach (Voorwerp kind; kinderen)
			kind.teken();
	}

	public void denkStap(Duration deltaT) {
		foreach (Voorwerp kind; kinderen)
			kind.denkStap(deltaT);
	}

	public void werkBij() {
		foreach (Voorwerp kind; kinderen)
			kind.werkBij(this, false);
	}
}
