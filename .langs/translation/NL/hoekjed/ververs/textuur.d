module hoekjed.ververs.textuur;
import hoekjed.kern.mat;
import hoekjed.ververs;

struct TextuurInfo {
	Textuur textuur;
	uint beeldplek;

	void gebruik(uint plek) {
		textuur.gebruik(plek);
	}
}

struct NormaalTextuurInfo {
	TextuurInfo textuurInfo;
	alias textuurInfo this;
	nauw normaal_schaal;

	void gebruik(Verver verver,uint plek) {
		verver.zetUniform("u_normaal_schaal", normaal_schaal);
		textuurInfo.gebruik(plek);
	}
}

struct OcclusionTextuurInfo {
	TextuurInfo textuurInfo;
	alias textuurInfo this;
	nauw occlusion_sterkte;

	void gebruik(Verver verver, uint plek) {
		verver.zetUniform("u_occlusion_sterkte", occlusion_sterkte);
		textuurInfo.gebruik(plek);
	}
}

struct Textuur {
	string naam;
	Sampler sampler;
	Afbeelding afbeelding;

	void gebruik(uint plek) {
		sampler.gebruik(plek);
		afbeelding.gebruik(plek);
	}
}
