shader_type canvas_item;

/* --------------------------------------------------------------------
   Advanced 2D Wind (Godot 4.4)
   - Layered sway + gust pulses
   - Optional grayscale stiffness mask (mask_tex)
   - High‑frequency leaf flutter (noise_tex)
   - Per‑instance variation via seed
   - Bottom‑anchored bend using UV.y and pivot_uv
   -------------------------------------------------------------------- */

uniform vec2 wind_dir = vec2(1.0, 0.0);   // Direction the wind pushes (will be normalized)
uniform float sway_amp_px = 5.0;         // Max bend in pixels at the very top (base sway)
uniform float sway_speed = 0.8;           // Base sway speed (Hz-like)
uniform float gust_amp = 0.6;             // Extra multiplier during gusts
uniform float gust_speed = 0.18;          // How often gusts happen
uniform float stiffness_pow = 1.6;        // Falloff exponent; higher = stiffer base
uniform float vertical_lift = 0.12;       // Small upward pull proportional to bend

// Leaf flutter (small, fast jitter)
uniform float flutter_amp_px = 2.2;       // Pixel amplitude for micro flutter
uniform float flutter_speed = 5.0;        // Speed of micro flutter

// Optional masks/textures
uniform sampler2D noise_tex : source_color; // 0..1 noise; set a NoiseTexture2D or similar
uniform vec2 noise_tiling = vec2(1.5, 2.0);
uniform vec2 noise_scroll = vec2(0.06, 0.0);

uniform sampler2D mask_tex;   // Optional grayscale mask; white = flexible
uniform bool use_mask_tex = false;          // If false, use height (1 - UV.y)
uniform float mask_mix = 1.0;               // 1=only mask, 0=only height

// Per-instance offset so multiple trees don’t sync
uniform float seed = 0.0;                   // Give different values per instance

// Bend pivot (UV space). Bottom center of sprite by default.
uniform vec2 pivot_uv = vec2(0.5, 1.0);

// Utility: sample noise in [-1, 1]
float n01(vec2 p) {
    // If noise_tex isn’t set, fall back to a cheap trig noise
    // (keeps shader functional without a texture)
    if (textureSize(noise_tex, 0).x == 0) {
        return sin(p.x) * cos(p.y);
    }
    return texture(noise_tex, p).r * 2.0 - 1.0;
}

void vertex() {
    // Normalize direction and compute per‑vertex “height” mask
    vec2 dir = normalize(wind_dir);
    float height_mask = clamp(1.0 - UV.y, 0.0, 1.0); // top moves, base stiff
    if (use_mask_tex) {
        float m = texture(mask_tex, UV).r;
        height_mask = mix(height_mask, m, clamp(mask_mix, 0.0, 1.0));
    }
    height_mask = pow(height_mask, max(0.001, stiffness_pow));

    // Time domains
    float t = TIME + seed; // per‑instance desync
    float base_phase = (t * sway_speed) + UV.y * 1.57; // slight vertical phase offset

    // Base sine sway
    float base_sway = sin(base_phase) * sway_amp_px;

    // Gust envelope: slow, smooth pulses in [0, 1]
    float g = n01(vec2(t * gust_speed, 0.37));
    float gust = smoothstep(0.15, 0.85, g);

    // Micro flutter from scrolling noise
    vec2 tex_px = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 uv_flow = UV * noise_tiling + t * noise_scroll;
    float flutter = n01(uv_flow * 2.3) * flutter_amp_px;

    // Combine
    float bend_px = (base_sway + flutter) * mix(1.0, 1.0 + gust_amp, gust);

    // Scale by height mask (stronger at top), add a little extra near the tip
    float tip_boost = mix(0.6, 1.0, height_mask);
    bend_px *= height_mask * tip_boost;

    // Apply displacement relative to a pivot so the base stays anchored
    vec2 sprite_size = tex_px; // in pixels
    vec2 from_pivot_px = (UV - pivot_uv) * sprite_size;

    // Horizontal bend along wind_dir and slight vertical lift
    vec2 bend_vec = dir * bend_px;
    float lift = abs(bend_px) * vertical_lift * height_mask;

    // Curvature: amplify toward the tip to arc the shape
    float curve = height_mask * height_mask;
    vec2 curved = bend_vec * curve;

    // Write back
    VERTEX += curved + vec2(0.0, -lift);

    // Optional tiny rotation flutter around pivot (cheap approximation)
    float rot = n01(uv_flow * 3.7 + 11.0) * radians(1.6) * height_mask;
    float s = sin(rot), c = cos(rot);
    vec2 p = from_pivot_px;
    vec2 rp = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
    VERTEX += (rp - p);
}