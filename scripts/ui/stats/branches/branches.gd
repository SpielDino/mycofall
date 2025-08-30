extends MarginContainer

# in order to trigger animations --> need to be in other scripts!!!
signal toggle_first_weapon;
signal toggle_second_weapon;
signal toggle_menu;
signal toggle_stamina;
signal toggle_mana;

const ANIMATION_NAMES: Array[String] = ["branch_one_full", "branch_two", "branch_three", "weapon_one", "weapon_two"];

var branch_one_full_sprite_frames: SpriteFrames;
var branch_two_sprite_frames: SpriteFrames;
var branch_three_sprite_frames: SpriteFrames;
var weapon_two_sprite_frames: SpriteFrames;

# branch states
var _is_branch_one: bool = true;
var _is_branch_two: bool = true;
var _is_branch_three: bool = false;
var _is_shrinking: bool = false;

# weapon states
var _is_first_weapon: bool = false;
var _is_second_weapon: bool = false;

# animation
var _is_playing: bool = false;
var _timer: float = 0;
var _frame_id: int = 0;

var _autoplay: bool = false;
var _loop: bool = false;

var _active_animations: Array[SpriteFrames];

var _animations : Dictionary[String, Dictionary] = {
	"branch_one_full":
		{
			"name": "branch_one",
			"fps": 60,
			"frame_duration": 1,
			"is_shrinking": true,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
	"branch_two":
		{
			"name": "branch_two",
			"fps": 60,
			"frame_duration": 1,
			"is_shrinking": false,
			"frame_id": 67,
			"timer": 0.0,
			"active_index": -1
		},
	"branch_three":
		{
			"name": "branch_three",
			"fps": 60,
			"frame_duration": 1,
			"is_shrinking": false,
			"frame_id": 81,
			"timer": 0.0,
			"active_index": -1
		},
	"weapon_one":
		{
			"name": "weapon_one",
			"fps": 60,
			"frame_duration": 1,
			"is_shrinking": false,
			"frame_id": 19,
			"timer": 0.0,
			"active_index": -1
		},
	"weapon_two":
		{
			"name": "weapon_two",
			"fps": 60,
			"frame_duration": 1,
			"is_shrinking": false,
			"frame_id": 19,
			"timer": 0.0,
			"active_index": -1
		},
	
}
#@onready var player: Node3D = GlobalPlayer.get_player()

func _ready() -> void:
	pass
	#player.toggle_first_weapon.connect(_on_first_weapon_toggle())
	#player.toggle_second_weapon.connect(_on_second_weapon_toggle())
	#ui.toggle_menu.connect(_on_menu_toggle())
	#player.toggle_stamina.connect(_on_stamina_toggle())
	#player.toggle_mana.connect(_on_mana_toggle())

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		_on_menu_toggle()

func _process(delta: float) -> void:
		
	if len(_active_animations) <= 0:
		return
	
	for animation: SpriteFrames in _active_animations:
		var res_name = animation.resource_path.get_file().get_basename()
		print(animation.resource_path.get_file().get_basename())
		if !_check_valid_animation(animation):
			_active_animations.remove_at(_animations[res_name]["active_index"]);
			continue
		_animations[res_name]["timer"] += delta;
		var frame_time = _animations[res_name]["frame_duration"] / _animations[res_name]["fps"];
		print(frame_time)
		if _animations[res_name]["timer"] >= frame_time:
			_animations[res_name]["timer"] -= frame_time;
			_change_frame_id(animation, res_name);
			_set_current_frame_texture(animation, res_name);
		
func _check_valid_animation(sprite_frames: SpriteFrames) -> bool:
	print(sprite_frames.resource_path.get_file().get_basename())
	if !sprite_frames.has_animation("default"):
		push_error("Animation not found: default")
		return false
	return true
	
func _change_frame_id(frames: SpriteFrames, res_name: String) -> void:
	print(_animations[res_name]["frame_id"])
	print(_animations[res_name]["is_shrinking"])
	if _animations[res_name]["is_shrinking"]:
		if _animations[res_name]["frame_id"] + 1 >= frames.get_frame_count("default"):
			_stop(res_name, _animations[res_name]["active_index"]);
			return
		else:
			_animations[res_name]["frame_id"] += 1;
	else:
		if _animations[res_name]["frame_id"] -1 <= 0:
			_stop(res_name, _animations[res_name]["active_index"]);
			return
		else:
			_animations[res_name]["frame_id"] -= 1;
	
	
func _set_current_frame_texture(frames: SpriteFrames, res_name: String) -> void:
	var element = get_node(res_name)
	print(res_name)
	element.texture = frames.get_frame_texture("default", _animations[res_name]["frame_id"]);

func _stop(res_name: String, index: int) -> void:
	for animation: String in ANIMATION_NAMES:
		if _animations[animation]["active_index"] > 0:
			_animations[animation]["active_index"] -= 1
	_active_animations.remove_at(index);
	_animations[res_name]["active_index"] = -1
	
func _on_first_weapon_toggle() -> void:
	if _animations[ANIMATION_NAMES[3]]["active_index"] == -1:
		_active_animations.append(ANIMATION_NAMES[3]);
		_animations[ANIMATION_NAMES[3]]["active_index"] = len(_active_animations) - 1;
	
	if _is_first_weapon: 
		_animations[ANIMATION_NAMES[3]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[3]]["is_shrinking"] = false;
	_is_first_weapon = !_is_first_weapon;
	
func _on_second_weapon_toggle() -> void:
	if _animations[ANIMATION_NAMES[4]]["active_index"] == -1:
		var weapon_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/weapon_two/weapon_two.tres");
		_active_animations.append(weapon_two_sprite_frames);
		_animations[ANIMATION_NAMES[4]]["active_index"] = len(_active_animations) - 1;
	
	if _is_second_weapon: 
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = false;
	_is_second_weapon = !_is_second_weapon;
	
func _on_menu_toggle() -> void:
	if _animations[ANIMATION_NAMES[0]]["active_index"] == -1:
		var branch_one_full_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_one_full/branch_one_full.tres");
		_active_animations.append(branch_one_full_sprite_frames);
		_animations[ANIMATION_NAMES[0]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_one: 
		_animations[ANIMATION_NAMES[0]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[0]]["is_shrinking"] = false;
	_is_branch_one = !_is_branch_one;
	
	#if _is_branch_two:
		#_on_stamina_toggle()
		#
	#if _is_branch_three:
		#_on_mana_toggle()
	
func _on_stamina_toggle() -> void:
	print(_is_branch_two)
	if _animations[ANIMATION_NAMES[1]]["active_index"] == -1:
		var branch_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_two/branch_two.tres");
		_active_animations.append(branch_two_sprite_frames);
		_animations[ANIMATION_NAMES[1]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_two: 
		_animations[ANIMATION_NAMES[1]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[1]]["is_shrinking"] = false;
	_is_branch_two = !_is_branch_two;
	
func _on_mana_toggle() -> void:
	if _animations[ANIMATION_NAMES[2]]["active_index"] == -1:
		var branch_three_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_three/branch_three.tres");
		_active_animations.append(branch_three_sprite_frames);
		_animations[ANIMATION_NAMES[2]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_three: 
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = false;
	_is_branch_three = !_is_branch_three;
