extends Node3D

const UPGRADE_LEVEL_NO_WEAPON: int = 0
const UPGRADE_LEVEL_WOOD_WEAPON: int = 1
const UPGRADE_LEVEL_WEAPON: int = 2
const UPGRADE_LEVEL_METAL_WEAPON: int = 3

# Main hand is right hand and off-hand is left hand
@export_category("Main Hand Weapons")
@export_subgroup("Swords")
@export var main_hand_wood_sword: MeshInstance3D
@export var main_hand_sword: MeshInstance3D
@export var main_hand_metal_sword: MeshInstance3D
@export_subgroup("Staffs")
@export var main_hand_wood_staff: MeshInstance3D
@export var main_hand_crystal_wood_staff: MeshInstance3D
@export var main_hand_staff: MeshInstance3D
@export var main_hand_metal_staff: MeshInstance3D
@export var main_hand_crystal_metal_staff: MeshInstance3D

@export_category("Off-Hand Weapons")
@export_subgroup("Bows")
@export var off_hand_wood_bow: MeshInstance3D
@export var off_hand_bow: MeshInstance3D
@export var off_hand_metal_bow: MeshInstance3D
@export_subgroup("Shields")
@export var off_hand_wood_shield: MeshInstance3D
@export var off_hand_shield: MeshInstance3D
@export var off_hand_metal_shield: MeshInstance3D

@export_category("Back Weapons")
@export_subgroup("Swords")
@export var back_wood_sword: MeshInstance3D
@export var back_sword: MeshInstance3D
@export var back_metal_sword: MeshInstance3D
@export_subgroup("Staffs")
@export var back_wood_staff: MeshInstance3D
@export var back_crystal_wood_staff: MeshInstance3D
@export var back_staff: MeshInstance3D
@export var back_metal_staff: MeshInstance3D
@export var back_crystal_metal_staff: MeshInstance3D
@export_subgroup("Bows")
@export var back_wood_bow: MeshInstance3D
@export var back_bow: MeshInstance3D
@export var back_metal_bow: MeshInstance3D
@export_subgroup("Shields")
@export var back_wood_shield: MeshInstance3D
@export var back_shield: MeshInstance3D
@export var back_metal_shield: MeshInstance3D


var sword_name = "Sword"
var shield_name = "Shield"
var staff_name = "Staff"
var bow_name = "Bow"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_interact_ray_cast_interacted_with_socket(hit_object: Variant) -> void:
	take_weapon(hit_object)

func swapping_weapons():
	if (
		Input.is_action_just_pressed("weapon_swap") 
		and GameManager.get_is_attacking() == false 
		and GameManager.get_is_dodging() == false 
		and GameManager.get_is_blocking() == false
		and GameManager.get_first_weapon() == true
		and GameManager.get_second_weapon() == true
		):
		# Dont swap if Sword and Shield
		if GameManager.get_first_weapon_name() == sword_name and GameManager.get_second_weapon_name() == shield_name:
			pass
		else:
			match GameManager.get_second_weapon_name():
				sword_name:
					pass
					#sword_main.visible = true
					#sword_main.process_mode = Node.PROCESS_MODE_INHERIT
					#sword_back.visible = false
				staff_name:
					pass
					#staff_main.visible = true
					#staff_back.visible = false
				bow_name:
					pass
					#bow_main.visible = true
					#bow_back.visible = false
				shield_name:
					pass
					#shield_main.visible = true
					#shield_back.visible = false
						
			match GameManager.get_first_weapon():
				sword_name:
					pass
					#sword_back.visible = true
					#sword_main.visible = false
					#sword_main.process_mode = Node.PROCESS_MODE_DISABLED
				staff_name:
					pass
					#staff_back.visible = true
					#staff_main.visible = false
				bow_name:
					pass
					#bow_back.visible = true
					#bow_main.visible = false
				shield_name:
					pass
					#shield_back.visible = true
					#shield_main.visible = false
						
			#var first_weapon_game_manager = GameManager.get_first_weapon()
			#var second_weapon_game_manager = GameManager.get_second_weapon()
			#GameManager.set_first_weapon(second_weapon_game_manager)
			#GameManager.set_second_weapon(first_weapon_game_manager)
			#GameManager.weapons_updated()

func take_weapon(hit_object):
	if hit_object.get_empty_socket() == false:
		var socket_weapon = hit_object.get_current_weapon_in_socket()
		if GameManager.get_first_weapon() == false:
			take_weapon_while_no_equipped_weapon(hit_object, socket_weapon)
		elif GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == false:
			take_weapon_while_first_weapon_active(hit_object, socket_weapon)
		elif GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == true:
			take_weapon_while_first_and_second_weapon_active(hit_object, socket_weapon)
		
