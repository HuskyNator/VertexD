#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require
layout(std140, row_major) uniform;
layout(std430, row_major) buffer;

struct InstanceData {
    vec4 textColor;
    ivec2 topLeft;
    ivec2 maxBounds;
    uint64_t textureHandle;
    float zDepth;
};

layout(binding = 0) buffer InstanceBuffer{
    ivec2 screenSize;
    // 32 bit std430 padding?
    InstanceData instances[];
};

layout(location = 0) in vec2 pos;

out vec2 uvPosition;
out vec2 screenPos;
flat out int instanceID;

void main(){
    InstanceData instance = instances[gl_InstanceID];
    if(instance.textureHandle == 0) {
        gl_Position = vec4(0, 0, 0, 0);
        return;
    }
    instanceID = gl_InstanceID;
    vec2 vertexPos = pos;
    uvPosition = vec2(vertexPos.x, 1-vertexPos.y);

    sampler2D glyph = sampler2D(instance.textureHandle);
    ivec2 size = textureSize(glyph, 0);
    screenPos = instance.topLeft + vertexPos*size;
    vec2 clipSpacePos = (2*screenPos)/screenSize - 1;
    gl_Position = vec4(clipSpacePos, instance.zDepth, 1);
}
