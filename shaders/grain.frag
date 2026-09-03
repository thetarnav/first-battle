#version 300 es
precision highp float;

in vec2 frag_texcoord;
in vec4 frag_color;

uniform sampler2D tex;

uniform vec2  size;
uniform float pixel_scale;
uniform float strength;
uniform float time;

out vec4 final_color;

float hash21(vec2 p, float time) {
    p = fract(p * vec2(123.34, 456.21));
    float t = fract(time / 1000.0);
    p += dot(p, p + 40.0 + t);
    return fract(p.x * p.y);
}

void main() {
    vec4 color = texture(tex, frag_texcoord);

    // One noise value per source pixel
    vec2 pixel = floor(frag_texcoord * size / pixel_scale);

    float noise = hash21(pixel, time);

    // Remap [0, 1] -> [-1, 1]
    noise = noise * 2.0 - 1.0; 

    // Multiplicative grain
    color.rgb *= 1.0 + noise * strength;

    final_color = color * frag_color;
}
