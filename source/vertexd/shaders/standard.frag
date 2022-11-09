#version 460
#extension GL_ARB_gpu_shader_int64:require
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
	vec3 emissive_factor;// + 1 float of padding (std140)
	Texture baseColor_texture;
	Texture metal_roughness_texture;
	Texture normal_texture;
	Texture occlusion_texture;
	Texture emissive_texture;
};

uniform mat4 modelMatrix;

//TODO: Remove
uniform vec4 u_color;
float u_occlusion=.1;
float u_diffuse=.7;
float u_specular=.2;
float u_specular_power=50;

uniform bool u_useNormalTexture;
uniform bool u_useColorTexture;
uniform bool u_renderNormals;
uniform bool u_absNormals;
uniform bool u_renderTangents;
uniform bool u_renderUV;

// in vec4 gl_Position;
in vec3 frag_POSITION_world;
in vec3 frag_NORMAL_world;
in vec4 frag_TANGENT_world;
in vec2 frag_TEXCOORD_0;
in vec2 frag_TEXCOORD_1;
in vec4 frag_COLOR_0;

out vec4 out_color;

float luminocity(vec3 light){
	return dot(light,vec3(.2126,.7152,.0722));
}

void main(){
	vec2 texCoords[2]=vec2[](frag_TEXCOORD_0,frag_TEXCOORD_1);
	
	// TODO: alphaMode
	vec4 color_in=vec4(1,1,1,1);
	if(baseColor_texture.sampler!=0&&u_useColorTexture)
	{color_in=texture(sampler2D(baseColor_texture.sampler),texCoords[baseColor_texture.texCoord]);}
	color_in=color_in*baseColor_factor*frag_COLOR_0;
	
	vec3 normal_world=normalize(frag_NORMAL_world);
	vec3 tangent_world=normalize(frag_TANGENT_world.xyz);
	vec3 bitangent_world=cross(normal_world,tangent_world)*frag_TANGENT_world.w;
	
	mat3 tangentToWorldMat;
	tangentToWorldMat[0]=tangent_world;
	tangentToWorldMat[1]=bitangent_world;
	tangentToWorldMat[2]=normal_world;
	// tangentToWorldMat=transpose(tangentToWorldMat);
	
	if(normal_texture.sampler!=0&&u_useNormalTexture)
	{normal_world=tangentToWorldMat*normalize((texture(sampler2D(normal_texture.sampler),texCoords[normal_texture.texCoord]).xyz*2.-1.)*vec3(normal_texture.factor,normal_texture.factor,1.));}
	
	vec3 cameraDir_world=normalize(camera_world-frag_POSITION_world);
	
	float light_sum=0;
	if(lights.length()==0){
		float diffuse=u_diffuse*clamp(dot(normal_world,cameraDir_world),0.,1.);
		light_sum+=u_occlusion+diffuse;
	}else{
		for(int i=0;i<lights.length();i++){
			Light l=lights[i];
			//TODO: Use material & light properties.
			vec3 lightDir_world=normalize(l.location-frag_POSITION_world);
			vec3 halfway_world=normalize(lightDir_world+cameraDir_world);
			float diffuse=u_diffuse*clamp(dot(normal_world,lightDir_world),0.,1.);
			float specular=u_specular*clamp(pow(dot(halfway_world,normal_world),u_specular_power),0.,1.);
			light_sum+=u_occlusion+diffuse+specular;
		}
	}
	
	vec3 light=color_in.xyz*light_sum;
	float light_lumen=luminocity(light);
	out_color=vec4(light/(1+light_lumen),color_in.w);
	// out_color=color_in;
	if(u_renderNormals){
		if(u_renderTangents)
			normal_world=tangent_world;
		if(u_absNormals)
		out_color=vec4(abs(normal_world.x),abs(normal_world.y),abs(normal_world.z),1);
		else
		out_color=vec4(normal_world,1);
	}

	if(u_renderUV){
		out_color=vec4(texCoords[0].x, texCoords[0].y, baseColor_texture.texCoord, 1);
	}
}