class_name ReactionChamber
extends RefCounted

## ReactionChamber handles chemical synthesis, thermodynamic decomposition,
## and nuclear fusion, converting elemental inputs into power and output products.

signal reaction_started(recipe_id: String)
signal reaction_progress_updated(recipe_id: String, progress_ratio: float)
signal reaction_completed(recipe_id: String, energy_generated: float)

enum State {
	IDLE,
	PROCESSING
}

const TIME_EPSILON: float = 0.000001

var state: State = State.IDLE
var active_recipe_id: String = ""
var current_progress_sec: float = 0.0
var total_duration_sec: float = 1.0
var auto_repeat: bool = false
var speed_multiplier: float = 1.0
var yield_multiplier: float = 1.0

func start_reaction(recipe_id: String, inventory: PlayerInventory) -> bool:
	if state == State.PROCESSING:
		return false
	
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	
	# Verify and consume ingredients from inventory
	if not inventory.consume_recipe_inputs(recipe):
		return false
		
	active_recipe_id = recipe_id
	total_duration_sec = max(0.05, float(recipe.get("duration_sec", 1.0)) / speed_multiplier)
	current_progress_sec = 0.0
	state = State.PROCESSING
	reaction_started.emit(recipe_id)
	return true

func tick(delta_time: float, inventory: PlayerInventory, energy_system: EnergySystem) -> void:
	var remaining: float = delta_time
	# Loop (not recursion) so large time jumps cannot overflow the call stack.
	while state == State.PROCESSING and remaining > TIME_EPSILON:
		var needed: float = total_duration_sec - current_progress_sec
		if remaining < needed - TIME_EPSILON:
			current_progress_sec += remaining
			reaction_progress_updated.emit(active_recipe_id, current_progress_sec / total_duration_sec)
			return
		# Epsilon above guards float drift (e.g. 10 x 0.1 = 0.9999999).
		# Leftover time carries into the next auto-repeated reaction.
		remaining -= max(0.0, needed)
		reaction_progress_updated.emit(active_recipe_id, 1.0)
		_finish_reaction(inventory, energy_system)

func _finish_reaction(inventory: PlayerInventory, energy_system: EnergySystem) -> void:
	var recipe: Dictionary = ElementData.get_recipe(active_recipe_id)
	var energy_base: float = recipe.get("energy_joules", 0.0)
	var final_energy: float = energy_base * yield_multiplier
	
	# Add generated power into the energy system
	energy_system.add_energy(final_energy)
	
	# Add any chemical outputs to inventory
	var outputs: Dictionary = recipe.get("outputs", {})
	for elem_id in outputs.keys():
		inventory.add_element(elem_id, outputs[elem_id] * yield_multiplier)
		
	var finished_id: String = active_recipe_id
	state = State.IDLE
	active_recipe_id = ""
	current_progress_sec = 0.0
	reaction_completed.emit(finished_id, final_energy)
	
	# If auto-repeat is enabled, attempt to run again immediately
	if auto_repeat:
		start_reaction(finished_id, inventory)
