extends CharacterBody3D

@export var damage: float = 10
@export var speed: float = 10
@export var player: Node3D
@export var vel: Vector3 = Vector3(1,0,0)
@export var explopsion_life_timer: float = 3

var blockCostModifier: float = 0
var has_hit = false
var is_in_slow_area: bool = false

@onready var explosion_effect = $Explosion
@onready var projectile_effect = $Projectile
@onready var explosion_sound = $ExplosionSound

func setParameter(playerInput: Node3D, damageInput: float, speedInput: float, velInput: Vector3):
	player = playerInput
	damage = damageInput
	speed = speedInput
	vel = velInput

func setBlockCostModifier(value):
	blockCostModifier = value

func _physics_process(delta):
	if has_hit:
		explopsion_life_timer -= delta
		if explopsion_life_timer >= 0:
			slow_player()
		else:
			player.get_child(0).is_slowed = false
			queue_free()
	else:
		move(delta)
		move_and_slide()

func move(delta):
	velocity = vel * speed * delta * 50

func explosion():
	has_hit = true
	explosion_sound.play()
	explosion_effect.restart()
	explosion_effect.emitting = true

func slow_player():
	player.get_child(0).is_slowed = false
	if is_in_slow_area:
		player.get_child(0).is_slowed = true

func _on_hit_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player") and !has_hit:
		player.take_damage(damage, self, true, blockCostModifier)
		explosion()

func _on_hit_area_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Enemy") and !has_hit:
		explosion()

func _on_explosion_range_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_slow_area = true

func _on_explosion_range_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		is_in_slow_area = false
