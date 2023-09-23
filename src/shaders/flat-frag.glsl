#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

void main() {
    // Gradient background
    vec3 fireColors = mix(vec3(1.0, 0.5, 0.0), vec3(0.8, 0.1, 0.0), fs_Pos.y * 0.5 + 0.5);
    
    // Glow effect
    float glow = smoothstep(0.4, 0.0, length(fs_Pos.y));
    vec3 glowColor = vec3(1.0, 0.8, 0.0) * glow;

    out_Col = vec4(fireColors + glowColor, 1.0);
}
