#[compute]
#version 450
layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

struct AgentData {
    vec2  position_px;
    float angle;
    float state_mode;
    float home_node_index;
    float last_node_index;
    float was_inside_any;
    float pad_f0;
};

layout(set = 0, binding = 0, rgba32f) uniform image2D TrailIn;   // read
layout(set = 0, binding = 1, rgba32f) uniform image2D TrailOut;  // write

layout(std140, set = 0, binding = 3) uniform Params {
    float node_count;
    float time_sec;
    float grow_chance;
    float grow_angle_variance;
    float nearest_nodes_dist_px;
    float seed;
    float deltaTime;
    float pad1;
    vec2  start_pos;
    float pad2;
    float pad3;
    float decay_rate;
    float visited_decay;
    float visited_penalty;
    float min_life;
} params;

layout(set = 0, binding = 4) uniform sampler2D TitleTex;

const float PI = 3.141592653589793;

// 8-neighborhood offsets (global to avoid redefinitions)
const ivec2 OFF[8] = ivec2[](
    ivec2(1,0), ivec2(1,1), ivec2(0,1), ivec2(-1,1),
    ivec2(-1,0), ivec2(-1,-1), ivec2(0,-1), ivec2(1,-1)
);

// RNG
uint wang_hash(uint x){
    x = (x ^ 61u) ^ (x >> 16);
    x *= 9u;
    x = x ^ (x >> 4);
    x *= 0x27d4eb2du;
    x = x ^ (x >> 15);
    return x;
}
float urand01(uint x){ return float(wang_hash(x)) * (1.0 / 4294967295.0); }
float rand_at(ivec2 p, uint salt){
    uint key = uint(p.x) * 374761393u ^ (uint(p.y) * 668265263u) ^ (salt * 0x9e3779b9u);
    return urand01(key);
}

// Angle helpers kept for completeness (not central in this version)
float angle_between(vec2 from, vec2 to, vec2 dir){
    vec2 v = to - from;
    float L = length(v);
    if (L < 1e-6) return 0.0;
    v /= L;
    float d = clamp(dot(v, dir), -1.0, 1.0);
    return acos(d); // [0, PI]
}

// Sensor-based clump sampler
int count_blue_disk(ivec2 c, int r){
    ivec2 sz = imageSize(TrailIn);
    int cnt = 0;
    for (int y=-r; y<=r; ++y)
    for (int x=-r; x<=r; ++x){
        if (x*x + y*y > r*r) continue;
        ivec2 q = c + ivec2(x,y);
        if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
        if (imageLoad(TrailIn, q).b > 0.6) cnt++;
    }
    return cnt;
}

void best_sensor_dir(ivec2 p, float offset_px, int sensor_radius, int sensors,
                     out int best_cnt, out vec2 best_dir){
    best_cnt = 0; best_dir = vec2(0.0);
    vec2 P = vec2(p) + vec2(0.5);
    for (int s=0; s<sensors; ++s){
        float a   = (2.0*PI) * (float(s)/float(sensors));
        vec2  dir = vec2(cos(a), sin(a));
        ivec2 sc  = ivec2(floor(P + dir * offset_px));
        int cnt   = count_blue_disk(sc, sensor_radius);
        if (cnt > best_cnt){ best_cnt = cnt; best_dir = dir; }
    }
}

// Dot/cos alignment test (unsigned angle)
bool aligned_dir(vec2 v_from, vec2 v_to, float max_angle){
    float lv = length(v_from), lw = length(v_to);
    if (lv < 1e-6 || lw < 1e-6) return false;
    float c = dot(v_from / lv, v_to / lw);
    return c >= cos(max_angle);
}

bool is_seed_cell(ivec2 q, ivec2 seed_px){
    return  q == seed_px ||
            q == seed_px + ivec2(1,0) || q == seed_px + ivec2(0,1) ||
            q == seed_px + ivec2(1,1) || q == seed_px + ivec2(-1,0) ||
            q == seed_px + ivec2(0,-1) || q == seed_px + ivec2(-1,-1) ||
            q == seed_px + ivec2(1,-1) || q == seed_px + ivec2(-1,1);
}

// void main() {
//     ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
//     ivec2 sz = imageSize(TrailIn);
//     if (p.x >= sz.x || p.y >= sz.y) return;

//     vec4 cur  = imageLoad(TrailIn, p);
//     vec4 outc = cur;

//     // ---- one-time clear: invisible everywhere, seed is "alive" only in R ----
//     bool do_clear = (params.time_sec < 0.0001);
//     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
//     bool is_seed =
//         (p == seed_px) || (p == seed_px + ivec2(1,0)) || (p == seed_px + ivec2(0,1)) ||
//         (p == seed_px + ivec2(1,1)) || (p == seed_px + ivec2(-1,0)) || (p == seed_px + ivec2(0,-1)) ||
//         (p == seed_px + ivec2(-1,-1)) || (p == seed_px + ivec2(1,-1)) || (p == seed_px + ivec2(-1,1));

//     if (do_clear) {
//         vec4 init = vec4(0.0, 0.0, 0.0, 1.0);        // RGB=0, A=0
//         if (is_seed) init.r = 1.0;    // seed active; still invisible
//         imageStore(TrailOut, p, init);
//         return;
//     }

//     // ---- simple neighbor count for spread on the red channel ----
//     int active_n = 0;
//     for (int oy=-1; oy<=1; ++oy)
//     for (int ox=-1; ox<=1; ++ox) {
//         if (ox==0 && oy==0) continue;
//         ivec2 q = p + ivec2(ox,oy);
//         if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
//         if (imageLoad(TrailIn, q).r > 0.5) active_n++;
//     }

