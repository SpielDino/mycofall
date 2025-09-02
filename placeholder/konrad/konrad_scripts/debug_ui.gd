extends Node

@export var controller: Node3D

@export var input: RichTextLabel
@export var xyz: RichTextLabel
@export var speed: RichTextLabel
@export var sneaking: RichTextLabel
@export var in_detection_area: RichTextLabel
@export var in_hiding_area: RichTextLabel
@export var detected: RichTextLabel
@export var hidden: RichTextLabel
@export var health: RichTextLabel
@export var stamina: RichTextLabel
@export var mana: RichTextLabel

var player: Node3D

func _ready():
	player = GlobalPlayer.get_player()

func _physics_process(delta):
	input.text = str(Input.get_vector("move_left", "move_right", "move_forward", "move_backward"))
	xyz.text = "(" + str(round_to_2(controller.transform.origin.x)) + ", " + str(round_to_2(controller.transform.origin.y)) + ", " + str(round_to_2(controller.transform.origin.z)) + ")"
	speed.text = "(" + str(round_to_2(controller.velocity.x)) + ", " + str(round_to_2(controller.velocity.y)) + ", " + str(round_to_2(controller.velocity.z)) + ")"
	sneaking.text = str(player.is_sneaking)
	in_detection_area.text = str(player.is_in_detection_area)
	in_hiding_area.text = str(player.is_in_hiding_area)
	detected.text = str(player.is_detected)
	hidden.text = str(player.is_hidden)
	health.text = str(player.health)
	stamina.text = str(player.stamina)
	mana.text = str(player.mana)

func round_to_2(num):
	return round(num * pow(10.0, 2)) / pow(10.0, 2)
