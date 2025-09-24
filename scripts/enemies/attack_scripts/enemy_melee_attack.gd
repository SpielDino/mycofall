extends Node

@export_subgroup("Attack Stats")
@export var attackDamage: int = 10
@export var attackSpeed: float = 1/0.7917
@export var attackDelay: float = -0.1

var enemy
var player

var is_attacking = false
var attack_cooldown: float = 0
var is_in_inner_attack_area: bool = false
var is_in_outer_attack_area: bool = false

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
	if attack_cooldown > 0:
		attack_cooldown -= delta
	elif attack_cooldown <= 0:
		is_attacking = false
		enemy.state = enemy.States.NONE
	attack(delta)

func attack(delta):
	if !is_attacking:
		attack_cooldown = (1/attackSpeed) + 5
	if is_in_inner_attack_area and !is_attacking:
		is_attacking = true
		enemy.state = enemy.States.ATTACK_TYPE_1
		enemy.velocity = Vector3(0, enemy.velocity.y, 0)
	if is_attacking and !enemy.died:
		enemy.velocity = lerp(enemy.velocity, Vector3(0, 0, 0), 0.03)
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play("Bump")
		if attack_cooldown <= 5.42 and attack_cooldown > 5:
			attack_sound.play()
			particles.restart()
			particles.emitting = true
			attack_cooldown -= 5
			if is_in_outer_attack_area:
				player.take_damage(attackDamage, self, true, 0)

func _on_inner_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_inner_attack_area = true

func _on_inner_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_inner_attack_area = false

func _on_outer_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_outer_attack_area = true

func _on_outer_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_outer_attack_area = false
