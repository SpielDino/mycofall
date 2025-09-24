extends Node3D

@export_group("Attack Stats")
@export var attack_damage: int = 50
@export var attack_delay: float = 3.333

var enemy
var player

var is_attacking = false
var temp_attack_delay: float = 0
var is_in_attack_range: bool = false
var is_in_damage_range: bool = false
var attacked: bool = false

var particles
var attack_sound

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.get_player()
	await GameManager.game_controller.all_queued_scenes_loaded
	particles = $AttackParticles
	attack_sound = $AttackSound

func _physics_process(delta):
	if enemy.died:
		queue_free()
	attack(delta)

func attack(delta):
	if is_in_attack_range and !enemy.died:
		is_attacking = true
		enemy.state = enemy.States.ATTACK_TYPE_1
		enemy.velocity = Vector3(0, 0, 0)
	if !is_attacking:
		temp_attack_delay = attack_delay
	if is_attacking:
		enemy.velocity = lerp(enemy.velocity, Vector3(0, 0, 0), 0.06)
		if temp_attack_delay > 0:
			enemy.animation_player.speed_scale = 1
			enemy.animation_player.play("attack")
			temp_attack_delay -= delta
		if temp_attack_delay <= 1.333 and !attacked and !enemy.died:
			attack_sound.play()
			attacked = true
			particles.restart()
			particles.emitting = true
			if is_in_damage_range:
				player.take_damage(attack_damage, self, false, 0)
		if temp_attack_delay <= 0:
			attacked = false
			temp_attack_delay = attack_delay
			is_attacking = false
			enemy.state = enemy.States.NONE

func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_range = true

func _on_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_range = false

func _on_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_range = true

func _on_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_range = false
