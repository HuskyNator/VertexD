module hoekjed.wereld.zicht;

import hoekjed.wereld;
import hoekjed.kern;
import std.math : tan;

class Zicht {
	Mat!4 projectieM = Mat!4(1);
	Mat!4 zichtM = Mat!4(1);
	Voorwerp ouder;

	this(Voorwerp ouder, Mat!4 projectieM) {
		this.ouder = ouder;
		this.projectieM = projectieM;
	}

	static Mat!4 perspectiefProjectie(
		nauwkeurigheid schermverhouding = (1080.0 / 1920.0),
		nauwkeurigheid zichthoek = 3.14 / 2,
		nauwkeurigheid voorvlak = 0.1,
		nauwkeurigheid achtervlak = 100) {
		nauwkeurigheid a = 1 / tan(zichthoek / 2);
		alias V = voorvlak;
		alias A = achtervlak;
		return Mat!4([
			[a, 0, 0, 0], [0, 0, schermverhouding * a, 0],
			[0, (A + V) / (A - V), 0, -(2 * A * V) / (A - V)],
			[0, cast(nauwkeurigheid) 1, 0, 0]
		]);
	}

	void werkBij()
	in (ouder !is null) {
		this.zichtM = ouder.voorwerpMatrix.inverse();
	}
}
