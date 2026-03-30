extends Control
## Equipment panel showing gear slots.

const SLOT_ORDER := [
	ItemResource.EquipSlot.HEAD,
	ItemResource.EquipSlot.AMULET,
	ItemResource.EquipSlot.BODY,
	ItemResource.EquipSlot.MAIN_HAND,
	ItemResource.EquipSlot.OFF_HAND,
	ItemResource.EquipSlot.LEGS,
	ItemResource.EquipSlot.RING,
	ItemResource.EquipSlot.FEET,
]

var _slots: Dictionary = {}
var _stats_label: Label


func _ready() -> void:
	visible = false
	
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "Equipment"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)
	
	for equip_slot in SLOT_ORDER:
		var label := Label.new()
		label.text = Equipment.get_slot_name(equip_slot)
		label.add_theme_font_size_override("font_size", 11)
		label.custom_minimum_size.x = 70
		grid.add_child(label)
		
		var slot := ItemSlotUI.new()
		slot.slot_index = equip_slot
		slot.show_quantity = false
		slot.slot_clicked.connect(_on_slot_clicked)
		grid.add_child(slot)
		_slots[equip_slot] = slot
	
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_stats_label)
	
	Equipment.equipment_changed.connect(_refresh)
	PlayerStats.stats_changed.connect(_refresh_stats)
	_refresh()
	_refresh_stats()


func _refresh() -> void:
	for equip_slot in _slots:
		var item := Equipment.get_equipped(equip_slot)
		var slot: ItemSlotUI = _slots[equip_slot]
		if item:
			slot.set_item(item, 1)
		else:
			slot.clear()


func _refresh_stats() -> void:
	_stats_label.text = "Str: %d  Def: %d\nHP: %d  MP: %d" % [
		PlayerStats.total_strength(),
		PlayerStats.total_defense(),
		PlayerStats.total_max_hp(),
		PlayerStats.total_max_mana(),
	]


func _on_slot_clicked(index: int, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		Equipment.unequip(index)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_E:
			visible = not visible
			get_viewport().set_input_as_handled()
