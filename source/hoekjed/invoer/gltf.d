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

layout(location=0)in vec3 h_plek;
layout(location=1)in vec3 h_normaal;
layout(location=2)in vec2 h_beeldplek;

uniform mat4 projectieM;
uniform mat4 zichtM;
uniform mat4 voorwerpM;
uniform vec3 ziener;

out vec4 gl_Position;
out vec3 plaats;
out vec3 normaal;

void main(){
	vec4 plaats4 = voorwerpM * vec4(h_plek, 1.0);
	plaats = plaats4.xyz;
	gl_Position = projectieM * zichtM * plaats4;
	normaal = h_normaal;
}
`;

string standaard_frag = `
#version 460

uniform vec4 kleur;
uniform vec3 ziener;

in vec3 plaats;
in vec3 normaal;

out vec4 u_kleur;

void main(){
	vec3 licht = vec3(1, 1, 1);
	vec3 l = normalize(licht-plaats);
	vec3 n = normalize(normaal);
	vec3 r = reflect(-l, n);
	vec3 z = normalize(ziener-plaats);
	float omgeving = 0.1;
	float diffuus = clamp(dot(n, l), 0, 1);
	float specular = clamp(pow(dot(z, r), 50), 0, 1);
	u_kleur = kleur * clamp(omgeving + diffuus + specular, 0, 1);
}
`;
