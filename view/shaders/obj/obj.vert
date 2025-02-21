#version 460

layout(row_major) uniform;
layout(row_major) buffer;

layout(std140, binding = 0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraPosition;
};

layout(location = 0) uniform mat4 modelMatrix;

uniform float ambientLight;

layout(location = 0) in vec3 vert_pos;
layout(location = 1) in vec2 vert_uv;
layout(location = 2) in vec3 vert_normal;
out vec4 gl_Position;
out vec3 frag_pos;
out vec2 frag_uv;
out vec3 frag_normal;

void main() {
	vec4 position_world = modelMatrix * vec4(vert_pos, 1);
	gl_Position = projectionMatrix * cameraMatrix * position_world;
	frag_pos = vec3(position_world.xyz) / position_world.w;
	frag_normal =
		normalize((modelMatrix * vec4(normalize(vert_normal), 0)).xyz);
	frag_uv = vert_uv;
}