//     // random activation/decay for the red state only
//     float r_state = cur.r;
//     if (is_seed) r_state = 1.0;                            // keep seed on
//     float decay = max(0.0, params.decay_rate);
//     if (r_state > 0.0) r_state = max(r_state - decay, 0.0);

//     float p_single = clamp(params.grow_chance, 0.0, 1.0);
//     float p_total  = 1.0 - pow(1.0 - p_single, float(active_n));
//     float toss     = rand_at(p, uint(params.seed) + uint(p.x)*9176u + uint(p.y)*6113u);
//     if (r_state == 0.0 && active_n > 0 && toss < p_total) r_state = 1.0;

//     // write back SIMULATION STATE ONLY (kept in RGB; here we use R only)
//     outc.r = r_state;
//     outc.g = 0.0;
//     outc.b = 0.0;

//     // ---- reveal logic: TitleTex gating + sticky alpha ----
//     vec2 uv = (vec2(p) + vec2(0.5)) / vec2(sz);
//     vec4 title = texture(TitleTex, uv);

//     // treat bright title pixels as "ink"; tweak threshold for the art
//     float title_luma = max(title.r, max(title.g, title.b)); // fast max; use dot for true luma if needed
//     bool  hit_title  = (title_luma > 0.02);                  // ignore background grain/noise

//     // only consider reveal if the simulation is active here
//     float reveal_threshold = clamp(params.visited_penalty, 0.0, 1.0); // raise if R is noisy
//     float reveal_softness  = max(params.visited_decay, 0.0001);
//     float stickiness       = clamp(params.min_life, 0.0, 1.0);

//     float a_prev = cur.a;
//     float a_new  = (r_state > 0.0 && hit_title)
//                  ? smoothstep(reveal_threshold, reveal_threshold + reveal_softness, r_state)
//                  : 0.0;

//     float a_out  = mix(a_new, max(a_prev, a_new), stickiness);

//     // compose: RGB from title only if revealing; otherwise keep previous RGB (or keep black)
//     // To keep the screen black until reveal, write title.rgb only when a_out increased.
//     vec3 rgb_prev = cur.rgb; // was just simulation last frame; safe to ignore if using black
//     vec3 rgb_out  = (a_out > a_prev && hit_title) ? title.rgb : rgb_prev * 0.0;

//     // outc.rgb = rgb_out;
//     // outc.a   = a_out;

//     imageStore(TrailOut, p, outc);
// }
void main(){
    ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
    ivec2 sz = imageSize(TrailIn);
    if (p.x >= sz.x || p.y >= sz.y) return;

    vec4 cur  = imageLoad(TrailIn, p);
    vec4 outc = cur;

    // One-time clear (frame 0) so TrailIn is known-zero except seed
    bool do_clear = (params.time_sec < 0.0001); // or pass an explicit reset flag
    ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
    bool is_seed = (p == seed_px || p == seed_px + ivec2(1,0) || p == seed_px + ivec2(0,1) ||
                    p == seed_px + ivec2(1,1) || p == seed_px + ivec2(-1,0) || p == seed_px + ivec2(0,-1) ||
                    p == seed_px + ivec2(-1,-1) || p == seed_px + ivec2(1,-1) || p == seed_px + ivec2(-1,1));
    if (do_clear) {
        vec4 init = vec4(0.0);          // R,G,B,A = 0  (invisible)
        if (is_seed) init.r = 1.0;       // seed “active” in the red channel
        imageStore(TrailOut, p, init);
        return;
    }


    // Neighbor tallies
    int active_n = 0;
    float decay = max(0.0, params.decay_rate);
    for (int oy=-1; oy<=1; ++oy){
        for (int ox=-1; ox<=1; ++ox){
            if (ox==0 && oy==0) continue;
            ivec2 s = p + ivec2(ox,oy);
            if (s.x<0 || s.y<0 || s.x>=sz.x || s.y>=sz.y) continue;
            vec4 src = imageLoad(TrailIn, s);
            if (src.r > 0.0 || is_seed_cell(s, seed_px)) active_n++;
        }
    }
    vec2 uv = (vec2(p) + vec2(0.5)) / vec2(sz);
    vec4 title = texture(TitleTex, uv);

    float dist_px = length(p - seed_px); 
    float speed = 45.0 * params.time_sec; // pixels per second
    float R = speed * params.time_sec;
    if (dist_px < R) {
        outc = title;
        imageStore(TrailOut, p, outc);
        return;
    } 
    // INACTIVE pixel branch
    if (active_n == 0){
        // Preserve B/G so stabilized paths aren’t erased
        // outc.b = time_sec / 1000.0;
        imageStore(TrailOut, p, outc);
        return;
    }

    // Random growth to keep slime moving (do not clear B/G)
    uint  salt = uint(params.seed) + uint(p.x)*9176u + uint(p.y)*6113u;
    float rr   = rand_at(p, salt);
    // if (best_angle <= PI * 0.05 && rr < 0.3 && cur.b == 0.0){
    //     outc.b = 1.0; // optional spark
    // }
    float p_single = max(0.05, clamp(params.grow_chance, 0.0, 1.0));
    float p_total  = 1.0 - pow(1.0 - p_single, float(active_n));
    float r        = rand_at(p, salt);
    if (r < p_total && title.a > 0){
        outc = title;
    } else {
        outc = vec4(0.0);           // remain inactive; DO NOT zero G/B
    }
    float rgb_max = max(outc.r, max(outc.g, outc.b));

    imageStore(TrailOut, p, outc);
}
