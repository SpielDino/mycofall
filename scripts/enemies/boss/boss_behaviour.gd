extends CharacterBody3D

@export_category("Stats")

@export_subgroup("Boss Settings")
@export var base_aggression_level: float = 0
@export var move_points: Array[Node3D]

@export_subgroup("Enemy Stats")
@export var health: float = 1000
@export var speed: float = 4
@export var acceleration: float = 3

@export_category("Attacks")
@export_subgroup("Ranged Spore Attack")
@export var bullet_speed: float = 7
@export var bullet_damage: float = 5
@export var bullet_lifetime: float = 120
@export_range(0, 1) var homing_strength: float = 1
@export var homing_range: float = 500

@export_subgroup("Area Spore Attack")
@export var damage_interval: float = 0.2
@export var spore_area_damage: float = 5

@export_subgroup("ChargeAttack")
@export var charge_attack_damage: float = 50

@export_subgroup("SpearAttack")
@export var spear_damage: float = 25

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var spore_spawn_points = $SporeSpawnPoints
@onready var explosion_enemy_spawn_point = $ExplosionEnemySpawnPoint
@onready var animation_player = $Mesh/AnimationPlayer
@onready var spore_particles = $AreaDamageParticles
@onready var charge_collision = $ChargeCollision
@onready var launcher_sound_1 = $Sounds/LauncherSound1
@onready var launcher_sound_2 = $Sounds/LauncherSound2
@onready var squish_sound = $Sounds/SquishSound
@onready var spear_sound = $Sounds/SpearSound
@onready var walking_sound = $Sounds/WalkingSound
@onready var random_sound = $Sounds/RandomSound
@onready var poison_sound = $Sounds/PoisonSound
@onready var explosion_enemy_drop_points = $ExplosionsEnemySpawnpoints

@onready var health_bar = get_tree().current_scene.find_child("bossHealthMargin")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var bullet_scene: PackedScene = preload("res://scenes/prefabs/enemies/enemy_bullet.tscn")
var explosion_enemy: PackedScene = preload("res://scenes/prefabs/enemies/explosion_enemy.tscn")
var teleport_smoke: PackedScene = preload("res://scenes/prefabs/enemies/Boss_Teleport_Smoke.tscn")
#var win: PackedScene = preload("res://Prefabs/Asset Scenes/UI/win.tscn")

@onready var death_spores = GameManager.get_child_by_name(self, "DeathSpores")

var aggression: float = 0
var attacks_blocked_percentage: float = 0
var attacks_dodged_percentage: float = 0
var player
var detected_player: bool = false
var player_in_spore_area: bool = false
var rng = RandomNumberGenerator.new()
var area_attack_cooldown: float = 0
var active: bool = false
var spore_time: float = 0
var charge_attack_on_going: bool = false
var in_charge_attack_area: bool = false
var charge_hit: bool = false
var direction_to_player: Vector3
var target
var combo_area_1: bool = false
var combo_area_2: bool = false
var combo_area_3: bool = false
var spear_time_keeper: float = 0
var destination: Vector3
var death_timer: float = 10

enum action_types {NONE, EXPLOSION_ATTACK, RANGED_ATTACK, CHARGE_ATTACK, POISON_CLOUD_ATTACK, SPEAR_ATTACK}
var action_type = action_types.NONE
var action_time: float = 0

signal health_changed
signal boss_died

func _ready():
	calculate_aggression()
	calculate_blocks_and_dashes()
	player = GlobalPlayer.get_player()

func _physics_process(delta: float):
	die(delta)
	apply_gravity(delta)
	if active and death_timer == 10:
		action_manager(delta)

func calculate_aggression():
	aggression = base_aggression_level
	if GameManager.get_first_weapon_name() == "Bow" or GameManager.get_second_weapon_name() == "Bow": #Bow Equipped
		aggression += 0.3
	if GameManager.get_first_weapon_name() == "Staff" or GameManager.get_second_weapon_name() == "Staff": #Staff Equipped
		aggression += 0.2
	if GameManager.get_first_weapon_name() == "Sword" or GameManager.get_second_weapon_name() == "Sword": #Sword Equipped
		aggression -= 0.3
	var rangedKills: float = PlayerActionTracker.staff_kills + PlayerActionTracker.bow_kills
	var meleeKills: float = PlayerActionTracker.melee_kills
	var totalKills: float = rangedKills + meleeKills
	aggression += (rangedKills - meleeKills)/totalKills
	aggression = clamp(aggression, -0.7, 0.7)
	print(aggression)

