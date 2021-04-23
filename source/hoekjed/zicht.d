module hoekjed.zicht;
import hoekjed;

abstract class Zicht : Voorwerp { // VOEG TOE: zicht als voorwerp in de wereld.
	Mat!4 projectieM;
	Mat!4 zichtM;

	override void _teken() {
	}

	override void _denk(Wereld wereld) {
	}

	override void werkBij() {
		werkZichtMBij();
		werkProjectieMBij();
	}

	void teken(Wereld wereld) {
		zetUniform();
		wereld.teken();
	}

	abstract void werkProjectieMBij();
	void werkZichtMBij() {
		zichtM = Mat!(4).identiteit;
		zichtM = Mat!(4).draaiMz(-_draai.z) * Mat!(4)
			.draaiMx(-_draai.x) * Mat!(4).draaiMy(-_draai.y);
		zichtM[0][3] = -_plek.x;
		zichtM[1][3] = -_plek.y;
		zichtM[2][3] = -_plek.z;
	}

	void zetUniform() {
		foreach (Verver verver; Verver.ververs) {
			verver.zetUniform("projectieM", projectieM);
			verver.zetUniform("zichtM", zichtM);
		}
	}
}

class DiepteZicht : Zicht {
	nauwkeurigheid schermverhouding = 1080 / 1920;
	nauwkeurigheid zichthoek = 90;
	nauwkeurigheid voorvlak = 0.01;
	nauwkeurigheid achtervlak = 100;

	this(nauwkeurigheid schermverhouding = 1080 / 1920, nauwkeurigheid zichthoek = 90,
			nauwkeurigheid voorvlak = 0.01, nauwkeurigheid achtervlak = 100,) {
		this.voorvlak = voorvlak;
		this.achtervlak = achtervlak;
		this.zichthoek = zichthoek;
		this.schermverhouding = schermverhouding;
	}

	override void werkProjectieMBij() {
		import std.math : tan;

		const nauwkeurigheid a = 1 / tan(zichthoek / 2);
		projectieM.mat = [
			[a, 0, 0, 0], [0, a * schermverhouding, 0, 0],
			[
				0, 0, (achtervlak + voorvlak) / (achtervlak - voorvlak),
				(2 * achtervlak * voorvlak) / (achtervlak - voorvlak)
			], [0, 0, cast(nauwkeurigheid) 1, 0]
		];
	}
}

// VOEG TOE: VlakteZicht
