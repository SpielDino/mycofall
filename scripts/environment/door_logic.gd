extends Interactable

@export var animation_player: AnimationPlayer

var can_interact: bool = false
var door_open: bool = false

@onready var light_source: DirectionalLight3D = GlobalPlayer.get_light_source()

func _ready() -> void:
	GameManager.weapons_changed.connect(_active_interactable_and_light)
	one_time_use = true

func _active_interactable_and_light():
	if GameManager.get_first_weapon():
		can_interact = true
		one_time_use = false
		light_source.visible = true
	else:
		can_interact = false
		one_time_use = true
		light_source.visible = false

func _on_interacted(body: Variant) -> void:
	if !door_open and can_interact:
		can_interact = false
		one_time_use = true
		door_open = true
		animation_player.play("Door Open Push")
		await get_tree().create_timer(1.25).timeout
		can_interact = true
		one_time_use = false
	elif door_open and can_interact:
		can_interact = false
		one_time_use = true
		door_open = false
		animation_player.play_backwards("Door Open Push")
		await get_tree().create_timer(1.25).timeout
		can_interact = true
		one_time_use = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and can_interact:
		print("true")
		can_interact = false
		one_time_use = true
		door_open = false
		animation_player.play_backwards("Door Open Push")
