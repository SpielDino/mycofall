#[compute]

// #version 450
// layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// struct AgentData {
//     vec2  position_px;
//     float angle;
//     float state_mode;          // 0=EXPLORE, 1=RETURN

//     float home_node_index;     // persistent "base" unless policy changes
//     float last_node_index;     // -1 if none
//     float was_inside_any;      // 0/1
//     float pad_f0;

// };

// layout(set = 0, binding = 0, rgba32f) uniform image2D TrailIn;   // read
// layout(set = 0, binding = 1, rgba32f) uniform image2D TrailOut;  // write
// layout(set = 0, binding = 2, std430) buffer NodeBuffer { vec2 nodes[]; };
// // layout(set = 0, binding = 3, std430) buffer AgentBuffer      { AgentData agents[]; };

// // std140 layout to match UBO packing on CPU (16 floats = 64 bytes)
// layout(std140, set = 0, binding = 3) uniform Params {
//     float node_count;              // 0
//     float time_sec;                // 4
//     float grow_chance;             // 8   (suggest 0.25..0.45)
//     float grow_angle_variance;     // 12  (suggest 0.2..0.5)
//     float nearest_nodes_dist_px;   // 16  (unused)
//     float seed;                    // 20
//     float deltaTime;                    // 24
//     float pad1;                    // 28
//     vec2  start_pos;               // 32..39
//     float pad2;                    // 40
//     float pad3;                    // 44
//     float decay_rate;              // 48  (unused here)
//     float visited_decay;           // 52  (unused)
//     float visited_penalty;         // 56  (unused)
//     float min_life;                // 60  (unused)
// } params;

// const float PI = 3.141592653589793;

// // ---------------- RNG: uint hash -> [0,1) ----------------
// uint wang_hash(uint x) {
//     x = (x ^ 61u) ^ (x >> 16);
//     x *= 9u;
//     x = x ^ (x >> 4);
//     x *= 0x27d4eb2du;
//     x = x ^ (x >> 15);
//     return x;
// }
// float urand01(uint x) { return float(wang_hash(x)) * (1.0 / 4294967295.0); }
// float rand_at(ivec2 p, uint salt) {
//     uint key = uint(p.x) * 374761393u ^ (uint(p.y) * 668265263u) ^ (salt * 0x9e3779b9u);
//     return urand01(key);
// }

// // float sample_trails_RB(vec2 position_px, float heading_rad, float angle_offset_rad){
// //     float a  = heading_rad + angle_offset_rad;
// //     vec2  d  = vec2(cos(a), sin(a));
// //     ivec2 c  = ivec2(position_px + d * u_params.sensor_offset_px);

// //     float sumB = 0.0;

// //     int r = int(u_params.sensor_size_px + 0.5);
// //     for (int dy=-r; dy<=r; ++dy){
// //         for (int dx=-r; dx<=r; ++dx){
// //             ivec2 p = c + ivec2(dx,dy);
// //             if (p.x>=0 && p.x<int(u_params.surface_width_f) &&
// //                 p.y>=0 && p.y<int(u_params.surface_height_f)){
// //                 vec4 t = imageLoad(TrailMap, p);
// //                 sumB += t.b;   // explore
// //             }
// //         }
// //     }
// //     return sumB;
// // }

// // -------------- calculate angle between node and pixel ----------------
// float angle_between(vec2 from, vec2 to, vec2 dir) {
//     vec2 v = to - from;
//     float length = length(v);
//     if (length < 1e-6) return 0.0;
//     v /= length;
//     float d = clamp(dot(v, dir), -1.0, 1.0);
//     return acos(d); // [0,PI]
// }

// bool in_jitter_corridor(vec2 P, out float best_perp) {
//     vec2 C = params.start_pos;
//     uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
//     best_perp = 1e30;
//     if (N == 0u) return false;

//     // pixel vector from center
//     vec2 w = P - C;
//     float wlen = length(w);
//     if (wlen < 1e-6) return true;

//     bool inside = false;
//     for (uint i = 0u; i < N; ++i) {
//         vec2 u = nodes[i] - C;
//         float ulen = length(u);
//         if (ulen < 1e-6) continue;
//         u /= ulen; // unit ray toward node

//         float along = dot(w, u);           // signed projection length on the ray [px]
//         if (along <= 0.0) continue;        // behind center → ignore
//         // 2D perp distance = |cross(u,w)| where cross(u,w)=u.x*w.y - u.y*w.x
//         float perp = abs(u.x * w.y - u.y * w.x);

//         // wedge radius grows with along distance; add jitter
//         float base_r   = max(0.0, params.nearest_nodes_dist_px);
//         float slope_r  = max(0.0, params.grow_angle_variance);
//         float radius   = base_r + slope_r * along;
//         float jitter   = (rand_at(ivec2(P), uint(params.seed)) - 0.5) * 2.0; // [-1,1]
//         float jittered = radius * (1.0 + 0.25 * jitter); // 25% wobble

//         if (perp <= jittered) {
//             inside = true;
//             best_perp = min(best_perp, perp);
//         }
//     }
//     return inside;
// }

// int count_blue_disk(ivec2 c, int r){
//     ivec2 sz = imageSize(TrailIn);
//     int cnt = 0;
//     for (int y=-r; y<=r; ++y)
//     for (int x=-r; x<=r; ++x){
//         if (x*x + y*y > r*r) continue;
//         ivec2 q = c + ivec2(x,y);
//         if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
//         if (imageLoad(TrailIn, q).b > 0.6) cnt++;
//     }
//     return cnt;
// }

