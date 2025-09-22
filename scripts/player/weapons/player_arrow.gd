extends Node3D

@export var speed = 40.0
@export var dmg = 30
@export var lifetime = 5

@export_subgroup("Arrow Hit")
@export var arrow_hit_audio: AudioStreamPlayer3D

var extra_dmg
var total_dmg
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
	extra_dmg = GameManager.get_bow_attack_timer()
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		total_dmg = dmg * extra_dmg
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(total_dmg + upgrade_dmg, dmg_position.global_position)
		body.take_damage(total_dmg + upgrade_dmg, "Bow")
		# Normal or somewhat charged Bow Attack
		if extra_dmg < 4:
			arrow_hit_audio.play()
			self.get_node_or_null("Area3D").queue_free()
			self.get_node_or_null("ArrowMesh").queue_free()
			await get_tree().create_timer(0.59).timeout
			queue_free()
		# Fully Charged Bow Attack pierces enemies
		elif extra_dmg >= 4:
			arrow_hit_audio.play()
			pass
			
	elif body.is_in_group("target_dummy"):
		total_dmg = dmg * extra_dmg
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if body.get_node_or_null("AnimationPlayer"):
			body.play_animations(false)
		if dmg_position:
			DamageNumbers.display_number(total_dmg + upgrade_dmg, dmg_position.global_position)
		# Normal or somewhat charged Bow Attack
		if extra_dmg < 4:
			arrow_hit_audio.play()
			self.get_node_or_null("Area3D").queue_free()
			self.get_node_or_null("ArrowMesh").queue_free()
			await get_tree().create_timer(0.59).timeout
			queue_free()
		# Fully Charged Bow Attack pierces enemies
		elif extra_dmg >= 4:
			arrow_hit_audio.play()
			pass
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
