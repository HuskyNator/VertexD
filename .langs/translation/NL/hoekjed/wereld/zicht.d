module hoekjed.wereld.zicht;

import hoekjed.net.buffer;
import hoekjed.kern;
import hoekjed.ververs.verver;
import hoekjed.wereld;
import std.math : tan;

class Zicht : Voorwerp.Eigenschap {
	struct ZichtS {
		Mat!4 projectieM = Mat!4(1);
		Mat!4 zichtM = Mat!4(1);
		Vec!3 plek = Vec!3(0);
	}

	static Buffer uniformBuffer;

	ZichtS zichtS;
	alias zichtS this;

	this(Mat!4 projectieM) {
		this.projectieM = projectieM;

		if (uniformBuffer is null) {
			uniformBuffer = new Buffer(&zichtS, zichtS.sizeof, true);
			Verver.zetUniformBuffer(0, uniformBuffer);
		}
	}

	void werkBij(Wereld wereld, Voorwerp ouder) {
		this.plek = Vec!3(ouder.voorwerpMatrix.kol(3)[0 .. 3]);
		this.zichtM = ouder.voorwerpMatrix.inverse();
	}

	void gebruik() {
		uniformBuffer.zetInhoud(&zichtS, zichtS.sizeof);
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
}
