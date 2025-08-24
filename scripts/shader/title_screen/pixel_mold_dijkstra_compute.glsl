#[compute]

#version 450
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D TrailIn;   // read
layout(set = 0, binding = 1, rgba32f) uniform image2D TrailOut;  // write
layout(set = 0, binding = 2, std430) buffer NodeBuffer { vec2 nodes[]; };

// std140 layout to match UBO packing on CPU (16 floats = 64 bytes)
layout(std140, set = 0, binding = 3) uniform Params {
    float node_count;              // 0
    float time_sec;                // 4
    float grow_chance;             // 8   (suggest 0.25..0.45)
    float grow_angle_variance;     // 12  (suggest 0.2..0.5)
    float nearest_nodes_dist_px;   // 16  (unused)
    float seed;                    // 20
    float pad0;                    // 24
    float pad1;                    // 28
    vec2  start_pos;               // 32..39
    float pad2;                    // 40
    float pad3;                    // 44
    float decay_rate;              // 48  (unused here)
    float visited_decay;           // 52  (unused)
    float visited_penalty;         // 56  (unused)
    float min_life;                // 60  (unused)
} params;

const float PI = 3.141592653589793;

// ---------------- RNG: uint hash -> [0,1) ----------------
uint wang_hash(uint x) {
    x = (x ^ 61u) ^ (x >> 16);
    x *= 9u;
    x = x ^ (x >> 4);
    x *= 0x27d4eb2du;
    x = x ^ (x >> 15);
    return x;
}
float urand01(uint x) { return float(wang_hash(x)) * (1.0 / 4294967295.0); }
float rand_at(ivec2 p, uint salt) {
    uint key = uint(p.x) * 374761393u ^ (uint(p.y) * 668265263u) ^ (salt * 0x9e3779b9u);
    return urand01(key);
}

// --------- choose between two nearest nodes (stochastic) ----------
bool two_nearest(vec2 pos, out uint n1, out uint n2) {
    n1 = uint(-1); n2 = uint(-1);
    float d1 = 1e20, d2 = 1e20;
    uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
    if (N == 0u) return false;
    for (uint i = 0u; i < N; ++i) {
        float d = length(nodes[i] - pos);
        if (d < d1) { d2 = d1; n2 = n1; d1 = d; n1 = i; }
        else if (d < d2) { d2 = d; n2 = i; }
    }
    return (n1 != uint(-1) && n2 != uint(-1));
}

uint choose_near_node(vec2 pos, uint salt) {
    uint a, b;
    if (!two_nearest(pos, a, b)) return uint(-1);
    float d1 = max(length(nodes[a] - pos), 1e-3);
    float d2 = max(length(nodes[b] - pos), 1e-3);
    float w1 = 1.0 / d1, w2 = 1.0 / d2;
    float pick = urand01(salt ^ uint(pos.x) ^ (uint(pos.y) << 1));
    return (pick < (w1 / (w1 + w2))) ? a : b;
}

