#version 460

layout(location = 0) in vec3 hplek;
layout(location = 1) in vec3 hnormaal;
layout(location = 2) in vec2 hbeeldplek;
layout(location = 3) in int gl_VertexID;

uniform mat4 projectieM;
uniform mat4 zichtM;
uniform mat4 tekenM;

out vec3 splek;
out vec3 snormaal;
out vec2 sbeeldplek;

out vec4 gl_Position;

void main(){
	splek=hplek;
	snormaal=hnormaal;
	sbeeldplek=hbeeldplek;
	
	// gl_Position=zichtM*tekenM*vec4(hplek,1);
	gl_Position=projectieM*zichtM*tekenM*vec4(hplek,1);
}
