#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require

layout(row_major)uniform;
layout(row_major)buffer;

layout(binding=0)uniform uint64_t colorMapHandle;

in vec2 frag_uv;
out vec4 color;

void main(){
    color=texture(sampler2D(colorMapHandle),frag_uv);
}