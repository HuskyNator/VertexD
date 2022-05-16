module hoekjed.ververs.materiaal;

import hoekjed.kern.wiskunde;

struct Materiaal {
	string naam;
	PBR pbr;
	// normaal_afbeelding = null
	// afdekking_afbeelding = null
	// straling_afbeelding = null
	// straling = Vec!3(0)
	// alpha_gedrag = OPAGUE (blending)
	// alpha_scheiding = 0.5
	// tweezijdig = false (backface culling)
	// TODO
}

struct PBR {
	Vec!4 kleur = Vec!4(1);
	// kleur_afbeelding = null
	nauwkeurigheid metaal = 1;
	nauwkeurigheid ruwheid = 1;
	// metaal_ruwheid_afbeelding = null
}
