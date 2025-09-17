extends Node3D

@export var speed = 10.0
@export var dmg = 50
@export var lifetime = 5

var enemy_position_for_tracking
var tracking = false
var directions
var upgrade_dmg: int = 0

func _physics_process(delta: float) -> void:
	moving(delta)
	lifetime_of_bullet(delta)
	
func moving(delta):
	if !tracking:
		position += transform.basis * Vector3(0, 0, -speed) * delta
	elif tracking:
		directions = (enemy_position_for_tracking.global_position - global_position).normalized()
		position += directions * speed * delta

func _on_area_3d_body_entered(body: Node3D) -> void:
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		body.take_damage(dmg + upgrade_dmg, "Staff")
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		queue_free()
		#print("hit")
	elif body.is_in_group("target_dummy"):
		#print("dummy hit")
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		body.play_animations(false)
		queue_free()
	else:
		queue_free()
		#print("bullet despawned")

func lifetime_of_bullet(delta):
	lifetime -= delta
	if lifetime < 0:
		queue_free()
		#print("bullet despawned")

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy") and !tracking:
		enemy_position_for_tracking = body
		tracking = true
		#print(tracking)
		#print(enemy_position_for_tracking)
		#print("hallo enemy")

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy") and tracking:
		tracking = false

func get_upgrade_dmg():
	if GameManager.get_first_weapon_name() == "Staff":
		match GameManager.get_first_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
	elif GameManager.get_second_weapon_name() == "Staff":
		match GameManager.get_second_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
