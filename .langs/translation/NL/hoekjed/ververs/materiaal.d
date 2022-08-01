module hoekjed.ververs.materiaal;

import hoekjed.kern.mat;
import hoekjed.ververs.textuur;
import hoekjed.ververs.verver;
import std.conv;
import std.typecons : Nullable;

struct Materiaal {
	enum AlphaGedrag {
		ONDOORZICHTIG,
		MASKER,
		MENGEN
	}

	string naam;
	PBR pbr;
	alias pbr this;
	Vec!3 straling_factor = Vec!3(0);
	AlphaGedrag alpha_gedrag = AlphaGedrag.ONDOORZICHTIG;
	nauw alpha_scheiding = 0.5;
	bool tweezijdig = false;
	Nullable!NormaalTextuurInfo normaal_textuur;
	Nullable!OcclusionTextuurInfo occlusion_textuur;
	Nullable!TextuurInfo straling_textuur;

	void gebruik(Verver verver) {
		verver.zetUniform("u_kleur_factor", kleur_factor);
		if (!kleur_textuur.isNull)
			kleur_textuur.get.gebruik(2);
		verver.zetUniform("u_metaal", metaal);
		verver.zetUniform("u_ruwheid", ruwheid);
		if (!metaal_ruwheid_textuur.isNull)
			metaal_ruwheid_textuur.get.gebruik(3);

		if (!normaal_textuur.isNull)
			normaal_textuur.get.gebruik(verver, 4);
		if (!occlusion_textuur.isNull)
			occlusion_textuur.get.gebruik(verver, 5);
		if (!straling_textuur.isNull)
			straling_textuur.get.gebruik(6);
		verver.zetUniform("u_straling_factor", straling_factor);
	}
}

struct PBR {
	Vec!4 kleur_factor = Vec!4(1);
	nauwkeurigheid metaal = 1;
	nauwkeurigheid ruwheid = 1;
	Nullable!TextuurInfo kleur_textuur; // TODO: Mogelijk SRGB
	Nullable!TextuurInfo metaal_ruwheid_textuur;
}
