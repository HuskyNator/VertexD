module hoekjed.dingen.vormen;
import hoekjed.kern;
import bindbc.opengl;
import std.math : sin, cos, PI;

static class PlatteVorm {
	static Voorwerp maak(Vec!3 plek, uint hoektal, bool maakNormalen = false,
			bool maakBeeldplekken = false) {
		assert(hoektal >= 3);

		Vec!3[] plekken = new Vec!3[](hoektal);
		immutable real stap = 2 * PI / hoektal;
		foreach (i; 0 .. hoektal)
			plekken[i] = Vec!3([
					-sin(i * stap) + plek.x, 0 + plek.y, cos(i * stap) + plek.z
					]);
		
		return maak(plekken, maakNormalen, maakBeeldplekken);
	}

	static Voorwerp maak(Vec!3[] plekken, bool maakNormalen = false, bool maakBeeldplekken = false) {
		assert(plekken.length >= 3);

		Vec!(3, uint)[] volgorde;
		volgorde.length = plekken.length - 2;
		foreach (uint i; 0 .. cast(uint) volgorde.length) {
			volgorde[i] = Vec!(3, uint)([0, i + 1, i + 2]);
		}

		Vec!3[] normalen = null;
		if (maakNormalen) {
			Vec!3 normaal = plekken[0].uitp(plekken[1]).normaliseer();
			normalen = new Vec!3[](plekken.length);
			normalen[] = normaal;
			// Normalen kunnen mogelijk ook voor alle voorwerpen berekend worden.
		}

		Vec!2[] beeldplekken = null;
		if (maakBeeldplekken) {
			beeldplekken = new Vec!2[](plekken.length);
			Vec!3 plek = Vec!3([plekken[0].x, plekken[0].y, plekken[0].z - 1]);
			foreach (i; 0 .. plekken.length)
				beeldplekken[i] = Vec!2([
						(plekken[i].x - plek.x) * 0.5 + 0.5,
						(plekken[i].z - plek.z) * 0.5 + 0.5
						]);
		}

		return new Voorwerp(plekken, volgorde, normalen, beeldplekken);
	}
}
