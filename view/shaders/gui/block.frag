#version 460
layout(row_major)uniform;
layout(row_major)buffer;

layout(location=0)uniform vec2 u_anchor;
layout(location=1)uniform vec2 u_size; // [0,1]
layout(location=2)uniform float u_zDepth;
layout(location=3)uniform float u_radius;
layout(location=4)uniform vec4 u_color;
layout(location=5)uniform float u_aspectRatio;
// layout(location=7)uniform ivec2 u_resolution;

in vec2 frag_pos; // [0,1]
out vec4 color;

void main(){
    float x=(frag_pos.x>.5)?1-frag_pos.x:frag_pos.x; // [0,0.5]
    float y=(frag_pos.y>.5)?1-frag_pos.y:frag_pos.y; // [0,0.5]
    vec2 trueSize=vec2(u_size.x*u_aspectRatio,u_size.y); // [0,aspectRatio],[0,1]
    vec2 cornerPos=vec2(x,y)*trueSize; // [0,aspectRatio/2],[0,0.5]
    
    float radius=u_radius; // [0,1]
    radius=min(radius,min(trueSize.x,trueSize.y)/2); // [0,25?]
    
    if(cornerPos.x<radius&&cornerPos.y<radius){
        float dist=length(vec2(radius)-cornerPos);
        if(dist>radius)discard;
    }
    color=u_color;
}