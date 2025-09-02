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

#@onready var particles = $root/AttackParticles #TODO implement later

func _ready():
	enemy = get_parent()
	player = GlobalPlayer.getPlayer()

func _physics_process(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
	elif attack_cooldown <= 0:
		is_attacking = false

func attack(delta):
	if !is_attacking:
		attack_cooldown = (1/attackSpeed) + 5
	if is_in_inner_attack_area:
		is_attacking = true
		enemy.state = enemy.States.ATTACK_TYPE_1
	if is_attacking and enemy.deathTimer == 10:
		enemy.animation_player.play("Bump")
		if attack_cooldown <= 5.42 and attack_cooldown > 5:
			if is_in_outer_attack_area:
				#particles.restart()
				#particles.emitting = true
				player.takeDamage(attackDamage, self, true, 0)
				attack_cooldown -= 5

func _on_inner_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		var is_in_inner_attack_area: bool = true

func _on_inner_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		var is_in_inner_attack_area: bool = false

func _on_outer_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		var is_in_outer_attack_area: bool = true

func _on_outer_attack_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		if is_in_outer_attack_area: 
			enemy.state = enemy.States.NONE
			var is_in_outer_attack_area: bool = false
