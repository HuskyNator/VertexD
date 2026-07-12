#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require
layout(std140, row_major) uniform;
layout(std430, row_major) buffer;

struct InstanceData {
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

in vec2 uvPosition;
in vec2 screenPos;
flat in int instanceID;

out vec4 color;

void main() {
    InstanceData instance = instances[instanceID];
    if(floor(screenPos.x) >= instance.maxBounds.x || floor(screenPos.y) <= instance.maxBounds.y) discard;

    if(instance.textureHandle == 0)
        discard;

    sampler2D glyph = sampler2D(instance.textureHandle);
    float pixelColor = texture(glyph, vec2(uvPosition.x, 1-uvPosition.y)).x;
    if(pixelColor == 0)
        discard;
    color = vec4(vec3(pixelColor), 1);
}
