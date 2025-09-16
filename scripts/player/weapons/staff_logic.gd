extends Node3D

@export var mana_cost_per_attack: int = 60
@export var ray_position: RayCast3D

@onready var player: Node3D = GlobalPlayer.get_player()
@onready var world = GlobalPlayer.get_world()

var bullet_scene: PackedScene = preload("res://scenes/prefabs/weapons/player_bullet.tscn")
var heavy_magic_scene: PackedScene = preload("res://scenes/prefabs/weapons/player_heavy_magic.tscn")

func spawn_bullet():
	var bullet_instance = bullet_scene.instantiate()
	var direction = player.get_child(0).get_child(0)
	bullet_instance.position = ray_position.global_position
	bullet_instance.transform.basis = direction.transform.basis
	world.add_child(bullet_instance)

func magic_attack():
	if player.mana >= mana_cost_per_attack:
		player.reduce_mana(mana_cost_per_attack)
		#print("-" + str(mana_cost_per_attack))
		spawn_bullet()

func heavy_magic_attack():
	var heavy_magic_instance = heavy_magic_scene.instantiate()
	var spawn_position = self.global_position
	heavy_magic_instance.position = spawn_position
	world.add_child(heavy_magic_instance)
