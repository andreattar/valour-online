extends Resource
class_name ItemResource
## Definition for an item: gear, consumables, misc.

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MISC }
enum EquipSlot { NONE, HEAD, BODY, LEGS, FEET, MAIN_HAND, OFF_HAND, RING, AMULET }

@export var id: String = ""
@export var display_name: String = "Item"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Type")
@export var item_type: ItemType = ItemType.MISC
@export var equip_slot: EquipSlot = EquipSlot.NONE

@export_group("Stacking")
@export var stackable: bool = false
@export var max_stack: int = 100

@export_group("Stats")
@export var bonus_strength: int = 0
@export var bonus_defense: int = 0
@export var bonus_max_hp: int = 0
@export var bonus_max_mana: int = 0
@export var attack_damage: int = 0

@export_group("Consumable")
@export var heal_amount: int = 0
@export var mana_restore: int = 0

@export_group("Value")
@export var gold_value: int = 0
@export var drop_chance: float = 1.0


func is_equippable() -> bool:
	return equip_slot != EquipSlot.NONE


func is_consumable() -> bool:
	return item_type == ItemType.CONSUMABLE


func use() -> bool:
	if not is_consumable():
		return false
	if heal_amount > 0:
		PlayerStats.heal(heal_amount)
	if mana_restore > 0:
		PlayerStats.restore_mana(mana_restore)
	return true


func get_stat_text() -> String:
	var parts: PackedStringArray = []
	if attack_damage > 0:
		parts.append("Atk +%d" % attack_damage)
	if bonus_strength > 0:
		parts.append("Str +%d" % bonus_strength)
	if bonus_defense > 0:
		parts.append("Def +%d" % bonus_defense)
	if bonus_max_hp > 0:
		parts.append("HP +%d" % bonus_max_hp)
	if bonus_max_mana > 0:
		parts.append("MP +%d" % bonus_max_mana)
	if heal_amount > 0:
		parts.append("Heals %d" % heal_amount)
	if mana_restore > 0:
		parts.append("Restores %d MP" % mana_restore)
	return ", ".join(parts)
