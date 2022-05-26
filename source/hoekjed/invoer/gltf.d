module hoekjed.invoer.gltf;

import hoekjed.ververs;
import hoekjed.kern.wiskunde;

class Gltf {
	@disable this();
static const:
	PBR standaard_pbr = PBR(Vec!4(1), 1, 1);
	Materiaal standaard_materiaal = Materiaal("Standaard Materiaal", standaard_pbr);
	@property Verver standaard_verver() {
		bool nieuw;
		Verver v = Verver.laad(standaard_vert, standaard_frag, &nieuw);
		if (nieuw) {
			v.zetUniform("u_kleur", Vec!4([
					250.0 / 255.0, 176.0 / 255.0, 22.0 / 255.0, 1
				]));
			v.zetUniform("u_omgeving", Vec!1([0.1]));
			v.zetUniform("u_diffuus", Vec!1([0.7]));
			v.zetUniform("u_specular", Vec!1([0.2]));
			float a = 50.0f;
			Vec!1 b = Vec!1(a);
			Vec!1 c = Vec!1([a]);
			Vec!1 d = Vec!1([50.0f]);
			v.zetUniform("u_specular_macht", Vec!1([50.0f]));
			v.zetUniform("u_specular_macht", Vec!1([50.0f]));
		}
		return v;
	}
}

// TODO PBR

private:
string standaard_vert = `
#version 460

layout(location=0) in vec3 h_plek;
layout(location=1) in vec3 h_normaal;
layout(location=2) in vec2 h_beeldplek;

layout(row_major, std140, binding=0) uniform Zicht {
	mat4 projectieM;
	mat4 zichtM;
	vec3 zichtplek;
};

uniform mat4 voorwerpM;

out vec4 gl_Position;
out vec3 plek;
out vec3 normaal;

void main(){
	vec4 plek4 = voorwerpM * vec4(h_plek, 1.0);
	plek = plek4.xyz/plek4.w;
	gl_Position = projectieM * zichtM * plek4;
	normaal = h_normaal;
}
`;

string standaard_frag = `
#version 460

in vec3 plek;
in vec3 normaal;

uniform vec4 u_kleur;
uniform nauwkeurigheid u_omgeving;
uniform nauwkeurigheid u_diffuus;
uniform nauwkeurigheid u_specular;
uniform nauwkeurigheid u_specular_macht;

layout(row_major, std140, binding=0) uniform Zicht {
	mat4 projectieM;
	mat4 zichtM;
	vec3 zichtplek;
};

layout(row_major, std140, binding=1) uniform Lichten {
	uint lichtaantal;
	vec3 lichtplekken[MAX_LICHTEN];
};

out vec4 kleur;

nauwkeurigheid lichtheid(vec3 licht){
	return dot(licht, vec3(0.2126, 0.7152, 0.0722));
}

void main(){
	vec3 N = normalize(normaal);
	vec3 Z = normalize(zichtplek-plek);

	nauwkeurigheid licht_som = 0;
	for(int i = 0; i < lichtaantal; i++){
		vec3 L = normalize(lichtplekken[i]-plek);
		vec3 H = normalize(L+Z);
		nauwkeurigheid diffuus = u_diffuus*clamp(dot(N, L), 0.0, 1.0);
		nauwkeurigheid specular = u_specular*clamp(pow(dot(H, N), u_specular_macht), 0.0, 1.0);
		licht_som += u_omgeving+diffuus+specular;
	}

	vec3 totaallicht = 0.2*u_kleur.xyz * licht_som;
	nauwkeurigheid licht = lichtheid(totaallicht);
	kleur = vec4(totaallicht/(1+licht), u_kleur.w);
}
`;
