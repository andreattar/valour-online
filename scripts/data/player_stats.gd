extends Node
class_name PlayerStatsClass
## Singleton holding player stats: HP, mana, level, XP, and base attributes.
## Autoloaded as PlayerStats.

signal hp_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal xp_changed(current: int, to_next: int)
signal level_changed(new_level: int)
signal stats_changed
signal died

const XP_BASE := 100
const XP_SCALE := 1.5

var max_hp: int = 100:
	set(v):
		max_hp = maxi(1, v)
		hp = mini(hp, max_hp)
		hp_changed.emit(hp, max_hp)
		stats_changed.emit()

var hp: int = 100:
	set(v):
		var old := hp
		hp = clampi(v, 0, max_hp)
		if hp != old:
			hp_changed.emit(hp, max_hp)
		if hp <= 0 and old > 0:
			died.emit()

var max_mana: int = 50:
	set(v):
		max_mana = maxi(0, v)
		mana = mini(mana, max_mana)
		mana_changed.emit(mana, max_mana)
		stats_changed.emit()

var mana: int = 50:
	set(v):
		var old := mana
		mana = clampi(v, 0, max_mana)
		if mana != old:
			mana_changed.emit(mana, max_mana)

var level: int = 1:
	set(v):
		var old := level
		level = maxi(1, v)
		if level != old:
			_recalc_xp_to_next()
			level_changed.emit(level)
			stats_changed.emit()

var xp: int = 0:
	set(v):
		xp = maxi(0, v)
		while xp >= xp_to_next:
			xp -= xp_to_next
			level += 1
		xp_changed.emit(xp, xp_to_next)

var xp_to_next: int = 100

var strength: int = 10:
	set(v):
		strength = maxi(1, v)
		stats_changed.emit()

var defense: int = 10:
	set(v):
		defense = maxi(0, v)
		stats_changed.emit()

var magic_level: int = 0:
	set(v):
		magic_level = maxi(0, v)
		stats_changed.emit()

var _bonus_strength: int = 0
var _bonus_defense: int = 0
var _bonus_max_hp: int = 0
var _bonus_max_mana: int = 0


func _ready() -> void:
	_recalc_xp_to_next()
	hp = max_hp
	mana = max_mana


func _recalc_xp_to_next() -> void:
	xp_to_next = int(XP_BASE * pow(XP_SCALE, level - 1))


func total_strength() -> int:
	return strength + _bonus_strength


func total_defense() -> int:
	return defense + _bonus_defense


func total_max_hp() -> int:
	return max_hp + _bonus_max_hp


func total_max_mana() -> int:
	return max_mana + _bonus_max_mana


func take_damage(amount: int) -> void:
	var mitigated := maxi(0, amount - total_defense() / 4)
	hp -= maxi(1, mitigated)


func heal(amount: int) -> void:
	hp = mini(hp + amount, total_max_hp())


func restore_mana(amount: int) -> void:
	mana = mini(mana + amount, total_max_mana())


func use_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true


func gain_xp(amount: int) -> void:
	xp += amount


func set_equipment_bonuses(bonus_str: int, bonus_def: int, bonus_hp: int, bonus_mp: int) -> void:
	_bonus_strength = bonus_str
	_bonus_defense = bonus_def
	_bonus_max_hp = bonus_hp
	_bonus_max_mana = bonus_mp
	stats_changed.emit()


func reset() -> void:
	level = 1
	xp = 0
	hp = max_hp
	mana = max_mana
