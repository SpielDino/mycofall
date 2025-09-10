extends Area3D

@export var reset_time: float = 0.3  # small cooldown window

var hit_bodies := {}   # Dictionary or Set to remember which dummies/enemies are hit
var timer := 0.0

func _physics_process(delta: float) -> void:
	if hit_bodies.size() > 0:
		timer += delta
		if timer > reset_time:
			hit_bodies.clear()
			timer = 0.0


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		hitting_enemy(body)
	elif body.is_in_group("target_dummy"):
		hitting_target_dummy(body)


func hitting_enemy(body: Node3D) -> void:
	# Only hit if we haven't already hit this body during the current swing
	if not hit_bodies.has(body):
		body.take_damage(50)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(50, dmg_position.global_position)
		hit_bodies[body] = true   # mark this body as hit


func hitting_target_dummy(body: Node3D) -> void:
	if not hit_bodies.has(body):
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(50, dmg_position.global_position)
		hit_bodies[body] = true
