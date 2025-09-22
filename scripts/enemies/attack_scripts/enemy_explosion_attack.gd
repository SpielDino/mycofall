extends Node

@export_subgroup("Attack Stats")
@export var attack_damage: int = 25
@export var attack_delay: float = 1
@export var lifetime: float = 5

var enemy
var player

var is_in_damage_area: bool = false
var has_taken_damage: bool = false
var started: bool = false

@onready var paricles = $Explosion
@onready var explosion_sound = $ExplosionSound

func _ready():
	player = GlobalPlayer.get_player()
	enemy = get_parent()

func _physics_process(delta):
	if enemy.state == enemy.States.MOVING and !started:
		started = true
		await get_tree().create_timer(lifetime).timeout
		if !enemy.died:
			attack()

func attack():
	enemy.state = enemy.States.ATTACK_TYPE_1
	explode()
	var time_betweeen_explosion_and_queue_free: float = 1
	await get_tree().create_timer(time_betweeen_explosion_and_queue_free).timeout
	enemy.queue_free()

func explode():
	PlayerActionTracker.enemies_exploded += 1
	paricles.emitting = true
	enemy.model.visible = false
	explosion_sound.play()
	enemy.velocity = Vector3(0, 0, 0)
	if !has_taken_damage and is_in_damage_area:
		player.take_damage(attack_damage, self, false, 0)
	has_taken_damage = true

func _on_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player") and enemy.state == enemy.States.MOVING:
		if !enemy.died:
			attack()

func _on_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = true

func _on_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_damage_area = false
