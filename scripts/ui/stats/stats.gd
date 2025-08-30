extends MarginContainer

@onready var health_bar = $health/health_bar

var max_health: float = 200;
var health: float = 200;
var health_sprite_frames: SpriteFrames = load("res://assets/textures/ui_textures/interface/stats/health/health.tres");

func _on_player_health_change() -> void:
	print(health)
	var health_stages: float = max_health / 50;
	var percentage_range: float = 1 / health_stages;
	var health_percentage: float = health / max_health;
	print(health_percentage)
	print(percentage_range)
	print(health_stages)
	var textures: Array[String] = ["leaf_four", "leaf_three", "leaf_two", "leaf_one"];
	match health_stages:
		5: textures.push_front("leaf_five");
		6: 
			textures.push_front("leaf_five");
			textures.push_front("leaf_six");
		
	for i in range(0, health_stages):
		if health_percentage > percentage_range * (health_stages - (i + 1)):
			var health_percentage_in_range: float = health - (50 * (health_stages - (i + 1)));
			var frame_id: int = health_sprite_frames.get_frame_count("default") - (health_percentage_in_range / 5) - 1
			var element: TextureRect = health_bar.get_node(textures[i] + "/texture")
			element.texture = health_sprite_frames.get_frame_texture("default", frame_id);
			break;

func _on_payer_damaged_one() -> void:
	if health > 0:
		health -= 1
		_on_player_health_change()
	
func _on_payer_damaged_five() -> void:
	if health > 0:
		health -= 5
		_on_player_health_change()
	
func _on_payer_heal() -> void:
	if health < max_health:
		health += 5
		_on_player_health_change()
