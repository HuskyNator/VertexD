module zicht;
import wereld;
import wiskunde;

abstract class Zicht {
	Wereld wereld;
	Houding houding;
	Mat!4 projectieM;
	Mat!4 zichtM;

	abstract void werkProjectieBij();
	void teken() {
		houding.werkBij();
		// VOEG TOE zet verver uniformen.
		wereld.teken();
	}
}

class DiepteZicht : Zicht {
	nauwkeurigheid voorvlak = 0.01;
	nauwkeurigheid achtervlak = 100;
	nauwkeurigheid zichthoek = 90;
	nauwkeurigheid schermverhouding = 1080 / 1920;

	this(nauwkeurigheid voorvlak = 0.01, nauwkeurigheid achtervlak = 100,
			nauwkeurigheid zichthoek = 90, nauwkeurigheid schermverhouding = 1080 / 1920) {
		this.voorvlak = voorvlak;
		this.achtervlak = achtervlak;
		this.zichthoek = zichthoek;
		this.schermverhouding = schermverhouding;
	}

	override void werkProjectieBij() {
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
