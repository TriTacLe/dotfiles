// CRT Scanline Effect for Ghostty
// Retro CRT monitor look with scanlines and curvature

float scanline(vec2 uv, float intensity) {
    float scanline = sin(uv.y * 800.0) * intensity;
    return 1.0 - scanline;
}

float vignette(vec2 uv, float intensity) {
    vec2 dist = (uv - 0.5) * 1.2;
    return 1.0 - dot(dist, dist) * intensity;
}

vec2 curve(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv *= 1.1;
    uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
    uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
    uv = (uv / 2.0) + 0.5;
    return uv;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    
    // Apply curvature
    vec2 curvedUV = curve(uv);
    
    // Sample the terminal
    vec4 color = texture(iChannel0, curvedUV);
    
    // Scanlines
    float scan = scanline(curvedUV, 0.15);
    color.rgb *= scan;
    
    // Vignette
    float vig = vignette(curvedUV, 0.4);
    color.rgb *= vig;
    
    // Chromatic aberration (slight color shift)
    float aberration = 0.002;
    color.r = texture(iChannel0, curvedUV + vec2(aberration, 0.0)).r;
    color.b = texture(iChannel0, curvedUV - vec2(aberration, 0.0)).b;
    
    // Slight green tint (phosphor look)
    color.g *= 1.05;
    
    fragColor = color;
}