// -------------- main ----------------
void main() {
    ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
    ivec2 sz = imageSize(TrailIn);
    if (p.x >= sz.x || p.y >= sz.y) return;

    // load current
    vec4 cur  = imageLoad(TrailIn, p);
    vec4 outc = cur; // carry-over by default

    // node pixels (visual)
    uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
    for (uint i = 0u; i < N; ++i) {
        ivec2 np = ivec2(nodes[i] + vec2(0.5));
        if (p == np) {
            imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
            return; // nodes are fully handled
        }
    }

    // seed: ensure seed pixel stays active (so there's always a frontier)
    ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
    if (p == seed_px || p == seed_px + ivec2(1,0) || p == seed_px + ivec2(0,1) || p == seed_px + ivec2(1,1) || p == seed_px + ivec2(-1,0) || p == seed_px + ivec2(0,-1) || p == seed_px + ivec2(-1,-1) || p == seed_px + ivec2(1,-1) || p == seed_px + ivec2(-1,1)) {
        outc = vec4(1.0, 0.0, 0.0, 1.0);
        imageStore(TrailOut, p, outc);
        return;
    }

    // if (cur.r > 0.1) {
    //     // keep alive and slowly decay
    //     float life = max(cur.r - params.decay_rate, 0.0);
    //     outc.r = life;
    //     // optionally keep "visited" or other channels unchanged
    //     imageStore(TrailOut, p, outc);
    //     return;
    // }
    // decay / keep active pixels for several frames
    float decay = max(0.0, params.decay_rate); // e.g. 0.01
    if (cur.r >= 0.1) {
        // keep alive and slowly decay
        float life = max(cur.r - decay, 0.1);
        outc.r = life;
        // optionally keep "visited" or other channels unchanged
        imageStore(TrailOut, p, outc);
        return;
    }

    // inactive pixel: check neighbors
    int active_n = 0;
    for (int oy = -1; oy <= 1; ++oy) {
        for (int ox = -1; ox <= 1; ++ox) {
            if (ox == 0 && oy == 0) continue;
            ivec2 s = p + ivec2(ox, oy);
            if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;
            vec4 src = imageLoad(TrailIn, s);
            if (src.r > 0.0) active_n++;
        }
    }

    // if no active neighbors, stay idle (but still write outc to preserve image)
    if (active_n == 0) {
        imageStore(TrailOut, p, outc);
        return;
    }

    // Compute combined probability from k active neighbors:
    // P_total = 1 - (1-p)^k  (independent neighbor attempts)
    float p_single = clamp(params.grow_chance, 0.0, 1.0);
    float p_total = 1.0 - pow(1.0 - p_single, float(active_n));

    // Use candidate-specific RNG (salt uses neighbor coords to avoid correlation)
    uint salt = uint(params.seed) + uint(p.x)*9176u + uint(p.y)*6113u;
    float r = rand_at(p, salt); // or rand_at(ivec2(p), salt) using your rand_at
    if (r < p_total) {
        // activate and give it a life value (1.0)
        outc = vec4(1.0, 0.0, 0.0, 1.0);
    } else {
        // remain inactive
        outc = vec4(0.0, 0.0, 0.0, 1.0);
    }

    imageStore(TrailOut, p, outc);
}
// void main() {
//     ivec2 p  = ivec2(gl_GlobalInvocationID.xy);
//     ivec2 sz = imageSize(TrailIn);
//     if (p.x >= sz.x || p.y >= sz.y) return;

//     // Carry over by default (prevents accidental erasure)
//     vec4 cur  = imageLoad(TrailIn, p);
//     vec4 outc = cur;

//     // Keep node pixels green (visual)
//     uint N = (uint(params.node_count) > 0u) ? uint(params.node_count) : 0u;
//     for (uint i = 0u; i < N; ++i) {
//         ivec2 np = ivec2(nodes[i] + vec2(0.5));
//         if (p == np) {
//             imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
//             return;
//         }
//     }
//     // if (cur.r > 0.0) {
//     //     imageStore(TrailOut, p, cur);
//     //     return;
//     // }
//     // Seed stays red so there is always a frontier
//     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
//     if (p == seed_px && cur.r <= 0.0) {
//         imageStore(TrailOut, p, vec4(1.0, 0.0, 0.0, 1.0));
//     }

//     // Already active? keep it
//     if (cur.r <= 0.0) {
//         for (int oy = -1; oy <= 1; ++oy) {
//             for (int ox = -1; ox <= 1; ++ox) {
//                 if (ox == 0 && oy == 0) continue;
//                 ivec2 s = p + ivec2(ox, oy);
//                 if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;
//                 vec4 src = imageLoad(TrailIn, s);
//                 float r = rand_at(p, uint(params.seed) + uint(s.x) * 9176u + uint(s.y) * 6113u);
//                 if (src.r > 0.0 && r < 0.25) {
//                     src.r = 1.0; // keep active if any neighbor is active
//                     imageStore(TrailOut, p, vec4(1.0, 0.0, 0.0, 1.0));
//                     // return;
//                 }
//             }
//         }
//     }