// void best_sensor_dir(ivec2 p, float offset_px, int sensor_radius, int sensors,
//                      out int best_cnt, out vec2 best_dir){
//     best_cnt = 0; best_dir = vec2(0.0);
//     vec2 P = vec2(p) + vec2(0.5);
//     for (int s=0; s<sensors; ++s){
//         float a = (2.0*PI) * (float(s)/float(sensors));
//         vec2  dir = vec2(cos(a), sin(a));
//         ivec2 sc  = ivec2(floor(P + dir * offset_px));
//         int cnt = count_blue_disk(sc, sensor_radius);
//         if (cnt > best_cnt){ best_cnt = cnt; best_dir = dir; }
//     }
// }

// // Fast “within angle” test using cosine threshold
// bool aligned_dir(vec2 v_from, vec2 v_to, float max_angle){
//     float lv = length(v_from), lw = length(v_to);
//     if (lv < 1e-6 || lw < 1e-6) return false;
//     float c = dot(v_from / lv, v_to / lw); // cos(theta)
//     return c >= cos(max_angle);            // theta <= max_angle
// }

// // -------------- main ----------------
// void main() {
//     ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
//     ivec2 sz = imageSize(TrailIn);
//     if (p.x >= sz.x || p.y >= sz.y) return;

//     // load current
//     vec4 cur  = imageLoad(TrailIn, p);
//     vec4 outc = cur; // carry-over by default

//     // node pixels (visual)
//     uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
//     for (uint i = 0u; i < N; ++i) {
//         ivec2 np = ivec2(nodes[i] + vec2(0.5));
//         if (p == np) {
//             imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
//             return; // nodes are fully handled
//         }
//     }

//     // seed: ensure seed pixel stays active (so there's always a frontier)
//     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
//     if (p == seed_px || p == seed_px + ivec2(1,0) || p == seed_px + ivec2(0,1) || p == seed_px + ivec2(1,1) || p == seed_px + ivec2(-1,0) || p == seed_px + ivec2(0,-1) || p == seed_px + ivec2(-1,-1) || p == seed_px + ivec2(1,-1) || p == seed_px + ivec2(-1,1)) {
//         outc = vec4(1.0, 0.0, 0.0, 1.0);
//         imageStore(TrailOut, p, outc);
//         return;
//     }

//     // if (cur.r > 0.1) {
//     //     // keep alive and slowly decay
//     //     float life = max(cur.r - params.decay_rate, 0.0);
//     //     outc.r = life;
//     //     // optionally keep "visited" or other channels unchanged
//     //     imageStore(TrailOut, p, outc);
//     //     return;
//     // }
//     // decay / keep active pixels for several frames
//     int active_n = 0;
//     int active_blue_n = 0;
//     int active_green_n = 0;
//     vec2[8] neighbor_blues = vec2[8](vec2(0,0), vec2(0,0), vec2(0,0), vec2(0,0),
//                                  vec2(0,0), vec2(0,0), vec2(0,0), vec2(0,0));
//     float decay = max(0.0, params.decay_rate); // e.g. 0.01
//     for (int oy = -1; oy <= 1; ++oy) {
//         for (int ox = -1; ox <= 1; ++ox) {
//             if (ox == 0 && oy == 0) continue;
//             ivec2 s = p + ivec2(ox, oy);
//             if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;
//             vec4 src = imageLoad(TrailIn, s);
//             if (src.r > 0.0) active_n++;
//             if (src.b > 0.0) {
//                 neighbor_blues[active_blue_n] = vec2(s);
//                 active_blue_n++;
//             }
//             if (src.g > 0.0) active_green_n++; // keep blue if neighbor is green
//         }
//     }

//     if (cur.r >= 0.1) {
//         // keep alive and slowly decay
//         float life = max(cur.r - decay, 0.1);
//         outc.r = life;
//         outc.b = max(cur.b - decay, 0.0);
//         // outc.g = max(cur.g - decay, 0.4);
//         // if (active_green_n > 0 && active_blue_n > 0) {
//         //     outc.g = 1.0; // keep green if neighbor is green
//         // }
//         if (active_blue_n >= 5 && cur.r <= 0.2) { outc.b = 1.0; }
//         // if (cur.g > 0.0) {
//             const int   SENSORS       = 8;
//             const float SENSOR_OFFSET = 20.0;
//             const int   SENSOR_RAD    = 3;
//             const int   MIN_CNT       = 2;
//             const float BLUE_GAIN     = (params.min_life     > 0.0 ? params.min_life     : 0.40);
//             const float BLUE_DECAY    = (params.visited_decay> 0.0 ? params.visited_decay: 0.06);
//             const float MAX_ANG       = PI * 0.05; // ~9°

//             const float STAB_ADD   = (params.min_life      > 0.0 ? params.min_life      : 0.45); // build rate
//             const float STAB_DECAY = (params.visited_decay > 0.0 ? params.visited_decay : 0.08); // forget rate
//             const float T_LOCK     = 0.75;     // high threshold to lock
//             const float T_UNLOCK   = 0.55;     // low threshold (hysteresis)
//             const float B_LOCK     = 0.95;     // consider already solid if B is high
//             const float ALIGN_MAX  = PI*0.10;  // ~18° alignment cone for connections

//             int  best_cnt;
//             vec2 best_dir;
//             best_sensor_dir(p, SENSOR_OFFSET, SENSOR_RAD, SENSORS, best_cnt, best_dir);

//             // Only proceed if a sensor actually saw a clump
//             bool any_match = false;
//             if (best_cnt >= MIN_CNT){
//                 // Opposite of clump direction from this pixel
//                 vec2 desired = -best_dir;

