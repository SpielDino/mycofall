class_name Upgrade
extends Interactable

const UPGRADE_LEVEL_METAL_WEAPON: int = 3

var text_position: Node3D

func _on_interacted(body: Variant) -> void:
	text_position = self.get_node_or_null("TextPosition")
	upgrade_first_weapon()

func upgrade_first_weapon():
	if GameManager.get_first_weapon():
		if GameManager.get_first_weapon_upgrade_level() == UPGRADE_LEVEL_METAL_WEAPON:
			cant_upgrade_weapon_cause_first_weapon_is_fully_upgraded()
		else:
			can_upgrade_weapon()
	else:
		cant_upgrade_weapon_cause_no_first_weapon()

func can_upgrade_weapon():
	GameManager.use_signal_interacted_with_upgrade_item()
	if text_position:
		DamageNumbers.display_text("Weapon upgraded", text_position.global_position, 0.5)
	queue_free()

func cant_upgrade_weapon_cause_no_first_weapon():
	if text_position:
		DamageNumbers.display_text("No Weapon to upgrade", text_position.global_position, 0.5)

func cant_upgrade_weapon_cause_first_weapon_is_fully_upgraded():
	if text_position:
		DamageNumbers.display_text("Current weapon already fully upgraded", text_position.global_position, 0.5)
