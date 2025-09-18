extends RayCast3D

signal interacted_with_socket(hit_object)

@export var ray_cast_helper: RayCast3D
@export var ray_cast_helper_2: RayCast3D

var talking_with_old_man: bool = false

# Interacting
@onready var prompt = $Prompt

func _physics_process(delta: float) -> void:
	interacting_with_world()

func interacting_with_world():
	prompt.text = ""
	
	if is_colliding() or ray_cast_helper.is_colliding() or ray_cast_helper_2.is_colliding():
		var hit_object
		if is_colliding():
			hit_object = get_collider()
		elif ray_cast_helper.is_colliding():
			hit_object = ray_cast_helper.get_collider()
		elif ray_cast_helper_2.is_colliding():
			hit_object = ray_cast_helper_2.get_collider()
		if hit_object is Interactable:
			show_interactable_text(hit_object)
			interact_with_socket(hit_object)
			interact_with_upgrade(hit_object)
			interact_with_something(hit_object)
		elif hit_object is InteractableNPC:
			interact_with_npc_for_talking(hit_object)

func show_interactable_text(hit_object):
	if hit_object is Socket and hit_object.get_empty_socket() == true and GameManager.get_first_weapon() == false:
		pass
	elif hit_object.one_time_use:
		pass
	else:
		prompt.text = hit_object.get_prompt(GameManager.get_controller_input_device())

func interact_with_socket(hit_object):
	if Input.is_action_just_pressed(hit_object.prompt_input) and hit_object is Socket:
		interacted_with_socket.emit(hit_object)

func interact_with_upgrade(hit_object):
	if hit_object is Upgrade and Input.is_action_just_pressed(hit_object.prompt_input):
		hit_object.interact(owner)

func interact_with_npc_for_talking(hit_object):
	if !talking_with_old_man:
		show_interactable_text(hit_object)
		if Input.is_action_just_pressed(hit_object.prompt_input) and hit_object is OldMan:
			talking_with_old_man = true
			hit_object.interact(owner)
			await get_tree().create_timer(5).timeout
			talking_with_old_man = false

func interact_with_something(hit_object):
	if !hit_object.one_time_use:
		if Input.is_action_just_pressed(hit_object.prompt_input) and hit_object is not Socket and hit_object is not Upgrade:
			hit_object.interact(owner)
			print("yeah")