//     // Try to activate this pixel if any active neighbor pushes into it
//     bool activate = false;
    // for (int oy = -1; oy <= 1 && !activate; ++oy) {
    //     for (int ox = -1; ox <= 1 && !activate; ++ox) {
    //         if (ox == 0 && oy == 0) continue;
    //         ivec2 s = p + ivec2(ox, oy);
    //         if (s.x < 0 || s.y < 0 || s.x >= sz.x || s.y >= sz.y) continue;

    //         vec4 src = imageLoad(TrailIn, s);
    //         if (src.r <= 0.0) continue; // only from active neighbors

    //         // Choose node: mostly nearest, sometimes random
    //         uint salt   = uint(params.seed) + uint(s.x) * 17u + uint(s.y) * 29u;
    //         float pickR = rand_at(p, salt ^ 0x2F2F2F2Fu);
    //         uint chosen;

    //         if (pickR < 0.7 && N > 0u) {
    //             chosen = choose_near_node(vec2(s), salt ^ 0xA5A5A5A5u);
    //         } else if (N > 0u) {
    //             float r = rand_at(s, salt ^ 0xC3C3C3C3u);
    //             chosen = uint(r * float(N));
    //             if (chosen >= N) chosen = N - 1u;
    //         } else {
    //             chosen = uint(-1); // no nodes
    //         }

    //         // Direction from source -> here (always valid)
    //         vec2 grow_dir = normalize(vec2(p - s));

    //         // Direction from source toward node (may be invalid)
    //         vec2 node_dir = vec2(0.0, 0.0);
    //         bool node_ok  = false;
    //         if (chosen != uint(-1)) {
    //             vec2 v = nodes[chosen] - vec2(s);
    //             float L = length(v);
    //             if (L > 1e-6) { node_dir = v / L; node_ok = true; }
    //         }

    //         // Alignment in [0,1]; if node invalid, use neutral 0.5 so we still grow
    //         float align01 = 0.5;
    //         if (node_ok) {
    //             float align = clamp(dot(grow_dir, node_dir), -1.0, 1.0);
    //             align01 = 0.5 * (align + 1.0);
    //         }

    //         // Wander (kept moderate to avoid stalling)
    //         float wander  = (rand_at(s, salt ^ 0x5F5F5F5Fu) - 0.5) * clamp(params.grow_angle_variance, 0.0, 1.0);
    //         float w       = clamp(align01 + wander, 0.0, 1.0);

    //         // Final activation probability:
    //         // - never zero (0.05 floor)
    //         // - capped by grow_chance
    //         float baseP = mix(0.05, clamp(params.grow_chance, 0.0, 1.0), pow(w, 2.2));

    //         // Last random test (unique per destination+source)
    //         float rpush = rand_at(p + ivec2(ox * 379 + oy * 613, oy * 997 - ox * 421), salt ^ 0x9E3779B9u);
    //         if (rpush < baseP) activate = true;
    //     }
    // }

    // if (activate) outc = vec4(1.0, 0.0, 0.0, 1.0);
    // imageStore(TrailOut, p, outc);
// }
// #version 450
// layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// layout(set = 0, binding = 0, rgba32f) uniform image2D TrailIn;
// layout(set = 0, binding = 1, rgba32f) uniform image2D TrailOut;

// layout(set = 0, binding = 2, std430) buffer NodeBuffer { vec2 nodes[]; };

// layout(set = 0, binding = 3) uniform Params {
//     float node_count;
//     float time_sec;
//     float grow_chance;
//     float grow_angle_variance;
//     float nearest_nodes_dist_px;
//     float seed;
//     vec2  start_pos;
//     float decay_rate;       // how quickly an active pixel's life falls per step (0..1)
//     float visited_decay;    // how quickly the visited pheromone decays per step (0..1)
//     float visited_penalty;  // how strongly visited discourages re-activation (0..1)
//     float min_life;         // minimum residual life for an "active" pixel (0..1)
// } params;

