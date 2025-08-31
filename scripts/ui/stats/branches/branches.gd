extends MarginContainer

# in order to trigger animations --> need to be in other scripts!!!
signal toggle_weapon_one;
signal toggle_weapon_two;
signal toggle_menu;
signal toggle_stamina;
signal toggle_mana;

const ANIMATION_NAMES: Array[String] = ["branch_one_full", "branch_two", "branch_three", "weapon_one", "weapon_two"];

var branch_one_full_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_one_full/branch_one_full.tres");
var branch_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_two/branch_two.tres");
var branch_three_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_three/branch_three.tres");
var weapon_one_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/weapon_two/weapon_two.tres");
var weapon_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/weapon_two/weapon_two.tres");
		
# stat actives (does the player have a mana weapon, ...)
var _is_menu: bool = false;
var _is_branch_two_active: bool = false;
var _is_branch_three_active: bool = false;
var _is_weapon_one_active: bool = false;
var _is_weapon_two_active: bool = false;

var _is_past_tutorial: bool = false;

# branch states
var _is_branch_one: bool = true;
var _is_branch_two: bool = false;
var _is_branch_three: bool = false;
var _is_shrinking: bool = false;

# weapon states
var _is_weapon_one: bool = false;
var _is_weapon_two: bool = false;

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
			"fps": 120,
			"is_shrinking": true,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
	"branch_two":
		{
			"fps": 60,
			"is_shrinking": false,
			"frame_id": 67,
			"timer": 0.0,
			"active_index": -1
		},
	"branch_three":
		{
			"fps": 60,
			"is_shrinking": false,
			"frame_id": 81,
			"timer": 0.0,
			"active_index": -1
		},
	"weapon_one":
		{
			"fps": 60,
			"is_shrinking": false,
			"frame_id": 19,
			"timer": 0.0,
			"active_index": -1
		},
	"weapon_two":
		{
			"fps": 60,
			"is_shrinking": false,
			"frame_id": 19,
			"timer": 0.0,
			"active_index": -1
		},
	
}
#@onready var player: Node3D = GlobalPlayer.get_player()

func _ready() -> void:
	var frames: Array[SpriteFrames] = [
		branch_one_full_sprite_frames,
		branch_two_sprite_frames,
		branch_three_sprite_frames,
		weapon_one_sprite_frames,
		weapon_two_sprite_frames
	]
	for animation in ANIMATION_NAMES.size():
		if !frames[animation] || !frames[animation].resource_path.get_file().get_basename() == ANIMATION_NAMES[animation]:
			push_warning("SpriteFrames do not match or are null: ", ANIMATION_NAMES[animation])
			continue
		_set_current_frame_texture(frames[animation], ANIMATION_NAMES[animation])
	#player.toggle_weapon_one.connect(_on_weapon_one_toggle())
	#player.toggle_weapon_two.connect(_on_weapon_two_toggle())
	#ui.toggle_menu.connect(_on_menu_toggle())
	#player.toggle_stamina.connect(_on_stamina_toggle())
	#player.toggle_mana.connect(_on_mana_toggle())

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		_on_menu_toggle()
		toggle_menu.emit()
		
	if len(_active_animations) <= 0:
		return
	
	for animation: SpriteFrames in _active_animations:
		var res_name = animation.resource_path.get_file().get_basename()
		if !_check_valid_animation(animation):
			_active_animations.remove_at(_animations[res_name]["active_index"]);
			continue
		_animations[res_name]["timer"] += delta;
		var frame_time = 1.0 / _animations[res_name]["fps"];
		var advanced := false
		# maybe fix? does a calculation more when having multiple frames to advance 
		while _animations[res_name]["timer"] >= frame_time:
			if _animations[res_name]["active_index"] == -1:
				_animations[res_name]["timer"] = 0.0
				break
			_animations[res_name]["timer"] -= frame_time
			print("frame_id: ", _animations[res_name]["frame_id"])
			_change_frame_id(animation, res_name, 1)
			advanced = true
		#if _animations[res_name]["timer"] >= frame_time:
			#var advance_frames: int = roundi(delta / frame_time)
			#_animations[res_name]["timer"] -= frame_time * 1;
			#_change_frame_id(animation, res_name, 1);
			#_set_current_frame_texture(animation, res_name)
		if advanced:
			_set_current_frame_texture(animation, res_name);

		
