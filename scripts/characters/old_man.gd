extends InteractableNPC
class_name OldMan

@export var old_man_animation_player: AnimationPlayer
@export var old_man_audio: AudioStreamPlayer3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var played_animation = false
var played_animation_2 = false
var talked_animation = false
var talking_animation = false
var walking = false
var lol = true

@onready var player: Node3D = GlobalPlayer.get_player()
@onready var text_position = self.get_node_or_null("TextPosition")

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	if lol:
		move_for_x_amount_of_sec_at_start(5)
	#else:
		#move_and_slide()

func apply_gravity(delta):
	velocity.y += -gravity * delta

func playing_walking_animation():
	old_man_animation_player.play("Walking")

func playing_talking_animation():
	old_man_animation_player.play("Talking")

func playing_idle_animation():
	old_man_animation_player.play("Idle")

func move_for_x_amount_of_sec_at_start(check: float):
	if !played_animation:
		played_animation = true
		playing_walking_animation()
		walking = true
	if walking:
		velocity.z = 0.6
		velocity.x = -0.4
		move_and_slide()
		if !played_animation_2:
			played_animation_2 = true
			await get_tree().create_timer(check).timeout
			if text_position:
				DamageNumbers.display_text("Come here you lil' mushroom", text_position.global_position, 2)
			playing_idle_animation()
			velocity.z = 0
			velocity.x = 0
			walking = false
			lol = false


func _on_interacted(body: Variant) -> void:
	if !talked_animation:
		playing_talking_animation()
		talked_animation = true
		talking_animation = true
		var npc_pos = global_transform.origin
		var player_pos = player.get_child(0).global_transform.origin
		player_pos.y = npc_pos.y  # keep same height so he only rotates horizontally
		look_at(player_pos, Vector3.UP, true)
		DamageNumbers.display_text("Pick a weapon and start slaying", text_position.global_position, 5)
	if talking_animation:
		talking_animation = false
		#old_man_audio.play(10)
		play_offset_audio()
		await get_tree().create_timer(5).timeout
		playing_idle_animation()
		old_man_audio.stop()
		talked_animation = false


func play_offset_audio():
	var offset = randf_range(0.0, 8.0)
	old_man_audio.play(offset)
