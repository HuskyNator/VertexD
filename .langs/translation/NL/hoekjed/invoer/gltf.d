module hoekjed.invoer.gltf;

import bindbc.opengl;
import hoekjed.net;
import hoekjed.kern.mat;
import hoekjed.ververs;
import std.typecons;
import std.conv;
import std.array : replace;
import std.string : splitLines;

class Gltf {
	@disable this();

static:
	PBR standaard_pbr;

	Materiaal standaard_materiaal;
	static this() {
		standaard_pbr = PBR(Vec!4(1), 1, 1);
		standaard_materiaal = Materiaal(
			"Standaard Materiaal",
			standaard_pbr,
			Vec!3(0),
			Materiaal.AlphaGedrag.ONDOORZICHTIG,
			cast(nauw) 0.5,
			false
		);
	}

	Verver genereerVerver(Driehoeksnet.Eigenschap[] eigenschappen, string[] namen, Materiaal materiaal) {
		string[string] vervangers;
		// KNOOP_INVOER_UITVOER
		string knoop_invoer_uitvoer;
		foreach (i; 0 .. eigenschappen.length) {
			Driehoeksnet.Eigenschap e = eigenschappen[i];
			knoop_invoer_uitvoer ~= `layout(location=` ~ i.to!string ~ `) in ` ~ soortString(
				e) ~ ` knoop_` ~ namen[i] ~ ";\n";
			knoop_invoer_uitvoer ~= `out ` ~ soortString(
				e) ~ ` punt_` ~ namen[i] ~ ";\n";
		}
		vervangers["KNOOP_INVOER_UITVOER"] = knoop_invoer_uitvoer;

		// PUNT_INVOER
		string punt_invoer;
		foreach (i; 0 .. eigenschappen.length) {
			Driehoeksnet.Eigenschap e = eigenschappen[i];
			punt_invoer ~= `in ` ~ soortString(
				e) ~ ` punt_` ~ namen[i] ~ ";\n";
		}
		vervangers["PUNT_INVOER"] = punt_invoer;

		// KNOOP_NAAR_PUNT_INVOER
		// KNOOP_UITVOER
		string knoop_naar_punt_invoer;
		foreach (i; 0 .. eigenschappen.length) {
			knoop_naar_punt_invoer ~= "\tpunt_" ~ namen[i] ~ " = " ~ "knoop_" ~ namen[i] ~ ";\n";
		}
		vervangers["KNOOP_NAAR_PUNT_INVOER"] = knoop_naar_punt_invoer;

		// Texturen
		string textuur_uniformen;
		uint plek = 2;

		void voegTextuurToeTI(TextuurInfo ti, string naam) {
			textuur_uniformen ~= `layout(binding = ` ~ plek.to!string ~ `) uniform sampler2D u_` ~ naam ~ ";\n";
			vervangers["u_" ~ naam ~ "_beeldplek"] = "punt_TEXCOORD_" ~ ti.beeldplek.to!string;
			plek += 1;
		}

		void voegTextuurToeNTI(Nullable!TextuurInfo ti, string naam) {
			if (ti.isNull)
				return;
			voegTextuurToeTI(ti.get(), naam);
		}

		void voegTextuurToeNNTI(Nullable!NormaalTextuurInfo ti, string naam) {
			if (ti.isNull)
				return;
			voegTextuurToeTI(ti.get.textuurInfo, naam);
			textuur_uniformen ~= "uniform nauwkeurigheid u_normaal_schaal;\n";
		}

		void voegTextuurToeNOTI(Nullable!OcclusionTextuurInfo ti, string naam) {
			if (ti.isNull)
				return;
			voegTextuurToeTI(ti.get.textuurInfo, naam);
			textuur_uniformen ~= "uniform nauwkeurigheid u_occlusion_sterkte;\n";
		}

		voegTextuurToeNTI(materiaal.pbr.kleur_textuur, "kleur_textuur");
		voegTextuurToeNTI(materiaal.pbr.metaal_ruwheid_textuur, "metaal_ruwheid_textuur");
		voegTextuurToeNNTI(materiaal.normaal_textuur, "normaal_textuur");
		voegTextuurToeNOTI(materiaal.occlusion_textuur, "occlusion_textuur");
		voegTextuurToeNTI(materiaal.straling_textuur, "straling_textuur");
		vervangers["TEXTUREN"] = textuur_uniformen;

		//TODO TIJDELIJK
		if (!materiaal.pbr.kleur_textuur.isNull)
			vervangers["KLEUR_IN"] = `texture(u_kleur_textuur, u_kleur_textuur_beeldplek) * u_kleur_factor;`;
		else
			vervangers["KLEUR_IN"] = `vec4(0,0,0,0); discard;`;

		// if (!materiaal.normaal_textuur.isNull)
		// 	vervangers["NORMAAL_IN"] = `normalize((texture(u_normaal_textuur, u_normaal_textuur_beeldplek).xyz*2.0-1.0)*vec3(u_normaal_schaal, u_normaal_schaal, 1.0))`;
		// else
		// 	vervangers["NORMAAL_IN"] = `punt_NORMAL`;

		return Verver.laad(standaard_knoop, standaard_punt, vervangers);
	}

