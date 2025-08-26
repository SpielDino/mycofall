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
		1800.0, 900.0
	])

	node_ssbo_rid = rd.storage_buffer_create(node_positions.size() * 4, node_positions.to_byte_array())

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

	ubo_rid = rd.uniform_buffer_create(_make_params().size() * 4, _make_params().to_byte_array())

	# Create the initial uniform set (bind tex_in for read, tex_out for write)
	_update_uniform_set()

func _process(delta: float) -> void:
	var params := _make_params()
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

func _make_params() -> PackedFloat32Array:
	var t := Time.get_ticks_msec() / 1000.0
	return PackedFloat32Array([
		float(MAX_NODES),             # 0
		t,                            # 1 time_sec
		0.28,                         # 2 grow_chance (start here)
		0.35,                         # 3 grow_angle_variance (0.2..0.5)
		0.0,                          # 4 nearest_nodes_dist_px (unused)
		float(seed),                  # 5 seed (as float)
		0.0, 0.0,                     # 6..7 pad0, pad1 (force start_pos at 16B boundary)
		960.0, 540.0,                 # 8..9 start_pos (center)
		0.0, 0.0,                     # 10..11 pad2, pad3
		0.01,                          # 12 decay_rate (unused)
		0.0,                          # 13 visited_decay (unused)
		0.0,                          # 14 visited_penalty (unused)
		0.0                           # 15 min_life (unused)
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

	var u3 := RDUniform.new()
	u3.binding = 3
	u3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u3.add_id(ubo_rid)

	uniform_set_rid = rd.uniform_set_create([u0, u1, u2, u3], shader_rid, 0)

func _exit_tree() -> void:
	if rd:
		for rid in [shader_rid, pipeline_rid, ubo_rid, node_ssbo_rid, tex_in, tex_out]:
			if rid.is_valid():
				rd.free_rid(rid)
