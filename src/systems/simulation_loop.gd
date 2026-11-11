class_name SimulationLoop
extends RefCounted

## Deterministic fixed-timestep driver for the whole simulation.
## Real frame deltas are accumulated and consumed in FIXED_STEP increments, so
## results are identical regardless of frame rate. This is also the foundation
## for offline progress (Stage 3), which will replay elapsed time in steps.

const FIXED_STEP: float = 0.1
const TIME_EPSILON: float = 0.000001

var state: GameState
var total_steps: int = 0
var _accumulator: float = 0.0

func _init(game_state: GameState) -> void:
	state = game_state

## Accumulates real time and runs as many fixed steps as fit. Returns steps run.
func advance(delta: float) -> int:
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= FIXED_STEP - TIME_EPSILON:
		step()
		_accumulator -= FIXED_STEP
		steps += 1
	return steps

## Runs exactly one fixed step. Machines update in build order for determinism.
func step() -> void:
	step_dt(FIXED_STEP)

## Runs a single simulation step with an explicit delta `dt` (used by fixed-step and offline replay).
func step_dt(dt: float) -> void:
	state.planet.step(dt, state)
	for machine in state.machines:
		machine.step(dt, state)
	state.energy.update_tick(dt)
	total_steps += 1
