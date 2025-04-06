#version 460
layout(std140,row_major)uniform;
layout(std140,row_major)buffer;

layout(location=0)uniform vec2 u_anchor;
layout(location=1)uniform vec2 u_size;
layout(location=2)uniform float u_zDepth;
layout(location=3)uniform float u_radius;
layout(location=4)uniform vec4 u_color;
layout(location=5)uniform float u_aspectRatio;
// layout(location=7)uniform ivec2 u_resolution;

layout(location=0)in vec3 position;
out vec2 frag_pos;
out vec4 gl_Position;

void main(){
    vec2 uiPos=u_anchor+position.xy*u_size;
    vec2 clipPos=uiPos*2-1;
    vec2 clipPosUpright=vec2(clipPos.x,-clipPos.y);
    gl_Position=vec4(clipPosUpright,u_zDepth,1);

    // get clipped position of shape
    frag_pos=position.xy;
}