// Glitch Effect for Ghostty
// Subtle digital glitch artifacts

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    
    // Subtle random offset
    float glitch = random(vec2(iTime * 0.1, uv.y * 10.0));
    float glitchIntensity = 0.002;
    
    vec2 offset = vec2(
        (random(vec2(iTime, uv.y)) - 0.5) * glitchIntensity,
        0.0
    );
    
    // RGB split on glitch
    float r = texture(iChannel0, uv + offset).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - offset).b;
    
    vec4 color = vec4(r, g, b, 1.0);
    
    // Scanlines
    float scanline = sin(uv.y * 800.0 + iTime) * 0.02;
    color.rgb += scanline;
    
    fragColor = color;
}