	/**
 * Geeft glsl invoersnaam voor knoop soort.
 * Gaat uit van soorten die glTF ondersteunt.
 */
	private string soortString(Driehoeksnet.Eigenschap e) {
		if (e.soorttal == 1) {
			switch (e.soort) {
			case GL_BYTE, GL_SHORT:
				return "int";
			case GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT:
				return "int";
			case GL_FLOAT:
				return "float";
			default:
				assert(0, "Soort niet ondersteund voor eigenschappen: " ~ e.soort.to!string);
			}
		}

		if (e.matrix) {
			assert(e.soort == GL_FLOAT, "Matrix moet float zijn.");
			switch (e.soorttal) {
			case 4:
				return "mat2";
			case 9:
				return "mat3";
			case 16:
				return "mat4";
			default:
				assert(0, "Matrix van onverwachtte grootte: " ~ e.soorttal.to!string);
			}
		}

		string s;
		switch (e.soort) {
		case GL_BYTE, GL_SHORT:
			s ~= "i";
			break;
		case GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT:
			s ~= "u";
			break;
		case GL_FLOAT:
			break;
		default:
			assert(0, "Soort niet ondersteund voor eigenschappen: " ~ e.soort.to!string);
		}
		s ~= "vec";
		s ~= e.soorttal.to!string;
		return s;
	}

	// TODO PBR

private:
	string standaard_knoop = `#version 460

KNOOP_INVOER_UITVOER

TEXTUREN
//// Materiaal
// PBR
uniform vec4 u_kleur_factor;
uniform nauwkeurigheid u_metaal;
uniform nauwkeurigheid u_ruwheid;
// Materiaal
uniform vec3 u_straling_factor;

layout(row_major, std140, binding=0) uniform Zicht {
	mat4 projectieM;
	mat4 zichtM;
	vec3 zichtplek;
};

uniform mat4 voorwerpM;

out vec4 gl_Position;
out vec3 punt_plek;

void main(){
	KNOOP_NAAR_PUNT_INVOER

	vec4 plek4 = voorwerpM * vec4(knoop_POSITION, 1.0);
	gl_Position = projectieM * zichtM * plek4;

	punt_plek = plek4.xyz/plek4.w;
}
`;

	string standaard_punt = `#version 460

PUNT_INVOER

in vec3 punt_plek;

uniform vec4 u_kleur;
nauwkeurigheid u_occlusion = 0.1;
nauwkeurigheid u_diffuus = 0.7;
nauwkeurigheid u_specular = 0.2;
nauwkeurigheid u_specular_macht = 50;

TEXTUREN
//// Materiaal
// PBR
uniform vec4 u_kleur_factor;
uniform nauwkeurigheid u_metaal;
uniform nauwkeurigheid u_ruwheid;
// Materiaal
uniform vec3 u_straling_factor;

layout(row_major, std140, binding=0) uniform Zicht {
	mat4 projectieM;
	mat4 zichtM;
	vec3 zichtplek;
};

layout(row_major, std140, binding=1) uniform Lichten {
	uint lichtaantal;
	vec3 lichtplekken[MAX_LICHTEN];
};

out vec4 uit_kleur;

nauwkeurigheid lichtheid(vec3 licht){
	return dot(licht, vec3(0.2126, 0.7152, 0.0722));
}

void main(){
	vec4 kleur_in = KLEUR_IN;
	vec3 N = normalize(punt_NORMAL);
	vec3 Z = normalize(zichtplek-punt_plek);

	nauwkeurigheid licht_som = 0;
	if(lichtaantal == 0){
		vec3 licht = vec3(1,1,1);
		vec3 L = normalize(licht-punt_plek);
		vec3 H = normalize(L+Z);
		nauwkeurigheid diffuus = u_diffuus*clamp(dot(N, L), 0.0, 1.0);
		nauwkeurigheid specular = u_specular*clamp(pow(dot(H, N), u_specular_macht), 0.0, 1.0);
		licht_som += u_occlusion+diffuus+specular;
	} else{
	for(int i = 0; i < lichtaantal; i++){
		vec3 L = normalize(lichtplekken[i]-punt_plek);
		vec3 H = normalize(L+Z);
		nauwkeurigheid diffuus = u_diffuus*clamp(dot(N, L), 0.0, 1.0);
		nauwkeurigheid specular = u_specular*clamp(pow(dot(H, N), u_specular_macht), 0.0, 1.0);
		licht_som += u_occlusion+diffuus+specular;
	}}

	vec3 totaallicht = 0.2*kleur_in.xyz * licht_som;
	nauwkeurigheid licht = lichtheid(totaallicht);
	uit_kleur = vec4(totaallicht/(1+licht), kleur_in.w);
}
`;
}
