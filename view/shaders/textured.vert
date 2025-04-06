#version 460

layout(row_major)uniform;
layout(row_major)buffer;

layout(std140,binding=0)uniform Camera{
    mat4 projectionMatrix;
    mat4 cameraMatrix;
    vec3 cameraPosition;
};
layout(location=0)uniform mat4 modelMatrix;

layout(location=0)in vec3 vert_pos;
layout(location=2)in vec2 vert_uv;
out vec4 gl_Position;
out vec2 frag_uv;

void main(){
    vec4 position_world=modelMatrix*vec4(vert_pos,1);
    gl_Position=projectionMatrix*cameraMatrix*position_world;
    frag_uv=vert_uv;
}