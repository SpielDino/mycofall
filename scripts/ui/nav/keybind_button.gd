class_name KeybindButton
extends Control

const BASE_PATH_KEYS: String = "res://assets/textures/ui_textures/menus/Keys/"

@onready var label: Label = $KeybindContainer/Label
@onready var button: TextureButton = $KeybindContainer/HBoxContainer/key
@onready var texture: TextureRect = $KeybindContainer/HBoxContainer/key/TextureRect
@onready var press_key_label: Label = $KeybindContainer/HBoxContainer/key/Label

@export var action_name: String;

var _current_action_event: InputEvent;
var _current_key: String = "W";

func _ready() -> void:
	set_process_unhandled_input(false)
	set_action_name()
	set_texture_for_key()
	load_keybind()
	button.toggle_mode = true
	
func load_keybind() -> void:
	rebind_action_key(SettingsDataContainer.get_keybind(action_name))
	
func set_action_name() -> void:
	label.text = "KEY_" + action_name.to_upper();

func set_texture_for_key() -> void:
	var action_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	
	if len(action_events) == 0:
		push_warning("No action events found for the following input action: ", action_name);
		return
	print(action_name)
	print(SettingsDataContainer.get_keybind(action_name))
	for action_event in action_events: 
		var action_keycode: int = action_event.physical_keycode if action_event is InputEventKey else action_event.button_index
		if OS.find_keycode_from_string(_current_key) == action_keycode:
			_current_action_event = action_event
	
	
	texture.texture = load(BASE_PATH_KEYS + _current_key + ".png")

func _on_key_toggled(button_pressed: bool) -> void:
	#print(button_pressed)
	if button_pressed:
		texture.visible = false
		press_key_label.visible = true
		set_process_unhandled_input(true)
		
		for i in get_tree().get_nodes_in_group("keybind_button"):
			if i.action_name != self.action_name:
				i.button.toggle_mode = false;
				i.set_process_unhandled_input(false);
	else: 
		texture.visible = true
		press_key_label.visible = false
		for i in get_tree().get_nodes_in_group("keybind_button"):
			if i.action_name != self.action_name:
				i.button.toggle_mode = true;
				i.set_process_unhandled_input(false);
				
		set_texture_for_key()

func _unhandled_input(event: InputEvent) -> void:
	#print(event)
	rebind_action_key(event)
	button.button_pressed = false

func rebind_action_key(event) -> void:
	print("new binding: ", event)
	var new_key: String = OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "MOUSE%d" % event.button_index
	#print("curretn: ", event)
	for i in get_tree().get_nodes_in_group("keybind_button"):
		print("other button: ", i)
		if i.action_name != self.action_name:
			print("check texture of others: ", i.texture)
			print("double key: ", new_key)
			if i.texture.texture == null: continue;
			if i.texture.texture.resource_path.get_file().get_basename() == new_key:
				print("double key: ", new_key)
				press_key_label.text = "ALREADY USED!  CHOOSE ANOTHER"
				set_process_unhandled_input(true);
				return
	if _current_action_event != null:
		InputMap.action_erase_event(action_name, _current_action_event);
	else: 
		InputMap.action_erase_events(action_name);

	InputMap.action_add_event(action_name, event);
	if event is InputEventMouseButton:
		print(new_key)
	_current_key = new_key
	SettingsDataContainer.set_keybind(action_name, event)
	set_process_unhandled_input(false);
	set_texture_for_key()
	set_action_name()
