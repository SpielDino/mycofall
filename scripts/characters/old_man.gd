extends InteractableNPC
class_name OldMan

@export var old_man_animation_player: AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var played_animation = false
var played_animation_2 = false
var talked_animation = false
var talking_animation = false
var walking = false

@onready var player: Node3D = GlobalPlayer.get_player()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()

func apply_gravity(delta):
	velocity.y += -gravity * delta

func playing_walking_animation():
	old_man_animation_player.play("Walking")

func playing_talking_animation():
	old_man_animation_player.play("Talking")

func playing_idle_animation():
	old_man_animation_player.play("Idle")

func move_for_x_amount_of_sec(check: float):
	if !played_animation:
		played_animation = true
		playing_walking_animation()
		walking = true
	if walking:
		velocity.z = 0.5
		move_and_slide()
		if !played_animation_2:
			played_animation_2 = true
			await get_tree().create_timer(check).timeout
			playing_idle_animation()
			walking = false

#await get_tree().create_timer(2.09).timeout

func _on_interacted(body: Variant) -> void:
	if !talked_animation:
		playing_talking_animation()
		talked_animation = true
		talking_animation = true
		var npc_pos = global_transform.origin
		var player_pos = player.get_child(0).global_transform.origin
		player_pos.y = npc_pos.y  # keep same height so he only rotates horizontally
		look_at(player_pos, Vector3.UP, true)
	if talking_animation:
		talking_animation = false
		await get_tree().create_timer(5).timeout
		playing_idle_animation()
		talked_animation = false
