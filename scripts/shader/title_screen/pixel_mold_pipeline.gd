extends MarginContainer

const STEPS_PER_SEC := 750
const MAX_NODES := 10
const WORKGROUPS := Vector3i(32, 32, 1)

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
var title_tex_rd: RID
var title_sampler: RID

var texA: RID  # first storage texture
var texB: RID  # second storage texture
var set_ab: RID  # read A, write B (includes node SSBO, UBO, sampler)
var set_ba: RID  # read B, write A
var ping_ab := true   # true -> next dispatch uses set_ab
var sim_time := 0.0   # optional running sim time
var current_output: RID = texB  # last written RID to display

@onready var sprite: Sprite2D = $Title

var seed: int = randi()
var node_positions := PackedFloat32Array()

func _ready() -> void:
	rd = RenderingServer.get_rendering_device()

	# 1) Create two storage-capable RGBA32F textures for ping‑pong
	var fmt := RDTextureFormat.new()
	fmt.width = texture_width
	fmt.height = texture_height
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var view := RDTextureView.new()
	texA = rd.texture_create(fmt, view, [])
	texB = rd.texture_create(fmt, view, [])

	# 2) Display sprite shows the "current_output"
	texrd = Texture2DRD.new()
	current_output = texB  # will be last written after first dispatch
	texrd.texture_rd_rid = current_output
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = get_viewport_rect().size * 0.5
	sprite.position.y -= get_viewport_rect().size.y * 0.2
	sprite.scale = Vector2(0.5, 0.5)
	sprite.texture = texrd
	add_child(sprite)

	# 3) Load title texture and sampler (use NEAREST to avoid edge bleed)
	var title_tex: Texture2D = load("res://assets/textures/ui_textures/title_screen/title.png")
	var img: Image = title_tex.get_image()
	img.convert(Image.FORMAT_RGBAF)
	var tf := RDTextureFormat.new()
	tf.width = img.get_width()
	tf.height = img.get_height()
	tf.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	title_tex_rd = rd.texture_create(tf, RDTextureView.new(), [img.get_data()])

	var samp := RDSamplerState.new()
	samp.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samp.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samp.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	samp.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	title_sampler = rd.sampler_create(samp)

	# 4) Create pipeline and UBO
	var rd_file: RDShaderFile = load("res://scripts/shader/title_screen/pixel_mold_dijkstra_compute.glsl")
	var spirv: RDShaderSPIRV = rd_file.get_spirv()
	shader_rid = rd.shader_create_from_spirv(spirv)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	ubo_rid = rd.uniform_buffer_create(_make_params(0.0).size() * 4, _make_params(0.0).to_byte_array())

	# 5) Build two uniform sets: read A -> write B, and read B -> write A
	_build_pingpong_uniform_sets()

	# Optional: run a single clear/seed step so texB is initialized
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline_rid)
	rd.compute_list_bind_uniform_set(cl, set_ab, 0)  # first pass reads A (zeros), writes B
	rd.compute_list_dispatch(cl,
		int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
		int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
	rd.compute_list_end()
	current_output = texB
	ping_ab = false  # next pass will read B -> write A

func _process(delta: float) -> void:
	var target := STEPS_PER_SEC * delta
	var steps := int(target)
	var remainder := target - float(steps)
	if randf() < remainder:
		steps += 1

	var dt_step := delta / float(steps) if (steps > 0) else 0.0

	for i in steps:
		sim_time += dt_step
		var params := _make_params(dt_step)
		rd.buffer_update(ubo_rid, 0, params.size() * 4, params.to_byte_array())

		var cl := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(cl, pipeline_rid)
		rd.compute_list_bind_uniform_set(cl, set_ab if ping_ab else set_ba, 0)
		rd.compute_list_dispatch(cl,
			int((texture_width  + WORKGROUPS.x - 1) / WORKGROUPS.x),
			int((texture_height + WORKGROUPS.y - 1) / WORKGROUPS.y), 1)
		rd.compute_list_end()

		current_output = texB if ping_ab else texA
		ping_ab = !ping_ab
		
	texrd.texture_rd_rid = current_output
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

	var u3 := RDUniform.new()
	u3.binding = 3
	u3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u3.add_id(ubo_rid)
	
	var u4 := RDUniform.new()
	u4.binding = 4
	u4.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u4.add_id(title_sampler)
	u4.add_id(title_tex_rd)

	uniform_set_rid = rd.uniform_set_create([u0, u1, u3, u4], shader_rid, 0)

func _build_pingpong_uniform_sets() -> void:
	# Set AB: read texA, write texB
	var a0 := RDUniform.new(); a0.binding = 0; a0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE; a0.add_id(texA)
	var a1 := RDUniform.new(); a1.binding = 1; a1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE; a1.add_id(texB)
	var a3 := RDUniform.new(); a3.binding = 3; a3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER; a3.add_id(ubo_rid)
	var a4 := RDUniform.new(); a4.binding = 4; a4.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE; a4.add_id(title_sampler); a4.add_id(title_tex_rd)
	set_ab = rd.uniform_set_create([a0, a1, a3, a4], shader_rid, 0)

	# Set BA: read texB, write texA
	var b0 := RDUniform.new(); b0.binding = 0; b0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE; b0.add_id(texB)
	var b1 := RDUniform.new(); b1.binding = 1; b1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE; b1.add_id(texA)
	var b3 := RDUniform.new(); b3.binding = 3; b3.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER; b3.add_id(ubo_rid)
	var b4 := RDUniform.new(); b4.binding = 4; b4.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE; b4.add_id(title_sampler); b4.add_id(title_tex_rd)
	set_ba = rd.uniform_set_create([b0, b1, b3, b4], shader_rid, 0)
	
#func _exit_tree() -> void:
	#if rd:
		#for rid in [shader_rid, pipeline_rid, ubo_rid, texA, texB, title_tex_rd, set_ab, set_ba, title_sampler]:
			#if rid is RID and rid.is_valid():
				#rd.free_rid(rid)
