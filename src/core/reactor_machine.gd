class_name ReactorMachine
extends Machine

## Deployable reactor that repeatedly runs a single recipe, pulling inputs from
## storage and feeding generated energy into the shared EnergySystem.

var recipe_id: String = ""
var chamber: ReactionChamber = ReactionChamber.new()

func _init() -> void:
	chamber.auto_repeat = true

func step(dt: float, state: GameState) -> void:
	if not enabled:
		status = Status.DISABLED
		return

	if chamber.state == ReactionChamber.State.IDLE:
		if not chamber.start_reaction(recipe_id, state.inventory):
			status = Status.NO_INPUT
			return

	if not _draw_power(dt, state):
		return

	chamber.tick(dt, state.inventory, state.energy)
	status = Status.RUNNING

## Reaction progress in [0, 1] for UI display.
func get_progress() -> float:
	if chamber.state != ReactionChamber.State.PROCESSING:
		return 0.0
	return clamp(chamber.current_progress_sec / chamber.total_duration_sec, 0.0, 1.0)
