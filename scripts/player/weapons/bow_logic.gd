extends Node3D

@export var ray_position: RayCast3D

@export_subgroup("Bow Shotgun")
@export var bow_shotgun_audio: AudioStreamPlayer3D

@onready var player: Node3D = GlobalPlayer.get_player()
@onready var world = GlobalPlayer.get_world()

var bullet_scene: PackedScene = preload("res://scenes/prefabs/weapons/player_arrow.tscn")
var shotgun_bullet_scene: PackedScene = preload("res://scenes/prefabs/weapons/player_shotgun_arrow.tscn")

func spawn_bullet():
	var bullet_instance = bullet_scene.instantiate()
	var direction = player.get_child(0).get_child(0)
	bullet_instance.position = ray_position.global_position
	bullet_instance.transform.basis = direction.transform.basis
	world.add_child(bullet_instance)

func shotgun_spawn_bullet():
	bow_shotgun_audio.play()
	var direction = player.get_child(0).get_child(0)
	#var angles = [0, 30, -30, 15, -15]
	#var angles = [0, 30, -30, 10, -10, 20, -20]
	#var angles = [0, 30, -30, 10, -10, 20, -20, 5, -5, 15, -15, 25, -25]
	var angles = [0, 20, -20, 5, -5, 10, -10, 15, -15]

	for angle in angles:
		var bullet_instance = shotgun_bullet_scene.instantiate()
		var new_basis = direction.transform.basis.rotated(Vector3.UP, deg_to_rad(angle))
		bullet_instance.position = ray_position.global_position
		bullet_instance.transform.basis = new_basis
		world.add_child(bullet_instance)
