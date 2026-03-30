extends Control
## Inventory panel showing bag slots in a grid.

signal slot_selected(index: int)

const COLS := 5
const ROWS := 4

var _slots: Array[ItemSlotUI] = []
var _grid: GridContainer
var _gold_label: Label
var _title: Label


func _ready() -> void:
	visible = false
	
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	_title = Label.new()
	_title.text = "Inventory"
	_title.add_theme_font_size_override("font_size", 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)
	
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)
	
	for i in COLS * ROWS:
		var slot := ItemSlotUI.new()
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)
		_grid.add_child(slot)
		_slots.append(slot)
	
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_gold_label)
	
	Inventory.inventory_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in _slots.size():
		var item := Inventory.get_slot_item(i)
		var qty := Inventory.get_slot_quantity(i)
		if item:
			_slots[i].set_item(item, qty)
		else:
			_slots[i].clear()
	
	_gold_label.text = "Gold: %d" % Inventory.gold


func _on_slot_clicked(index: int, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		var item := Inventory.get_slot_item(index)
		if item:
			if item.is_consumable():
				Inventory.use_item(index)
			elif item.is_equippable():
				Equipment.equip_from_inventory(index)
	else:
		slot_selected.emit(index)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_I or key.keycode == KEY_B:
			visible = not visible
			get_viewport().set_input_as_handled()
