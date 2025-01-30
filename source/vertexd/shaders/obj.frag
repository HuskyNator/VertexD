#version 460

layout(row_major)uniform;
layout(row_major)buffer;

layout(std140,binding=0)uniform Camera{
	mat4 projectionMatrix;
	mat4 cameraMatrix;
	vec3 cameraPosition;
};

layout(std140,binding=1)uniform Material{
	vec3 ka;
	vec3 kd;
	vec3 ks;
	float ns;
	uint illum;
};

layout(location=0)uniform mat4 modelMatrix;

uniform float ambientLight;

in vec3 frag_pos;
in vec2 frag_uv;
in vec3 frag_normal;
out vec4 out_color;

void main(){
	if(illum==0){
		out_color=vec4(kd,1);
		return;
	}
	
	vec3 normal=normalize(frag_normal);
	vec3 lightPos=vec3(1,10,-10);
	vec3 lightDir=normalize(lightPos-frag_pos);
	float diffuse=max(dot(normal,lightDir),0);
	if(illum==1){
		out_color=vec4(ka*ambientLight+kd*diffuse,1);
		return;
	}
	
	vec3 camDir=normalize(cameraPosition-frag_pos);
	vec3 halfDir=normalize(lightDir+camDir);
	float specular=pow(max(dot(halfDir,normal),0),ns);
	if(illum==2){
		out_color=vec4(ka*ambientLight+kd*diffuse+ks*specular,1);
		return;
	}
	
	out_color=vec4(1,0,1,1);
	return;// Not implemented
}