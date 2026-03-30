extends Control
class_name ItemSlotUI
## UI for a single inventory/equipment slot.

signal slot_clicked(index: int, button: int)
signal slot_right_clicked(index: int)

@export var slot_index: int = 0
@export var slot_size: Vector2 = Vector2(40, 40)
@export var show_quantity: bool = true

var item: ItemResource = null
var quantity: int = 0

var _bg: ColorRect
var _icon: TextureRect
var _qty_label: Label


func _ready() -> void:
	custom_minimum_size = slot_size
	
	_bg = ColorRect.new()
	_bg.color = Color(0.12, 0.12, 0.15, 0.9)
	_bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_bg)
	
	_icon = TextureRect.new()
	_icon.set_anchors_preset(PRESET_FULL_RECT)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.visible = false
	add_child(_icon)
	
	_qty_label = Label.new()
	_qty_label.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	_qty_label.position = Vector2(-20, -16)
	_qty_label.add_theme_font_size_override("font_size", 10)
	_qty_label.visible = false
	add_child(_qty_label)
	
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_item(it: ItemResource, qty: int = 1) -> void:
	item = it
	quantity = qty
	_refresh()


func clear() -> void:
	item = null
	quantity = 0
	_refresh()


func _refresh() -> void:
	if item and item.icon:
		_icon.texture = item.icon
		_icon.visible = true
	else:
		_icon.visible = false
	
	if show_quantity and item and item.stackable and quantity > 1:
		_qty_label.text = str(quantity)
		_qty_label.visible = true
	else:
		_qty_label.visible = false
	
	if item:
		_bg.color = Color(0.2, 0.2, 0.25, 0.9)
	else:
		_bg.color = Color(0.12, 0.12, 0.15, 0.9)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				slot_clicked.emit(slot_index, MOUSE_BUTTON_LEFT)
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				slot_clicked.emit(slot_index, MOUSE_BUTTON_RIGHT)
				slot_right_clicked.emit(slot_index)
