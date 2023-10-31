#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require

layout(row_major,std140,binding=0)uniform Camera{
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 camera_world;
};

layout(location=0)uniform mat4 modelMatrix;
layout(row_major,std140,binding=1)uniform Texture{
	uint64_t bindlessTexture;
};

// in vec4 gl_Position;
in vec2 frag_TEXCOORD0;

out vec4 out_color;

void main(){
	if(bindlessTexture==0){
		out_color=vec4(0,1,0,1);}
	else{
		out_color = texture(sampler2D(bindlessTexture), frag_TEXCOORD0);}
}