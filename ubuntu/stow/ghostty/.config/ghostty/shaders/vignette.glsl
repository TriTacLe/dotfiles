// Vignette Effect for Ghostty
// Darkens the edges of the screen for focus

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);
    
    // Calculate distance from center
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Vignette intensity
    float intensity = 0.6;
    float smoothness = 0.4;
    
    // Create vignette
    float vignette = 1.0 - smoothness;
    vignette = smoothstep(vignette, vignette + smoothness, 1.0 - dist * intensity);
    
    // Apply vignette (darken edges)
    color.rgb *= vignette * 0.7 + 0.3;
    
    fragColor = color;
}