//                 // Check all 8 neighbors; if any blue neighbor lies along desired, we “hit”
//                 const ivec2 OFF[8] = ivec2[8](
//                     ivec2(1,0), ivec2(1,1), ivec2(0,1), ivec2(-1,1),
//                     ivec2(-1,0), ivec2(-1,-1), ivec2(0,-1), ivec2(1,-1)
//                 );
//                 vec2 Pcenter = vec2(p) + vec2(0.5);
//                 for (int i=0;i<8;i++){
//                     ivec2 q = p + OFF[i];
//                     if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
//                     float nb = imageLoad(TrailIn, q).b;
//                     if (nb >= 0.2) {
//                         vec2 v = (vec2(q) + vec2(0.5)) - Pcenter; // direction to that neighbor
//                         if (aligned_dir(v, desired, MAX_ANG)) { any_match = true; break; } // dot-cos test
//                     } else {
//                         continue;
//                         // vec2 v = Pcenter - params.start_pos; // direction to that neighbor
//                         // if (aligned_dir(v, desired, MAX_ANG)) { any_match = true; break; } // dot-cos test
//                     }
//                 }
//             }

//             // 1) Stability EMA in G (driven by your sensor gate)
//             float g = cur.g;
//             g = g * (1.0 - STAB_DECAY) + (any_match ? STAB_ADD : 0.0);                 // EMA accumulate/decay [3]
//             bool neighbor_locked = false;
//             const ivec2 OFF[8] = ivec2[](ivec2(1,0),ivec2(1,1),ivec2(0,1),ivec2(-1,1),
//                                         ivec2(-1,0),ivec2(-1,-1),ivec2(0,-1),ivec2(1,-1));
//             for (int i=0;i<8;i++){
//                 ivec2 q = p + OFF[i];
//                 if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
//                 vec4 nb = imageLoad(TrailIn, q);
//                 if (nb.g >= T_LOCK || nb.b >= B_LOCK) { neighbor_locked = true; break; }        // Canny-style tracking [4]
//             }
//             if (neighbor_locked) g = max(g, T_LOCK);

//             // 3) Lock/solid test without alpha
//             bool locked = (g >= T_LOCK) || (cur.b >= B_LOCK);

//             // 4) Connection reinforcement to close gaps toward center/nodes (no neighbor writes)
//             vec2 P = vec2(p) + vec2(0.5);
//             vec2 dir_center = normalize(params.start_pos - P);

//             // nearest-node direction (simple argmin)
//             uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
//             vec2 dir_node = vec2(0.0);
//             if (N > 0u){
//                 float bestd=1e30; uint bi=0u;
//                 for (uint i=0u;i<N;++i){ float d = length(nodes[i]-P); if (d<bestd){bestd=d; bi=i;} }
//                 vec2 v = nodes[bi]-P; if (length(v)>1e-6) dir_node = normalize(v);
//             }

//             // cosine threshold
//             float cos_thr = cos(ALIGN_MAX);

//             // Check neighbors: if any blue neighbor roughly points along a valid path, treat as hit to “grow” into the gap
//             bool connect_hit = false;
//             for (int i=0;i<8;i++){
//                 ivec2 q = p + OFF[i];
//                 if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
//                 vec4 nb = imageLoad(TrailIn, q);
//                 if (nb.b <= 0.6) continue; // not blue
//                 vec2 v = (vec2(q)+vec2(0.5)) - P;
//                 float lv = length(v);
//                 if (lv < 1e-6) continue;
//                 vec2 vu = v / lv;
//                 if (dot(vu, dir_center) >= cos_thr) { connect_hit = true; break; }             // toward center [8]
//                 if (dir_node != vec2(0.0) && dot(vu, dir_node) >= cos_thr) { connect_hit = true; break; } // toward node [8]
//             }

//             // 5) Update B: permanent if locked; else reinforce on sensor/connection hits; else gentle fade
//             float b = cur.b;
//             if (locked) {
//                 b = 1.0;                                                              // stays forever [4]
//             } else if (any_match || connect_hit) {
//                 b = min(1.0, b + STAB_ADD);                                           // grow into gaps [3]
//             } else {
//                 b = b * (1.0 - max(STAB_DECAY, 0.02));                                // gentle fade [3]
//             }

//             // 6) Store and return from active branch
//             outc.g = clamp(g, 0.0, 1.0);
//             outc.b = clamp(b, 0.0, 1.0);
//             // // Update blue at THIS pixel (no neighbor writes)
//             // float g = cur.g;
//             // if (any_match) {
//             //     g = min(1.0, g + BLUE_GAIN);         // reinforce if aligned with the opposite-of-clump
//             // } else {
//             //     g = g * (1.0 - BLUE_DECAY);          // gentle decay otherwise
//             // }
//             // outc.g = clamp(g, 0.0, 1.0);
//             // if (cur.g > 0.0) {
//             //     outc.g = max(cur.g - decay, 0.0);
//             // }
//         // }

//         // if (active_blue_n > 4 && cur.r <= 0.2) {
//         //     outc.b = 1.0; // extra decay if no blue neighbors
//         // }
//         // optionally keep "visited" or other channels unchanged

//                 // --- sensor-offset clump attraction (no confidence/lock) ---
//         // const int   SENSORS       = 8;      // 6–12 works well
//         // const float SENSOR_OFFSET = 5.0;   // px
//         // const int   SENSOR_RAD    = 1;      // px
//         // const int   MIN_CNT       = 6;      // min blue hits to accept clump
//         // const float BLUE_GAIN     = (params.min_life > 0.0 ? params.min_life : 0.4);
//         // const float BLUE_DECAY    = (params.visited_decay > 0.0 ? params.visited_decay : 0.06);

