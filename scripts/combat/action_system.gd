extends Node
class_name ActionSystemClass
## Manages player actions and their assignment to action bar slots.

signal action_executed(action: ActionBase)

var _actions: Dictionary = {}
var _slot_assignments: Array = []
var _action_bar: Control = null
var _player: Node = null

const SLOT_COUNT := 12


func _ready() -> void:
	_slot_assignments.resize(SLOT_COUNT)


func register_action(action: ActionBase) -> void:
	_actions[action.id] = action


func get_action(action_id: String) -> ActionBase:
	return _actions.get(action_id)


func assign_to_slot(slot_index: int, action_id: String) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	var action := get_action(action_id)
	_slot_assignments[slot_index] = action
	if _action_bar and _action_bar.has_method("set_slot_action"):
		_action_bar.set_slot_action(slot_index, action)


func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	_slot_assignments[slot_index] = null
	if _action_bar and _action_bar.has_method("clear_slot"):
		_action_bar.clear_slot(slot_index)


func execute_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	var action: ActionBase = _slot_assignments[slot_index]
	if not action:
		return false
	if action.execute():
		action_executed.emit(action)
		return true
	return false


func set_action_bar(bar: Control) -> void:
	_action_bar = bar
	if _action_bar and _action_bar.has_signal("action_triggered"):
		_action_bar.action_triggered.connect(_on_action_triggered)
	_sync_all_slots()


func set_player(p: Node) -> void:
	_player = p


func get_player() -> Node:
	return _player


func _sync_all_slots() -> void:
	if not _action_bar:
		return
	for i in SLOT_COUNT:
		var action: ActionBase = _slot_assignments[i]
		if action:
			_action_bar.set_slot_action(i, action)
		else:
			_action_bar.clear_slot(i)


func _on_action_triggered(slot_index: int) -> void:
	execute_slot(slot_index)


func _process(_delta: float) -> void:
	if not _action_bar:
		return
	for i in SLOT_COUNT:
		var action: ActionBase = _slot_assignments[i]
		if action:
			_action_bar.set_slot_cooldown(i, action.cooldown_remaining(), action.cooldown_total())
