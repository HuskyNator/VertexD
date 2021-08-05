module hoekjed.dingen.zicht;
import hoekjed.kern;

abstract class Zicht : Ding { // VOEG TOE: zicht als ding in de wereld.
	Mat!4 projectieM;
	Mat!4 zichtM;

	override void teken() {
	}

	override void denk() {
	}

	override protected void werkBij(bool ouderAangepast) {
		werkZichtMBij();
		werkProjectieMBij();
		super.werkBij(ouderAangepast);
	}

	static Zicht huidig; //PAS OP: tijdelijk
	void teken(Wereld wereld) {
		Zicht.huidig = this;
		zetUniform();
		wereld.teken();
	}

	abstract void werkProjectieMBij();
	void werkZichtMBij() {
		zichtM = Mat!(4).identiteit;
		zichtM[0][3] = -_plek.x;
		zichtM[1][3] = -_plek.y;
		zichtM[2][3] = -_plek.z;
		zichtM = Mat!(4).draaiMy(-_draai.y).maal(Mat!(4).draaiMx(-_draai.x)
				.maal(Mat!(4).draaiMz(-_draai.z)).maal(zichtM));
	}

	void zetUniform() {
		// TODO: dit is zwaar slecht aangezien het elke verver koppelt.
		foreach (Verver verver; Verver.ververs) {
			verver.zetUniform("projectieM", projectieM);
			verver.zetUniform("zichtM", zichtM);
		}
	}
}

class DiepteZicht : Zicht {
	nauwkeurigheid schermverhouding;
	nauwkeurigheid zichthoek;
	nauwkeurigheid voorvlak;
	nauwkeurigheid achtervlak;

	this(nauwkeurigheid schermverhouding = 1920.0 / 1080.0, nauwkeurigheid zichthoek = 90,
			nauwkeurigheid voorvlak = 0.01, nauwkeurigheid achtervlak = 100,) {
		this.voorvlak = voorvlak;
		this.achtervlak = achtervlak;
		this.zichthoek = zichthoek;
		this.schermverhouding = schermverhouding;
	}

	override void werkProjectieMBij() {
		import std.math : tan;

		alias A = achtervlak;
		alias V = voorvlak;

		const nauwkeurigheid a = 1 / tan(zichthoek / 2);
		projectieM.mat = [
			[a, 0, 0, 0], [0, 0, schermverhouding * a, 0],
			[0, (A + V) / (A - V), 0, -(2 * A * V) / (A - V)],
			[0, cast(nauwkeurigheid) 1, 0, 0]
		];
	}
}

// VOEG TOE: VlakteZicht
