extends CanvasLayer
## Main game HUD: HP/mana bars, stats panel, target frame, exhaust indicator.

@export var player_path: NodePath

var _player: Node
var _target: Node

@onready var _hp_bar: ProgressBar = $TopLeft/HPBar
@onready var _hp_label: Label = $TopLeft/HPBar/Label
@onready var _mana_bar: ProgressBar = $TopLeft/ManaBar
@onready var _mana_label: Label = $TopLeft/ManaBar/Label
@onready var _level_label: Label = $TopLeft/StatsRow/LevelLabel
@onready var _xp_bar: ProgressBar = $TopLeft/StatsRow/XPBar
@onready var _exhaust_label: Label = $TopLeft/ExhaustLabel
@onready var _target_frame: Control = $TopLeft/TargetFrame
@onready var _target_name: Label = $TopLeft/TargetFrame/TargetName
@onready var _target_hp_bar: ProgressBar = $TopLeft/TargetFrame/TargetHPBar
@onready var _action_bar: Control = $ActionBar


func _ready() -> void:
	layer = 100
	_target_frame.visible = false
	
	if player_path:
		_player = get_node_or_null(player_path)
		if _player and _player.has_signal("target_changed"):
			_player.target_changed.connect(_on_player_target_changed)
	
	PlayerStats.hp_changed.connect(_on_hp_changed)
	PlayerStats.mana_changed.connect(_on_mana_changed)
	PlayerStats.xp_changed.connect(_on_xp_changed)
	PlayerStats.level_changed.connect(_on_level_changed)
	
	_on_hp_changed(PlayerStats.hp, PlayerStats.max_hp)
	_on_mana_changed(PlayerStats.mana, PlayerStats.max_mana)
	_on_xp_changed(PlayerStats.xp, PlayerStats.xp_to_next)
	_on_level_changed(PlayerStats.level)


func _on_player_target_changed(new_target: Node) -> void:
	_target = new_target


func _enter_tree() -> void:
	call_deferred("_connect_action_bar")


func _connect_action_bar() -> void:
	if _action_bar:
		ActionSystem.set_action_bar(_action_bar)


func _process(_delta: float) -> void:
	_update_exhaust()
	_update_target()


func _update_exhaust() -> void:
	if _player and _player.has_method("get_aggressive_cooldown_remaining"):
		var cd: float = _player.get_aggressive_cooldown_remaining()
		if cd > 0.01:
			_exhaust_label.text = "Exhaust: %.1fs" % cd
			_exhaust_label.modulate = Color(1.0, 0.6, 0.6)
		else:
			_exhaust_label.text = "Ready"
			_exhaust_label.modulate = Color(0.6, 1.0, 0.6)
	else:
		_exhaust_label.text = ""


func _update_target() -> void:
	if not is_instance_valid(_target):
		_target = null
		_target_frame.visible = false
		return
	
	_target_frame.visible = true
	if _target.has_method("get_display_name"):
		_target_name.text = _target.get_display_name()
	else:
		_target_name.text = _target.name
	
	if "hp" in _target and "max_hp" in _target:
		_target_hp_bar.max_value = _target.max_hp
		_target_hp_bar.value = _target.hp


func set_target(node: Node) -> void:
	_target = node


func clear_target() -> void:
	_target = null
	_target_frame.visible = false


func _on_hp_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [current, maximum]


func _on_mana_changed(current: int, maximum: int) -> void:
	_mana_bar.max_value = maximum
	_mana_bar.value = current
	_mana_label.text = "%d / %d" % [current, maximum]


func _on_xp_changed(current: int, to_next: int) -> void:
	_xp_bar.max_value = to_next
	_xp_bar.value = current


func _on_level_changed(new_level: int) -> void:
	_level_label.text = "Lv %d" % new_level
