module hoekjed.wereld;
import hoekjed;

import std.datetime.stopwatch;

class Wereld {
	static Wereld[] werelden;

	Voorwerp[] voorwerpen;

	// Voorwerp[] aangepast; VOEG TOE: meer optimalisatie.

	this(){
		Wereld.werelden ~= this;
	}

	void denk() {
		foreach (Voorwerp voorwerp; voorwerpen)
			voorwerp.denk(this);
		foreach (Voorwerp voorwerp; voorwerpen)
			voorwerp.werkBij();
	}

	void teken() {
		foreach (Voorwerp voorwerp; voorwerpen)
			voorwerp.teken();
	}
}
