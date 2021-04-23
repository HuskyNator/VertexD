#version 460

in vec3 hplek;
in vec3 hnormaal;
in vec2 hbeeldplek;

uniform mat4 projectieM
uniform mat4 zichtM

out vec3 splek;
out vec3 snormaal;
out vec2 sbeeldplek;

out vec4 gl_Position;

void main(){
	splek=hplek;
	snormaal=hnormaal;
	sbeeldplek=hbeeldplek;
	
	gl_Position=projectieM*zichtM*hplek;
}