//         // // 1) Pick best sensor
//         // int  best_cnt;
//         // vec2 best_dir;
//         // best_sensor_dir(p, SENSOR_OFFSET, SENSOR_RAD, SENSORS, best_cnt, best_dir);

//         // // 2) Optional node-alignment gate (unsigned angle via acos(dot))
//         // vec2 Pcenter    = vec2(p) + vec2(0.5);
//         // for (int i = 0; i < 8; ++i) {
//         //     if (neighbor_blues[i] != vec2(0.0)) {
//         //         if (aligned(neighbor_blues[i] - Pcenter, -best_dir, PI * 0.05)) {
//         //             float b = cur.b;
//         //             if (best_cnt >= MIN_CNT && active_blue_n > 6 && cur.r <= 0.2) {
//         //                 b = min(1.0, b + BLUE_GAIN);            // immediate reinforcement
//         //             } else {
//         //                 b = max(b - decay, 0.0);             // gentle decay
//         //             }
//         //             outc.b = clamp(b, 0.0, 1.0);
//         //         }
//         //     }
//         // }
//         // vec2 dir_center = normalize(Pcenter - params.start_pos); // toward center
//         // float best_angle = PI;
//         // for (uint i = 0u; i < N; ++i){
//         //     vec2 dn = normalize(nodes[i] - Pcenter);
//         //     float d = clamp(dot(dn, dir_center), -1.0, 1.0);
//         //     best_angle = min(best_angle, acos(d));
//         // }
//         // bool toward_node = (best_angle <= PI * 0.10);

//         // 3) Update blue locally: boost if strong clump and aligned, else fade a bit

//         // --- end sensor-offset clump attraction ---
//         // const int kernel[5] = int[](1, 4, 6, 4, 1);
//         // float norm = 16.0;
//         // vec4 sum = vec4(0.0);

//         // for (int k = -2; k <= 2; ++k) {
//         //     ivec2 n = p;
//         //     n.x += k; // horizontal offset
//         //     if (n.x < 0 || n.x >= 1920 || n.y < 0 || n.y >= 1080) continue;
//         //     sum += imageLoad(TrailIn, n) * float(kernel[k+2]);
//         // }

//         // vec4 blurred = sum / norm;
//         // vec4 v = mix(outc, blurred, clamp(0.2 * params.deltaTime, 0.1, 1.0));
//         imageStore(TrailOut, p, outc);
//         return;
//     }

//     // inactive pixel: check neighbors



//     // if no active neighbors, stay idle (but still write outc to preserve image)
//     if (active_n == 0) {
//         imageStore(TrailOut, p, outc);
//         return;
//     }

//     vec2 Pcenter = vec2(p) + vec2(0.5);
//     vec2 dir_center = normalize(Pcenter - params.start_pos);  // direction to center
//     // float best_perp;
//     // bool desired = in_jitter_corridor(Pcenter, best_perp);
//     // float blue_decay = clamp(params.visited_decay, 0.0, 1.0); // e.g., 0.04
//     // float blue_add   = clamp(params.min_life,     0.0, 1.0); // e.g., 0.35
//     // float b = cur.b;
//     // b = b * (1.0 - blue_decay) + (desired ? blue_add : 0.0);


//     // Optional cleanup: if not desired and few blue neighbors, erode faster
//     // if (!desired && active_blue_n <= 1) {
//     //     b *= (1.0 - min(0.5, 2.0 * blue_decay)); // stronger local erosion
//     // }

//     // Clamp and write blue; keep your red growth logic below
//     // outc.b = clamp(b, 0.0, 1.0);
//     // Find best-aligned node direction from this pixel (min angle)
//     float best_angle = PI;  // PI = 3.141592653589793
//     for (uint i = 0u; i < N; ++i) {
//         vec2 dir_node = normalize(nodes[i] - Pcenter);
//         float d = clamp(dot(dir_node, dir_center), -1.0, 1.0);
//         float a = acos(d);                    // unsigned angle [0, PI]
//         best_angle = min(best_angle, a);
//     }

//     // // Optional randomness to avoid solid rings (salt is per-destination pixel)
//     uint salt = uint(params.seed) + uint(p.x)*9176u + uint(p.y)*6113u;
//     float rr = rand_at(p, salt);

//     // // If aligned within (0.3*PI), mark this frontier pixel blue and stop
//     if (best_angle <= PI * 0.05 && rr < 0.3 && cur.b == 0.0) {
//         outc.b = 1.0;
//     }

//     // Compute combined probability from k active neighbors:
//     // P_total = 1 - (1-p)^k  (independent neighbor attempts)
//     float p_single = clamp(params.grow_chance, 0.0, 1.0);
//     float p_total = 1.0 - pow(1.0 - p_single, float(active_n));

//     // Use candidate-specific RNG (salt uses neighbor coords to avoid correlation)
//     float r = rand_at(p, salt); // or rand_at(ivec2(p), salt) using your rand_at
//     if (r < p_total) {
//         // activate and give it a life value (1.0)
//         outc.r = 1.0;
//         outc.g = 0.0;
//         // if (outc.b > 0.0) {
//         //     outc.b = 1.0; // keep blue if it was blue
//         // } else {
//         //     outc.b = 0.0;
//         // }
//         outc.a = 1.0;

//     } else {
//         // remain inactive
//         outc.r = 0.0;
//     }

