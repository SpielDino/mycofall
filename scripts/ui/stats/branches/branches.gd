extends MarginContainer

# in order to trigger animations --> need to be in other scripts!!!
signal toggle_weapon_one;
signal toggle_weapon_two;
signal toggle_menu;
signal toggle_stamina;
signal toggle_mana;
signal animation_finished(animation_name: String);

const ANIMATION_NAMES: Array[String] = ["branch_one_full", "branch_two", "branch_three", "weapon_one", "weapon_two", "sword", "bow", "staff", "shield"];

var branch_one_full_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_one_full/branch_one_full.tres");
var branch_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_two/branch_two.tres");
var branch_three_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/branch_three/branch_three.tres");
var weapon_one_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/weapon_two/weapon_two.tres");
var weapon_two_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/stats/branches/weapon_two/weapon_two.tres");

var sword_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/weapons/sword/sword_sprite_frames.tres")
var bow_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/weapons/bow/bow_sprite_frames.tres")
var staff_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/weapons/staff/staff_sprite_frames.tres")
var shield_sprite_frames: SpriteFrames = ResourceLoader.load("res://assets/textures/ui_textures/interface/weapons/shield/shield_sprite_frames.tres")
		
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

var _active_animations: Array[Dictionary];

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
			"fps": 120,
			"is_shrinking": false,
			"frame_id": 67,
			"timer": 0.0,
			"active_index": -1
		},
	"branch_three":
		{
			"fps": 120,
			"is_shrinking": false,
			"frame_id": 81,
			"timer": 0.0,
			"active_index": -1
		},
	"weapon_one":
		{
			"fps": 120,
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
	"sword_sprite_frames":
		{
			"fps": 30,
			"is_shrinking": false,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
	"bow_sprite_frames":
		{
			"fps": 30,
			"is_shrinking": false,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
	"staff_sprite_frames":
		{
			"fps": 30,
			"is_shrinking": false,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
	"shield_sprite_frames":
		{
			"fps": 30,
			"is_shrinking": false,
			"frame_id": 0,
			"timer": 0.0,
			"active_index": -1
		},
}
@onready var player: Node3D = GlobalPlayer.get_player()
@onready var weapon_slot_one = $"../weapons/WeaponOne/MarginContainer/WeaponOne"
@onready var weapon_slot_two = $"../weapons/WeaponTwo/MarginContainer/WeaponTwo"

func _ready() -> void:
	var frames: Array[SpriteFrames] = [
		branch_one_full_sprite_frames,
		branch_two_sprite_frames,
		branch_three_sprite_frames,
		weapon_one_sprite_frames,
		weapon_two_sprite_frames,
	]
	for animation in ANIMATION_NAMES.size() - 4:
		if !frames[animation] || !frames[animation].resource_path.get_file().get_basename() == ANIMATION_NAMES[animation]:
			push_warning("SpriteFrames do not match or are null: ", ANIMATION_NAMES[animation])
			continue
		_set_current_frame_texture(frames[animation], ANIMATION_NAMES[animation], "default")
	UIManager.toggle_menu.connect(_on_menu_toggle);
	#GameManager.weapons_changed.connect(_update_weapon_icons)
	#player.toggle_weapon_one.connect(_on_weapon_one_toggle
	#player.toggle_weapon_two.connect(_on_weapon_two_toggle
	#ui.toggle_menu.connect(_on_menu_toggle
	#player.toggle_stamina.connect(_on_stamina_toggle)
	#player.toggle_mana.connect(_on_mana_toggle)

func match_upgrade_level() -> String:
	match GameManager.get_first_weapon_upgrade_level():
		1: 
			return "wooden"
		2:
			return "normal"
		3: 
			return "metal"
	return ""
		
func _update_weapon_icons() -> void:
	print("weapons_picked")
	if GameManager.get_first_weapon():
		print("yesssir")
		_is_weapon_one = true
		var upgrade: String = match_upgrade_level()
		print(GameManager.get_first_weapon_name())
		print("%s_sword_attack" % upgrade)
		print(weapon_slot_one)
		print(weapon_slot_one.texture)
		print(sword_sprite_frames.get_frame_texture("%s_sword_attack" % upgrade, 0))
		match GameManager.get_first_weapon_name():
			"Sword":
				print("setting_sword")
				weapon_slot_one.texture = sword_sprite_frames.get_frame_texture("%s_sword_attack" % upgrade, 0)
				print(weapon_slot_one.texture)
			"Bow":
				weapon_slot_one.texture = bow_sprite_frames.get_frame_texture("%s_bow_block" % upgrade, 0)
			"Staff":
				weapon_slot_one.texture = staff_sprite_frames.get_frame_texture("%s_staff_attack" % upgrade, 0)
			"Shield":
				weapon_slot_one.texture = shield_sprite_frames.get_frame_texture("%s_shield_attack" % upgrade, 0)
	#else:
		#weapon_slot_one.texture = null
		
	if	GameManager.get_second_weapon():
		var upgrade: String = match_upgrade_level()
		match GameManager.get_first_weapon_name():
			"Sword":
				weapon_slot_one.texture = load("res://assets/textures/ui_textures/interface/weapons/sword/half/%s_sword_half" % upgrade)
			"Bow":
				weapon_slot_one.texture = load("res://assets/textures/ui_textures/interface/weapons/bow/half/%s_bow_half" % upgrade)
			"Staff":
				weapon_slot_one.texture = load("res://assets/textures/ui_textures/interface/weapons/staff/half/%s_staff_half" % upgrade)
			"Shield":
				weapon_slot_one.texture = load("res://assets/textures/ui_textures/interface/weapons/shield/half/%s_shield_half" % upgrade)
	#else:
		#weapon_slot_two.texture = null
				
func _input(event) -> void:
	if event.is_action_pressed("pause"):
		_on_menu_toggle()
		toggle_menu.emit()
	elif event.is_action_pressed("attack"):
		var upgrade: String = match_upgrade_level()
		match GameManager.get_first_weapon_name():
			"Sword":
				_active_animations.append({"name": "%s_sword_attack" % upgrade, "animation": sword_sprite_frames})
			"Bow":
				_active_animations.append({"name": "%s_bow_attack" % upgrade, "animation": bow_sprite_frames})
			"Staff":
				_active_animations.append({"name": "%s_staff_attack" % upgrade, "animation": staff_sprite_frames})
			"Shield":
				_active_animations.append({"name": "%s_shield_attack" % upgrade, "animation": shield_sprite_frames})
	elif event.is_action_pressed("block"):
		var upgrade: String = match_upgrade_level()
		match GameManager.get_first_weapon_name():
			"Sword":
				_active_animations.append({"name": "%s_sword_block" % upgrade, "animation": sword_sprite_frames})
			"Bow":
				_active_animations.append({"name": "%s_bow_block" % upgrade, "animation": bow_sprite_frames})
			"Staff":
				_active_animations.append({"name": "%s_staff_block" % upgrade, "animation": staff_sprite_frames})
			"Shield":
				_active_animations.append({"name": "%s_shield_block" % upgrade, "animation": shield_sprite_frames})
	elif event.is_action_pressed("heavy_attack"):
		var upgrade: String = match_upgrade_level()
		match GameManager.get_first_weapon_name():
			"Sword":
				_active_animations.append({"name": "%s_sword_special" % upgrade, "animation": sword_sprite_frames})
			"Bow":
				_active_animations.append({"name": "%s_bow_special" % upgrade, "animation": bow_sprite_frames})
			"Staff":
				_active_animations.append({"name": "%s_staff_special" % upgrade, "animation": staff_sprite_frames})
			"Shield":
				_active_animations.append({"name": "%s_shield_special" % upgrade, "animation": shield_sprite_frames})
		
		
func _process(delta: float) -> void:		
	if len(_active_animations) <= 0:
		return
	
	for animation_struct in _active_animations:
		var animation = animation_struct.animation
		var animation_name = animation_struct.name
		var res_name = animation.resource_path.get_file().get_basename()
		if !_check_valid_animation(animation, animation_name):
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
			_change_frame_id(animation, res_name, 1, animation_name)
			advanced = true
		if advanced:
			_set_current_frame_texture(animation, res_name, animation_name);

		
func _check_valid_animation(sprite_frames: SpriteFrames,animation_name) -> bool:
	if !sprite_frames.has_animation(animation_name):
		push_error("Animation not found: ", animation_name)
		return false
	return true
	
func _change_frame_id(frames: SpriteFrames, res_name: String, advance_frames: int, animation_name: String) -> void:
	if _animations[res_name]["is_shrinking"]:
		if _animations[res_name]["frame_id"] + advance_frames >= frames.get_frame_count(animation_name):
			_stop(res_name, _animations[res_name]["active_index"]);
			_animations[res_name]["frame_id"] = frames.get_frame_count(animation_name) - 1
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
	
	
func _set_current_frame_texture(frames: SpriteFrames, res_name: String, animation_name: String) -> void:
	var element = get_node(res_name)
	element.texture = frames.get_frame_texture(animation_name, _animations[res_name]["frame_id"]);

func _stop(res_name: String, index: int) -> void:
	_active_animations.remove_at(index);
	_animations[res_name]["active_index"] = -1
	for animation: String in ANIMATION_NAMES:
		if _animations[animation]["active_index"] > index:
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
		_active_animations.append({"name": "default", "animation": weapon_two_sprite_frames});
		_animations[ANIMATION_NAMES[4]]["active_index"] = len(_active_animations) - 1;
	
	if _is_weapon_two: 
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[4]]["is_shrinking"] = false;
	_is_weapon_two = !_is_weapon_two;
	if !_is_past_tutorial && !_is_menu:
		_is_weapon_two_active = _is_weapon_two
	
func _on_menu_toggle() -> void:
	if _animations[ANIMATION_NAMES[0]]["active_index"] == -1:
		_active_animations.append({"name": "default", "animation": branch_one_full_sprite_frames});
		_animations[ANIMATION_NAMES[0]]["active_index"] = len(_active_animations) - 1;
	
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
		_active_animations.append({"name": "default", "animation": branch_two_sprite_frames});
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
		_active_animations.append({"name": "default", "animation": branch_three_sprite_frames});
		_animations[ANIMATION_NAMES[2]]["active_index"] = len(_active_animations) - 1;
	
	if _is_branch_three: 
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = true;
	else:
		_animations[ANIMATION_NAMES[2]]["is_shrinking"] = false;
	_is_branch_three = !_is_branch_three;
	if !_is_past_tutorial && !_is_menu:
		_is_branch_three_active = _is_branch_three
