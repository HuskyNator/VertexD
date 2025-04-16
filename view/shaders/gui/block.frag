#version 460
layout(row_major)uniform;
layout(row_major)buffer;

layout(location=0)uniform vec2 u_anchor;
layout(location=1)uniform vec2 u_size;// [0,1]
layout(location=2)uniform float u_zDepth;
layout(location=3)uniform float u_radius;
layout(location=4)uniform vec4 u_color;
layout(location=5)uniform float u_aspectRatio;
// layout(location=7)uniform ivec2 u_resolution;

layout(binding=0)uniform sampler2D background;

in vec2 frag_pos;// [0,1]
out vec4 color;

void main(){
    // Corner rounding
    float x=(frag_pos.x>.5)?1-frag_pos.x:frag_pos.x;// [0,0.5]
    float y=(frag_pos.y>.5)?1-frag_pos.y:frag_pos.y;// [0,0.5]
    vec2 trueSize=vec2(u_size.x*u_aspectRatio,u_size.y);// [0,aspectRatio],[0,1]
    vec2 cornerPos=vec2(x,y)*trueSize;// [0,aspectRatio/2],[0,0.5]
    
    float radius=u_radius;// [0,1]
    radius=min(radius,min(trueSize.x,trueSize.y)/2);// [0,25?]
    
    if(cornerPos.x<radius&&cornerPos.y<radius){
        float dist=length(vec2(radius)-cornerPos);
        if(dist>radius)discard;
    }
    
    // Color
    // Combine texture & background color such that:
    // UI.Color * UI.Alpha + Buffer.Color * (1-UI.Alpha)
    // = t.rgb*t.a + ( b.rgb*b.a + B*(1-b.a) ) * (1-t.a)
    // Is correct such that the texture is blended over the ui background color
    // TLDR: manual blending
    vec4 texColor=texture(background,frag_pos);
    float alpha=u_color.a+texColor.a-u_color.a*texColor.a;
    if(alpha==0)discard;
    vec3 uiColorPreMultiplied=texColor.rgb*texColor.a+u_color.rgb*u_color.a*(1-texColor.a);
    color=vec4(uiColorPreMultiplied/alpha,alpha);
}