func _check_valid_animation(sprite_frames: SpriteFrames) -> bool:
	if !sprite_frames.has_animation("default"):
		push_error("Animation not found: default")
		return false
	return true
	
func _change_frame_id(frames: SpriteFrames, res_name: String, advance_frames) -> void:
	if _animations[res_name]["is_shrinking"]:
		if _animations[res_name]["frame_id"] + advance_frames >= frames.get_frame_count("default"):
			_stop(res_name, _animations[res_name]["active_index"]);
			print(frames.get_frame_count("default"))
			_animations[res_name]["frame_id"] = frames.get_frame_count("default") - 1
			return
		else:
			_animations[res_name]["frame_id"] += advance_frames;
	else:
		if _animations[res_name]["frame_id"] -advance_frames <= 0:
			_stop(res_name, _animations[res_name]["active_index"]);
			_animations[res_name]["frame_id"] = 0
			return
		else:
			_animations[res_name]["frame_id"] -= advance_frames;
	
	
func _set_current_frame_texture(frames: SpriteFrames, res_name: String) -> void:
	var element = get_node(res_name)
	element.texture = frames.get_frame_texture("default", _animations[res_name]["frame_id"]);

func _stop(res_name: String, index: int) -> void:
	print("stop: ", res_name, index)
	_active_animations.remove_at(index);
	_animations[res_name]["active_index"] = -1
	for animation: String in ANIMATION_NAMES:
		print("animation: ", animation, _animations[animation]["active_index"])
		if _animations[animation]["active_index"] > index:
			print("reduce: ", animation)
			_animations[animation]["active_index"] -= 1
	
func _on_weapon_one_toggle() -> void:
	if _animations[ANIMATION_NAMES[3]]["active_index"] == -1:
		_active_animations.append(ANIMATION_NAMES[3]);
		_animations[ANIMATION_NAMES[3]]["active_index"] = len(_active_animations) - 1;
	
	if _is_weapon_one: 
		_animations[ANIMATION_NAMES[3]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[3]]["is_shrinking"] = false;
	_is_weapon_one = !_is_weapon_one;
	if !_is_past_tutorial && !_is_menu:
		_is_weapon_one_active = _is_weapon_one
	
func _on_weapon_two_toggle() -> void:
	if _animations[ANIMATION_NAMES[4]]["active_index"] == -1:
		_active_animations.append(weapon_two_sprite_frames);
		_animations[ANIMATION_NAMES[4]]["active_index"] = len(_active_animations) - 1;
	
	if _is_weapon_two: 
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = false;
	_is_weapon_two = !_is_weapon_two;
	if !_is_past_tutorial && !_is_menu:
		_is_weapon_two_active = _is_weapon_two
	
func _on_menu_toggle() -> void:
	_is_menu = !_is_menu
	if _animations[ANIMATION_NAMES[0]]["active_index"] == -1:
		_active_animations.append(branch_one_full_sprite_frames);
		_animations[ANIMATION_NAMES[0]]["active_index"] = len(_active_animations) - 1;
		print("branch_one active: ", _animations[ANIMATION_NAMES[0]]["active_index"])
	
	if _is_branch_one: 
		_animations[ANIMATION_NAMES[0]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[0]]["is_shrinking"] = false;
	_is_branch_one = !_is_branch_one;
	
	if _is_branch_two_active:
		_on_stamina_toggle();
		
	if _is_branch_three_active:
		_on_mana_toggle();
	
	if _is_weapon_one_active:
		_on_weapon_one_toggle();
	
	if _is_weapon_two_active:
		_on_weapon_two_toggle();
	
func _on_stamina_toggle() -> void:
	if _animations[ANIMATION_NAMES[1]]["active_index"] == -1:
		_active_animations.append(branch_two_sprite_frames);
		_animations[ANIMATION_NAMES[1]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_two: 
		_animations[ANIMATION_NAMES[1]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[1]]["is_shrinking"] = false;
	_is_branch_two = !_is_branch_two;
	
	if !_is_past_tutorial && !_is_menu:
		_is_branch_two_active = _is_branch_two
	
func _on_mana_toggle() -> void:
	if _animations[ANIMATION_NAMES[2]]["active_index"] == -1:
		_active_animations.append(branch_three_sprite_frames);
		_animations[ANIMATION_NAMES[2]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_three: 
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = false;
	_is_branch_three = !_is_branch_three;
	if !_is_past_tutorial && !_is_menu:
		_is_branch_three_active = _is_branch_three
