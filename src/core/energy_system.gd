class_name EnergySystem
extends RefCounted

## EnergySystem manages global and local energy reserves, production rates,
## and provides human-readable formatting (J -> kJ -> MJ -> GJ -> TJ).

signal energy_changed(current_energy: float, delta: float)
signal power_rate_updated(watts: float)

const TIME_EPSILON: float = 0.000001

var current_energy_joules: float = 0.0
var total_lifetime_energy: float = 0.0
var current_power_watts: float = 0.0  # Real-time power output per second

# Rolling window for calculating real-time power rate (W = J/s)
var _energy_produced_this_second: float = 0.0
var _second_timer: float = 0.0

func add_energy(joules: float) -> void:
	if joules <= 0.0:
		return
	current_energy_joules += joules
	total_lifetime_energy += joules
	_energy_produced_this_second += joules
	energy_changed.emit(current_energy_joules, joules)

func consume_energy(joules: float) -> bool:
	if current_energy_joules >= joules:
		current_energy_joules -= joules
		energy_changed.emit(current_energy_joules, -joules)
		return true
	return false

func has_energy(joules: float) -> bool:
	return current_energy_joules >= joules

func update_tick(delta_time: float) -> void:
	_second_timer += delta_time
	# Epsilon guards against float drift (e.g. 10 x 0.1 = 0.9999999).
	if _second_timer >= 1.0 - TIME_EPSILON:
		current_power_watts = _energy_produced_this_second / _second_timer
		power_rate_updated.emit(current_power_watts)
		_energy_produced_this_second = 0.0
		_second_timer = 0.0

## Formats Joules into engineering notation: J, kJ, MJ, GJ, TJ, PJ
static func format_joules(joules: float) -> String:
	if joules < 1_000.0:
		return "%.1f J" % joules
	elif joules < 1_000_000.0:
		return "%.2f kJ" % (joules / 1_000.0)
	elif joules < 1_000_000_000.0:
		return "%.2f MJ" % (joules / 1_000_000.0)
	elif joules < 1_000_000_000_000.0:
		return "%.2f GJ" % (joules / 1_000_000_000.0)
	elif joules < 1_000_000_000_000_000.0:
		return "%.2f TJ" % (joules / 1_000_000_000_000.0)
	else:
		return "%.2f PJ" % (joules / 1_000_000_000_000_000.0)

## Formats Watts into engineering notation: W, kW, MW, GW, TW, PW
static func format_watts(watts: float) -> String:
	if watts < 1_000.0:
		return "%.1f W" % watts
	elif watts < 1_000_000.0:
		return "%.2f kW" % (watts / 1_000.0)
	elif watts < 1_000_000_000.0:
		return "%.2f MW" % (watts / 1_000_000.0)
	elif watts < 1_000_000_000_000.0:
		return "%.2f GW" % (watts / 1_000_000_000.0)
	elif watts < 1_000_000_000_000_000.0:
		return "%.2f TW" % (watts / 1_000_000_000_000.0)
	else:
		return "%.2f PW" % (watts / 1_000_000_000_000_000.0)
