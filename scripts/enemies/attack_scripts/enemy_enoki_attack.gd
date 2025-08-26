extends Node3D

@export_subgroup("Attack Stats")
@export var bullet_speed: int = 1
@export var bullet_damage: int = 10
@export var bullet_lifetime: float = 5
@export var attack_speed: float = 1/1.6667
@export_range(0, 1) var homing_strength: float = 0
@export var homing_range: float = 50

@export_subgroup("MeleeAttack")
@export var melee_damage: float = 20

var enemy
var player

var is_attacking = false
var attack_cooldown: float = 0
var is_in_inner_attack_area: bool = false
var is_in_outer_attack_area: bool = false
#var bullet_scene: PackedScene = preload("res://scenes/prefabs/enemies/enemy_bullet.tscn")
var got_attacked_time: float = 0
var throw_timer: float = 0
var punch_timer: float = 0

var idle_timer: float = 0
var in_melee_range: bool = false
var in_melee_damage_area: bool = false
var ranged_attack_delay: float = 0.54

@onready var bullet_spawn_point = $BulletSpawnPoint

func _ready():
	player = GlobalPlayer.getPlayer()
	enemy = get_parent()

func _physics_process(delta):
	if idle_timer >= 0:
		idle_timer -= delta
	if enemy.state == enemy.States.ATTACK_TYPE_1:
		if idle_timer <= 0:
			if !in_melee_range:
				rangedAttack(delta)
				rotateToPlayer()
			else: 
				meleeAttack(delta)

func rotateToPlayer():
	var angle_vector = player.get_child(0).global_position  - enemy.global_position 
	var angle = atan2(angle_vector.x, angle_vector.z)
	enemy.rotation.y = angle - PI/2

func rangedAttack(delta):
	ranged_attack_delay -= delta
	if attack_cooldown <= 0 and enemy.detect_player_raycast() and ranged_attack_delay <= 0:
		var pos: Vector3 = bullet_spawn_point.global_position 
		var vel: Vector3 = player.get_child(0).global_position - pos
		#var bullet = bullet_scene.instantiate()
		#bullet.setParameter(player, bullet_damage, bullet_speed, homing_range, homing_strength, vel, bullet_lifetime)
		#self.add_child(bullet)
		#bullet.global_position = pos
		attack_cooldown = 1.0/attack_speed
		throw_timer = 1.6667
	if(attack_cooldown >= 0): 
		attack_cooldown -= delta
	if throw_timer >= 0:
		throw_timer -= delta
		enemy.animationPlayer.play("Throw")

func slowRotateToPlayer(delta):
	var angle_vector = player.get_child(0).global_position - enemy.global_position 
	var angle = atan2(angle_vector.x, angle_vector.z)  - PI/2
	var angle_in_degrees = angle * 180 / PI
	var rotation_in_degrees = enemy.rotation_degrees.y
	var yRotation = enemy.rotation.y
	if angle_in_degrees < -360:
		angle_in_degrees += 360
		angle += 2*PI
	if angle_in_degrees < 0:
		angle_in_degrees += 360
		angle += 2*PI
	if rotation_in_degrees < -360:
		rotation_in_degrees += 360
		yRotation += 2*PI
	if rotation_in_degrees < 0:
		rotation_in_degrees += 360
		yRotation += 2*PI
	if angle_in_degrees + 180 < rotation_in_degrees:
		enemy.rotation.y = lerp(yRotation, angle + 2*PI, 0.2)
	elif rotation_in_degrees + 180 < angle_in_degrees:
		enemy.rotation.y = lerp(yRotation + 2*PI, angle, 0.2)
	elif abs(angle_in_degrees - rotation_in_degrees) > 5:
		enemy.rotation.y = lerp(yRotation, angle, 0.2)
	if abs(angle_in_degrees - rotation_in_degrees) < 5:
		return true
	return false

func meleeAttack(delta):
	if punch_timer <= 0:
		if slowRotateToPlayer(delta):
			punch_timer = 12.0833
			enemy.animationPlayer.pause()
	if punch_timer > 0: 
		punch_timer -= delta
		enemy.animationPlayer.play("Punch")
	if punch_timer <= 11.0833 and punch_timer > 10:
		if in_melee_damage_area:
			player.takeDamage(melee_damage, enemy, true, 0)
		punch_timer -= 10


func _on_melee_attack_range_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_melee_attack_range_exited(area: Area3D) -> void:
	pass # Replace with function body.


func _on_ranged_attack_range_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_ranged_attack_range_exited(area: Area3D) -> void:
	pass # Replace with function body.
