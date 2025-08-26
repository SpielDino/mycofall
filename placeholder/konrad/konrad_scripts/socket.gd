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

@onready var attachment = $"Weapon Slot"

# Models
@onready var bow = preload("res://assets/models/weapons/alt_bogen.blend")
@onready var shield = preload("res://assets/models/weapons/alt_schild.blend")
@onready var staff = preload("res://assets/models/weapons/alt_stab.blend")
@onready var sword = preload("res://assets/models/weapons/alt_schwert.blend")

func _ready() -> void:
	sword_intance = sword.instantiate()
	staff_intance = staff.instantiate()
	bow_intance = bow.instantiate()
	shield_intance = shield.instantiate()
	
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
	if empty_socket == false and GameManager.get_weapon_in_hand() == false:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		current_weapon_in_socket = ""
		empty_socket = true
		
	elif empty_socket == true and GameManager.get_weapon_in_hand() == true:
		var player_weapon = GameManager.get_first_weapon()
		match player_weapon:
			sword_name:
				attachment.add_child(sword_intance)
				current_weapon_in_socket = sword_intance.get_name()
			staff_name:
				attachment.add_child(staff_intance)
				current_weapon_in_socket = staff_intance.get_name()
			bow_name:
				attachment.add_child(bow_intance)
				current_weapon_in_socket = bow_intance.get_name()
			shield_name:
				attachment.add_child(shield_intance)
				current_weapon_in_socket = shield_intance.get_name()
		empty_socket = false
		
	elif empty_socket == false and GameManager.get_weapon_in_hand() == true and GameManager.get_weapon_on_back() == false:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		current_weapon_in_socket = ""
		empty_socket = true
		
	elif empty_socket == false and GameManager.get_weapon_in_hand() == true and GameManager.get_weapon_on_back() == true:
		var attachment_weapon = attachment.get_child(0)
		attachment.remove_child(attachment_weapon)
		var player_weapon = GameManager.get_first_weapon()
		match player_weapon:
			sword_name:
				attachment.add_child(sword_intance)
				current_weapon_in_socket = sword_intance.get_name()
			staff_name:
				attachment.add_child(staff_intance)
				current_weapon_in_socket = staff_intance.get_name()
			bow_name:
				attachment.add_child(bow_intance)
				current_weapon_in_socket = bow_intance.get_name()
			shield_name:
				attachment.add_child(shield_intance)
				current_weapon_in_socket = shield_intance.get_name()
		empty_socket = false

func get_current_weapon_in_socket():
	return current_weapon_in_socket

func get_empty_socket():
	return empty_socket
