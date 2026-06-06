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

in vec2 relativePosition;
flat in int instanceID;

out vec4 color;

void main() {
    InstanceData instance = instances[instanceID];
    float cornerRadius = instance.cornerRadius;

    // map quad to topleft quarter
    vec2 cornerPos = relativePosition;
    if (cornerPos.x > 0.5)
        cornerPos.x = 1 - cornerPos.x;
    if (cornerPos.y > 0.5)
        cornerPos.y = 1 - cornerPos.y;
    cornerPos = cornerPos * instance.size * screenSize;

    // discard top left corner beyond cornerRadius
    if (cornerPos.x < cornerRadius && cornerPos.y < cornerRadius ) {
        vec2 cornerCenter = vec2(cornerRadius);
        if( distance(cornerPos, cornerCenter) > cornerRadius ) {
            discard;
        }
    }

    if (instance.textureHandle != 0){
        vec2 uv = vec2(relativePosition.x, relativePosition.y);
        color = texture(sampler2D(instance.textureHandle), uv);
    } else {
        color = instance.color;
    }

}
