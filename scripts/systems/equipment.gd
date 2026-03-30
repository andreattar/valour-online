extends Node
class_name EquipmentClass
## Player equipment: gear slots that provide stat bonuses.

signal equipment_changed
signal item_equipped(item: ItemResource, slot: int)
signal item_unequipped(item: ItemResource, slot: int)

var _slots: Dictionary = {}


func _ready() -> void:
	for slot in ItemResource.EquipSlot.values():
		if slot != ItemResource.EquipSlot.NONE:
			_slots[slot] = null


func get_equipped(slot: int) -> ItemResource:
	return _slots.get(slot)


func equip(item: ItemResource) -> bool:
	if not item or not item.is_equippable():
		return false
	
	var slot := item.equip_slot
	var old_item: ItemResource = _slots.get(slot)
	
	if old_item:
		if not Inventory.add_item(old_item):
			return false
		item_unequipped.emit(old_item, slot)
	
	_slots[slot] = item
	item_equipped.emit(item, slot)
	_recalc_bonuses()
	equipment_changed.emit()
	return true


func unequip(slot: int) -> ItemResource:
	var item: ItemResource = _slots.get(slot)
	if not item:
		return null
	
	if Inventory.is_full():
		return null
	
	_slots[slot] = null
	Inventory.add_item(item)
	item_unequipped.emit(item, slot)
	_recalc_bonuses()
	equipment_changed.emit()
	return item


func equip_from_inventory(inv_slot: int) -> bool:
	var item := Inventory.get_slot_item(inv_slot)
	if not item or not item.is_equippable():
		return false
	
	var equip_slot := item.equip_slot
	var old_item: ItemResource = _slots.get(equip_slot)
	
	Inventory.remove_from_slot(inv_slot, 1)
	
	if old_item:
		Inventory.add_item(old_item)
		item_unequipped.emit(old_item, equip_slot)
	
	_slots[equip_slot] = item
	item_equipped.emit(item, equip_slot)
	_recalc_bonuses()
	equipment_changed.emit()
	return true


func _recalc_bonuses() -> void:
	var total_str := 0
	var total_def := 0
	var total_hp := 0
	var total_mp := 0
	
	for slot in _slots:
		var item: ItemResource = _slots[slot]
		if item:
			total_str += item.bonus_strength + item.attack_damage
			total_def += item.bonus_defense
			total_hp += item.bonus_max_hp
			total_mp += item.bonus_max_mana
	
	PlayerStats.set_equipment_bonuses(total_str, total_def, total_hp, total_mp)


func get_total_attack_damage() -> int:
	var weapon: ItemResource = _slots.get(ItemResource.EquipSlot.MAIN_HAND)
	if weapon:
		return weapon.attack_damage
	return 0


func get_slot_name(slot: int) -> String:
	match slot:
		ItemResource.EquipSlot.HEAD: return "Head"
		ItemResource.EquipSlot.BODY: return "Body"
		ItemResource.EquipSlot.LEGS: return "Legs"
		ItemResource.EquipSlot.FEET: return "Feet"
		ItemResource.EquipSlot.MAIN_HAND: return "Main Hand"
		ItemResource.EquipSlot.OFF_HAND: return "Off Hand"
		ItemResource.EquipSlot.RING: return "Ring"
		ItemResource.EquipSlot.AMULET: return "Amulet"
		_: return "Unknown"


func clear() -> void:
	for slot in _slots:
		_slots[slot] = null
	_recalc_bonuses()
	equipment_changed.emit()
