extends RayCast3D

signal interacted_with_socket(hit_object)
signal interacted_with_upgrade_item

# Interacting
@onready var prompt = $Prompt

func _physics_process(delta: float) -> void:
	interacting_with_world()

func interacting_with_world():
	prompt.text = ""
	
	if is_colliding():
		var hit_object = get_collider()
		if hit_object is Interactable:
			show_interactable_text(hit_object)
			interact_with_socket(hit_object)

func show_interactable_text(hit_object):
	if hit_object is Socket and hit_object.get_empty_socket() == true and GameManager.get_first_weapon() == false:
		pass
	else:
		prompt.text = hit_object.get_prompt(GameManager.get_controller_input_device())

func interact_with_socket(hit_object):
	if Input.is_action_just_pressed(hit_object.prompt_input) and hit_object is Socket:
		interacted_with_socket.emit(hit_object)
