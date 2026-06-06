#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require
layout(std140, row_major) uniform;
layout(std430, row_major) buffer;

struct InstanceData {
    vec2 topLeft;
    vec2 size;
    vec4 color;
    float cornerRadius;
    float zDepth;
    uint64_t textureHandle;
};

layout(binding = 0) buffer InstanceBuffer{
    ivec2 screenSize;
    InstanceData instances[];
};

layout(location = 0) in vec2 pos;

out vec2 relativePosition;
flat out int instanceID;

void main(){
    InstanceData instance = instances[gl_InstanceID];
    gl_Position = 2 * vec4(instance.topLeft + pos.xy * instance.size, instance.zDepth, 1) - 1;
    relativePosition = pos.xy;
    instanceID = gl_InstanceID;
}