//     imageStore(TrailOut, p, outc);
// }
// // void main() {
// //     ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
// //     ivec2 sz = imageSize(TrailIn);
// //     if (p.x >= sz.x || p.y >= sz.y) return;

// //     // Carry over by default (prevents accidental erasure)
// //     vec4 cur  = imageLoad(TrailIn, p);
// //     vec4 outc = cur;

// //     // Keep node pixels green (visual)
// //     uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
// //     for (uint i = 0u; i < N; ++i) {
// //         ivec2 np = ivec2(nodes[i] + vec2(0.5));
// //         if (p == np) {
// //             imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
// //             return;
// //         }
// //     }
// //     // if (cur.r > 0.0) {
// //     //     imageStore(TrailOut, p, cur);
// //     //     return;
// //     // }
// //     // Seed stays red so there is always a frontier
// //     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
// //     if (p == seed_px && cur.r <= 0.0) {
// //         imageStore(TrailOut, p, vec4(1.0, 0.0, 0.0, 1.0));
// //     }

// //     // Already active? keep it
// //     if (cur.r <= 0.0) {
// //         for (int oy = -1; oy <= 1; ++oy) {
// //             for (int ox = -1; ox <= 1; ++ox) {
// //                 if (ox == 0 && oy == 0) continue;
// //                 ivec2 s = p + ivec2(ox, oy);
// //                 if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;
// //                 vec4 src = imageLoad(TrailIn, s);
// //                 float r = rand_at(p, uint(params.seed) + uint(s.x) * 9176u + uint(s.y) * 6113u);
// //                 if (src.r > 0.0 && r < 0.25) {
// //                     src.r = 1.0; // keep active if any neighbor is active
// //                     imageStore(TrailOut, p, vec4(1.0, 0.0, 0.0, 1.0));
// //                     // return;
// //                 }
// //             }
// //         }
// //     }

// //     // Try to activate this pixel if any active neighbor pushes into it
// //     bool activate = false;
//     // for (int oy = -1; oy <= 1 && !activate; ++oy) {
//     //     for (int ox = -1; ox <= 1 && !activate; ++ox) {
//     //         if (ox == 0 && oy == 0) continue;
//     //         ivec2 s = p + ivec2(ox, oy);
//     //         if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;

//     //         vec4 src = imageLoad(TrailIn, s);
//     //         if (src.r <= 0.0) continue; // only from active neighbors

//     //         // Choose node: mostly nearest, sometimes random
//     //         uint salt   = uint(params.seed) + uint(s.x) * 17u + uint(s.y) * 29u;
//     //         float pickR = rand_at(p, salt ^ 0x2F2F2F2Fu);
//     //         uint chosen;

//     //         if (pickR < 0.7 && N > 0u) {
//     //             chosen = choose_near_node(vec2(s), salt ^ 0xA5A5A5A5u);
//     //         } else if (N > 0u) {
//     //             float r = rand_at(s, salt ^ 0xC3C3C3C3u);
//     //             chosen = uint(r * float(N));
//     //             if (chosen >= N) chosen = N - 1u;
//     //         } else {
//     //             chosen = uint(-1); // no nodes
//     //         }

//     //         // Direction from source -> here (always valid)
//     //         vec2 grow_dir = normalize(vec2(p - s));

//     //         // Direction from source toward node (may be invalid)
//     //         vec2 node_dir = vec2(0.0, 0.0);
//     //         bool node_ok  = false;
//     //         if (chosen != uint(-1)) {
//     //             vec2 v = nodes[chosen] - vec2(s);
//     //             float L = length(v);
//     //             if (L > 1e-6) { node_dir = v / L; node_ok = true; }
//     //         }

//     //         // Alignment in [0,1]; if node invalid, use neutral 0.5 so we still grow
//     //         float align01 = 0.5;
//     //         if (node_ok) {
//     //             float align = clamp(dot(grow_dir, node_dir), -1.0, 1.0);
//     //             align01 = 0.5 * (align + 1.0);
//     //         }

//     //         // Wander (kept moderate to avoid stalling)
//     //         float wander  = (rand_at(s, salt ^ 0x5F5F5F5Fu) - 0.5) * clamp(params.grow_angle_variance, 0.0, 1.0);
//     //         float w       = clamp(align01 + wander, 0.0, 1.0);

//     //         // Final activation probability:
//     //         // - never zero (0.05 floor)
//     //         // - capped by grow_chance
//     //         float baseP = mix(0.05, clamp(params.grow_chance, 0.0, 1.0), pow(w, 2.2));

//     //         // Last random test (unique per destination+source)
//     //         float rpush = rand_at(p + ivec2(ox * 379 + oy * 613, oy * 997 - ox * 421), salt ^ 0x9E3779B9u);
//     //         if (rpush < baseP) activate = true;
//     //     }
//     // }

//     // if (activate) outc = vec4(1.0, 0.0, 0.0, 1.0);
//     // imageStore(TrailOut, p, outc);
// // }
// // #version 450
// // layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// // layout(set = 0, binding = 0, rgba32f) uniform image2D TrailIn;
// // layout(set = 0, binding = 1, rgba32f) uniform image2D TrailOut;

// // layout(set = 0, binding = 2, std430) buffer NodeBuffer { vec2 nodes[]; };

