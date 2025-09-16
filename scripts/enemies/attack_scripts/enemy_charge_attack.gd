extends Node

@export_subgroup("Attack Stats")
@export var attack_damage: int = 25
@export var attack_speed: float = 1
@export var attack_delay: float = 0
@export var charge_attack_movement_speed: float = 7

var enemy
var player

var is_attacking = false
var attack_cooldown: float = 0
var is_in_attack_area: bool = false
var is_in_damage_area: bool = false
var has_collided_with_body: bool = false
var hitbox 
var player_position
var direction

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()
	hitbox = enemy.get_child(6)

func _physics_process(delta):
	if attack_delay > 0:
		attack_delay -= delta
	if is_in_attack_area and enemy.state == enemy.States.MOVING:
		enemy.state = enemy.States.ATTACK_TYPE_1
	if enemy.state == enemy.States.ATTACK_TYPE_1:
		attack(delta)

func attack(delta):
	if attack_delay <= 0:
		attack_delay = 10
	if attack_delay >= 10 - 1.25:
		enemy.velocity = Vector3(0, enemy.velocity.y, 0)
		enemy.animation_player.play("RamStart")
		player_position = player.get_child(0).global_position
		direction = (player_position - enemy.global_position).normalized()
		enemy.rotate_to_target(player.get_child(0))
		hitbox.rotation.z = (-85.0 / 360 * 2*PI)
	if attack_delay < 10 - 1.25 and attack_delay > 5:
		enemy.animation_player.play("rammAtack")
		var move_vector: Vector3 = direction * charge_attack_movement_speed
		print(move_vector)
		enemy.velocity = Vector3(move_vector.x, enemy.velocity.y, move_vector.z)
		enemy.move_and_slide()
		print(enemy.velocity)
	if is_in_damage_area or attack_delay <= 5 or has_collided_with_body: 
		if is_in_damage_area:
			player.take_damage(attack_damage, self, true, 1)
		if attack_delay > 5:
			attack_delay = 5
		is_in_damage_area = false
		has_collided_with_body = false
		enemy.animation_player.play("RamStop")
	if attack_delay <= 5 - 1.25:
		enemy.state = enemy.States.NONE
		attack_delay = 0


func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = true

func _on_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = false

func _on_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = true

func _on_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = false

func _on_damage_area_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Enemy"):
		has_collided_with_body = true
