#version 460
layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in vec3 geom_pos[3];
out vec3 frag_pos;
out vec3 frag_normal;

void main() {
	vec3 r = gl_in[1].gl_Position.xyz - gl_in[0].gl_Position.xyz;
    vec3 l = gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz;
    vec3 n = normalize(cross(r,l));

    for(int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        frag_pos = geom_pos[i];
        frag_normal = n;
        EmitVertex();
    }
    EndPrimitive();
}