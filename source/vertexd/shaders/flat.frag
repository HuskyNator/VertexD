#version 460

layout(row_major) uniform;
layout(row_major) buffer;

layout(std140, binding = 0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraPosition;
};

layout(std140, binding = 1) uniform Material {
    vec4 color;
};

layout(location = 0) uniform mat4 modelMatrix;

out vec4 out_color;

void main(){
	out_color = color;
}