func calculate_blocks_and_dashes():
	var attacksBlocked: float = PlayerActionTracker.attacks_blocked
	var attacksDodged: float = PlayerActionTracker.times_dodged_in_combat
	var totalDodgedAndBlocked: float = attacksBlocked + attacksDodged
	attacks_blocked_percentage = attacksBlocked / totalDodgedAndBlocked
	attacks_dodged_percentage = attacksDodged / totalDodgedAndBlocked
	attacks_blocked_percentage = clamp(attacks_blocked_percentage, 0.3, 0.7)
	attacks_dodged_percentage = clamp(attacks_blocked_percentage, 0.3, 0.7)
	print(attacks_blocked_percentage)
	print(attacks_dodged_percentage)
	

func activate_boss():
	calculate_aggression()
	calculate_blocks_and_dashes()
	active = true
	#health_bar.visible = true

func action_manager(delta):
	var playerPosition = player.get_child(0).global_position
	if action_time > 0:
		action_time -= delta
	if spore_time > 0:
		spore_time -= delta
	determine_next_action()
	
	if action_type == action_types.EXPLOSION_ATTACK:
		explosion_attack_action(delta, playerPosition)
	if action_type == action_types.CHARGE_ATTACK:
		charge_attack_action(delta)
	if action_type == action_types.RANGED_ATTACK:
		ranged_attack_action(delta, playerPosition)
	if action_type == action_types.POISON_CLOUD_ATTACK:
		spore_area_attack_action(delta)
	if action_type == action_types.SPEAR_ATTACK:
		spear_attack_action(delta, playerPosition)
		
	ongoing_spore_area_action(delta)
	apply_gravity(delta)
	move_and_slide()

func determine_next_action():
	if action_type == action_types.NONE:
		var ranged: bool = false
		var blockable: bool = false
		var randomAgressionValue: float = rng.randf_range(0.0, 1.0)
		var randomBlockValue: float = rng.randf_range(0.0, 1.0)
		var AreaAttackChance: float = rng.randf_range(0.0, 1.0)
		
		
		if AreaAttackChance < aggression and spore_time <= 0:
			action_type = action_types.POISON_CLOUD_ATTACK
			action_time = 200
		elif randomAgressionValue > aggression:
			if randomBlockValue > attacks_blocked_percentage:
				action_type = action_types.EXPLOSION_ATTACK #Unblockalbe and Ranged
				target = return_furthest_point_from_player()
				action_time = 200
			else:
				action_type = action_types.RANGED_ATTACK #Blockalbe and Ranged
				target = return_closest_point()
				action_time = 200
		else:
			if randomBlockValue > attacks_blocked_percentage:
				action_type = action_types.CHARGE_ATTACK #Unblockalbe and Melee
				target = return_closest_point()
				action_time = 200
			else:
				action_type = action_types.SPEAR_ATTACK #Blockalbe and Melee
				target = return_furthest_point_from_player()
				action_time = 200

#Boss Actions
#Movement
func reached_target(targetPoint):
	if global_position.distance_to(Vector3(targetPoint.x, global_position.y, targetPoint.z)) <= 2:
		return true
	return false

func return_closest_point():
	var closestPoint: Vector3
	if global_position.distance_to(move_points[0].global_position) >= 5:
		closestPoint = move_points[0].global_position
	else: 
		closestPoint = move_points[1].global_position
	for point in move_points:
		if self.global_position.distance_to(point.global_position) < self.global_position.distance_to(closestPoint) and global_position.distance_to(point.global_position) >= 5:
			closestPoint = point.global_position
	return closestPoint

func return_furthest_point_from_player():
	var furthestPoint: Vector3
	if global_position.distance_to(move_points[0].global_position) >= 5:
		furthestPoint = move_points[0].global_position
	else: 
		furthestPoint = move_points[1].global_position
	for point in move_points:
		if player.get_child(0).global_position.distance_to(point.global_position) > player.get_child(0).global_position.distance_to(furthestPoint) and global_position.distance_to(point.global_position) >= 5:
			furthestPoint = point.global_position
	return furthestPoint


func move_towards_target(delta, targetPoint):
	if !reached_target(targetPoint):
		var direction = Vector3()
		nav.target_position = Vector3(targetPoint.x, self.global_position.y, targetPoint.z)
		
		direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = velocity.lerp(direction * speed, acceleration * delta)
		rotate_to_target(targetPoint)
		animation_player.play("Running")
		if !walking_sound.playing:
			walking_sound.pitch_scale = 0.6
			walking_sound.play()
		return false
	else:
		velocity = Vector3(0, velocity.y, 0)
		return true

