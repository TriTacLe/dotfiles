// Bloom/Glow Effect for Ghostty
// Adds a soft glow to bright text

vec4 blur(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
    vec4 color = vec4(0.0);
    vec2 off1 = vec2(1.3846153846) * direction;
    vec2 off2 = vec2(3.2307692308) * direction;
    
    color += texture(image, uv) * 0.2270270270;
    color += texture(image, uv + (off1 / resolution)) * 0.3162162162;
    color += texture(image, uv - (off1 / resolution)) * 0.3162162162;
    color += texture(image, uv + (off2 / resolution)) * 0.0702702703;
    color += texture(image, uv - (off2 / resolution)) * 0.0702702703;
    
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 original = texture(iChannel0, uv);
    
    // Horizontal blur
    vec4 bloom = blur(iChannel0, uv, iResolution.xy, vec2(1.5, 0.0));
    // Vertical blur
    bloom += blur(iChannel0, uv, iResolution.xy, vec2(0.0, 1.5));
    bloom /= 2.0;
    
    // Extract bright areas
    float brightness = dot(bloom.rgb, vec3(0.299, 0.587, 0.114));
    bloom.rgb *= smoothstep(0.3, 0.8, brightness);
    
    // Combine with original
    vec3 final = original.rgb + bloom.rgb * 0.5;
    
    fragColor = vec4(final, original.a);
}
