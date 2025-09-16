extends Node3D

@export var speed = 40.0
@export var dmg = 30
@export var lifetime = 5

var extra_dmg
var total_dmg

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
	if body.is_in_group("enemy"):
		total_dmg = dmg * extra_dmg
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		DamageNumbers.display_number(total_dmg, dmg_position.global_position)
		body.takeDamage(total_dmg)
		# Normal or somewhat charged Bow Attack
		if extra_dmg < 4:
			queue_free()
		# Fully Charged Bow Attack pierces enemies
		elif extra_dmg >= 4:
			pass
			
	elif body.is_in_group("target_dummy"):
		total_dmg = dmg * extra_dmg
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		body.play_animations(false)
		DamageNumbers.display_number(total_dmg, dmg_position.global_position)
		# Normal or somewhat charged Bow Attack
		if extra_dmg < 4:
			queue_free()
		# Fully Charged Bow Attack pierces enemies
		elif extra_dmg >= 4:
			pass
	elif body.is_in_group("weapon"):
		pass
	else:
		queue_free()
