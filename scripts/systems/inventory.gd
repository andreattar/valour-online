extends Node
class_name InventoryClass
## Player inventory: bag slots holding items and quantities.

signal inventory_changed
signal item_added(item: ItemResource, slot: int)
signal item_removed(item: ItemResource, slot: int)

const SLOT_COUNT := 20

var _slots: Array = []
var _quantities: Array[int] = []
var gold: int = 0:
	set(v):
		gold = maxi(0, v)
		inventory_changed.emit()


func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_quantities.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		_slots[i] = null
		_quantities[i] = 0


func get_slot_item(index: int) -> ItemResource:
	if index < 0 or index >= SLOT_COUNT:
		return null
	return _slots[index]


func get_slot_quantity(index: int) -> int:
	if index < 0 or index >= SLOT_COUNT:
		return 0
	return _quantities[index]


func add_item(item: ItemResource, quantity: int = 1) -> int:
	if not item:
		return 0
	
	var remaining := quantity
	
	if item.stackable:
		for i in SLOT_COUNT:
			if remaining <= 0:
				break
			if _slots[i] == item or (_slots[i] and _slots[i].id == item.id):
				var can_add := mini(remaining, item.max_stack - _quantities[i])
				if can_add > 0:
					_quantities[i] += can_add
					remaining -= can_add
	
	while remaining > 0:
		var empty_slot := _find_empty_slot()
		if empty_slot < 0:
			break
		var to_add := mini(remaining, item.max_stack if item.stackable else 1)
		_slots[empty_slot] = item
		_quantities[empty_slot] = to_add
		remaining -= to_add
		item_added.emit(item, empty_slot)
	
	if remaining < quantity:
		inventory_changed.emit()
	
	return quantity - remaining


func remove_item(item: ItemResource, quantity: int = 1) -> int:
	if not item:
		return 0
	
	var remaining := quantity
	
	for i in range(SLOT_COUNT - 1, -1, -1):
		if remaining <= 0:
			break
		if _slots[i] and _slots[i].id == item.id:
			var can_remove := mini(remaining, _quantities[i])
			_quantities[i] -= can_remove
			remaining -= can_remove
			if _quantities[i] <= 0:
				var removed_item: ItemResource = _slots[i]
				_slots[i] = null
				_quantities[i] = 0
				item_removed.emit(removed_item, i)
	
	if remaining < quantity:
		inventory_changed.emit()
	
	return quantity - remaining


func remove_from_slot(slot: int, quantity: int = 1) -> ItemResource:
	if slot < 0 or slot >= SLOT_COUNT:
		return null
	if not _slots[slot]:
		return null
	
	var item: ItemResource = _slots[slot]
	var to_remove := mini(quantity, _quantities[slot])
	_quantities[slot] -= to_remove
	
	if _quantities[slot] <= 0:
		_slots[slot] = null
		_quantities[slot] = 0
		item_removed.emit(item, slot)
	
	inventory_changed.emit()
	return item


func has_item(item: ItemResource, quantity: int = 1) -> bool:
	return count_item(item) >= quantity


func count_item(item: ItemResource) -> int:
	if not item:
		return 0
	var total := 0
	for i in SLOT_COUNT:
		if _slots[i] and _slots[i].id == item.id:
			total += _quantities[i]
	return total


func use_item(slot: int) -> bool:
	var item := get_slot_item(slot)
	if not item:
		return false
	if not item.is_consumable():
		return false
	if item.use():
		remove_from_slot(slot, 1)
		return true
	return false


func _find_empty_slot() -> int:
	for i in SLOT_COUNT:
		if _slots[i] == null:
			return i
	return -1


func is_full() -> bool:
	return _find_empty_slot() < 0


func clear() -> void:
	for i in SLOT_COUNT:
		_slots[i] = null
		_quantities[i] = 0
	gold = 0
	inventory_changed.emit()
