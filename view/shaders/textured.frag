#version 460

layout(row_major)uniform;
layout(row_major)buffer;

layout(binding=0)uniform sampler2D colorMap;

in vec2 frag_uv;
out vec4 color;

void main(){
    color=texture(colorMap,frag_uv);
}