// // layout(set = 0, binding = 3) uniform Params {
// //     float node_count;
// //     float time_sec;
// //     float grow_chance;
// //     float grow_angle_variance;
// //     float nearest_nodes_dist_px;
// //     float seed;
// //     vec2  start_pos;
// //     float decay_rate;       // how quickly an active pixel's life falls per step (0..1)
// //     float visited_decay;    // how quickly the visited pheromone decays per step (0..1)
// //     float visited_penalty;  // how strongly visited discourages re-activation (0..1)
// //     float min_life;         // minimum residual life for an "active" pixel (0..1)
// // } params;

// // #define DEBUG_SIMPLE 0

// // const float PI = 3.141592653589793;

// // // ---- integer hash RNG (far better than fra(uv*const) ) -----------------------
// // uint wang_hash(uint x) {
// //     x = (x ^ 61u) ^ (x >> 16);
// //     x *= 9u;
// //     x = x ^ (x >> 4);
// //     x *= 0x27d4eb2du;
// //     x = x ^ (x >> 15);
// //     return x;
// // }
// // float hash_to_float(uint x) {
// //     // map 32-bit uint to [0,1]
// //     return float(wang_hash(x)) / 4294967295.0;
// // }
// // float rnd_at_ivec(ivec2 p, uint salt) {
// //     uint ux = uint(p.x);
// //     uint uy = uint(p.y);
// //     uint s  = salt;
// //     // mix primes + salt
// //     uint key = ux * 374761393u + uy * 668265263u + s * 0x9e3779b9u;
// //     return hash_to_float(key);
// // }

// // // ---- pick nearest two nodes (stochastic) -----------------------------------
// // uint pickNearestOfTwo(vec2 pos) {
// //     uint n1 = uint(-1), n2 = uint(-1);
// //     float d1 = 1e20, d2 = 1e20;
// //     for (uint i = 0u; i < uint(params.node_count); ++i) {
// //         float d = length(nodes[i] - pos);
// //         if (d < d1) { d2 = d1; n2 = n1; d1 = d; n1 = i; }
// //         else if (d < d2) { d2 = d; n2 = i; }
// //     }
// //     d1 = max(d1, 1e-3);
// //     d2 = max(d2, 1e-3);
// //     float w1 = 1.0 / d1;
// //     float chooser = hash_to_float(uint(params.seed) + uint(floor(params.time_sec * 1000.0)) + uint(pos.x) + uint(pos.y));
// //     return (chooser < w1 / (w1 + (1.0 / d2))) ? n1 : n2;
// // }

// // // ---- main ------------------------------------------------------------------
// // void main() {
// //     ivec2 p = ivec2(gl_GlobalInvocationID.xy);

// //     ivec2 size = imageSize(TrailIn);
// //     if (p.x >= size.x || p.y >= size.y) return;

// //     // If this is a node pixel, paint green and return
// //     // for (uint i = 0u; i < uint(params.node_count); ++i) {
// //     //     if (p == ivec2(nodes[i] + vec2(0.5))) {
// //     //         imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
// //     //         return;
// //     //     }
// //     // }

// //     // Packed channels:
// //     // R = life/active strength (1 = freshly active, decays)
// //     // G = visited pheromone (1 = recently visited, decays slowly)
// //     // B/A = currently unused (reserved for direction encoding if you want)
// //     vec4 cur = imageLoad(TrailIn, p);

// //     // Seed pixel: always (re)write seed to TrailOut so a frontier always exists.
// //     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
// //     if (p == seed_px) {
// //         imageStore(TrailOut, p, vec4(1.0, 1.0, 0.0, 1.0));
// //         // return;
// //     }

// //     // If currently active, decay life and visited pheromone
// //     // if (cur.r > params.min_life) {
// //     //     float life = max(cur.r - params.decay_rate, params.min_life);
// //     //     float visited = max(cur.g - params.visited_decay, 0.0);
// //     //     imageStore(TrailOut, p, vec4(life, visited, cur.b, cur.a));
// //     //     return;
// //     // }

// //     // Count active neighbors and also average neighboring visited value
// //     int active_n = 0;
// //     float neigh_visited_sum = 0.0;
// //     ivec2 src;
// //     // for (int oy = -1; oy <= 1; ++oy) {
// //     //     for (int ox = -1; ox <= 1; ++ox) {
// //     //         if (ox == 0 && oy == 0) continue;
// //     //         src = p + ivec2(ox, oy);
// //     //         if (src.x < 0 || src.y < 0 || src.x >= size.x || src.y >= size.y) continue;
// //     //         vec4 sVal = imageLoad(TrailIn, src);
// //     //         if (sVal.r > params.min_life) {
// //     //             active_n++;
// //     //         }
// //     //         neigh_visited_sum += sVal.g;
// //     //     }
// //     // }

// //     // If no active neighbor, decay visited slightly and bail out
// //     // if (active_n == 0) {
// //     //     float visited = max(cur.g - params.visited_decay, 0.0);
// //     //     imageStore(TrailOut, p, vec4(cur.r, visited, cur.b, cur.a));
// //     //     return;
// //     // }

// //     // crowd factor from number of active neighbors (avoid blobs)
// //     float crowd_factor = 1.0;
// //     if (active_n >= 4) crowd_factor = 0.45;
// //     else if (active_n >= 2) crowd_factor = 0.75;

// //     // neighborhood visited penalty (if neighbors are already heavily visited, reduce chance)
// //     float neigh_visited_avg = neigh_visited_sum / 8.0;
// //     float neigh_penalty = pow(max(0.0, 1.0 - neigh_visited_avg * params.visited_penalty), 1.5);

