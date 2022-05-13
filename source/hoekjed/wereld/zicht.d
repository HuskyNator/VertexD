module hoekjed.wereld.zicht;

import hoekjed.wereld;
import hoekjed.kern;
import std.math : tan;

class Zicht {
	string naam;
	Mat!4 projectieM = Mat!4(1);
	Mat!4 zichtM = Mat!4(1);
	Voorwerp ouder;

	this(string naam, Mat!4 projectieM, Voorwerp ouder) {
		this.naam = naam;
		this.projectieM = projectieM;
		this.ouder = ouder;
	}

	static Mat!4 perspectiefProjectie(
		nauwkeurigheid schermverhouding = (1920.0 / 1080.0),
		nauwkeurigheid zichthoek = 3.14 / 2.0,
		nauwkeurigheid voorvlak = 0.1,
		nauwkeurigheid achtervlak = 100) {
		nauwkeurigheid a = 1.0 / tan(zichthoek / 2.0);
		alias V = voorvlak;
		alias A = achtervlak;
		alias s = schermverhouding;
		nauwkeurigheid z = -(A + V) / (A - V);
		nauwkeurigheid y = -(2.0 * A * V) / (A - V);
		return Mat!4([
			[a, 0.0, 0.0, 0.0],
			[0.0, a * s, 0.0, 0.0],
			[0.0, 0.0, z, y],
			[0.0, 0.0, -1.0, 0.0]
		]);
	}

	void werkBij()
	in (ouder !is null) {
		this.zichtM = ouder.voorwerpMatrix.inverse();
	}
}
