extends MarginContainer

signal _on_menu_
@onready var health_bar = $player_stats/health/health_bar
@onready var stamina_bar = $player_stats/stamina/stamina_bar
@onready var mana_bar = $player_stats/mana/mana_bar

@onready var player = GlobalPlayer.get_player()

var is_health: bool = true;
var is_stamina: bool = false;
var is_mana: bool = false;

var health_stages: float = 4;
var stamina_stages: float = 4;
var mana_stages: float = 4;

var health_sprite_frames: SpriteFrames = preload("res://assets/textures/ui_textures/interface/stats/health/health.tres");
var stamina_sprite_frames: SpriteFrames = preload("res://assets/textures/ui_textures/interface/stats/stamina/stamina.tres");
var mana_sprite_frames: SpriteFrames = preload("res://assets/textures/ui_textures/interface/stats/mana/mana.tres");

var leaf_textures: Array[String] = ["leaf_one", "leaf_two", "leaf_three", "leaf_four"];
var stamina_textures: Array[String] = ["berry_one", "berry_two", "berry_three", "berry_four"];
var mana_textures: Array[String] = ["crystal_one", "crystal_two", "crystal_three", "crystal_four",];

var _is_menu = false

func _ready() -> void:
	if !is_health:
		health_bar.visible = false;
	if !is_stamina:
		stamina_bar.visible = false;
	if !is_mana:
		mana_bar.visible = false;

	player.health_changed.connect(_on_player_health_changed)
	player.stamina_changed.connect(_on_player_stamina_changed)
	player.mana_changed.connect(_on_player_mana_changed)
	player.toggle_stamina.connect(toggle_stamina)
	player.toggle_mana.connect(toggle_mana)
	UIManager.toggle_menu.connect(_toggle_stats)
	
func _on_player_health_changed() -> void:
	var percentage_range: float = 1 / health_stages;
	var health_percentage: float =	player.health / player.max_health;
		
	_update_textures(percentage_range, health_percentage, leaf_textures, health_sprite_frames, int(health_stages), health_bar, player.health);

func _on_player_stamina_changed() -> void:
	var percentage_range: float = 1 / stamina_stages;
	var stamina_percentage: float = player.stamina/ player.max_stamina;
	
	_update_textures(percentage_range, stamina_percentage, stamina_textures, stamina_sprite_frames, int(stamina_stages), stamina_bar, player.stamina);

func _on_player_mana_changed() -> void:
	var percentage_range: float = 1 / mana_stages;
	var mana_percentage: float = player.mana/ player.max_mana;
	
	_update_textures(percentage_range, mana_percentage, mana_textures, mana_sprite_frames, int(mana_stages), mana_bar, player.mana);
	
func _update_textures(percentage_range: float, percentage: float, textures: Array[String], sprite_frames: SpriteFrames, stages: int, bar: HBoxContainer, stat: float) -> void:
	var normalize_frame_id: float = 1.0 if sprite_frames.get_frame_count("default") > 12 else 5.0
	var frame_count = sprite_frames.get_frame_count("default")
	var current_stage = min(int(floor((stat / 50))), 3)
	var percentage_in_range: float = (stat / 50) - current_stage ;
	var frame_id: int = max(frame_count - roundi(percentage_in_range * frame_count) - 1, 0)
	var element: TextureRect = bar.get_node(textures[current_stage] + "/pivot_bl/texture")
	element.texture = sprite_frames.get_frame_texture("default", frame_id)
	for larger_index in range((stages - 1), current_stage, -1):
		var larger_element: TextureRect = bar.get_node(textures[larger_index] + "/pivot_bl/texture")
		larger_element.texture = sprite_frames.get_frame_texture("default", frame_count - 1)




func _toggle_stats() -> void:
	var delay_between := 0.02    # spacing between leaves (seconds)
	var per_stat_time := 0.08    # fade/scale duration per leaf
	var stats: Array[Array] = [leaf_textures, stamina_textures, mana_textures]
	var bars: Array[HBoxContainer] = [health_bar, stamina_bar, mana_bar]
	for index in stats.size():
		var texture_order: Array = stats[index].duplicate()  # don't mutate the base array
		if _is_menu:
			texture_order.reverse()
		_tween_stats(texture_order, per_stat_time, bars, index)
	
	_is_menu = !_is_menu
	
func _tween_stats(texture_order: Array[String], dur: float, bars: Array[HBoxContainer], index: int, appear: bool = _is_menu) -> Tween:
	var t := get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_OUT if appear else Tween.EASE_IN
		)  # feel
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if appear:
		t.tween_interval(1.0) 
	for path in texture_order:
		print(path)
		var texture_scale: Vector2 = Vector2(0.8, 0.8) if path.contains("berry") else Vector2.ONE
		var stat: TextureRect = bars[index].get_node(path + "/pivot_bl/texture")
		if appear:
			t.tween_callback(func():
				stat.modulate.a = 0.0
				stat.scale = Vector2.ZERO
			)
		t.parallel().tween_property(stat, "modulate:a", 1.0 if appear else 0.0, dur)
		t.parallel().tween_property(stat, "scale", texture_scale if appear else Vector2.ZERO, dur)
		t.tween_interval(0.02)
	return t
	
func _on_max_health_increase() -> void:
	player.max_health += 50
	health_stages += 1
	match health_stages:
		5: leaf_textures.push_front("leaf_five");
		6: 
			leaf_textures.push_front("leaf_six");

func toggle_stamina(value) -> void:
	var texture_order: Array = stamina_textures.duplicate()  # don't mutate the base array
	var appear = false;
	if value:
		is_stamina = true;
		stamina_bar.visible = true;
		texture_order.reverse()
		appear = true
	else:
		is_stamina = false;
		stamina_bar.visible = false;
	_tween_stats(texture_order, 0.08, [stamina_bar], 0, appear)
		
func toggle_mana(value) -> void:
	var texture_order: Array = mana_textures.duplicate()  # don't mutate the base array
	var appear = false;
	if value:
		is_mana = true;
		mana_bar.visible = true;
		texture_order.reverse()
		appear = true
	else:
		is_mana = false;
		mana_bar.visible = false;
	_tween_stats(texture_order, 0.08, [mana_bar], 0, appear)