func rotate_to_target(targetPoint):
	var angleVector = targetPoint - global_position
	var angle = atan2(angleVector.x, angleVector.z)
	rotation.y = angle - PI/2

#Full Attack Actions
func explosion_attack_action(delta, playerPosition):
	if action_time > 101:
		if move_towards_target(delta, target):
			action_time = 100
	else:
		rotate_to_target(playerPosition)
		animation_player.play("Fire_bombs")
	if abs(action_time - (100 - 2.11)) <= 1:
		explosion_mini_enemies_attack()
		action_time = 50
		launcher_sound_1.play(0.52)
	elif abs(action_time - (50 - 1.55)) <= 1:
		explosion_mini_enemies_attack()
		action_time = 0.9
		launcher_sound_2.play(0.52)
	elif action_time <= 0:
		animation_player.stop()
		action_type = action_types.NONE

func ranged_attack_action(delta, playerPosition):
	if action_time > 101:
		if move_towards_target(delta, target):
			action_time = 100
	else:
		rotate_to_target(playerPosition)
		animation_player.play("Squish")
	if abs(action_time - (100 - 3.5)) <= 1:
		spore_ranged_attack()
		squish_sound.play()
		action_time = 0.65
	elif action_time <= 0:
		animation_player.stop()
		action_type = action_types.NONE

func spore_area_attack_action(delta):
	if action_time > 101:
		animation_player.play("Squish" )
		action_time = 100
	if abs(action_time - (100 - 3.5)) <= 1:
		action_time = 0.65
		squish_sound.play()
		spore_particles.emitting = true
		spore_time = 10
	elif action_time <= 0:
		animation_player.stop()
		poison_sound.play()
		action_type = action_types.NONE

func charge_attack_action(delta):
	if action_time > 101:
		if move_towards_target(delta, target):
			action_time = 100
	elif action_time > 51:
		charge_collision.disabled = false
		animation_player.play("Rush")
		charge_attack()
		if !walking_sound.playing:
			walking_sound.pitch_scale = 1
			walking_sound.play()
	if charge_hit and action_time >= 51:
		animation_player.play("Smash_After_Rush")
		action_time = 50
	if abs(action_time - (50 - 1.5)) <= 1:
		action_time = 0
		charge_hit = false
		charge_collision.disabled = true
		action_type = action_types.NONE

func die(delta):
	if death_timer < 10:
		death_timer -= delta
	if death_timer >= 5 and death_timer <= 9:
		#var win_scene = win.instantiate()
		#get_tree().current_scene.find_child("CanvasLayer").add_child(win_scene)
		animation_player.stop()
		animation_player.play("Die")
		death_timer = 3.9167

func spear_attack_action(delta, playerPosition):
	if action_time >= 151:
		if global_position.distance_to(playerPosition) >= 10:
			rotate_to_target(playerPosition)
			var smoke = teleport_smoke.instantiate()
			self.add_child(smoke)
			smoke.global_position = self.global_position
			smoke.get_child(0).emitting = true
			
			destination = playerPosition - Vector3(playerPosition - global_position).normalized() * 2.5
			
			var smoke2 = teleport_smoke.instantiate()
			self.add_child(smoke2)
			smoke2.global_position = destination
			smoke2.get_child(0).emitting = true
			action_time = 100
		else:
			if move_towards_target(delta, playerPosition):
				action_time = 100
	elif abs(action_time - (100 - 2)) <= 1:
		if global_position.distance_to(playerPosition) >= 10:
			global_position = destination
		animation_player.play("Attack_Combo")
		action_time = 50
	if action_time <= 50 and action_time >= 50 - 2.75:
		spear_melee_attack(delta)
	elif action_time <= 50 - 2:
		action_time = 0
		spear_time_keeper = 0
		action_type = action_types.NONE

func ongoing_spore_area_action(delta):
	if spore_time > 0:
		spore_area_attack(delta)
	else:
		spore_particles.emitting = false

#Attacks
func spore_ranged_attack():
	for spore_spawn_point in spore_spawn_points.get_children():
		var randomTrackingDelay = rng.randf_range(0.1, 0.2)
		var pos: Vector3 = spore_spawn_point.global_position
		var vel: Vector3 = pos - global_position
		var bullet = bullet_scene.instantiate()
		self.add_child(bullet)
		bullet.set_parameter(player, bullet_damage, bullet_speed, homing_range, homing_strength, vel, bullet_lifetime)
		bullet.set_tracking_delay(randomTrackingDelay)
		bullet.set_block_cost_modifier(0.5)
		bullet.global_position = pos

