extends Node3D

@export var speed = 40.0
@export var dmg = 20
@export var lifetime = 5

var upgrade_dmg: int = 0

func _physics_process(delta: float) -> void:
	moving(delta)
	lifetime_of_bullet(delta)

func moving(delta):
		position += transform.basis * Vector3(0, 0, -speed) * delta

func lifetime_of_bullet(delta):
	lifetime -= delta
	if lifetime < 0:
		queue_free()

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
		body.take_damage(dmg + upgrade_dmg, "Bow", true, 1)
		
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
	elif body.is_in_group("weapon"):
		pass
	else:
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
