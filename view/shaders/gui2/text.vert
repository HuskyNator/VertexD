#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require
layout(std140, row_major) uniform;
layout(std430, row_major) buffer;

struct InstanceData {
    ivec2 bottomLeft;
    uint64_t textureHandle;
    float zDepth;
};

layout(binding = 0) buffer InstanceBuffer{
    ivec2 screenSize;
    // 32 bit std430 padding?
    InstanceData instances[];
};

layout(binding = 1) buffer DebugBuffer{
    vec2 calculatedPositions[];
};

layout(location = 0) in vec2 pos;

out vec2 relativePosition;
flat out int instanceID;

void main(){
    InstanceData instance = instances[gl_InstanceID];
    if(instance.textureHandle == 0) {
        gl_Position = vec4(0, 0, 0, 0);
        return;
    }
    instanceID = gl_InstanceID;
    relativePosition = pos;

    sampler2D glyph = sampler2D(instance.textureHandle);
    ivec2 size = textureSize(glyph, 0);
    vec2 screenPos = instance.bottomLeft + pos * size;
    vec2 clipSpacePos = (2*screenPos)/screenSize - 1;
    gl_Position = vec4(clipSpacePos, instance.zDepth, 1);

    // // // relativePosition = pos;
    // if(gl_VertexID == 0 && gl_InstanceID == 0) {
    //     calculatedPositions[0] = gl_Position.xy;
    //     calculatedPositions[1] = gl_Position.zw;}
    // if(gl_VertexID == 1 && gl_InstanceID == 0) {
    //     calculatedPositions[2] = gl_Position.xy;
    //     calculatedPositions[3] = gl_Position.zw;}
    // if(gl_VertexID == 2 && gl_InstanceID == 0) {
    //     calculatedPositions[4] = gl_Position.xy;
    //     calculatedPositions[5] = gl_Position.zw;}
    //     // calculatedPositions[0] = pos;
    // //     calculatedPositions[1] = size;
    // //     calculatedPositions[2] = instance.topLeft;
    // //     calculatedPositions[3] = newPos;
    // //     calculatedPositions[4] = screenSize;
    // //     calculatedPositions[5] = clipSpacePos;
    // // }
}
