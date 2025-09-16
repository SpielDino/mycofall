extends Area3D

@export var timer: float = 0.0

var hit = false

func _physics_process(delta: float) -> void:
	if hit:
		timer += delta
		if timer > 0.01:
			timer = 0.0
			hit = false

func _on_body_entered(body: Node3D) -> void:
	hitting_enemy(body)
	hitting_target_dummy(body)
		
func hitting_enemy(body):
	if body.is_in_group("Enemy") and !hit:
		body.take_damage(50)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		DamageNumbers.display_number(50, dmg_position.global_position)
		#print("enemy hit")
		hit = true

func hitting_target_dummy(body):
	if body.is_in_group("target_dummy") and !hit:
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		DamageNumbers.display_number(50, dmg_position.global_position)
		hit = true
