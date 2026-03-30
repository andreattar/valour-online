extends Resource
class_name LootTable
## Defines possible drops from enemies with weighted chances.

@export var entries: Array[LootEntry] = []


func roll() -> Array:
	var drops: Array = []
	for entry in entries:
		if randf() <= entry.drop_chance:
			var qty := randi_range(entry.min_quantity, entry.max_quantity)
			if qty > 0 and entry.item:
				drops.append({"item": entry.item, "quantity": qty})
	return drops
