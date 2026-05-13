// Rounded Corners Effect for Ghostty
// Soft rounded corners on the terminal

float roundedRect(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - 0.5) - (size * 0.5 - radius);
    return 1.0 - length(max(d, 0.0)) / radius;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);
    
    // Border radius
    float radius = 0.03; // 3% of screen size
    
    // Calculate distance from edge with rounded corners
    vec2 size = vec2(1.0, 1.0);
    float alpha = roundedRect(uv, size, radius);
    
    // Smooth the edge
    alpha = smoothstep(0.0, 1.0, alpha);
    
    // Apply alpha to edges (transparent outside)
    color.a *= alpha;
    
    fragColor = color;
}
