module hoekjed.invoer.gltf;

import hoekjed.ververs;
import hoekjed.kern.wiskunde;

class Gltf {
	@disable this();
static const:
	PBR standaard_pbr = PBR(Vec!4(1), 1, 1);
	Materiaal standaard_materiaal = Materiaal("Standaard Materiaal", standaard_pbr);
	@property Verver standaard_verver() {
		Verver v = Verver.laad(standaard_vert, standaard_frag);
		v.zetUniform("kleur", Vec!4([250.0 / 255.0, 176.0 / 255.0, 22.0 / 255.0, 1]));
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
	plek = plek4.xyz;
	gl_Position = projectieM * zichtM * plek4;
	normaal = h_normaal;
}
`;

string standaard_frag = `
#version 460

uniform vec4 kleur;
layout(row_major, std140, binding=0) uniform Zicht {
	mat4 projectieM;
	mat4 zichtM;
	vec3 zichtplek;
};

in vec3 plek;
in vec3 normaal;

out vec4 u_kleur;

void main(){
	vec3 licht = vec3(1, 1, 1);
	vec3 l = normalize(licht-plek);
	vec3 n = normalize(normaal);
	vec3 r = reflect(-l, n);
	vec3 z = normalize(zichtplek-plek);
	float omgeving = 0.1;
	float diffuus = clamp(dot(n, l), 0, 1);
	float specular = clamp(pow(dot(z, r), 50), 0, 1);
	u_kleur = kleur * clamp(omgeving + diffuus + specular, 0, 1);
}
`;
