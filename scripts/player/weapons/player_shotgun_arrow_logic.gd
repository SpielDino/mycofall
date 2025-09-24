extends CharacterBody3D

@export var speed = 40.0
@export var dmg = 15
@export var lifetime = 5

@export_subgroup("Arrow Hit")
@export var arrow_hit_audio: AudioStreamPlayer3D

var hit: bool = false
var upgrade_dmg: int = 0
var start_emitting: bool = false
var start_mesh: bool = false

func _physics_process(delta: float) -> void:
	moving(delta)
	lifetime_of_bullet(delta)
	make_arrow_visible()

func moving(delta):
	if !hit:
		velocity = (transform.basis * Vector3(0, 0, -1) * speed) * delta * (speed*1.5)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func lifetime_of_bullet(delta):
	if !hit:
		lifetime -= delta
		if lifetime < 0:
			queue_free()

func make_arrow_visible():
	if !start_emitting:
		start_emitting = true
		await get_tree().create_timer(0.04).timeout
		var trail = self.get_node_or_null("GPUTrail3D")
		if trail:
			trail.visible = true
	if !start_mesh:
		start_mesh = true
		await get_tree().create_timer(0.01).timeout
		var mesh = self.get_node_or_null("ArrowMesh")
		if mesh:
			mesh.visible = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	attack(body)

func attack(body):
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			var pos = dmg_position.global_position
			var offset = Vector3(
				randf_range(-0.3, 0.3),  # X-axis offset
				randf_range(0.0, 0.6),   # Y-axis offset (usually up a bit)
				randf_range(-0.3, 0.3)   # Z-axis offset
			)
			DamageNumbers.display_number(dmg + upgrade_dmg, pos + offset)
		body.take_damage(dmg + upgrade_dmg, "Bow", true, 2.5)
		arrow_hit_audio.play()
		
	elif body.is_in_group("target_dummy"):
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			var pos = dmg_position.global_position
			var offset = Vector3(
				randf_range(-0.3, 0.3),  # X-axis offset
				randf_range(0.0, 0.6),   # Y-axis offset (usually up a bit)
				randf_range(-0.3, 0.3)   # Z-axis offset
			)
			DamageNumbers.display_number(dmg + upgrade_dmg, pos + offset)
		if body.get_node_or_null("AnimationPlayer"):
			body.play_animations(true)
		arrow_hit_audio.play()
	elif body.is_in_group("weapon"):
		pass
	else:
		hit = true
		self.get_node_or_null("Area3D").queue_free()
		self.get_node_or_null("ArrowMesh").queue_free()
		await get_tree().create_timer(0.59).timeout
		queue_free()

func get_upgrade_dmg():
	if GameManager.get_first_weapon_name() == "Bow":
		match GameManager.get_first_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
	elif GameManager.get_second_weapon_name() == "Bow":
		match GameManager.get_second_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
