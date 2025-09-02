extends Node

# localization signals
signal lang_change

# stat signals
signal toggle_menu(_on_toggle_menu);
signal toggle_stamina;
signal toggle_mana;

const LANGUAGES : Dictionary = {
	"en_EN": "SETTING_LANGUAGE_ENGLISH",
	"en_GB": "SETTING_LANGUAGE_ENGLISH_GB",
	"en_US": "SETTING_LANGUAGE_ENGLISH_US",
	"en_AU": "SETTING_LANGUAGE_ENGLISH_AU",
	"de_DE": "SETTING_LANGUAGE_GERMAN"
}

# menus
var is_menu: bool = false;

# input
var is_controller: bool = false;

const button_mappings: Dictionary[String, Dictionary] = {
	"xbox": {
		"interact": "A",
		"block": "LT",
		"pause": "Menu",
		"attack": "RT",
		"weapon_swap": "Y",
		"sneak": "L3",
		"dash": "LB"
	},
	"ps5": {
		"interact": "✕",
		"block": "L2", 
		"pause": "Start",
		"attack": "R2",
		"weapon_swap": "△",
		"sneak": "L3",
		"dash": "L1"
	},
	"nintendo": {
		"interact": "B",
		"block": "ZL",
		"menu": "+",
		"attack": "ZR",
		"weapon_swap": "X",
		"sneak": "L3",
		"dash": "L"
	},
	"none": {
		"interact": "A",
		"block": "LT",
		"pause": "Menu",
		"attack": "RT",
		"weapon_swap": "Y",
		"sneak": "L3",
		"dash": "LB"
	}
}

var current_controller: String;
#@onready var text_field: Control = get_tree().current_scene.find_child("textField")
#@onready var stats: MarginContainer = get_tree().current_scene.find_child("stats")
#@onready var timer: Timer
@onready var gameBlend

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_controller();
	
func update_lang(lang: String) -> void:
	TranslationServer.set_locale(lang)
	lang_change.emit()
	
func get_controller_type() -> String:
	var controller_type: String = "None" 
	if len(Input.get_connected_joypads()) > 0:
		is_controller = true
		if "ps" in Input.get_joy_name(0).to_lower():
			controller_type = "PS5"
		elif "nintendo" in Input.get_joy_name(0).to_lower():
			controller_type = "Nintendo"
		elif "xbox" in Input.get_joy_name(0).to_lower():
			controller_type = "XBox"
	is_controller = false
	return controller_type

func get_controller() -> bool:
	if len(Input.get_connected_joypads()) > 0:
		is_controller = true;
	current_controller = get_controller_type();
	is_controller = false
	return is_controller;

func set_controller(new_state: bool) -> void:
	is_controller = new_state;
	
func get_controller_input_key(action: String, controller_connected: bool) -> String:
	return button_mappings[current_controller.to_lower()][action.to_lower()]
	
func _on_toggle_menu() -> void:
	is_menu = !is_menu;
