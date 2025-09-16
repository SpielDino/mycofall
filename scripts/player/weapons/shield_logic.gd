extends Area3D

signal hitting_with_shield

@export var reset_time: float = 0.3  # small cooldown window

var hit_bodies := {}   # Dictionary or Set to remember which dummies/enemies are hit
var timer := 0.0
var heavy_dmg: int = 200
var is_heavy_dmg: bool = false

func _physics_process(delta: float) -> void:
	if hit_bodies.size() > 0:
		timer += delta
		if timer > reset_time:
			hit_bodies.clear()
			timer = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		hitting_enemy(body)
		hitting_with_shield.emit()
	elif body.is_in_group("target_dummy"):
		hitting_target_dummy(body)
		hitting_with_shield.emit()

func hitting_enemy(body: Node3D) -> void:
	# Only hit if we haven't already hit this body during the current swing
	if not hit_bodies.has(body):
		if GameManager.get_is_heavy_attacking():
			is_heavy_dmg = true
		else:
			is_heavy_dmg = false
		body.take_damage(heavy_dmg, "Sword")
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(heavy_dmg, dmg_position.global_position)
		hit_bodies[body] = true   # mark this body as hit

func hitting_target_dummy(body: Node3D) -> void:
	if not hit_bodies.has(body):
		if GameManager.get_is_heavy_attacking():
			is_heavy_dmg = true
		else:
			is_heavy_dmg = false
		body.play_animations(is_heavy_dmg)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(heavy_dmg, dmg_position.global_position)
		hit_bodies[body] = true
