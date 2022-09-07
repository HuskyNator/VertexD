module vertexd.input.gltf;

import bindbc.opengl;
import vertexd.mesh;
import vertexd.core.mat;
import vertexd.shaders;
import std.typecons;
import std.conv;
import std.array : replace;
import std.string : splitLines;

class Gltf {
	@disable this();

static:
	// Shader generateShader(Mesh.Attribute[] attributes, string[] names, Material material) {
	// 	string[string] placeholders;
	// 	// VERTEX_INPUT_OUTPUT
	// 	string vertex_input_output;
	// 	foreach (i; 0 .. attributes.length) {
	// 		Mesh.Attribute e = attributes[i];
	// 		vertex_input_output ~= `layout(location=` ~ i.to!string ~ `) in ` ~ typeString(
	// 			e) ~ ` vertex_` ~ names[i] ~ ";\n";
	// 		vertex_input_output ~= `out ` ~ typeString(
	// 			e) ~ ` fragment_` ~ names[i] ~ ";\n";
	// 	}
	// 	placeholders["VERTEX_INPUT_OUTPUT"] = vertex_input_output;

	// 	// FRAGMENT_INPUT
	// 	string fragment_input;
	// 	foreach (i; 0 .. attributes.length) {
	// 		Mesh.Attribute e = attributes[i];
	// 		fragment_input ~= `in ` ~ typeString(
	// 			e) ~ ` fragment_` ~ names[i] ~ ";\n";
	// 	}
	// 	placeholders["FRAGMENT_INPUT"] = fragment_input;

	// 	// VERTEX_TO_FRAGMENT_INPUT
	// 	// VERTEX_OUTPUT
	// 	string vertex_to_fragment_input;
	// 	foreach (i; 0 .. attributes.length) {
	// 		vertex_to_fragment_input ~= "\tfragment_" ~ names[i] ~ " = " ~ "vertex_" ~ names[i] ~ ";\n";
	// 	}
	// 	placeholders["VERTEX_TO_FRAGMENT_INPUT"] = vertex_to_fragment_input;

	// 	// Textures
	// 	string texture_uniforms;
	// 	uint location = 2;

	// 	void addTextureTI(TextureInfo ti, string name) {
	// 		texture_uniforms ~= `layout(binding = ` ~ location.to!string ~ `) uniform sampler2D u_` ~ name ~ ";\n";
	// 		placeholders["u_" ~ name ~ "_textureCoord"] = "fragment_TEXCOORD_" ~ ti
	// 			.texCoord.to!string;
	// 		location += 1;
	// 	}

	// 	void addTextureNTI(Nullable!TextureInfo ti, string name) {
	// 		if (ti.isNull)
	// 			return;
	// 		addTextureTI(ti.get(), name);
	// 	}

	// 	void addTextureNNTI(Nullable!NormalTextureInfo ti, string name) {
	// 		if (ti.isNull)
	// 			return;
	// 		addTextureTI(ti.get.textureInfo, name);
	// 		texture_uniforms ~= "uniform precision u_normal_scale;\n";
	// 	}

	// 	void addTextureNOTI(Nullable!OcclusionTextureInfo ti, string name) {
	// 		if (ti.isNull)
	// 			return;
	// 		addTextureTI(ti.get.textureInfo, name);
	// 		texture_uniforms ~= "uniform precision u_occlusion_strength;\n";
	// 	}

	// 	addTextureNTI(material.pbr.color_texture, "color_texture");
	// 	addTextureNTI(material.pbr.metal_roughness_texture, "metal_roughness_texture");
	// 	addTextureNNTI(material.normal_texture, "normal_textures");
	// 	addTextureNOTI(material.occlusion_texture, "occlusion_textuur");
	// 	addTextureNTI(material.emission_texture, "emission_texture");
	// 	placeholders["TEXTURES"] = texture_uniforms;

	// 	// TODO TEMPORARY
	// 	if (!material.pbr.color_texture.isNull)
	// 		placeholders["COLOR_IN"] = `texture(u_color_texture, u_color_texture_textureCoord) * u_color_factor;`;
	// 	else
	// 		placeholders["COLOR_IN"] = `vec4(0,0,0,0); discard;`;

	// 	// if (!material.normal_texture.isNull)
	// 	// placeholders["NORMAL_IN"]="normalize((texture(u_normal_texture,u_normal_texture_textureCoord).xyz*2.0-1.0)*vec3(u_normal_scale,u_normal_scale,1.0))";
	// 	// else
	// 	// placeholders["NORMAL_IN"] = "fragment_NORMAL";

	// 	return Shader.load(standard_vertex, standard_fragment, placeholders);
	// }

	/**
		* Gives glsl inputname for vertex type.
		* Assumes types glTF supports.
		*/
	private string typeString(Mesh.Attribute e) {
		if (e.typeCount == 1) {
			switch (e.type) {
				case GL_BYTE, GL_SHORT:
					return "int";
				case GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT:
					return "int";
				case GL_FLOAT:
					return "float";
				default:
					assert(0, "Type not supported for attributes: " ~ e.type.to!string);
			}
		}

		if (e.matrix) {
			assert(e.type == GL_FLOAT, "Matrix must be float");
			switch (e.typeCount) {
				case 4:
					return "mat2";
				case 9:
					return "mat3";
				case 16:
					return "mat4";
				default:
					assert(0, "Matrix unexpected size: " ~ e.typeCount.to!string);
			}
		}

		string s;
		switch (e.type) {
			case GL_BYTE, GL_SHORT:
				s ~= "i";
				break;
			case GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT, GL_UNSIGNED_INT:
				s ~= "u";
				break;
			case GL_FLOAT:
				break;
			default:
				assert(0, "Type not supported for attributes: " ~ e.type.to!string);
		}
		s ~= "vec";
		s ~= e.typeCount.to!string;
		return s;
	}

