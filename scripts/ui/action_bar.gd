extends Control
## Action bar with 12 hotkey slots (1-9, 0, -, =). Displays abilities and items.

signal action_triggered(slot_index: int)

const SLOT_COUNT := 12
const HOTKEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]

var slots: Array[ActionSlot] = []
var _actions: Array = []

@onready var _container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	_actions.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		var slot := _create_slot(i)
		_container.add_child(slot)
		slots.append(slot)
		slot.slot_pressed.connect(_on_slot_pressed)


func _create_slot(index: int) -> ActionSlot:
	var slot := ActionSlot.new()
	slot.slot_index = index
	slot.hotkey_text = HOTKEYS[index]
	
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.15, 0.15, 0.2, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(bg)
	
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)
	
	var overlay := ColorRect.new()
	overlay.name = "CooldownOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	slot.add_child(overlay)
	
	var cd_label := Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.set_anchors_preset(Control.PRESET_CENTER)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.visible = false
	slot.add_child(cd_label)
	
	var hk_label := Label.new()
	hk_label.name = "HotkeyLabel"
	hk_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hk_label.position = Vector2(2, 0)
	hk_label.add_theme_font_size_override("font_size", 10)
	hk_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	slot.add_child(hk_label)
	
	return slot


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var idx := _keycode_to_slot(key.keycode)
		if idx >= 0:
			_trigger_slot(idx)
			get_viewport().set_input_as_handled()


func _keycode_to_slot(keycode: int) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		KEY_7: return 6
		KEY_8: return 7
		KEY_9: return 8
		KEY_0: return 9
		KEY_MINUS: return 10
		KEY_EQUAL: return 11
		_: return -1


func _trigger_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	action_triggered.emit(index)
	var act = _actions[index]
	if act and act.has_method("execute"):
		act.execute()


func _on_slot_pressed(index: int) -> void:
	_trigger_slot(index)


func set_slot_action(index: int, action: Resource) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	_actions[index] = action
	if index < slots.size():
		slots[index].set_action(action)


func set_slot_cooldown(index: int, remaining: float, total: float) -> void:
	if index < 0 or index >= slots.size():
		return
	slots[index].set_cooldown(remaining, total)


func clear_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	_actions[index] = null
	if index < slots.size():
		slots[index].clear()
