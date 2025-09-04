extends RayCast3D

# Animation
@export_category("Animation")
@export var staff_animation_player: AnimationPlayer

var sword_name = "Sword"
var shield_name = "Shield"
var staff_name = "Staff"
var bow_name = "Bow"

var controller_input_device = false
var weapon

# Interacting
@onready var prompt = $Prompt

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if controller_input_device != true:
			controller_input_device = true
			#print("Switched to controller")
	elif event is InputEventKey or event is InputEventMouse:
		if controller_input_device != false:
			controller_input_device = false
			#print("Switched to keyboard/mouse")

func _physics_process(delta: float) -> void:
	interacting_with_world()

func interacting_with_world():
	prompt.text = ""
	
	if is_colliding():
		var hitObj = get_collider()
		
		if hitObj is Interactable:
			
			if hitObj is Socket and hitObj.get_empty_socket() == true and GameManager.get_weapon_in_hand() == false:
				pass
			else:
				prompt.text = hitObj.get_prompt(controller_input_device)
			
			if Input.is_action_just_pressed(hitObj.prompt_input):
				
				if hitObj is Socket:
					# Taking a Weapon
					if GameManager.get_weapon_in_hand() == false:
						if hitObj.get_empty_socket() == false:
							var weapon_name = hitObj.get_current_weapon_in_socket()
							match weapon_name:
								sword_name:
									pass
									#sword_main.visible = true
									#sword_main.process_mode = Node.PROCESS_MODE_INHERIT
								staff_name:
									pass
									#staff_main.visible = true
								bow_name:
									pass
									#bow_main.visible = true
								shield_name:
									pass
									#shield_main.visible = true
							hitObj.interact(owner)
							GameManager.set_weapon_in_hand()
							GameManager.set_first_weapon(weapon_name)
							GameManager.weapons_updated()
							#print(GameManager.get_first_weapon())
							#print(GameManager.get_weapon_in_hand())
							#print(1)
							
					# Interaction with only main weapon
					elif GameManager.get_weapon_in_hand() == true and GameManager.get_weapon_on_back() == false:
						# Taking a second weapon
						if hitObj.get_empty_socket() == false:
							var weapon_name = hitObj.get_current_weapon_in_socket()
							
							# If you take a sword and your main weapon is a shield, swap sword to main hand and place shield to offhand
							if GameManager.get_first_weapon() == shield_name and weapon_name == sword_name:
								#weapon = sword.instantiate()
								#shield_main.visible = false
								#shield_offhand.visible = true
								#sword_main.visible = true
								hitObj.interact(owner)
								GameManager.set_weapon_on_back()
								GameManager.set_second_weapon(GameManager.get_first_weapon())
								GameManager.weapons_updated()
								GameManager.set_first_weapon(weapon_name)
								GameManager.weapons_updated()
								#print(GameManager.get_first_weapon())
								#print(GameManager.get_second_weapon())
								#print(GameManager.get_weapon_in_hand())
								#print(GameManager.get_weapon_on_back())
								#print(2)
								
							else:
								# If you take a shield and your main weapon is a sword, place shield to offhand
								if GameManager.get_first_weapon() == sword_name and weapon_name == shield_name:
									pass
									#shield_offhand.visible = true
								# Any other combo of weapons leads to putting the second weapon to back
								else:
									match weapon_name:
										sword_name:
											pass
											#sword_back.visible = true
										staff_name:
											pass
											#staff_back.visible = true
										bow_name:
											pass
											#bow_back.visible = true
										shield_name:
											pass
											#shield_back.visible = true
											
								hitObj.interact(owner)
								GameManager.set_weapon_on_back()
								GameManager.set_second_weapon(weapon_name)
								GameManager.weapons_updated()
								#print(GameManager.get_first_weapon())
								#print(GameManager.get_weapon_in_hand())
								#print(GameManager.get_second_weapon())
								#print(GameManager.get_weapon_on_back())
								#print(3)
								
						# Returning your main weapon if you only have a main weapon
						else:
							match GameManager.get_first_weapon():
								sword_name:
									#sword_main.visible = false
									pass
								staff_name:
									pass
									#staff_main.visible = false
								bow_name:
									pass
									#bow_main.visible = false
								shield_name:
									pass
									#shield_main.visible = false
							hitObj.interact(owner)
							GameManager.set_first_weapon("")
							GameManager.set_weapon_in_hand()
							GameManager.weapons_updated()
							#print(GameManager.get_first_weapon())
							#print(GameManager.get_weapon_in_hand())
							#print(4)
							
					# Interaction with main weapon and second weapon
					elif GameManager.get_weapon_in_hand() == true and GameManager.get_weapon_on_back() == true:
						match GameManager.get_first_weapon():
							sword_name:
								pass
								#sword_main.visible = false
								#sword_main.process_mode = Node.PROCESS_MODE_DISABLED
							staff_name:
								pass
								#staff_main.visible = false
							bow_name:
								pass
								#bow_main.visible = false
							shield_name:
								pass
								#shield_main.visible = false
						# Returning main weapon while having second weapon
						if hitObj.get_empty_socket() == true:
							if GameManager.get_second_weapon() == shield_name and GameManager.get_first_weapon() == sword_name:
								pass
								#shield_offhand.visible = false
							else:
								match GameManager.get_second_weapon():
									sword_name:
										pass
										#sword_back.visible = false
									staff_name:
										pass
										#staff_back.visible = false
									bow_name:
										pass
										#bow_back.visible = false
									shield_name:
										pass
										#shield_back.visible = false
								
							match GameManager.get_second_weapon():
								sword_name:
									pass
									#sword_main.visible = true
									#sword_main.process_mode = Node.PROCESS_MODE_INHERIT
								staff_name:
									pass
									#staff_main.visible = true
								bow_name:
									pass
									#bow_main.visible = true
								shield_name:
									pass
									#shield_main.visible = true
									
							hitObj.interact(owner)
							#print(GameManager.get_first_weapon())
							#print(GameManager.get_second_weapon())
							GameManager.set_first_weapon(GameManager.get_second_weapon())
							GameManager.set_second_weapon("")
							GameManager.set_weapon_on_back()
							GameManager.weapons_updated()
							#print(GameManager.get_first_weapon())
							#print(GameManager.get_weapon_in_hand())
							#print(GameManager.get_second_weapon())
							#print(GameManager.get_weapon_on_back())

						# Swapping main weapon with a socket weapon
						elif hitObj.get_empty_socket() == false:
							var weapon_name = hitObj.get_current_weapon_in_socket()
							
							if GameManager.get_second_weapon() == sword_name and weapon_name == shield_name:
								#shield_offhand.visible = true
								#sword_back.visible = false
								#sword_main.visible = true
								#sword_main.process_mode = Node.PROCESS_MODE_INHERIT
								
								hitObj.interact(owner)
								GameManager.set_first_weapon(GameManager.get_second_weapon())
								GameManager.set_second_weapon(weapon_name)
								GameManager.weapons_updated()
							
							else:
								if GameManager.get_first_weapon() == sword_name and GameManager.get_second_weapon() == shield_name:
									#shield_offhand.visible = false
									#shield_back.visible = true
									
									match weapon_name:
										staff_name:
											pass
											#staff_main.visible = true
										bow_name:
											pass
											#bow_main.visible = true
											
								elif GameManager.get_second_weapon() == shield_name and weapon_name == sword_name:
									#shield_offhand.visible = true
									#shield_back.visible = false
									#sword_main.visible = true
									pass
									
								else:
									match weapon_name:
										sword_name:
											pass
											#sword_main.visible = true
										staff_name:
											pass
											#staff_main.visible = true
										bow_name:
											pass
											#bow_main.visible = true
										shield_name:
											pass
											#shield_main.visible = true
											
								hitObj.interact(owner)
								GameManager.set_first_weapon(weapon_name)
								GameManager.weapons_updated()
								#print(GameManager.get_first_weapon())
								#print(GameManager.get_weapon_in_hand())
								#print(GameManager.get_second_weapon())
								#print(GameManager.get_weapon_on_back())
								#print(6)
				else:
					hitObj.interact(owner)
