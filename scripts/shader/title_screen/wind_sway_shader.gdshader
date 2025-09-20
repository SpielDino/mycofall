shader_type canvas_item;

/* Screen‑like wind sweep (displacement only)
   - Bands move right → left
   - No overlay lines; only UV distortion
   - Masked to a configurable region
*/

// Motion shape
uniform float band_density = 16.0;   // number of wind bands across width
uniform float band_width   = 0.08;   // band half-width in UV units
uniform float band_soft    = 0.05;   // feathering for soft edges
uniform float band_speed   = 0.35;   // positive = right→left travel
uniform float curve_amp    = 0.10;   // bend bands along Y (UV)
uniform float curve_freq_y = 5.0;    // how wavy each band is vertically
uniform float undulate_amp_px = 6.0; // pixel displacement amplitude
uniform float undulate_speed  = 0.9; // temporal undulation for liveliness
uniform float undulate_freq_y = 3.5; // vertical variation of push

// Local mask (ellipse in UV space) + optional texture mask
uniform vec2  mask_center_uv = vec2(0.6, 0.55);
uniform vec2  mask_radii_uv  = vec2(0.38, 0.30);
uniform float mask_soft      = 0.25;

uniform sampler2D mask_tex;
uniform bool  use_mask_tex  = false;
uniform float mask_tex_mix  = 1.0;   // 1 = only texture, 0 = only ellipse

uniform float sweep_speed = 0.35; // R→L speed (set > 0)
uniform float front_width = 0.35;  // width of the sweeping front (UV units)
uniform float front_soft  = 0.18;  // edge softness of the front
// Instance offset so many sprites don’t sync perfectly
uniform float seed = 0.0;

float ellipse_mask(vec2 uv) {
    vec2 d = (uv - mask_center_uv) / max(mask_radii_uv, vec2(0.0001));
    float r = length(d);
    // 1 inside center → 0 outside, with soft falloff
    return smoothstep(1.0, 1.0 - max(mask_soft, 0.0001), 1.0 - r);
}

float final_mask(vec2 uv) {
    float m = ellipse_mask(uv);
    if (use_mask_tex && textureSize(mask_tex, 0).x > 0) {
        float t = texture(mask_tex, uv).r;
        m = mix(m, t, clamp(mask_tex_mix, 0.0, 1.0));
    }
    return clamp(m, 0.0, 1.0);
}

// Helper: periodic wrapped distance in [-0.5, 0.5]
float wrap_dist(float x, float center) {
    float d = x - center;
    // Wrap using round() so distance is continuous across 0..1
    d -= round(d); // requires shader_functions: round/fract behavior
    return d;
}

float sweep_gate(float x, float center) {
    float d = wrap_dist(x, center);
    // Soft bell-shaped gate around the front
    return smoothstep(-front_width, -front_soft, d)
         * (1.0 - smoothstep(front_soft, front_width, d));
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);

    // Two fronts, 180° out of phase, cross-faded to avoid wrap pop
    float phase = fract(TIME * sweep_speed);
    float f1 = 1.0 - phase;                       // moving R->L
    float f2 = fract(f1 - 0.5);                   // second front, half-cycle behind

    float g1 = sweep_gate(UV.x, f1);
    float g2 = sweep_gate(UV.x, f2);
    float gate = clamp(g1 + g2, 0.0, 1.0);        // continuous total influence

    // Curved bands and undulation for “air” feel
    float curve = sin(UV.y * curve_freq_y + TIME * 0.3) * curve_amp;
    float x = (UV.x + curve) * band_density;
    float cell = abs(fract(x) - 0.5);
    float band = 1.0 - smoothstep(band_width, band_width + band_soft, cell);

    float undulate = sin(UV.y * undulate_freq_y + TIME * undulate_speed + seed);
    float disp_px  = undulate_amp_px * undulate * band * gate * final_mask(UV);

    vec2 uv_off = vec2(disp_px * TEXTURE_PIXEL_SIZE.x, 0.0);
    COLOR = texture(TEXTURE, UV + uv_off);
}