// //     // Try to grow from any active neighbor. We keep the first success (like agents).
// //     bool grow_here = true;
// //     // for (int oy = -1; oy <= 1 && !grow_here; ++oy) {
// //     //     for (int ox = -1; ox <= 1 && !grow_here; ++ox) {
// //     //         if (ox == 0 && oy == 0) continue;
// //     //         src = p + ivec2(ox, oy);
// //     //         if (src.x < 0 || src.y < 0 || src.x >= size.x || src.y >= size.y) continue;

// //     //         vec4 sVal = imageLoad(TrailIn, src);
// //     //         // if (sVal.r <= params.min_life) continue; // only from active neighbors

// //     //         // Stochastic choice: usually use nearest nodes, occasionally random exploration
// //     //         float pickr = rnd_at_ivec(src, uint(params.seed) + 7u);
// //     //         uint chosen = (pickr < 0.75) ? pickNearestOfTwo(vec2(src)) : uint(rnd_at_ivec(src, uint(params.seed) + 13u) * (max(1.0, params.node_count - 1.0)));

// //     //         // direction from source -> this pixel
// //     //         vec2 grow_dir = normalize(vec2(p - src));
// //     //         vec2 node_dir = normalize(nodes[chosen] - vec2(src));

// //     //         // directional noise to break symmetric patterns
// //     //         float noise = (rnd_at_ivec(src, uint(params.seed) + 31u) - 0.5) * params.grow_angle_variance;

// //     //         float angle = acos(clamp(dot(grow_dir, node_dir), -1.0, 1.0));
// //     //         float angle_w = clamp(1.0 - angle / PI + noise, 0.0, 1.0);

// //     //         // activation base (bounded). floor ensures exploration even for poor angles.
// //     //         float activation_base = max(0.02, mix(0.02, clamp(params.grow_chance, 0.0, 1.0), pow(angle_w, 3.0)));

// //     //         // visited penalty for *this* pixel reduces chance to revisit
// //     //         float visited_pen = pow(max(0.0, 1.0 - cur.g * params.visited_penalty), 1.45);

// //     //         // final activation probability
// //     //         float activation = activation_base * crowd_factor * neigh_penalty * visited_pen;;
// //     //         activation = 1.2;
// //     //         // stronger randomness per neighbor (salt depends on src)
// //     //         float r = rnd_at_ivec(p, uint(params.seed) + uint(src.x) * 9176u + uint(src.y) * 6113u);
// //     //         if (r < activation) {
// //     //             grow_here = true;
// //     //         }
// //     //     }
// //     // }

// //     if (grow_here) {
// //         // set fresh life and pheromone
// //         imageStore(TrailOut, p, vec4(1.0, 1.0, 0.0, 0.0));
// //     } else {
// //         // nothing changed except visited decays
// //         float visited = max(cur.g - params.visited_decay, 0.0);
// //         imageStore(TrailOut, p, vec4(cur.r, visited, cur.b, cur.a));
// //     }

// // }

