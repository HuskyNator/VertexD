module hoekjed.wereld.wereld;

import hoekjed;
import std.datetime : Duration;

class Wereld {
	string naam;
	Voorwerp[] kinderen;
	Zicht zicht;
	Verver verver;
	static Wereld[] werelden;

	this(string naam) {
		this.naam = naam;
		werelden ~= this;
		verver=Gltf.standaard_verver;
	}

	static Zicht ZICHT_TIJDELIJK;
	public void teken() {
		verver.zetUniform(zicht); // TODO: Uniform buffer objecten
		verver.zetUniform("ziener", zicht.ouder.plek);
		ZICHT_TIJDELIJK = zicht;
		foreach (Voorwerp kind; kinderen)
			kind.teken();
	}

	public void denkStap(Duration deltaT) {
		foreach (Voorwerp kind; kinderen)
			kind.denkStap(deltaT);
	}

	public void werkMatricesBij() {
		foreach (Voorwerp kind; kinderen)
			kind.werkMatrixBij(false);
		zicht.werkBij();
	}
}