// #define DEBUG_SIMPLE 0

// const float PI = 3.141592653589793;

// // ---- integer hash RNG (far better than fra(uv*const) ) -----------------------
// uint wang_hash(uint x) {
//     x = (x ^ 61u) ^ (x >> 16);
//     x *= 9u;
//     x = x ^ (x >> 4);
//     x *= 0x27d4eb2du;
//     x = x ^ (x >> 15);
//     return x;
// }
// float hash_to_float(uint x) {
//     // map 32-bit uint to [0,1]
//     return float(wang_hash(x)) / 4294967295.0;
// }
// float rnd_at_ivec(ivec2 p, uint salt) {
//     uint ux = uint(p.x);
//     uint uy = uint(p.y);
//     uint s  = salt;
//     // mix primes + salt
//     uint key = ux * 374761393u + uy * 668265263u + s * 0x9e3779b9u;
//     return hash_to_float(key);
// }

// // ---- pick nearest two nodes (stochastic) -----------------------------------
// uint pickNearestOfTwo(vec2 pos) {
//     uint n1 = uint(-1), n2 = uint(-1);
//     float d1 = 1e20, d2 = 1e20;
//     for (uint i = 0u; i < uint(params.node_count); ++i) {
//         float d = length(nodes[i] - pos);
//         if (d < d1) { d2 = d1; n2 = n1; d1 = d; n1 = i; }
//         else if (d < d2) { d2 = d; n2 = i; }
//     }
//     d1 = max(d1, 1e-3);
//     d2 = max(d2, 1e-3);
//     float w1 = 1.0 / d1;
//     float chooser = hash_to_float(uint(params.seed) + uint(floor(params.time_sec * 1000.0)) + uint(pos.x) + uint(pos.y));
//     return (chooser < w1 / (w1 + (1.0 / d2))) ? n1 : n2;
// }

// // ---- main ------------------------------------------------------------------
// void main() {
//     ivec2 p = ivec2(gl_GlobalInvocationID.xy);

//     ivec2 size = imageSize(TrailIn);
//     if (p.x >= size.x || p.y >= size.y) return;

//     // If this is a node pixel, paint green and return
//     // for (uint i = 0u; i < uint(params.node_count); ++i) {
//     //     if (p == ivec2(nodes[i] + vec2(0.5))) {
//     //         imageStore(TrailOut, p, vec4(0.0, 1.0, 0.0, 1.0));
//     //         return;
//     //     }
//     // }

//     // Packed channels:
//     // R = life/active strength (1 = freshly active, decays)
//     // G = visited pheromone (1 = recently visited, decays slowly)
//     // B/A = currently unused (reserved for direction encoding if you want)
//     vec4 cur = imageLoad(TrailIn, p);

//     // Seed pixel: always (re)write seed to TrailOut so a frontier always exists.
//     ivec2 seed_px = ivec2(params.start_pos + vec2(0.5));
//     if (p == seed_px) {
//         imageStore(TrailOut, p, vec4(1.0, 1.0, 0.0, 1.0));
//         // return;
//     }

//     // If currently active, decay life and visited pheromone
//     // if (cur.r > params.min_life) {
//     //     float life = max(cur.r - params.decay_rate, params.min_life);
//     //     float visited = max(cur.g - params.visited_decay, 0.0);
//     //     imageStore(TrailOut, p, vec4(life, visited, cur.b, cur.a));
//     //     return;
//     // }

//     // Count active neighbors and also average neighboring visited value
//     int active_n = 0;
//     float neigh_visited_sum = 0.0;
//     ivec2 src;
//     // for (int oy = -1; oy <= 1; ++oy) {
//     //     for (int ox = -1; ox <= 1; ++ox) {
//     //         if (ox == 0 && oy == 0) continue;
//     //         src = p + ivec2(ox, oy);
//     //         if (src.x < 0 || src.y < 0 || src.x >= size.x || src.y >= size.y) continue;
//     //         vec4 sVal = imageLoad(TrailIn, src);
//     //         if (sVal.r > params.min_life) {
//     //             active_n++;
//     //         }
//     //         neigh_visited_sum += sVal.g;
//     //     }
//     // }

