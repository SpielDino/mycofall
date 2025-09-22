extends Control

const CONTROLLER_CONTROLS: Dictionary = {
	"PS5_en_EN": "res://UI/Menus/Controller/PS5_en_EN.png",
	"PS5_de_DE": "res://UI/Menus/Controller/PS5_de_DE.png",
	"XBox_en_EN": "res://UI/Menus/Controller/XBox_en_EN.png",
	"XBox_de_DE": "res://UI/Menus/Controller/XBox_de_DE.png",
	"Nintendo_en_EN": "res://UI/Menus/Controller/Nintedno_en_EN.png",
	"Nintendo_de_DE": "res://UI/Menus/Controller/Nintendo_de_DE.png",
}

var _base_path: String = "res://assets/textures/ui_textures/menus/Keys/"
var _capturing_remap: bool = false;
var _current_action_name: String;
var _current_key: String;
var _current_label: Label;

@onready var controller_text = $MarginContainer/ControlsMenuContainer/MarginContainer/Titles/HBoxContainer/Controller
@onready var keyboard_text = $MarginContainer/ControlsMenuContainer/MarginContainer/Titles/HBoxContainer/Keyboard
@onready var controller_menu = $MarginContainer/ControlsMenuContainer/MarginContainer/Controller
@onready var controller_image = $MarginContainer/ControlsMenuContainer/MarginContainer/Controller/Inputs
@onready var controller_label = $MarginContainer/ControlsMenuContainer/MarginContainer/Controller/Connect_Controller
@onready var keyboard_menu = $MarginContainer/ControlsMenuContainer/MarginContainer/Keyboard

@onready var button_left = $MarginContainer/ControlsMenuContainer/MarginContainer/Titles/HBoxContainer/ButtonLeft
@onready var button_right = $MarginContainer/ControlsMenuContainer/MarginContainer/Titles/HBoxContainer/ButtonRight
@onready var back = $MarginContainer/ControlsMenuContainer/MarginContainer/NinePatchRect/ButtonMargin/Back

@onready var pause_menu: Control = get_node_or_null("../../PauseMenu");

func _ready() -> void:
	if pause_menu == null:
		pause_menu = get_node_or_null("../../TitleScreen")
	set_process_unhandled_input(false)

func _on_controls_opened() -> void:
	_update_controller_controls();
	
func _update_controller_controls() -> void:
	var controller_type = "XBox_" 
	if UIManager.get_controller():
		_reveal_controller()
		if "ps" in Input.get_joy_name(0).to_lower():
			controller_type = "PS5_"
		elif "nintendo" in Input.get_joy_name(0).to_lower():
			controller_type = "Nintendo_"
		else:
			controller_type = "XBox_"
		controller_image.visible == true
		controller_label.visible == false
		controller_image.texture = load(CONTROLLER_CONTROLS[controller_type + SettingsDataContainer.loaded_data.language_country_code])
	else:
		controller_image.visible == false
		controller_label.visible == true
		_reveal_keyboard()

func _on_button_left_pressed() -> void:
	_reveal_controller()

func _on_button_right_pressed() -> void:
	_reveal_keyboard()

func _reveal_keyboard() -> void:
	controller_text.visible = false
	controller_menu.visible = false
	keyboard_menu.visible = true
	keyboard_text.visible = true
	
func _reveal_controller() -> void:
	controller_text.visible = true
	controller_menu.visible = true
	keyboard_menu.visible = false
	keyboard_text.visible = false

func _on_key_remapping_pressed() -> void:
	_capturing_remap = true;
	var button = get_viewport().gui_get_focus_owner()
	_current_label = button.get_child(0)
	_current_key = _current_label.text
	var parent_container = button.get_parent().get_parent();
	var name_count = parent_container.get_path().get_name_count();
	var action_name: String = parent_container.get_path().get_name(name_count - 1)
	var split_index = 0;
	
	for char in len(action_name):
		if char == 0: continue;
		if action_name[char] == action_name[char].to_upper():
			split_index = char
			break;
	_current_action_name = action_name.substr(0, split_index).to_lower() + "_" + action_name.substr(split_index).to_lower();

func _unhandled_input(event: InputEvent) -> void:
	if !_capturing_remap: return;
	var input_events: Array[InputEvent] = InputMap.action_get_events(_current_action_name);
	if len(input_events) == 0:
		push_warning("No input events for action found: ", _current_action_name)
		return
	
	var current_event: InputEvent;
	for input_event in input_events: 
		if OS.find_keycode_from_string(_current_key) == input_event.physical_keycode:
			current_event = input_event
	rebind_key(_current_action_name, current_event)
	var new_key = OS.get_keycode_string(event.physical_keycode)
	_current_label.text = new_key
	SettingsDataContainer.set_keybind(_current_action_name, event)
	_capturing_remap = false;
	
func rebind_key(action, event):
	InputMap.action_erase_event(action, event);
	InputMap.action_add_event(_current_action_name, event);


func _on_back_pressed() -> void:
	pause_menu.controls_back_pressed.emit();
