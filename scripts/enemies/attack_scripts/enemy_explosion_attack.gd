extends Node

@export_subgroup("Attack Stats")
@export var attack_damage: int = 25
@export var attack_delay: float = 1
@export var lifetime: float = 5

var enemy
var player
var is_in_attack_area: bool = false
var is_in_damage_area: bool = false
var has_taken_damage: bool = false

@onready var paricles = $Explosion

func _ready():
	player = GlobalPlayer.get_player()
	enemy = get_parent()

func _physics_process(delta):
	attack(delta)

func attack(delta):
	if is_in_attack_area or attack_delay < 1:
		attack_delay -= delta
		if attack_delay <= 1:
			enemy.state = enemy.States.ATTACK_TYPE_1
			explode()
		if attack_delay <= 0:
			enemy.queue_free()

func explode():
	paricles.emitting = true
	enemy.model.visible = false
	#$ExplosionAudio.play()
	enemy.velocity = Vector3(0, 0, 0)
	if !has_taken_damage and is_in_damage_area:
		player.take_damage(attack_damage, self, false, 0)
	has_taken_damage = true

func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_attack_area = true

func _on_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = true

func _on_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = false
