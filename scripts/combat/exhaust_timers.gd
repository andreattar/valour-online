class_name ExhaustTimers
extends RefCounted
## Tibia-style aggressive / utility buckets (7.x feel). v1: aggressive only.

const AGGRESSIVE_MS := 2000
const UTILITY_MS := 1000

var _next_aggressive_ms: int = 0
var _next_utility_ms: int = 0


func can_aggressive() -> bool:
	return Time.get_ticks_msec() >= _next_aggressive_ms


func can_utility() -> bool:
	return Time.get_ticks_msec() >= _next_utility_ms


func consume_aggressive() -> void:
	_next_aggressive_ms = Time.get_ticks_msec() + AGGRESSIVE_MS


func consume_utility() -> void:
	_next_utility_ms = Time.get_ticks_msec() + UTILITY_MS


func aggressive_cooldown_remaining() -> float:
	var now := Time.get_ticks_msec()
	return maxf(0.0, (_next_aggressive_ms - now) / 1000.0)
