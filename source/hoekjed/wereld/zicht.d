module hoekjed.wereld.zicht;

import hoekjed.wereld;
import hoekjed.kern;
import std.math : tan;
import hoekjed.ververs.verver;
import hoekjed.driehoeksnet.buffer;

class Zicht {
	union {
		struct ZichtUniform {
			Mat!4 projectieM = Mat!4(1);
			Mat!4 zichtM = Mat!4(1);
			Vec!3 plek = Vec!3(0);
		}

		ZichtUniform zichtUniform;
		ubyte[ZichtUniform.sizeof] ubytes;
	}

	alias zichtUniform this;
	Buffer uniformBuffer;

	string naam;
	Voorwerp ouder;

	this(string naam, Mat!4 projectieM, Voorwerp ouder) {
		this.naam = naam;
		this.projectieM = projectieM;
		this.ouder = ouder;
	}

	void gebruik() {
		if (uniformBuffer is null) {
			uniformBuffer = new Buffer(ubytes, true);
			Verver.zetUniformBuffer(0, uniformBuffer);
		} else
			uniformBuffer.zetInhoud(ubytes);
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
		this.plek = Vec!3(ouder.voorwerpMatrix.maal(Vec!4([0, 0, 0, 1]))[0 .. 3]);
		this.zichtM = ouder.voorwerpMatrix.inverse();
	}
}
