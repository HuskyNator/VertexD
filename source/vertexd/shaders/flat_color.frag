#version 460
layout(row_major,std140,binding=0)uniform Camera{
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 camera_world;
};

layout(location=0)uniform mat4 modelMatrix;

// in vec4 gl_Position;
in vec4 frag_COLOR_0;

out vec4 out_color;

void main(){
	// out_color = frag_COLOR_0;
	out_color = vec4(1,0,0,1);
}