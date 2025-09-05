extends Node3D

@export var animation_tree: AnimationTree
@export var player_controller: CharacterBody3D
@export var sword_hit_box: Area3D

var reset_sword_animation_timer: float = 0
var max_sword_animation_timer: float = 1
var combo_number: int = 0
var combo_timer: float = 0
var max_combo_timer_sword_attack_1: float = 0.5
var max_combo_timer_sword_attack_2: float = 0.3

@onready var movement_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var sword_state_machine_playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine 2/playback")
@onready var sword_attack_blend = animation_tree.tree_root.get_node("SwordAnimation")

func _physics_process(delta: float) -> void:
	sword_attack(delta)
	
func sword_attack(delta):
	if player_controller.velocity.length() > 0.2:
		sword_attack_blend.filter_enabled = true
	else:
		sword_attack_blend.filter_enabled = false
	if !GameManager.get_is_dodging() and Input.is_action_just_pressed("attack") and !GameManager.get_is_sneaking():
		sword_attack_1()
		sword_attack_2()
		sword_attack_3()
		GameManager.set_is_attacking(true)
	if GameManager.get_is_dodging() and GameManager.get_is_attacking():
		change_back_to_movement_animation()
	calc_reset_sword_animation_timer(delta)
	calc_combo_timer(delta)
	
func sword_attack_1():
	if combo_number == 0:
		animation_tree.set("parameters/SwordAnimation/blend_amount", 1)
		sword_state_machine_playback.travel("SwordAttack1")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack1")
		reset_sword_animation_timer = max_sword_animation_timer
		combo_timer = max_combo_timer_sword_attack_1
		combo_number = 1

func sword_attack_2():
	if combo_number == 1 and combo_timer <= 0:
		sword_state_machine_playback.travel("SwordAttack2")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack2")
		reset_sword_animation_timer = max_sword_animation_timer
		combo_timer = max_combo_timer_sword_attack_2
		combo_number = 2
		
func sword_attack_3():
	if combo_number == 2 and combo_timer <= 0:
		sword_state_machine_playback.travel("SwordAttack3")
		sword_hit_box.get_child(1).stop()
		sword_hit_box.get_child(1).play("Attack3")
		reset_sword_animation_timer = max_sword_animation_timer
		combo_number = 3

func calc_reset_sword_animation_timer(delta):
	if combo_number == 1 or combo_number == 2 or combo_number == 3:
		if reset_sword_animation_timer > 0:
			reset_sword_animation_timer -= delta
		elif reset_sword_animation_timer <= 0:
			change_back_to_movement_animation()
			
func calc_combo_timer(delta):
	if combo_timer > 0:
		combo_timer -= delta
		
func change_back_to_movement_animation():
	sword_state_machine_playback.travel("Rest")
	animation_tree.set("parameters/SwordAnimation/blend_amount", 0)
	sword_hit_box.get_child(1).stop()
	combo_number = 0
	GameManager.set_is_attacking(false)
