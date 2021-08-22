module hoekjed.dingen.plattevorm;
import bindbc.opengl;
import hoekjed.kern;
import std.math : cos, PI, sin;

class PlatteVorm : Voorwerp {
	this(uint hoektal, Vec!3 plek = Vec!(3).nul, bool maakNormalen = false,
			bool maakBeeldplekken = false) {
		assert(hoektal >= 3);

		Vec!3[] plekken = new Vec!3[](hoektal);
		immutable real stap = 2 * PI / hoektal;
		foreach (i; 0 .. hoektal)
			plekken[i] = Vec!3([
					-0.5*sin(i * stap) + plek.x, 0 + plek.y, 0.5*cos(i * stap) + plek.z
					]);

		this(plekken, maakNormalen, maakBeeldplekken);
	}

	this(Vec!3[] plekken, bool maakNormalen = false, bool maakBeeldplekken = false) {
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

		super(plekken, volgorde, normalen, beeldplekken);
	}
}
