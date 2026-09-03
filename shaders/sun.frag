#version 300 es
precision highp float;

in vec2 frag_texcoord;
in vec4 frag_color;

uniform sampler2D tex;

uniform vec2  sun_pos;
uniform float strength;
uniform float time;

out vec4 final_color;

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// Smooth random value that changes over time
float smooth_random(float time, float period) {
    float t = time / period;
    float i = floor(t);
    float f = fract(t);

    float a = hash11(i);
    float b = hash11(i + 1.0);

    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);

    return mix(a, b, f);
}

void main() {
    vec4 color = texture(tex, frag_texcoord);

    // Distance from the sun
    float dist = distance(frag_texcoord, sun_pos) / 1.64;

    // Broad soft falloff
    float light = 1.0 - smoothstep(0.0, 1.0, dist);

    // Slowly varying sunlight intensity
    float variation = smooth_random(time, 10.0);

    // Keep the variation subtle
    float intensity = mix(0.5, 1.0, variation);

    light *= intensity;

    // Warm sunlight
    vec3 sun_color = vec3(1.0, 0.72, 0.45);

    // Add warm light
    color.rgb += sun_color * light * strength;

    final_color = color * frag_color;
}
