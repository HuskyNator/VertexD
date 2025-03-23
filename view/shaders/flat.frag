#version 460
layout(row_major) uniform;
layout(row_major) buffer;

layout(std140, binding = 0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraPosition;
};

in vec3 frag_pos;
in vec3 frag_normal;
out vec4 color;

void main() { color = vec4(vec3(1, 1, 1) * max(0,dot(frag_normal, frag_pos)), 1); }