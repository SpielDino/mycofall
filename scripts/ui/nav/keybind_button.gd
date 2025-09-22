class_name KeybindButton
extends Control

const BASE_PATH_KEYS: String = "res://assets/textures/ui_textures/menus/Keys/"

@onready var label: Label = $KeybindContainer/TextureRect/MarginContainer/Label
@onready var button: TextureButton
@onready var press_key_label: Label = $KeybindContainer/HBoxContainer/key/Label
@onready var texture: TextureRect = $KeybindContainer/HBoxContainer/key/TextureRect

@export var action_name: String;

var capturing := false
var _current_action_event: InputEvent;
var _current_key: String;

func _ready() -> void:
	init_onready_vars();
	set_process_unhandled_input(false)
	set_action_name()
	set_texture_for_key()
	load_keybind()
	button.toggle_mode = true

func init_onready_vars() -> void:
	label = $KeybindContainer/TextureRect/MarginContainer/Label
	button = $KeybindContainer/HBoxContainer/key
	press_key_label = $KeybindContainer/HBoxContainer/key/Label
	
func load_keybind() -> void:
	rebind_action_key(SettingsDataContainer.get_keybind(action_name))
	
func set_action_name() -> void:
	label.text = "KEY_" + action_name.to_upper();

func set_texture_for_key() -> void:
	var action_events: Array[InputEvent] = InputMap.action_get_events(action_name)
	
	if len(action_events) == 0:
		push_warning("No action events found for the following input action: ", action_name);
		return
	for action_event in action_events: 
		var btton: InputEventJoypadMotion = InputEventJoypadMotion.new()
		var action_keycode: int = action_event.physical_keycode if action_event is InputEventKey else action_event.button_index if action_event is InputEventMouseButton || action_event is InputEventJoypadButton else action_event.axis
		if OS.find_keycode_from_string(_current_key) == action_keycode:
			_current_action_event = action_event
	
	if _current_key.contains("MOUSE"):
		texture.texture = load(BASE_PATH_KEYS + _current_key + ".png")
		press_key_label.visible = false
		texture.visible = true
	else:
		press_key_label.text = _current_key
		press_key_label.visible = true
		texture.visible = false

func _on_key_toggled(button_pressed: bool) -> void:
	if button_pressed:
		capturing = button_pressed
		set_process_input(button_pressed)
		set_process_unhandled_input(false)
		press_key_label.text = "PRESS A KEY..."
		set_process_unhandled_input(true)
		
		for i in get_tree().get_nodes_in_group("keybind_button"):
			if i.action_name != self.action_name:
				i.button.toggle_mode = false;
				i.set_process_unhandled_input(false);
	else: 
		for i in get_tree().get_nodes_in_group("keybind_button"):
			if i.action_name != self.action_name:
				i.button.toggle_mode = true;
				i.set_process_unhandled_input(false);
				
		set_texture_for_key()

func _input(event: InputEvent) -> void:
	if not capturing:
		return
	if event is InputEventKey or event is InputEventMouseButton:
		rebind_action_key(event)
		get_viewport().set_input_as_handled()  # prevent UI from reacting [10]
		button.button_pressed = false
		capturing = false
		set_process_input(false)

func rebind_action_key(event) -> void:
	var new_key: String = OS.get_keycode_string(event.physical_keycode) if event is InputEventKey else "MOUSE%d" % event.button_index
	for i: KeybindButton in get_tree().get_nodes_in_group("keybind_button"):
		if i.action_name != null && !self.action_name.contains("block") && i.action_name != self.action_name:
			if i.press_key_label == null: 
				continue
			if i.press_key_label.text == new_key:
				press_key_label.text = "ALREADY USED!  CHOOSE ANOTHER"
				await get_tree().create_timer(1).timeout
				press_key_label.text = "PRESS A KEY..."
				set_process_unhandled_input(false)
				_on_key_toggled(true)
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