//     // If no active neighbor, decay visited slightly and bail out
//     // if (active_n == 0) {
//     //     float visited = max(cur.g - params.visited_decay, 0.0);
//     //     imageStore(TrailOut, p, vec4(cur.r, visited, cur.b, cur.a));
//     //     return;
//     // }

//     // crowd factor from number of active neighbors (avoid blobs)
//     float crowd_factor = 1.0;
//     if (active_n >= 4) crowd_factor = 0.45;
//     else if (active_n >= 2) crowd_factor = 0.75;

//     // neighborhood visited penalty (if neighbors are already heavily visited, reduce chance)
//     float neigh_visited_avg = neigh_visited_sum / 8.0;
//     float neigh_penalty = pow(max(0.0, 1.0 - neigh_visited_avg * params.visited_penalty), 1.5);

//     // Try to grow from any active neighbor. We keep the first success (like agents).
//     bool grow_here = true;
//     // for (int oy = -1; oy <= 1 && !grow_here; ++oy) {
//     //     for (int ox = -1; ox <= 1 && !grow_here; ++ox) {
//     //         if (ox == 0 && oy == 0) continue;
//     //         src = p + ivec2(ox, oy);
//     //         if (src.x < 0 || src.y < 0 || src.x >= size.x || src.y >= size.y) continue;

//     //         vec4 sVal = imageLoad(TrailIn, src);
//     //         // if (sVal.r <= params.min_life) continue; // only from active neighbors

//     //         // Stochastic choice: usually use nearest nodes, occasionally random exploration
//     //         float pickr = rnd_at_ivec(src, uint(params.seed) + 7u);
//     //         uint chosen = (pickr < 0.75) ? pickNearestOfTwo(vec2(src)) : uint(rnd_at_ivec(src, uint(params.seed) + 13u) * (max(1.0, params.node_count - 1.0)));

//     //         // direction from source -> this pixel
//     //         vec2 grow_dir = normalize(vec2(p - src));
//     //         vec2 node_dir = normalize(nodes[chosen] - vec2(src));

//     //         // directional noise to break symmetric patterns
//     //         float noise = (rnd_at_ivec(src, uint(params.seed) + 31u) - 0.5) * params.grow_angle_variance;

//     //         float angle = acos(clamp(dot(grow_dir, node_dir), -1.0, 1.0));
//     //         float angle_w = clamp(1.0 - angle / PI + noise, 0.0, 1.0);

//     //         // activation base (bounded). floor ensures exploration even for poor angles.
//     //         float activation_base = max(0.02, mix(0.02, clamp(params.grow_chance, 0.0, 1.0), pow(angle_w, 3.0)));

//     //         // visited penalty for *this* pixel reduces chance to revisit
//     //         float visited_pen = pow(max(0.0, 1.0 - cur.g * params.visited_penalty), 1.45);

//     //         // final activation probability
//     //         float activation = activation_base * crowd_factor * neigh_penalty * visited_pen;;
//     //         activation = 1.2;
//     //         // stronger randomness per neighbor (salt depends on src)
//     //         float r = rnd_at_ivec(p, uint(params.seed) + uint(src.x) * 9176u + uint(src.y) * 6113u);
//     //         if (r < activation) {
//     //             grow_here = true;
//     //         }
//     //     }
//     // }

//     if (grow_here) {
//         // set fresh life and pheromone
//         imageStore(TrailOut, p, vec4(1.0, 1.0, 0.0, 0.0));
//     } else {
//         // nothing changed except visited decays
//         float visited = max(cur.g - params.visited_decay, 0.0);
//         imageStore(TrailOut, p, vec4(cur.r, visited, cur.b, cur.a));
//     }

// }