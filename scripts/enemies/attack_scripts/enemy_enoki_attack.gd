extends Node3D

@export_group("Attack Stats")
@export var bullet_speed: int = 10
@export var bullet_damage: int = 10
@export var bullet_lifetime: float = 5
@export var attack_speed: float = 1/1.6667
@export_range(0, 1) var homing_strength: float = 0
@export var homing_range: float = 50

@export_subgroup("MeleeAttack")
@export var melee_damage: float = 20

var enemy
var player

var attack_cooldown: float = 0
var throw_timer: float = 0
var punch_timer: float = 0
var idle_timer: float = 0
var in_melee_range: bool = false
var in_melee_damage_area: bool = false
var ranged_attack_delay: float = 0.54

var bullet_scene: PackedScene = preload("res://scenes/prefabs/enemies/enemy_bullet.tscn")

@onready var bullet_spawn_point = $BulletSpawnPoint

func _ready():
	player = GlobalPlayer.get_player()
	enemy = get_parent()

func _physics_process(delta):
	if idle_timer >= 0:
		idle_timer -= delta
	if enemy.state == enemy.States.MOVING:
		enemy.state = enemy.States.ATTACK_TYPE_1
	if enemy.state == enemy.States.ATTACK_TYPE_1 and !enemy.died:
		if idle_timer <= 0:
			if !in_melee_range and punch_timer <= 0:
				rangedAttack(delta)
				enemy.rotate_to_target(player.get_child(0))
			else: 
				meleeAttack(delta)
				throw_timer = 0

func rangedAttack(delta):
	ranged_attack_delay -= delta
	if attack_cooldown <= 0 and enemy.detect_player_raycast() and ranged_attack_delay <= 0:
		var pos: Vector3 = bullet_spawn_point.global_position 
		var vel: Vector3 = player.get_child(0).global_position - pos
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		bullet.setParameter(player, bullet_damage, bullet_speed, homing_range, homing_strength, vel, bullet_lifetime)
		bullet.global_position = pos
		attack_cooldown = 1.0/attack_speed
		throw_timer = 1.6667
	if(attack_cooldown >= 0): 
		attack_cooldown -= delta
	if throw_timer >= 0:
		throw_timer -= delta
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play("Throw")

func meleeAttack(delta):
	if punch_timer <= 0:
		if enemy.slow_rotate_to_player():
			punch_timer = 12.0833
			enemy.animation_player.pause()
	if punch_timer > 0: 
		punch_timer -= delta
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play("Punch")
	if punch_timer <= 11.0833 and punch_timer > 10:
		if in_melee_damage_area:
			player.take_damage(melee_damage, enemy, true, 0)
		punch_timer -= 10

func _on_melee_attack_range_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_range = true

func _on_melee_attack_range_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_range = false

func _on_melee_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_damage_area = true

func _on_melee_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_melee_damage_area = false
