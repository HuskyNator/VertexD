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

in vec3 frag_pos;
in vec2 frag_uv;
in vec3 frag_normal;
out vec4 out_color;

void main(){
	vec3 lightPos = vec3(1, 10, -10);
	out_color = color * dot(normalize(lightPos-frag_pos), normalize(frag_normal));
}