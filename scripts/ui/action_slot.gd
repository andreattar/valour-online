extends Control
class_name ActionSlot
## Single action bar slot with icon, cooldown overlay, and hotkey label.

signal slot_pressed(slot_index: int)

@export var slot_index: int = 0
@export var hotkey_text: String = "1"

var action: Resource = null
var cooldown_remaining: float = 0.0
var cooldown_total: float = 1.0

@onready var _bg: ColorRect = $Background
@onready var _icon: TextureRect = $Icon
@onready var _cooldown_overlay: ColorRect = $CooldownOverlay
@onready var _cooldown_label: Label = $CooldownLabel
@onready var _hotkey_label: Label = $HotkeyLabel


func _ready() -> void:
	_hotkey_label.text = hotkey_text
	_cooldown_overlay.visible = false
	_cooldown_label.visible = false
	custom_minimum_size = Vector2(48, 48)


func _process(_delta: float) -> void:
	if cooldown_remaining > 0.01:
		_cooldown_overlay.visible = true
		_cooldown_label.visible = true
		_cooldown_label.text = "%.1f" % cooldown_remaining
		var ratio := cooldown_remaining / maxf(cooldown_total, 0.01)
		_cooldown_overlay.size.y = _bg.size.y * ratio
		_cooldown_overlay.position.y = _bg.size.y * (1.0 - ratio)
	else:
		_cooldown_overlay.visible = false
		_cooldown_label.visible = false


func set_action(act: Resource) -> void:
	action = act
	if action and "icon" in action and action.icon:
		_icon.texture = action.icon
		_icon.visible = true
	else:
		_icon.visible = false


func set_cooldown(remaining: float, total: float) -> void:
	cooldown_remaining = remaining
	cooldown_total = total


func clear() -> void:
	action = null
	_icon.visible = false
	cooldown_remaining = 0.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			slot_pressed.emit(slot_index)
