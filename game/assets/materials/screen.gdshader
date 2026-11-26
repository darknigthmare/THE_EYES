shader_type canvas_item;
uniform float danger : hint_range(0.0,1.0) = 0.0;
uniform float strength : hint_range(0.0,1.0) = 0.6;
void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float vignette = smoothstep(0.25, 1.5, length(uv));
    vec3 tint = mix(vec3(0.01, 0.025, 0.032), vec3(0.22, 0.025, 0.018), danger);
    COLOR = vec4(tint, vignette * (0.38 + danger * 0.36) * strength);
}

