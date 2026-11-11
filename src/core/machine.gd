class_name Machine
extends RefCounted

## Base class for every deployable automated facility (extractors, reactors, ...).
## Machines are stepped by SimulationLoop at a fixed timestep and operate on a
## shared GameState. Subclasses override step().

enum Status {
	IDLE,            # Built but has nothing to do yet
	RUNNING,         # Producing normally this step
	NO_POWER,        # Not enough stored energy to cover power draw
	NO_INPUT,        # Missing input elements
	OUTPUT_BLOCKED,  # Destination storage is full
	DISABLED         # Turned off by the player
}

var id: int = -1
var def_id: String = ""
var display_name: String = ""
var enabled: bool = true
var power_draw_watts: float = 0.0
var status: Status = Status.IDLE
var world_position: Vector3 = Vector3.ZERO

## Advance this machine by `dt` seconds. Override in subclasses.
func step(_dt: float, _state: GameState) -> void:
	pass

## Draws power_draw_watts * dt joules. Sets NO_POWER and returns false if unaffordable.
func _draw_power(dt: float, state: GameState) -> bool:
	var needed: float = power_draw_watts * dt
	if needed <= 0.0:
		return true
	if state.energy.consume_energy(needed):
		return true
	status = Status.NO_POWER
	return false

static func status_to_string(s: Status) -> String:
	match s:
		Status.IDLE: return "Idle"
		Status.RUNNING: return "Running"
		Status.NO_POWER: return "No Power"
		Status.NO_INPUT: return "No Input"
		Status.OUTPUT_BLOCKED: return "Storage Full"
		Status.DISABLED: return "Disabled"
	return "Unknown"
