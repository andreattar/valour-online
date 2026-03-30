extends Resource
class_name LootEntry
## A single loot table entry with item, quantity range, and drop chance.

@export var item: ItemResource
@export var drop_chance: float = 0.5
@export var min_quantity: int = 1
@export var max_quantity: int = 1
