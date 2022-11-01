#version 460
#extension GL_NV_gpu_shader5:require
#extension GL_ARB_bindless_texture:require

struct Texture{
	uint64_t sampler;
	int texCoord;
	float factor;
};

struct Light{
	uint type;// 0-4
	float strength;// 4-8
	float range;// 8-16
	float innerAngle;// 16-20
	float outerAngle;// 20-24
	// pading (24-32)
	vec3 color;// 32-44 padding (44-48)
	vec3 location;// 48-60 padding (60-64)
	vec3 direction;// 64-76 padding (76-80)
};

layout(row_major,std140,binding=0)uniform Camera{
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 camera_world;
};

layout(row_major,std140,binding=1)readonly buffer Lights{
	Light lights[];
};

layout(row_major,std140,binding=2)uniform Material{
	vec4 baseColor_factor;
	float metal_factor;
	float roughness_factor;
	vec3 emissive_factor;
	Texture baseColor_texture;
	Texture metal_roughness_texture;
	Texture normal_texture;
	Texture occlusion_texture;
	Texture emissive_texture;
};

uniform mat4 modelMatrix;

layout(location = 0) in vec3 vert_POSITION_model;
layout(location = 1) in vec3 vert_NORMAL_model;
layout(location = 2) in vec4 vert_TANGENT_model;
layout(location = 3) in vec2 vert_TEXCOORD_0;
layout(location = 4) in vec2 vert_TEXCOORD_1;
layout(location = 5) in vec4 vert_COLOR_0;

out vec4 gl_Position;
out vec3 frag_POSITION_world;
out vec3 frag_NORMAL_world;
out vec4 frag_TANGENT_world;
out vec2 frag_TEXCOORD_0;
out vec2 frag_TEXCOORD_1;
out vec4 frag_COLOR_0;

void main(){
	mat4 camModelMatrix=cameraMatrix*modelMatrix;
	
	vec4 pos_world=modelMatrix*vec4(vert_POSITION_model,1.);
	gl_Position=projectionMatrix*cameraMatrix*pos_world;
	
	vec4 temp;
	frag_POSITION_world=pos_world.xyz/pos_world.w;
	temp=modelMatrix*vec4(vert_NORMAL_model,0);
	frag_NORMAL_world=normalize(temp.xyz);
	temp=modelMatrix*vec4(vert_TANGENT_model.xyz,0);
	frag_TANGENT_world=vec4(normalize(temp.xyz),vert_TANGENT_model.w);
	frag_TEXCOORD_0 = vert_TEXCOORD_0;
	frag_TEXCOORD_1 = vert_TEXCOORD_1;
	frag_COLOR_0=vert_COLOR_0;
}