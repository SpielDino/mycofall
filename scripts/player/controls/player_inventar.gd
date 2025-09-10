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
var empty_weapon_name = ""

func _physics_process(delta: float) -> void:
	swapping_weapons()

func _on_interact_ray_cast_interacted_with_socket(hit_object: Variant) -> void:
	if (
		GameManager.get_is_attacking() == false 
		and GameManager.get_is_dodging() == false 
		and GameManager.get_is_blocking() == false
		):
		if hit_object.get_empty_socket() == false:
			take_weapon_from_socket(hit_object)
		else:
			put_equipped_weapon_to_socket(hit_object)

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
			swap_second_weapon_to_first_weapon_based_on_upgrade_level()
			swap_first_weapon_to_second_weapon_based_on_upgrade_level()
			var first_weapon_name = GameManager.get_first_weapon_name()
			var second_weapon_name = GameManager.get_second_weapon_name()
			GameManager.set_first_weapon_name(second_weapon_name)
			GameManager.weapons_updated()
			GameManager.set_second_weapon_name(first_weapon_name)
			GameManager.weapons_updated()

func swap_second_weapon_to_first_weapon_based_on_upgrade_level():
	var second_weapon_upgrade_level = GameManager.get_second_weapon_upgrade_level()
	match GameManager.get_second_weapon_name():
		sword_name:
			match second_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_sword.visible = false
					main_hand_wood_sword.visible = true
				UPGRADE_LEVEL_WEAPON:
					back_sword.visible = false
					main_hand_sword.visible = true
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_sword.visible = false
					main_hand_metal_sword.visible = true
		staff_name:
			match second_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_staff.visible = false
					back_crystal_wood_staff.visible = false
					main_hand_wood_staff.visible = true
					main_hand_crystal_wood_staff.visible = true
				UPGRADE_LEVEL_WEAPON:
					back_staff.visible = false
					main_hand_staff.visible = true
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_staff.visible = false
					back_crystal_metal_staff.visible = false
					main_hand_metal_staff.visible = true
					main_hand_crystal_metal_staff.visible = true
		bow_name:
			match second_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_bow.visible = false
					off_hand_wood_bow.visible = true
				UPGRADE_LEVEL_WEAPON:
					back_bow.visible = false
					off_hand_bow.visible = true
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_bow.visible = false
					off_hand_metal_bow.visible = true
		shield_name:
			match second_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_shield.visible = false
					off_hand_wood_shield.visible = true
				UPGRADE_LEVEL_WEAPON:
					back_shield.visible = false
					off_hand_shield.visible = true
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_shield.visible = false
					off_hand_metal_shield.visible = true

func swap_first_weapon_to_second_weapon_based_on_upgrade_level():
	var first_weapon_upgrade_level = GameManager.get_first_weapon_upgrade_level()
	match GameManager.get_first_weapon_name():
		sword_name:
			match first_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_sword.visible = true
					main_hand_wood_sword.visible = false
				UPGRADE_LEVEL_WEAPON:
					back_sword.visible = true
					main_hand_sword.visible = false
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_sword.visible = true
					main_hand_metal_sword.visible = false
		staff_name:
			match first_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_staff.visible = true
					back_crystal_wood_staff.visible = true
					main_hand_wood_staff.visible = false
					main_hand_crystal_wood_staff.visible = false
				UPGRADE_LEVEL_WEAPON:
					back_staff.visible = true
					main_hand_staff.visible = false
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_staff.visible = true
					back_crystal_metal_staff.visible = true
					main_hand_metal_staff.visible = false
					main_hand_crystal_metal_staff.visible = false
		bow_name:
			match first_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_bow.visible = true
					off_hand_wood_bow.visible = false
				UPGRADE_LEVEL_WEAPON:
					back_bow.visible = true
					off_hand_bow.visible = false
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_bow.visible = true
					off_hand_metal_bow.visible = false
		shield_name:
			match first_weapon_upgrade_level:
				UPGRADE_LEVEL_WOOD_WEAPON:
					back_wood_shield.visible = true
					off_hand_wood_shield.visible = false
				UPGRADE_LEVEL_WEAPON:
					back_shield.visible = true
					off_hand_shield.visible = false
				UPGRADE_LEVEL_METAL_WEAPON:
					back_metal_shield.visible = true
					off_hand_metal_shield.visible = false

func take_weapon_from_socket(hit_object):
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
			main_hand_crystal_wood_staff.visible = false
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

func put_equipped_weapon_to_socket(hit_object):
	if GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == false:
		put_away_weapon_while_first_weapon_active(hit_object)
	elif GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == true:
		put_away_weapon_while_first_weapon_and_second_weapon_active(hit_object)

func put_away_weapon_while_first_weapon_active(hit_object):
	remove_first_weapon()
	hit_object.interact(owner)
	GameManager.set_first_weapon(false)
	GameManager.set_first_weapon_name(empty_weapon_name)
	GameManager.set_first_weapon_upgrade_level(UPGRADE_LEVEL_NO_WEAPON)
	GameManager.weapons_updated()

func put_away_weapon_while_first_weapon_and_second_weapon_active(hit_object):
	remove_first_weapon()
	equip_second_weapon_as_first_weapon()
	hit_object.interact(owner)
	GameManager.set_first_weapon_name(GameManager.get_second_weapon_name())
	GameManager.set_first_weapon_upgrade_level(GameManager.get_second_weapon_upgrade_level())
	GameManager.weapons_updated()
	GameManager.set_second_weapon(false)
	GameManager.set_second_weapon_name(empty_weapon_name)
	GameManager.set_second_weapon_upgrade_level(UPGRADE_LEVEL_NO_WEAPON)
	GameManager.weapons_updated()

func equip_second_weapon_as_first_weapon():
	match GameManager.get_second_weapon_name():
		sword_name:
			back_wood_sword.visible = false
			main_hand_wood_sword.visible = true
		staff_name:
			back_wood_staff.visible = false
			back_crystal_wood_staff.visible = false
			main_hand_wood_staff.visible = true
			main_hand_crystal_wood_staff.visible = true
		bow_name:
			back_wood_bow.visible = false
			off_hand_wood_bow.visible = true
		shield_name:
			if GameManager.get_first_weapon_name() == sword_name:
				pass
			else:
				back_wood_shield.visible = false
				off_hand_wood_shield.visible = true

func debug_game_manager_variables():
	print("First Weapon")
	print(GameManager.get_first_weapon())
	print(GameManager.get_first_weapon_name())
	print(GameManager.get_first_weapon_upgrade_level())
	print("Second Weapon")
	print(GameManager.get_second_weapon())
	print(GameManager.get_second_weapon_name())
	print(GameManager.get_second_weapon_upgrade_level())
