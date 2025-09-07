class_name Socket
extends Interactable

@export_enum("SWORD", "STAFF", "BOW", "SHIELD", "NOTHING") var Weapon: String = "SWORD"
@export_category("Items")
@export_subgroup("Weapons")

var sword_name = "Sword"
var shield_name = "Shield"
var staff_name = "Staff"
var bow_name = "Bow"

var socket_sword_name = "SWORD"
var socket_shield_name = "SHIELD"
var socket_staff_name = "STAFF"
var socket_bow_name = "BOW"

var sword_intance
var staff_intance
var bow_intance
var shield_intance

var empty_socket = true
var current_weapon_in_socket = ""

var bow_scale = 0.5

@onready var attachment = $"WeaponSlot"

# Models
@onready var bow = preload("res://placeholder/konrad/konrad_scenes/bow.tscn")
@onready var shield = preload("res://placeholder/konrad/konrad_scenes/shield.tscn")
@onready var staff = preload("res://placeholder/konrad/konrad_scenes/staff.tscn")
@onready var sword = preload("res://placeholder/konrad/konrad_scenes/sword.tscn")

func _ready() -> void:
	sword_intance = sword.instantiate()
	staff_intance = staff.instantiate()
	bow_intance = bow.instantiate()
	shield_intance = shield.instantiate()
	
	bow_intance.scale = Vector3(bow_scale, bow_scale, bow_scale)
	
	match Weapon:
		socket_sword_name:
			attachment.add_child(sword_intance)
			empty_socket = false
			current_weapon_in_socket = sword_name
		socket_staff_name:
			attachment.add_child(staff_intance)
			empty_socket = false
			current_weapon_in_socket = staff_name
		socket_bow_name:
			attachment.add_child(bow_intance)
			empty_socket = false
			current_weapon_in_socket = bow_name
		socket_shield_name:
			attachment.add_child(shield_intance)
			empty_socket = false
			current_weapon_in_socket = shield_name

func _on_interacted(body: Variant) -> void:
	# Take a weapon without having a weapon
	if empty_socket == false and GameManager.get_first_weapon() == false:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		current_weapon_in_socket = ""
		empty_socket = true
	
	# Put away weapon
	elif empty_socket == true and GameManager.get_first_weapon() == true:
		var player_weapon = GameManager.get_first_weapon_name()
		match player_weapon:
			sword_name:
				attachment.add_child(sword_intance)
				current_weapon_in_socket = sword_name
			staff_name:
				attachment.add_child(staff_intance)
				current_weapon_in_socket = staff_name
			bow_name:
				attachment.add_child(bow_intance)
				current_weapon_in_socket = bow_name
			shield_name:
				attachment.add_child(shield_intance)
				current_weapon_in_socket = shield_name
		empty_socket = false
		
	# Take a 2nd weapon while having 1 weapon
	elif empty_socket == false and GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == false:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		current_weapon_in_socket = ""
		empty_socket = true
		
	# Swap weapon in hand with socket weapon (only works if you have 2 weapons)
	elif empty_socket == false and GameManager.get_first_weapon() == true and GameManager.get_second_weapon() == true:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		var player_weapon = GameManager.get_first_weapon_name()
		match player_weapon:
			sword_name:
				attachment.add_child(sword_intance)
				current_weapon_in_socket = sword_name
			staff_name:
				attachment.add_child(staff_intance)
				current_weapon_in_socket = staff_name
			bow_name:
				attachment.add_child(bow_intance)
				current_weapon_in_socket = bow_name
			shield_name:
				attachment.add_child(shield_intance)
				current_weapon_in_socket = shield_name
		empty_socket = false

func get_current_weapon_in_socket():
	return current_weapon_in_socket

func get_empty_socket():
	return empty_socket
