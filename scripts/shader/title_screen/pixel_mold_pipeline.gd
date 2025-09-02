extends Node2D

const MAX_NODES := 10
const WORKGROUPS := Vector3i(16, 16, 1)

var rd: RenderingDevice
var texture_width := 1920
var texture_height := 1080

var shader_rid: RID
var pipeline_rid: RID
var ubo_rid: RID
var node_ssbo_rid: RID
var uniform_set_rid: RID
var agent_buffer: RID;

var tex_in: RID
var tex_out: RID
var texrd: Texture2DRD
var sprite: Sprite2D

var seed: int = randi()
var node_positions := PackedFloat32Array()

func _ready() -> void:
	rd = RenderingServer.get_rendering_device()
	assert(rd)

	node_positions = PackedFloat32Array([
		100.0, 100.0,
		400.0, 200.0,
		700.0, 400.0,
		500.0, 800.0,
		300.0, 700.0,
		900.0, 900.0,
		1200.0, 1000.0,
		1500.0, 600.0,
		1700.0, 300.0,
		1800.0, 900.0,
		156.0, 203.0,
		873.0, 726.0,
		193.0, 654.0,
		437.0, 483.0,
		298.0, 653.0
	])

	node_ssbo_rid = rd.storage_buffer_create(node_positions.size() * 4, node_positions.to_byte_array())
	agent_buffer = build_agents(100, 0, Vector2(960.0, 540.0), randi())
	var rd_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_dijkstra_compute.glsl")
	var spirv: RDShaderSPIRV = rd_file.get_spirv()
	shader_rid = rd.shader_create_from_spirv(spirv)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)

	# Create two storage-capable textures
	var fmt := RDTextureFormat.new()
	fmt.width = texture_width
	fmt.height = texture_height
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	tex_in  = rd.texture_create(fmt, view, [])
	tex_out = rd.texture_create(fmt, view, [])

	texrd = Texture2DRD.new()
	texrd.texture_rd_rid = tex_out
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = get_viewport_rect().size * 0.5
	sprite.texture = texrd
	add_child(sprite)

	ubo_rid = rd.uniform_buffer_create(_make_params(0.0).size() * 4, _make_params(0.0).to_byte_array())

	# Create the initial uniform set (bind tex_in for read, tex_out for write)
	_update_uniform_set()

