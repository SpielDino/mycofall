extends Node


var window_mode_index: int = 0;
var resolution_index: int = 0;
var language_index: int = 0; 

var master_volume: float = 0;
var sfx_volume: float = 0;
var music_volume: float = 0;
var voice_volume: float = 0;

var loaded_data: Dictionary = {};

@onready var default_settings: DefaultSettingsResource = preload("res://scenes/resources/settings/default_settings.tres")
@onready var keybind_resource: PlayerKeybindResource = preload("res://scenes/resources/settings/player_keybind_default.tres")

func _ready() -> void:
	handle_signals();
	create_storage_dictionary();

func create_storage_dictionary() -> Dictionary:
	var settings_container_dict: Dictionary = {
		"window_mode_index" : window_mode_index,
		"resolution_index"  : resolution_index,
		"language_index": language_index,
		"master_volume" : master_volume,
		"music_volume" : music_volume,
		"sfx_volume" : sfx_volume,
		"voice_volume" : voice_volume,
		"keybinds": create_keybinds_dictionary()
	}
	
	return settings_container_dict

func create_keybinds_dictionary() -> Dictionary:
	var keybinds_container_dict = {
		keybind_resource.MOVE_FORWARD: keybind_resource.move_forward_key,
		keybind_resource.MOVE_LEFT: keybind_resource.move_left_key,
		keybind_resource.MOVE_RIGHT: keybind_resource.move_right_key,
		keybind_resource.MOVE_BACKWARD: keybind_resource.move_backward_key,
		keybind_resource.DODGE: keybind_resource.dodge_key,
		keybind_resource.SNEAK: keybind_resource.sneak_key,
		keybind_resource.ATTACK: keybind_resource.attack_key,
		keybind_resource.BLOCK: keybind_resource.block_key,
		keybind_resource.HEAVY_ATTACK: keybind_resource.heavy_attack_key,
		keybind_resource.SWAP_WEAPON: keybind_resource.swap_weapon_key,
		keybind_resource.INTERACT: keybind_resource.interact_key,
		keybind_resource.PAUSE: keybind_resource.pause_key,
	}
	return keybinds_container_dict;

func get_window_mode_index() -> int:
	if loaded_data == {}:
		return default_settings.DEFAULT_WINDOW_MODE_INDEX;
	return window_mode_index;
	
func get_resolution_index() -> int:
	if loaded_data == {}:
		return default_settings.DEFAULT_RESOLUTION_INDEX;
	return resolution_index;
	
func get_language_index() -> int:
	if loaded_data == {}:
		return default_settings.DEFAULT_LANGUAGE_COUNTRY_CODE;
	return language_index;
	
func get_master_volume() -> float:
	if loaded_data == {}:
		return default_settings.DEFAULT_WINDOW_MODE_INDEX;
	return master_volume;
	
func get_sfx_volume() -> float:
	if loaded_data == {}:
		return default_settings.DEFAULT_WINDOW_MODE_INDEX;
	return sfx_volume;
	
func get_music_volume() -> float:
	if loaded_data == {}:
		return default_settings.DEFAULT_WINDOW_MODE_INDEX;
	return music_volume;
	
func get_voice_volume() -> float:
	if loaded_data == {}:
		return default_settings.DEFAULT_WINDOW_MODE_INDEX;
	return voice_volume;

func get_keybind(action: String):
	if !loaded_data.has("keybinds"):
		match action:
			keybind_resource.MOVE_FORWARD:
				return keybind_resource.DEFAULT_MOVE_FORWARD_KEY;
			keybind_resource.MOVE_LEFT:
				return keybind_resource.DEFAULT_MOVE_LEFT_KEY;
			keybind_resource.MOVE_RIGHT:
				return keybind_resource.DEFAULT_MOVE_RIGHT_KEY;
			keybind_resource.MOVE_BACKWARD:
				return keybind_resource.DEFAULT_MOVE_BACKWARD_KEY;
			keybind_resource.DODGE:
				return keybind_resource.DEFAULT_DODGE_KEY;
			keybind_resource.SNEAK:
				return keybind_resource.DEFAULT_SNEAK_KEY;
			keybind_resource.ATTACK:
				return keybind_resource.DEFAULT_ATTACK_KEY;
			keybind_resource.BLOCK:
				return keybind_resource.DEFAULT_BLOCK_KEY;
			keybind_resource.HEAVY_ATTACK:
				return keybind_resource.DEFAULT_HEAVY_ATTACK_KEY;
			keybind_resource.SWAP_WEAPON:
				return keybind_resource.DEFAULT_SWAP_WEAPON_KEY	;
			keybind_resource.INTERACT:
				return keybind_resource.DEFAULT_INTERACT_KEY;
			keybind_resource.PAUSE:
				return keybind_resource.DEFAULT_PAUSE_KEY;
			
	else:
		match action:
			keybind_resource.MOVE_FORWARD:
				return keybind_resource.move_forward_key;
			keybind_resource.MOVE_LEFT:
				return keybind_resource.move_left_key;
			keybind_resource.MOVE_RIGHT:
				return keybind_resource.move_right_key;
			keybind_resource.MOVE_BACKWARD:
				return keybind_resource.move_backward_key;
			keybind_resource.DODGE:
				return keybind_resource.dodge_key;
			keybind_resource.SNEAK:
				return keybind_resource.sneak_key;
			keybind_resource.ATTACK:
				return keybind_resource.attack_key;
			keybind_resource.BLOCK:
				return keybind_resource.block_key;
			keybind_resource.HEAVY_ATTACK:
				return keybind_resource.heavy_attack_key;
			keybind_resource.SWAP_WEAPON:
				return keybind_resource.swap_weapon_key	;
			keybind_resource.INTERACT:
				return keybind_resource.interact_key;
			keybind_resource.PAUSE:
				return keybind_resource.pause_key;