#version 450
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

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
layout(set = 0, binding = 2, std430) buffer NodeBuffer { vec2 nodes[]; };

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
        vec4 init = is_seed ? vec4(1.0, 0.0, 0.0, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
        imageStore(TrailOut, p, init);
        return;
    }


    // Nodes visible as green
    uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
    for (uint i=0u; i<N; ++i){
        if (p == ivec2(nodes[i] + vec2(0.5))){
            imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
            return;
        }
    }

    // Seed: keep only red on, do NOT whiten
    // ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
    // if (p == seed_px || p == seed_px + ivec2(1,0) || p == seed_px + ivec2(0,1) ||
    //     p == seed_px + ivec2(1,1) || p == seed_px + ivec2(-1,0) || p == seed_px + ivec2(0,-1) ||
    //     p == seed_px + ivec2(-1,-1) || p == seed_px + ivec2(1,-1) || p == seed_px + ivec2(-1,1)){
    //     outc = vec4(1.0, 0.0, 0.0, 1.0); // R only
    //     imageStore(TrailOut, p, outc);
    //     return;
    // }

    // Neighbor tallies
    int active_n = 0;
    int active_blue_n = 0;
    float decay = max(0.0, params.decay_rate);
    for (int oy=-1; oy<=1; ++oy){
        for (int ox=-1; ox<=1; ++ox){
            if (ox==0 && oy==0) continue;
            ivec2 s = p + ivec2(ox,oy);
            if (s.x<0 || s.y<0 || s.x>=sz.x || s.y>=sz.y) continue;
            vec4 src = imageLoad(TrailIn, s);
            if (src.r > 0.0 || is_seed_cell(s, seed_px)) active_n++;
            if (src.b > 0.6) active_blue_n++;
        }
    }

    // ACTIVE pixel branch
    if (cur.r >= 0.1){
        // Red decays slowly
        outc.r = max(cur.r - decay, 0.1);

        // Sensor parameters
        const int   SENSORS       = 8;
        const float SENSOR_OFFSET = 20.0;
        const int   SENSOR_RAD    = 3;
        const int   MIN_CNT       = 3;      // lower so hits register
        const float MAX_ANG       = PI * 0.10; // ~18°

        // Stability (EMA) + hysteresis thresholds
        const float STAB_ADD   = (params.min_life      > 0.5 ? params.min_life      : 0.25);
        const float STAB_DECAY = (params.visited_decay > 0.01 ? params.visited_decay : 0.06);
        const float T_LOCK     = 0.75;
        const float B_LOCK     = 0.95;

        // 1) Best sensor (clump direction)
        int  best_cnt; vec2 best_dir;
        best_sensor_dir(p, SENSOR_OFFSET, SENSOR_RAD, SENSORS, best_cnt, best_dir);

        // 2) Gate: any blue neighbor roughly opposite clump direction?
        bool any_match = false;
        if (best_cnt >= MIN_CNT){
            vec2 desired = -best_dir;
            vec2 Pcenter = vec2(p) + vec2(0.5);
            for (int i=0;i<8;i++){
                ivec2 q = p + OFF[i];
                if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
                float nb = imageLoad(TrailIn, q).b;
                if (nb < 0.2) continue;
                vec2 v = (vec2(q) + vec2(0.5)) - Pcenter;
                if (aligned_dir(v, desired, MAX_ANG)){ any_match = true; break; }
            }
        }

        // 3) Stability EMA in G
        float g = cur.g;
        g = g * (1.0 - STAB_DECAY) + (any_match ? STAB_ADD : 0.0);      // EMA

        // 4) Neighbor hysteresis (snap to locked if a neighbor is strong)
        bool neighbor_locked = false;
        for (int i=0;i<8;i++){
            ivec2 q = p + OFF[i];
            if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
            vec4 nb = imageLoad(TrailIn, q);
            if (nb.g >= T_LOCK){ neighbor_locked = true; break; }
        }
        if (neighbor_locked) g = max(g, T_LOCK);

        // 5) Lock condition (no alpha): stable or already strong blue
        bool locked = (g >= T_LOCK);

        // 6) Gap-closing reinforcement toward center or nearest node
        vec2 P = vec2(p) + vec2(0.5);
        vec2 dir_center = normalize(params.start_pos - P);
        vec2 dir_node   = vec2(0.0);
        if (N > 0u){
            float bestd=1e30; uint bi=0u;
            for (uint i=0u;i<N;++i){ float d = length(nodes[i]-P); if (d<bestd){bestd=d; bi=i;} }
            vec2 v = nodes[bi]-P; if (length(v)>1e-6) dir_node = normalize(v);
        }
        float cos_thr = cos(MAX_ANG);
        float d_to_node = 1e30;
        uint  bi = 0u;
        if (N > 0u){
            d_to_node = length(nodes[bi] - P); // 'bi' chosen earlier
        }
        const float CAP_R = 16.0;     // absorbing capture radius [px]
        const float EPS_D = 0.75;     // monotonic margin [px]

        // 1) One-way hysteresis: only consider locked neighbors that are CLOSER to the node
        bool inward_locked_neighbor = false;
        for (int i=0;i<8;i++){
            ivec2 q = p + OFF[i];
            if (q.x<0||q.y<0||q.x>=sz.x||q.y>=sz.y) continue;
            vec4 nb = imageLoad(TrailIn, q);
            if (nb.g < T_LOCK) continue; // only stable neighbors (Canny hysteresis idea)
            float nb_d = (N > 0u) ? length(nodes[bi] - (vec2(q)+vec2(0.5))) : 1e30;
            if (nb_d + EPS_D < d_to_node) { // strictly closer to the sink
                // also require alignment toward the node or center ray
                vec2 v = (vec2(q)+vec2(0.5)) - P;
                float lv = length(v);
                if (lv > 1e-6) {
                    vec2 vu = v / lv;
                    if (dot(vu, dir_node)  >= cos_thr || dot(vu, dir_center) >= cos_thr) {
                        inward_locked_neighbor = true; break;
                    }
                }
            }
        }

        // 2) Absorbing zone at the node: no lateral reinforcement inside CAP_R
        bool in_cap = (N > 0u) && (d_to_node <= CAP_R);

        // 3) Revised reinforcement and locking
        // g is your EMA stability already updated earlier as: g = g*(1-STAB_DECAY) + (any_match ? STAB_ADD : 0)
        locked = (g >= T_LOCK); // stability-only lock

        // Gains: make them gentle to avoid sudden plates
        const float ADD  = clamp(params.min_life,     0.05, 0.25);
        const float DEC  = clamp(params.visited_decay,0.01, 0.06);

        float b = cur.b;
        if (locked) {
            b = 1.0; // permanent
        } else if (!in_cap && any_match && inward_locked_neighbor) {
            // reinforce only when (a) outside absorbing zone, (b) sensor hit, (c) inward locked support
            b = min(1.0, b + ADD);
        } else {
            b = b * (1.0 - DEC);
        }

        // Inside the capture radius, snap to line but damp red so growth stops
        if (in_cap) {
            g = max(g, T_LOCK);       // stabilize
            b = max(b, 1.0);          // keep bright
            outc.r = max(outc.r - 0.5, 0.1); // damp red life so no lateral advance
        }

        outc.g = clamp(g, 0.0, 1.0);
        outc.b = clamp(b, 0.0, 1.0);
        imageStore(TrailOut, p, outc);
        return;
    }

    // INACTIVE pixel branch
    if (active_n == 0){
        // Preserve B/G so stabilized paths aren’t erased
        imageStore(TrailOut, p, outc);
        return;
    }

    // Angle gate toward nodes (kept simple)
    vec2 Pcenter = vec2(p) + vec2(0.5);
    vec2 dir_center2 = normalize(Pcenter - params.start_pos);
    float best_angle = PI;
    for (uint i=0u; i<N; ++i){
        vec2 dn = normalize(nodes[i] - Pcenter);
        float d = clamp(dot(dn, dir_center2), -1.0, 1.0);
        best_angle = min(best_angle, acos(d)); // unsigned
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
    if (r < p_total){
        outc.r = 1.0; 
        outc.a = 1.0;          // activate red
        // keep existing G/B
    } else {
        outc.r = 0.0;            // remain inactive; DO NOT zero G/B
    }

    imageStore(TrailOut, p, outc);
}