func take_weapon_while_no_equipped_weapon(hit_object, socket_weapon):
	match socket_weapon:
		sword_name:
			main_hand_wood_sword.visible = true
		staff_name:
			main_hand_wood_staff.visible = true
			main_hand_crystal_wood_staff.visible = true
		bow_name:
			off_hand_wood_bow.visible = true
		shield_name:
			off_hand_wood_shield.visible = true
	hit_object.interact(owner)
	GameManager.set_first_weapon(true)
	GameManager.set_first_weapon_name(socket_weapon)
	GameManager.set_first_weapon_upgrade_level(UPGRADE_LEVEL_WOOD_WEAPON)
	GameManager.weapons_updated()

func take_weapon_while_first_weapon_active(hit_object, socket_weapon):
	# If you take a sword and your main weapon is a shield, swap sword to main hand and place shield to offhand
	if GameManager.get_first_weapon_name() == shield_name and socket_weapon == sword_name:
		main_hand_wood_sword.visible = true
		hit_object.interact(owner)
		GameManager.set_second_weapon(true)
		GameManager.set_second_weapon_upgrade_level(GameManager.get_first_weapon_upgrade_level())
		GameManager.set_second_weapon_name(GameManager.get_first_weapon_name())
		GameManager.weapons_updated()
		GameManager.set_first_weapon_name(socket_weapon)
		GameManager.set_first_weapon_upgrade_level(UPGRADE_LEVEL_WOOD_WEAPON)
		GameManager.weapons_updated()
	else:
		match socket_weapon:
			sword_name:
				back_wood_sword.visible = true
			staff_name:
				back_wood_staff.visible = true
				back_crystal_wood_staff.visible = true
			bow_name:
				back_wood_bow.visible = true
			shield_name:
				# If you take a shield and your main weapon is a sword, place shield to offhand
				if GameManager.get_first_weapon_name() == sword_name:
					off_hand_wood_shield.visible = true
				else:
					back_wood_shield.visible = true
		hit_object.interact(owner)
		GameManager.set_second_weapon(true)
		GameManager.set_second_weapon_name(socket_weapon)
		GameManager.set_second_weapon_upgrade_level(UPGRADE_LEVEL_WOOD_WEAPON)
		GameManager.weapons_updated()


func take_weapon_while_first_and_second_weapon_active(hit_object, socket_weapon):
	remove_first_weapon()
	if socket_weapon == shield_name and GameManager.get_second_weapon_name() == sword_name:
		take_shield_while_having_sword_as_second_weapon(hit_object, socket_weapon)
	else:
		if GameManager.get_first_weapon_name() == sword_name and GameManager.get_second_weapon_name() == shield_name:
			take_weapon_while_having_sword_and_shield(socket_weapon)
		elif GameManager.get_second_weapon_name() == shield_name and socket_weapon == sword_name:
			take_sword_while_having_shield_as_second_weapon()
		else:
			swap_current_first_weapon_with_socket_weapon(socket_weapon)
		hit_object.interact(owner)
		GameManager.set_first_weapon_name(socket_weapon)
		GameManager.set_first_weapon_upgrade_level(UPGRADE_LEVEL_WOOD_WEAPON)
		GameManager.weapons_updated()

func take_shield_while_having_sword_as_second_weapon(hit_object, socket_weapon):
		main_hand_wood_sword.visible = true
		back_wood_sword.visible = false
		off_hand_wood_shield.visible = true
		hit_object.interact(owner)
		GameManager.set_first_weapon_name(GameManager.get_second_weapon_name())
		GameManager.set_first_weapon_upgrade_level(GameManager.get_second_weapon_upgrade_level())
		GameManager.weapons_updated()
		GameManager.set_second_weapon_name(socket_weapon)
		GameManager.set_second_weapon_upgrade_level(UPGRADE_LEVEL_WOOD_WEAPON)
		GameManager.weapons_updated()

func take_weapon_while_having_sword_and_shield(socket_weapon):
	off_hand_wood_shield.visible = false
	back_wood_shield.visible = true
	match socket_weapon:
		staff_name:
			main_hand_wood_staff.visible = true
		bow_name:
			off_hand_wood_bow.visible = true
			
func take_sword_while_having_shield_as_second_weapon():
	off_hand_wood_shield.visible = true
	back_wood_shield.visible = false
	main_hand_wood_sword.visible = true
	
func remove_first_weapon():
	match GameManager.get_first_weapon_name():
		sword_name:
			main_hand_wood_sword.visible = false
		staff_name:
			main_hand_wood_staff.visible = false
		bow_name:
			off_hand_wood_bow.visible = false
		shield_name:
			off_hand_wood_shield.visible = false

func swap_current_first_weapon_with_socket_weapon(socket_weapon):
	match socket_weapon:
		sword_name:
			main_hand_wood_sword.visible = true
		staff_name:
			main_hand_wood_staff.visible = true
		bow_name:
			off_hand_wood_bow.visible = true
		shield_name:
			off_hand_wood_shield.visible = true
