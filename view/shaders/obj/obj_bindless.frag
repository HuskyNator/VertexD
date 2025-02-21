#version 460
#extension GL_ARB_gpu_shader_int64 : require

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
	uint64_t mapKa;
	uint64_t mapKd;
	uint64_t mapKs;
	uint64_t mapNs;
	uint64_t mapD;
}
material;

layout(location = 0) uniform mat4 modelMatrix;

uniform float ambientLight;

in vec3 frag_pos;
in vec2 frag_uv;
in vec3 frag_normal;
out vec4 out_color;

vec3 readTexture(uint64_t map, vec3 factor) {
	if (map == 0) return factor;
	sampler2D mapSampler = sampler2D(map);
	return factor * texture(mapSampler, frag_uv);
}

float readTexture(uint64_t map, float factor) {
	if (map == 0) return factor;
	sampler2D mapSampler = sampler2D(map);
	return factor * texture(mapSampler, frag_uv);
}

void main() {
	float dissolve = readTexture(material.mapD, material.d);
	vec3 kd = readTexture(material.mapKd, material.kd);

	if (illum == 0) {
		out_color = vec4(kd, dissolve);
		return;
	}

	vec3 ka = readTexture(material.mapKa, material.ka);
	vec3 normal = normalize(frag_normal);
	vec3 lightPos = vec3(1, 10, -10);
	vec3 lightDir = normalize(lightPos - frag_pos);
	float diffuse = max(dot(normal, lightDir), 0);

	if (illum == 1) {
		out_color = vec4(ka * ambientLight + kd * diffuse, dissolve);
		return;
	}

	vec3 ks = texture(material.mapKs, material.ks);
	float ns = texture(material.mapNs, material.ns);
	vec3 camDir = normalize(cameraPosition - frag_pos);
	vec3 halfDir = normalize(lightDir + camDir);
	float specular = pow(max(dot(halfDir, normal), 0), ns);

	if (illum == 2) {
		out_color =
			vec4(ka * ambientLight + kd * diffuse + ks * specular, dissolve);
		return;
	}

	out_color = vec4(1, 0, 1, 1);
	return;	 // Not implemented
}