#version 460

layout(row_major) uniform;
layout(row_major) buffer;

layout(std140, binding = 0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraPosition;
};

layout(std140, binding = 1) uniform Material {
	vec3 ka;
	vec3 kd;
	vec3 ks;
	float ns;
	float d;
	uint illum;
}
material;

layout(binding = 0) uniform sampler2D mapKa;
layout(binding = 1) uniform sampler2D mapKd;
layout(binding = 2) uniform sampler2D mapKs;
layout(binding = 3) uniform sampler2D mapNs;
layout(binding = 4) uniform sampler2D mapD;

layout(location = 0) uniform mat4 modelMatrix;

uniform float ambientLight;

in vec3 frag_pos;
in vec2 frag_uv;
in vec3 frag_normal;
out vec4 out_color;

vec3 readTexture(sampler2D map, vec3 factor) {
	return factor * texture(map, frag_uv).rgb;
}

float readTexture(sampler2D map, float factor) {
	return factor * texture(map, frag_uv).r;
}

void main() {
	float dissolve = readTexture(mapD, material.d);
	vec3 kd = readTexture(mapKd, material.kd);

	if (material.illum == 0) {
		out_color = vec4(kd, dissolve);
		return;
	}

	vec3 ka = readTexture(mapKa, material.ka);
	vec3 normal = normalize(frag_normal);
	vec3 lightPos = vec3(1, 10, -10);
	vec3 lightDir = normalize(lightPos - frag_pos);
	float diffuse = max(dot(normal, lightDir), 0);

	if (material.illum == 1) {
		out_color = vec4(ka * ambientLight + kd * diffuse, dissolve);
		return;
	}

	vec3 ks = readTexture(mapKs, material.ks);
	float ns = readTexture(mapNs, material.ns);
	vec3 camDir = normalize(cameraPosition - frag_pos);
	vec3 halfDir = normalize(lightDir + camDir);
	float specular = pow(max(dot(halfDir, normal), 0), ns);

	if (material.illum >= 2) { // > 2 not implemented
		out_color =
			vec4(ka * ambientLight + kd * diffuse + ks * specular, dissolve);
		return;
	}
}