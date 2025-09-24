extends Node

@export_subgroup("Attack Stats")
@export var attack_damage: int = 25
@export var charge_attack_movement_speed: float = 7
@export var retreat_speed: float = 3
@export var retreat_duration: float = 2

var enemy
var player
var direction

var is_charging: bool = false
var is_retreating: bool = false
var starting_to_charge: bool = false
var has_hit_player: bool = false
var is_in_attack: bool = false
var is_in_attack_area: bool = false

var running_sound
var hit_sound
var talking_sound

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()
	await GameManager.game_controller.all_queued_scenes_loaded
	running_sound = $RunningSound
	hit_sound = $HitSound
	talking_sound = $TalkingSound
func _physics_process(delta):
	if is_in_attack_area and enemy.state == enemy.States.MOVING and !enemy.died:
		ram_start()
	if starting_to_charge:
		enemy.rotate_to_target(player.get_child(0))
	if is_charging:
		charge_movement(direction, charge_attack_movement_speed)
	if is_retreating:
		charge_movement(-direction, retreat_speed)

func ram_start():
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	is_in_attack = true
	has_hit_player = false
	enemy.state = enemy.States.ATTACK_TYPE_1
	starting_to_charge = true
	enemy.animation_player.play("RamStart")
	await get_tree().create_timer(1.2667).timeout #RamStart animation duration
	var player_position = player.get_child(0).global_position
	direction = (player_position - enemy.global_position).normalized()
	starting_to_charge = false
	is_charging = true
	charging()

func charging():
	running_sound.play()
	talking_sound.play()
	enemy.animation_player.play("rammAtack")
	await get_tree().create_timer(5).timeout #Charge duration without hitting anything
	if is_charging:
		ram_stop()

func ram_stop():
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	running_sound.stop()
	talking_sound.stop()
	is_charging = false
	enemy.animation_player.play("RamStop")
	hit_sound.play()
	await get_tree().create_timer(1.6667).timeout #RamStop animation duration
	is_retreating = true
	is_in_attack = false
	enemy.animation_player.play("run")
	await get_tree().create_timer(retreat_duration).timeout 
	is_retreating = false
	enemy.state = enemy.States.NONE

func charge_movement(move_direction, speed):
	var move_vector: Vector3 = move_direction * speed
	enemy.velocity = Vector3(move_vector.x, enemy.velocity.y, move_vector.z)

func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = true

func _on_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player") and !has_hit_player and is_in_attack:
		if is_charging:
			ram_stop()
			await get_tree().create_timer(0.5).timeout #time between hit and damage taken to represent the animtaion better
		player.take_damage(attack_damage, self, true, 1)
		has_hit_player = true

func _on_damage_area_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Enemy") and is_charging:
		ram_stop()
