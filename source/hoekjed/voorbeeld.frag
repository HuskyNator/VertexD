#version 460

in vec3 splek;
in vec3 snormaal;
in vec2 sbeeldplek;

uniform mat4 projectieM;
uniform mat4 zichtM;

layout(location=0)out vec4 kleur;

void main(){
	kleur = vec4(0, 1, 0, 1)
}