func charge_attack():
	if !charge_attack_on_going:
		var playerPosition: Vector3 = player.get_child(0).global_position
		direction_to_player = (playerPosition - global_position).normalized()
		rotate_to_target(playerPosition)
		charge_attack_on_going = true
	velocity = direction_to_player * 10
	if in_charge_attack_area:
		player.take_damage(charge_attack_damage, self, false, 0)
		in_charge_attack_area = false
	if charge_hit:
		charge_attack_on_going = false

func explosion_mini_enemies_attack():
	var temp_explosion_enemy: Node3D = explosion_enemy.instantiate()
	GlobalPlayer.get_world().add_child(temp_explosion_enemy)
	temp_explosion_enemy.get_child(0).is_tracking = false
	temp_explosion_enemy.get_child(1).return_to_idle_point = false
	temp_explosion_enemy.get_child(2).lifetime = 8
	temp_explosion_enemy.state = temp_explosion_enemy.States.ATTACK_TYPE_2
	temp_explosion_enemy.global_position = explosion_enemy_spawn_point.global_position
	temp_explosion_enemy.velocity = Vector3(0, 30, 0)
	await get_tree().create_timer(3).timeout
	temp_explosion_enemy.velocity = Vector3(0, 0, 0)
	var rnd_x = rng.randf_range(-10.0, 10.0)
	var rnd_z = rng.randf_range(-10.0, 10.0)
	temp_explosion_enemy.global_position = Vector3(explosion_enemy_drop_points.global_position.x + rnd_x, explosion_enemy_drop_points.global_position.y + 30, explosion_enemy_drop_points.global_position.z + rnd_z)
	temp_explosion_enemy.velocity = Vector3(0, -50, 0)
	temp_explosion_enemy.state = temp_explosion_enemy.States.IDLE
	print(temp_explosion_enemy.velocity)
	await get_tree().create_timer(2.5).timeout
	temp_explosion_enemy.get_child(0).is_tracking = true
	temp_explosion_enemy.get_child(0).activate_tracking()

func spear_melee_attack(delta):
	spear_time_keeper += delta
	if spear_time_keeper >= 0.64 and spear_time_keeper <= 0.73:
		spear_sound.play()
		if combo_area_1:
			player.take_damage(spear_damage, self, true, 0.5)
			combo_area_1 = false
	elif spear_time_keeper >= 1.12 and spear_time_keeper <= 1.16:
		spear_sound.play()
		if combo_area_2:
			player.take_damage(spear_damage, self, true, 0.5)
			combo_area_2 = false
	elif spear_time_keeper >= 1.7 and spear_time_keeper <= 2.1:
		spear_sound.play()
		if combo_area_3:
			player.take_damage(spear_damage, self, true, 0.5)
			combo_area_3 = false

func spore_area_attack(delta):
	area_attack_cooldown -= delta
	if area_attack_cooldown <= 0:
		if player_in_spore_area:
			player.take_damage(spore_area_damage, self, false, 0)
		area_attack_cooldown = damage_interval

func apply_gravity(delta):
	velocity.y += -gravity * delta

func take_damage(damage: int, type: String, has_knockback: bool = false, knockback_strenght: float = 0):
	if !active:
		activate_boss()
	health -= damage
	health_changed.emit()
	if health <= 0:
		death_timer = 8
	else:
		if has_knockback:
			var direction = (global_position - player.get_child(0).global_position).normalized()
			velocity += direction * knockback_strenght

func _on_detection_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		detected_player = true
		player.add_detecting_enemy([self])

func _on_detection_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		detected_player = false
		player.add_detecting_enemy([self])

func _on_spore_damage_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_in_spore_area = true

func _on_spore_damage_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player_in_spore_area = false

func _on_charge_attack_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		in_charge_attack_area = true
		charge_hit = true

func _on_charge_attack_body_entered(body: Node3D) -> void:
	if body.is_in_group("World"):
		charge_hit = true

func _on_spear_combo_1_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_1 = true

func _on_spear_combo_2_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_2 = true
	
func _on_spear_combo_3_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_3 = true

func _on_spear_combo_1_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_1 = false

func _on_spear_combo_2_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_2 = false

func _on_spear_combo_3_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		combo_area_3 = false

func _on_boss_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		activate_boss()