func on_window_mode_selected(index: int) -> void:
	window_mode_index = index;

func on_resolution_selected(index: int) -> void:
	resolution_index = index;

func on_language_selected(index: int) -> void:
	language_index = index;

func on_master_volume_set(value: float) -> void:
	master_volume = value;

func on_sfx_volume_set(value: float) -> void:
	sfx_volume = value;

func on_music_volume_set(value: float) -> void:
	music_volume = value;

func on_voice_volume_set(value: float) -> void:
	voice_volume = value;

func set_keybind(action: String, event) -> void:
	match action:
		keybind_resource.MOVE_FORWARD:
			keybind_resource.move_forward_key = event;
		keybind_resource.MOVE_LEFT:
			keybind_resource.move_left_key = event;
		keybind_resource.MOVE_RIGHT:
			keybind_resource.move_right_key = event;
		keybind_resource.MOVE_BACKWARD:
			keybind_resource.move_backward_key = event;
		keybind_resource.DODGE:
			keybind_resource.dodge_key = event;
		keybind_resource.SNEAK:
			keybind_resource.sneak_key = event;
		keybind_resource.ATTACK:
			keybind_resource.attack_key = event;
		keybind_resource.BLOCK:
			keybind_resource.block_key = event;
		keybind_resource.HEAVY_ATTACK:
			keybind_resource.heavy_attack_key = event;
		keybind_resource.SWAP_WEAPON:
			keybind_resource.swap_weapon_key = event;
		keybind_resource.INTERACT:
			keybind_resource.interact_key = event;
		keybind_resource.PAUSE:
			keybind_resource.pause_key = event;

func on_keybinds_loaded(data: Dictionary) -> void:
	for key in data.keys():
		if data[key].contains("InputEventKey"):
			keybind_resource[key + "_key"] = InputEventKey.new()
			keybind_resource[key + "_key"].set_physical_keycode(int(data[key]))
		elif data[key].contains("InputEventMouseButton"):
			keybind_resource[key + "_key"] = InputEventMouseButton.new()
			keybind_resource[key + "_key"].button_index = int(data[key]) / 10
	
func on_settings_data_loaded(data: Dictionary) -> void:
	loaded_data = data;
	on_window_mode_selected(int(loaded_data.window_mode_index))
	on_resolution_selected(int(loaded_data.resolution_index))
	on_language_selected(int(loaded_data.language_index))
	on_master_volume_set(loaded_data.master_volume)
	on_sfx_volume_set(loaded_data.sfx_volume)
	on_music_volume_set(loaded_data.music_volume)
	on_voice_volume_set(loaded_data.voice_volume)
	on_keybinds_loaded(loaded_data.keybinds)

func handle_signals() -> void:
	SettingsSignalBus.on_window_mode_selected.connect(on_window_mode_selected);
	SettingsSignalBus.on_resolution_selected.connect(on_resolution_selected);
	SettingsSignalBus.on_language_selected.connect(on_language_selected);
	SettingsSignalBus.on_master_volume_set.connect(on_master_volume_set);
	SettingsSignalBus.on_sfx_volume_set.connect(on_sfx_volume_set);
	SettingsSignalBus.on_music_volume_set.connect(on_music_volume_set);
	SettingsSignalBus.on_voice_volume_set.connect(on_voice_volume_set);
	SettingsSignalBus.load_settings_data.connect(on_settings_data_loaded)
