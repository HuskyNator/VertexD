#version 460
#extension GL_ARB_bindless_texture:require
#extension GL_ARB_gpu_shader_int64:require
layout(std140,row_major)uniform;
layout(std430,row_major)buffer;

struct InstanceData{
    vec2 bottomLeft;
    vec2 size;
    vec4 color;
    vec4 borderColor;
    float borderWidth;
    float cornerRadius;
    float zDepth;
    uint64_t textureHandle;
};

layout(binding=0)buffer InstanceBuffer{
    ivec2 screenSize;
    InstanceData instances[];
};

in vec2 relativePosition;
flat in int instanceID;

out vec4 color_out;

void main(){
    InstanceData instance=instances[instanceID];
    float cornerRadius=instance.cornerRadius;
    float borderWidth=instance.borderWidth;
    
    vec4 color=instance.color;
    if(instance.textureHandle!=0){
        vec2 uv=vec2(relativePosition.x,relativePosition.y);
        color=texture(sampler2D(instance.textureHandle),uv);
    }
    
    // map quad to topleft quarter
    vec2 cornerPos=relativePosition;
    if(cornerPos.x>.5)
    cornerPos.x=1-cornerPos.x;
    if(cornerPos.y>.5)
    cornerPos.y=1-cornerPos.y;
    cornerPos=cornerPos*instance.size*screenSize;
    
    // discard top left corner beyond cornerRadius
    if(cornerPos.x<cornerRadius&&cornerPos.y<cornerRadius){
        vec2 cornerCenter=vec2(cornerRadius);
        float cornerDistance=distance(cornerPos,cornerCenter);
        if(cornerDistance>cornerRadius){
            discard;
        }
        if(cornerRadius-borderWidth<cornerDistance){
            color=instance.borderColor;
        }
    }else if(min(cornerPos.x,cornerPos.y)<borderWidth){
        color=instance.borderColor;
    }
    
    color_out=color;
}
