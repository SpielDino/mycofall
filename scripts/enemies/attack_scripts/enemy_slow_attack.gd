extends Node

@export_group("Attack Stats")
@export var bullet_speed: int = 1
@export var bullet_damage: int = 10
@export var attack_speed: float = 0.2

var enemy
var player

var attack_cooldown: float = 0
var is_in_attack_area: bool = false
var attack_timer: float = 0
var has_fired: bool = false

var bullet_scene: PackedScene = preload("res://scenes/prefabs/enemies/enemy_spider_bullet.tscn")

@onready var bullet_spawn_point = $BulletSpawnPoint
@onready var attack_sound = $AttackSound

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()

func _physics_process(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if is_in_attack_area and enemy.state == enemy.States.MOVING and attack_cooldown <= 0 and !enemy.died:
		enemy.state = enemy.States.ATTACK_TYPE_1
		attack_cooldown = 1/attack_speed
		attack_timer = 1.6667
		enemy.rotate_to_target(player.get_child(0))
		has_fired = false
	if enemy.state == enemy.States.ATTACK_TYPE_1:
		attack(delta)
	if attack_timer >= 0:
		attack_timer -= delta

func attack(delta):
	enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	enemy.animation_player.play("Attack")
	if attack_timer <= 1.6667 - 0.45:
		if !has_fired:
			attack_sound.play()
			var pos: Vector3 = bullet_spawn_point.global_position
			var vel: Vector3 = (player.get_child(0).global_position - pos).normalized()
			var bullet = bullet_scene.instantiate()
			bullet.setParameter(player, bullet_damage, bullet_speed, vel)
			get_tree().root.add_child(bullet)
			bullet.global_position = pos
			has_fired = true
	if attack_timer <= 0:
		enemy.state = enemy.States.NONE

func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = true

func _on_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = false
