#version 460
layout(row_major,std140,binding=0)uniform Camera{
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 camera_world;
};

uniform mat4 modelMatrix;

in vec3 vert_POSITION_model;
in vec4 vert_COLOR_0;

out vec4 gl_Position;
out vec4 frag_COLOR_0;

void main(){
	gl_Position=projectionMatrix*cameraMatrix*modelMatrix*vec4(vert_POSITION_model,1.);
	frag_COLOR_0=vert_COLOR_0;
}