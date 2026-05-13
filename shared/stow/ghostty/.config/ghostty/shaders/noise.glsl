// Noise/Static Effect for Ghostty
// Subtle film grain effect

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);
    
    // Generate noise
    float noise = random(uv + iTime * 0.1);
    
    // Subtle noise (very light)
    float noiseIntensity = 0.03;
    color.rgb += (noise - 0.5) * noiseIntensity;
    
    // Slight contrast boost
    color.rgb = (color.rgb - 0.5) * 1.05 + 0.5;
    
    fragColor = color;
}
