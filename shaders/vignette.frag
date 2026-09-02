#version 330
precision highp float;

in vec2 frag_texcoord;
in vec4 frag_color;

uniform sampler2D tex;

out vec4 final_color;

void main() {
    vec4 color = texture(tex, frag_texcoord);

    float dist = length(frag_texcoord - vec2(0.5));

    float radius   = 1.16;
    float softness = 0.85;
    float vignette = smoothstep(radius, radius - softness, dist);

    final_color = vec4(color.rgb * vignette, color.a);
}
