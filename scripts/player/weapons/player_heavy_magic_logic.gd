extends Node3D

@export var dmg: int = 50
@export var tick_rate: float = 1.0
@export var lifetime: float = 4.5

var overlapping_bodies: Array = []
var active: bool = true
var upgrade_dmg: int = 0

func _ready() -> void:
	start_tick_dmg()

func start_tick_dmg():
	tick_dmg()
	await get_tree().create_timer(lifetime).timeout
	active = false
	queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body not in overlapping_bodies:
		if body.is_in_group("Enemy") or body.is_in_group("target_dummy"):
			overlapping_bodies.append(body)
			apply_contact_dmg(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body in overlapping_bodies:
		overlapping_bodies.erase(body)

func tick_dmg():
	if not active:
		return
	await get_tree().create_timer(tick_rate).timeout
	apply_tick_dmg()
	tick_dmg()

func apply_tick_dmg():
	for body in overlapping_bodies:
		get_upgrade_dmg()
		if body.is_in_group("Enemy"):
			body.take_damage(dmg + upgrade_dmg, "Staff")
			var dmg_position = body.get_node_or_null("DamageNumbersPosition")
			if dmg_position:
				DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		if body.is_in_group("target_dummy"):
			var dmg_position = body.get_node_or_null("DamageNumbersPosition")
			if dmg_position:
				DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
			if body.get_node_or_null("AnimationPlayer"):
				body.play_animations(true)

func apply_contact_dmg(body):
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		body.take_damage(dmg + upgrade_dmg, "Staff", true, 1)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
	if body.is_in_group("target_dummy"):
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		if body.get_node_or_null("AnimationPlayer"):
			body.play_animations(true)

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