	// TODO PBR

private:
	string standard_vertex = `#version 460

layout(location=0) in vec3 POSITION;
layout(location=1) in vec3 NORMAL;
layout(location=2) in vec3 TANGENT;
layout(location=3) in vec2 TEXCOORD_0;
layout(location=4) in vec2 TEXCOORD_1;
layout(location=5) in vec4 COLOR_0;
// layout(location=0) in vec4 JOINTS_0;
// layout(location=0) in vec3 WEIGHTS_0;
// Custom INPUT

struct Texture {
	sampler2D sampler;
	int texCoord;
	float factor;
};

layout(row_major, std140, binding=0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraLocation;
};

layout(row_major, std140, binding=1) uniform Lights {
	uint lightCount;
	vec3 lightLocations[512];
};

layout(row_major, std140, binding=2) uniform Material {
	vec4 color_factor;
	float metal_factor;
	float roughness_factor;
	vec3 emissive_factor;
	Texture color_texture;
	Texture metal_roughness_texture;
	Texture normal_texture;
	Texture occlusion_texture;
	Texture emissive_texture;
};

uniform mat4 nodeMatrix;

out vec4 gl_Position;

out vec3 frag_POSITION;
out vec3 frag_NORMAL;
out vec3 frag_TANGENT;
out vec2 frag_TEXCOORD_0;
out vec2 frag_TEXCOORD_1;
out vec4 frag_COLOR_0;

void main(){
	frag_POSITION = POSITION;
	frag_NORMAL = NORMAL;
	frag_TANGENT = TANGENT;
	frag_TEXCOORD_0 = TEXCOORD_0;
	frag_TEXCOORD_1 = TEXCOORD_1;
	frag_COLOR_0 = COLOR_0;

	vec4 globalPosition = nodeMatrix * vec4(POSITION, 1.0);
	gl_Position = projectionMatrix * cameraMatrix * globalPosition;
}
`;

	string standard_fragment = `#version 460

in vec4 gl_Position;

in vec3 frag_POSITION;
in vec3 frag_NORMAL;
in vec3 frag_TANGENT;
in vec2 frag_TEXCOORD_0;
in vec2 frag_TEXCOORD_1;
in vec4 frag_COLOR_0;

struct Texture {
	sampler2D sampler;
	int texCoord;
	float factor;
};

layout(row_major, std140, binding=0) uniform Camera {
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraLocation;
};

layout(row_major, std140, binding=1) uniform Lights {
	uint lightCount;
	vec3 lightLocations[512];
};

layout(row_major, std140, binding=2) uniform Material {
	vec4 color_factor;
	float metal_factor;
	float roughness_factor;
	vec3 emissive_factor;
	Texture color_texture;
	Texture metal_roughness_texture;
	Texture normal_texture;
	Texture occlusion_texture;
	Texture emissive_texture;
};

uniform mat4 nodeMatrix;

// uniform vec4 u_color;
// precision u_occlusion = 0.1;
// precision u_diffuse = 0.7;
// precision u_specular = 0.2;
// precision u_specular_power = 50;

out vec4 out_color;

precision luminocity(vec3 light){
	return dot(light, vec3(0.2126, 0.7152, 0.0722));
}

void main(){
	vec4 color_in = frag_COLOR_0;
	if (color_texture.sampler != 0)
		color_in = normalize(
			texture(color_texture.sampler, color_texture.texCoord).xyz
			* vec3(color_texture.factor, color_texture.factor, 1));
	vec3 N = frag_NORMAL;
	vec3 Z = normalize(cameraLocation-fragment_location);

	precision light_sum = 0;
	if(lightCount == 0){
		vec3 light = vec3(1,1,1);
		vec3 L = normalize(light-fragment_location);
		vec3 H = normalize(L+Z);
		precision diffuse = u_diffuse*clamp(dot(N, L), 0.0, 1.0);
		precision specular = u_specular*clamp(pow(dot(H, N), u_specular_power), 0.0, 1.0);
		light_sum += u_occlusion+diffuse+specular;
	} else{
	for(int i = 0; i < lightCount; i++){
		vec3 L = normalize(lichtLocations[i]-fragment_location);
		vec3 H = normalize(L+Z);
		precision diffuse = u_diffuse*clamp(dot(N, L), 0.0, 1.0);
		precision specular = u_specular*clamp(pow(dot(H, N), u_specular_power), 0.0, 1.0);
		light_sum += u_occlusion+diffuse+specular;
	}}

	vec3 totalLight = 0.2*color_in.xyz * light_sum;
	precision light = luminocity(totalLight);
	out_color = vec4(totalLight/(1+light), color_in.w);
}
`;
}