func _process(delta: float) -> void:
	var params := _make_params(delta)
	rd.buffer_update(ubo_rid, 0, params.size() * 4, params.to_byte_array())

	# Bind, dispatch
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline_rid)
	rd.compute_list_bind_uniform_set(cl, uniform_set_rid, 0)
	rd.compute_list_dispatch(cl, int((texture_width + WORKGROUPS.x - 1) / WORKGROUPS.x), int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
	rd.compute_list_end()

	texrd.texture_rd_rid = tex_out

	# Ping‑pong for next frame
	var tmp := tex_in
	tex_in = tex_out
	tex_out = tmp

	_update_uniform_set()

func _make_params(delta) -> PackedFloat32Array:
	var t := Time.get_ticks_msec() / 1000.0
	return PackedFloat32Array([
		float(MAX_NODES),             # 0
		t,                            # 1 time_sec
		0.28,                         # 2 grow_chance (start here)
		0.35,                         # 3 grow_angle_variance (0.2..0.5)
		2.5,                          # 4 nearest_nodes_dist_px (unused)
		float(seed),                  # 5 seed (as float)
		delta, 0.0,                     # 6..7 pad0, pad1 (force start_pos at 16B boundary)
		960.0, 540.0,                 # 8..9 start_pos (center)
		0.0, 0.0,                     # 10..11 pad2, pad3
		0.01,                          # 12 decay_rate (unused)
		0.08,                          # 13 visited_decay (unused)
		0.0,                          # 14 visited_penalty (unused)
		0.45                           # 15 min_life (unused)
	])

func _update_uniform_set() -> void:
	# Rebuild the uniform set each time swapping the textures, so bindings stay correct.
	var u0 := RDUniform.new()
	u0.binding = 0
	u0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u0.add_id(tex_in)   # read

	var u1 := RDUniform.new()
	u1.binding = 1
	u1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u1.add_id(tex_out)  # write

	var u2 := RDUniform.new()
	u2.binding = 2
	u2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u2.add_id(node_ssbo_rid)

	var u4 := RDUniform.new()
	u4.binding = 3
	u4.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u4.add_id(ubo_rid)
	
	var u3 := RDUniform.new()
	u3.binding = 3
	u3.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u3.add_id(agent_buffer)

	uniform_set_rid = rd.uniform_set_create([u0, u1, u2, u4], shader_rid, 0)

func _exit_tree() -> void:
	if rd:
		for rid in [shader_rid, pipeline_rid, ubo_rid, node_ssbo_rid, tex_in, tex_out]:
			if rid.is_valid():
				rd.free_rid(rid)

func build_agents(num_agents:int, home_index:int, home_pos:Vector2, seed:int) -> RID:
	var TWO_PI := PI*2.0
	var bytes := PackedByteArray()
	for i in num_agents:
		var agent_fract: float = float(i) / max(1.0, float(num_agents))
		var agent_angle: float = TWO_PI * agent_fract  # equal spread
		var pos: Vector2 = home_pos + Vector2(randf()*4.0 - 2.0, randf()*4.0 - 2.0)
		var final_angle: float = agent_angle # + (randf() - 0.5) * 0.3 # in radians
		
		# A: pos.xy, angle, state(0=EXPLORE)
		bytes.append_array(PackedFloat32Array([pos.x, pos.y, final_angle, 0.0]).to_byte_array())

		# B: home_idx, last_node(-1), time_since_node(0), rng_salt
		#bytes.append_array(PackedFloat32Array([float(home_index), -1.0, 0.0, float(seed ^ i)]).to_byte_array())
		# B: home_idx, last_node(-1), was_inside, pad
		bytes.append_array(PackedFloat32Array([float(home_index), -1.0, 0.0, 0.0]).to_byte_array())

		## C: was_inside(0/1), pad, pad, pad
		#bytes.append_array(PackedFloat32Array([0.0, 0.0, 0.0, 0.0]).to_byte_array())
	return rd.storage_buffer_create(bytes.size(), bytes)
#extends Node2D
#
#const MAX_NODES := 10
#const WORKGROUPS := Vector3i(16, 16, 1)
#
#var rd: RenderingDevice
#var texture_width := 1920
#var texture_height := 1080
#
## Existing pipeline (unchanged names)
#var shader_rid: RID
#var pipeline_rid: RID
#var ubo_rid: RID
#var node_ssbo_rid: RID
#var uniform_set_rid: RID
#var tex_in: RID
#var tex_out: RID
#var texrd: Texture2DRD
#var sprite: Sprite2D
#var seed: int = randi()
#var node_positions := PackedFloat32Array()
#
## NEW: distance field (JFA) ping‑pong, path mask, and extra pipelines
#var dist_a: RID
#var dist_b: RID
#var jfa_shader: RID
#var jfa_pipeline: RID
#var jfa_params_ubo: RID
#var jfa_uniform_set_a: RID      # DistIn=dist_a, DistOut=dist_b
#var jfa_uniform_set_b: RID      # DistIn=dist_b, DistOut=dist_a
#var dist_ping_is_a := true
#
#var clear_mask_shader: RID
#var clear_mask_pipeline: RID
#var clear_mask_uniform_set: RID
#
#var path_mask: RID              # R32UI for atomics
#var backtrace_shader: RID
#var backtrace_pipeline: RID
#var backtrace_params_ubo: RID
#var backtrace_uniform_set: RID
#
#var stylize_shader: RID
#var stylize_pipeline: RID
#var stylize_params_ubo: RID
#var stylize_uniform_set: RID
#
#func _ready() -> void:
	#rd = RenderingServer.get_rendering_device()
	#assert(rd)
#
	## ---------------- Nodes SSBO ----------------
	#node_positions = PackedFloat32Array([
		#100.0, 100.0,
		#400.0, 200.0,
		#700.0, 400.0,
		#500.0, 800.0,
		#300.0, 700.0,
		#900.0, 900.0,
		#1200.0, 1000.0,
		#1500.0, 600.0,
		#1700.0, 300.0,
		#1800.0, 900.0
	#])
	#node_ssbo_rid = rd.storage_buffer_create(node_positions.size() * 4, node_positions.to_byte_array())
#
	## ---------------- Existing pass ----------------
	#var rd_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_dijkstra_compute.glsl")
	#var spirv: RDShaderSPIRV = rd_file.get_spirv()
	#shader_rid = rd.shader_create_from_spirv(spirv)
	#pipeline_rid = rd.compute_pipeline_create(shader_rid)
#
	## Two storage-capable RGBA32F textures for visible ping‑pong
	#var fmt := RDTextureFormat.new()
	#fmt.width = texture_width
	#fmt.height = texture_height
	#fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	#fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		#| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		#| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	#var view := RDTextureView.new()
	#tex_in  = rd.texture_create(fmt, view, [])
	#tex_out = rd.texture_create(fmt, view, [])
#
	## Display sprite
	#texrd = Texture2DRD.new()
	#texrd.texture_rd_rid = tex_out
	#sprite = Sprite2D.new()
	#sprite.centered = true
	#sprite.position = get_viewport_rect().size * 0.5
	#sprite.texture = texrd
	#add_child(sprite)
#
	## ---------------- UBO for existing pass (unchanged layout) ----------------
	#ubo_rid = rd.uniform_buffer_create(_make_params().size() * 4, _make_params().to_byte_array())
	#_update_uniform_set() # for existing pass (read tex_in, write tex_out)
#
	## ---------------- NEW RESOURCES: distance + mask ----------------
	## Distance field ping‑pong: R32F storage images
	#dist_a = _create_storage_texture(RenderingDevice.DATA_FORMAT_R32_SFLOAT)
	#dist_b = _create_storage_texture(RenderingDevice.DATA_FORMAT_R32_SFLOAT)
#
	## Path mask for atomics: R32UI
	#path_mask = _create_storage_texture(RenderingDevice.DATA_FORMAT_R32_UINT)
#
	## ---------------- NEW SHADERS + PIPELINES ----------------
	## JFA step
	#var jfa_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_jfa_step.glsl")
	#jfa_shader = rd.shader_create_from_spirv(jfa_file.get_spirv())
	#jfa_pipeline = rd.compute_pipeline_create(jfa_shader)
	#jfa_params_ubo = rd.uniform_buffer_create(16, PackedFloat32Array([960.0, 540.0, 0.0, 0.0]).to_byte_array()) # center.xy, jump(int) stored in u32 via rd.buffer_update
	#_build_jfa_uniform_sets()
#
	## Clear path mask
	#var clr_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_clear_mask.glsl")
	#clear_mask_shader = rd.shader_create_from_spirv(clr_file.get_spirv())
	#clear_mask_pipeline = rd.compute_pipeline_create(clear_mask_shader)
	#_build_clear_mask_uniform_set()
#
	## Backtrace pass
	#var bt_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_backtrace.glsl")
	#backtrace_shader = rd.shader_create_from_spirv(bt_file.get_spirv())
	#backtrace_pipeline = rd.compute_pipeline_create(backtrace_shader)
	#backtrace_params_ubo = rd.uniform_buffer_create(32, PackedFloat32Array([960.0, 540.0, 2048.0, 0.001, 0.0, 0.0, 0.0, 0.0]).to_byte_array()) # center.xy, max_steps, stop_eps
	#_build_backtrace_uniform_set()
#
	## Stylize/composite pass (reads PathMask + tex_in, writes tex_out)
	#var st_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_stylize.glsl")
	#stylize_shader = rd.shader_create_from_spirv(st_file.get_spirv())
	#stylize_pipeline = rd.compute_pipeline_create(stylize_shader)
	#stylize_params_ubo = rd.uniform_buffer_create(16, PackedFloat32Array([3.0, 0.15, 0.0, 0.0]).to_byte_array()) # radius, jitter_amp
	#_build_stylize_uniform_set()
#
	## Optionally initialize distance to large and mask to zero by running one clear in shaders
	#_run_clear_mask()
	#_init_distance_with_center()
	## End setup
	#
#
#func _process(delta: float) -> void:
	## Update existing UBO (time etc.)
	#var params := _make_params()
	#rd.buffer_update(ubo_rid, 0, params.size() * 4, params.to_byte_array())
#
	## 1) Distance field (JFA) multi‑pass
	#_run_jfa_distance()
#
	## 2) Clear path mask
	#_run_clear_mask()
#
	## 3) Backtrace from nodes into mask
	#_run_backtrace()
#
	## 4) Existing pass (kept, writes tex_out from tex_in)
	#var cl0 := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(cl0, pipeline_rid)
	#rd.compute_list_bind_uniform_set(cl0, uniform_set_rid, 0)
	#rd.compute_list_dispatch(cl0,
		#int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
		#int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
	#rd.compute_list_end()
#
	#var sp = PackedFloat32Array([3.0, 0.15, Time.get_ticks_msec()/1000.0, 0.0]).to_byte_array()
	#rd.buffer_update(stylize_params_ubo, 0, sp.size(), sp)
	## 5) Stylize/composite from PathMask over visible image
	#_run_stylize()
#
	## Display latest output
	#texrd.texture_rd_rid = tex_out
#
	## Ping‑pong for next frame (visible buffers)
	#var tmp := tex_in
	#tex_in = tex_out
	#tex_out = tmp
	#_update_uniform_set()
	#_build_stylize_uniform_set() # src/dst changed for stylize too
#
#
#func _make_params() -> PackedFloat32Array:
	#var t := Time.get_ticks_msec() / 1000.0
	#return PackedFloat32Array([
		#float(MAX_NODES),             # 0
		#t,                            # 1 time_sec
		#0.28,                         # 2 grow_chance
		#0.35,                         # 3 grow_angle_variance
		#0.0,                          # 4 nearest_nodes_dist_px (unused)
		#float(seed),                  # 5 seed (as float)
		#0.0, 0.0,                     # 6..7 pad0, pad1
		#960.0, 540.0,                 # 8..9 start_pos (center)
		#0.0, 0.0,                     # 10..11 pad2, pad3
		#0.01,                         # 12 decay_rate
		#0.0,                          # 13 visited_decay
		#0.0,                          # 14 visited_penalty
		#0.0                           # 15 min_life
	#])
#
#
#func _update_uniform_set() -> void:
	## Existing pass uniform set (read tex_in, write tex_out)
	#var u0 := RDUniform.new()
	#u0.binding = 0
	#u0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u0.add_id(tex_in)   # read
	#var u1 := RDUniform.new()
	#u1.binding = 1
	#u1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u1.add_id(tex_out)  # write
	#var u2 := RDUniform.new()
	#u2.binding = 2
	#u2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#u2.add_id(node_ssbo_rid)
	#var u3 := RDUniform.new()
	#u3.binding = 3
	#u3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	#u3.add_id(ubo_rid)
	#uniform_set_rid = rd.uniform_set_create([u0, u1, u2, u3], shader_rid, 0)
#
#
## ---------- Helpers for new passes ----------
#func _create_storage_texture(fmt_format:int) -> RID:
	#var fmt := RDTextureFormat.new()
	#fmt.width = texture_width
	#fmt.height = texture_height
	#fmt.format = fmt_format
	#fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	#return rd.texture_create(fmt, RDTextureView.new(), [])
#
#
## --- JFA distance setup and dispatch ---
#func _build_jfa_uniform_sets() -> void:
	## Set A: DistIn=dist_a -> DistOut=dist_b
	#var a0 := RDUniform.new()
	#a0.binding = 0
	#a0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#a0.add_id(dist_a)
	#var a1 := RDUniform.new()
	#a1.binding = 1
	#a1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#a1.add_id(dist_b)
	#var a2 := RDUniform.new()
	#a2.binding = 2
	#a2.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	#a2.add_id(jfa_params_ubo)
	#jfa_uniform_set_a = rd.uniform_set_create([a0, a1, a2], jfa_shader, 0)
#
	## Set B: DistIn=dist_b -> DistOut=dist_a
	#var b0 := RDUniform.new()
	#b0.binding = 0
	#b0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#b0.add_id(dist_b)
	#var b1 := RDUniform.new()
	#b1.binding = 1
	#b1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#b1.add_id(dist_a)
	#var b2 := RDUniform.new()
	#b2.binding = 2
	#b2.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	#b2.add_id(jfa_params_ubo)
	#jfa_uniform_set_b = rd.uniform_set_create([b0, b1, b2], jfa_shader, 0)
#
#func _init_distance_with_center() -> void:
	## One tiny init pass is expected in the GLSL to set Dist=0 at center and large elsewhere;
	## if not, you can upload a filled buffer here. Then run one short JFA sweep.
	#_run_jfa_distance()
#
#func _run_jfa_distance() -> void:
	## Jump sequence: powers of two down to 1
	#var max_dim = max(texture_width, texture_height)
	#var k := 1
	#while k < max_dim: k <<= 1
	#while k >= 1:
		## Update JFA UBO: center.xy, jump as float bits placed into buffer (shader reads int)
		#var payload := PackedFloat32Array([960.0, 540.0, float(k), 0.0]).to_byte_array()
		#rd.buffer_update(jfa_params_ubo, 0, payload.size(), payload)
		#var cl := rd.compute_list_begin()
		#rd.compute_list_bind_compute_pipeline(cl, jfa_pipeline)
		## Bind correct ping‑pong uniform set
		#if dist_ping_is_a:
			#rd.compute_list_bind_uniform_set(cl, jfa_uniform_set_a, 0)
		#else:
			#rd.compute_list_bind_uniform_set(cl, jfa_uniform_set_b, 0)
		#rd.compute_list_dispatch(cl,
			#int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
			#int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
		#rd.compute_list_end()
		#dist_ping_is_a = !dist_ping_is_a
		#k >>= 1
#
#func _dist_final_rid() -> RID:
	#return dist_b if dist_ping_is_a else dist_a
#
#
## --- Clear path mask ---
#func _build_clear_mask_uniform_set() -> void:
	#var u := RDUniform.new()
	#u.binding = 0
	#u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u.add_id(path_mask)
	#clear_mask_uniform_set = rd.uniform_set_create([u], clear_mask_shader, 0)
#
#func _run_clear_mask() -> void:
	#var cl := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(cl, clear_mask_pipeline)
	#rd.compute_list_bind_uniform_set(cl, clear_mask_uniform_set, 0)
	#rd.compute_list_dispatch(cl,
		#int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
		#int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
	#rd.compute_list_end()
#
#
## --- Backtrace from nodes into mask ---
#func _build_backtrace_uniform_set() -> void:
	#var u0 := RDUniform.new()
	#u0.binding = 0
	#u0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u0.add_id(_dist_final_rid())
	#var u1 := RDUniform.new()
	#u1.binding = 1
	#u1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u1.add_id(path_mask) # uimage2D (R32UI)
	#var u2 := RDUniform.new()
	#u2.binding = 2
	#u2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#u2.add_id(node_ssbo_rid)
	#var u3 := RDUniform.new()
	#u3.binding = 3
	#u3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	#u3.add_id(backtrace_params_ubo)
	#backtrace_uniform_set = rd.uniform_set_create([u0, u1, u2, u3], backtrace_shader, 0)
#
#func _run_backtrace() -> void:
	## Build farthest->nearest order by Euclidean distance to center (matches our DistTex)
	#var cx := 960.0
	#var cy := 540.0
	#var order := []
	#for i in range(MAX_NODES):
		#var px = node_positions[i*2+0]
		#var py = node_positions[i*2+1]
		#var d  = sqrt((px - cx)*(px - cx) + (py - cy)*(py - cy))
		#order.append({ "i": i, "d": d })
	#order.sort_custom(func(a,b): return a["d"] > b["d"])  # farthest first
#
	## One node per dispatch; label = i+1 to keep non-zero and unique
	#for k in order.size():
		#var idx:int = order[k]["i"]
		## BtParams: center.xy, max_steps, stop_eps, node_index, label, pad
		#var label_u32 := float(idx + 1)         # packed into float slot (shader reads as uint)
		#var bt = PackedFloat32Array([cx, cy, 4096.0, 0.001, float(idx), label_u32, 0.0, 0.0]).to_byte_array()
		#rd.buffer_update(backtrace_params_ubo, 0, bt.size(), bt)
#
		#var cl := rd.compute_list_begin()
		#rd.compute_list_bind_compute_pipeline(cl, backtrace_pipeline)
		#rd.compute_list_bind_uniform_set(cl, backtrace_uniform_set, 0)
		#rd.compute_list_dispatch(cl, 1, 1, 1)  # exactly one invocation
		#rd.compute_list_end()
#
#
## --- Stylize/composite from PathMask into visible ping‑pong ---
#func _build_stylize_uniform_set() -> void:
	#var u0 := RDUniform.new()
	#u0.binding = 0
	#u0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u0.add_id(path_mask)   # read uimage2D
	#var u1 := RDUniform.new()
	#u1.binding = 1
	#u1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u1.add_id(tex_in)      # read source visible
	#var u2 := RDUniform.new()
	#u2.binding = 2
	#u2.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#u2.add_id(tex_out)     # write destination visible
	#var u3 := RDUniform.new()
	#u3.binding = 3
	#u3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	#u3.add_id(stylize_params_ubo)
	#stylize_uniform_set = rd.uniform_set_create([u0, u1, u2, u3], stylize_shader, 0)
#
#func _run_stylize() -> void:
	#var cl := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(cl, stylize_pipeline)
	#rd.compute_list_bind_uniform_set(cl, stylize_uniform_set, 0)
	#rd.compute_list_dispatch(cl,
		#int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
		#int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
	#rd.compute_list_end()
#
#
#func _exit_tree() -> void:
	#if rd:
		#for rid in [
			#shader_rid, pipeline_rid, ubo_rid, node_ssbo_rid, tex_in, tex_out,
			#dist_a, dist_b, jfa_shader, jfa_pipeline, jfa_params_ubo, jfa_uniform_set_a, jfa_uniform_set_b,
			#path_mask, clear_mask_shader, clear_mask_pipeline, clear_mask_uniform_set,
			#backtrace_shader, backtrace_pipeline, backtrace_params_ubo, backtrace_uniform_set,
			#stylize_shader, stylize_pipeline, stylize_params_ubo, stylize_uniform_set
		#]:
			#if rid is RID and rid.is_valid():
				#rd.free_rid(rid)
