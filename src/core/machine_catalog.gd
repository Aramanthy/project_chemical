class_name MachineCatalog
extends RefCounted

## Data definitions and factory for all buildable machines.
## Numbers here are first-pass values; balancing happens in Stage 2 (progression).

const DEFS: Dictionary = {
	"extractor_h": {
		"name": "Hydrogen Extractor",
		"type": "extractor",
		"element": "H",
		"rate_per_sec": 1.0,
		"power_draw_watts": 2000.0,
		"build_cost_joules": 100000.0
	},
	"extractor_o": {
		"name": "Oxygen Extractor",
		"type": "extractor",
		"element": "O",
		"rate_per_sec": 0.5,
		"power_draw_watts": 2000.0,
		"build_cost_joules": 100000.0
	},
	"extractor_c": {
		"name": "Carbon Extractor",
		"type": "extractor",
		"element": "C",
		"rate_per_sec": 0.25,
		"power_draw_watts": 3000.0,
		"build_cost_joules": 250000.0
	},
	"reactor_water": {
		"name": "Water Synthesis Reactor",
		"type": "reactor",
		"recipe": "combustion_water",
		"power_draw_watts": 0.0,
		"build_cost_joules": 300000.0
	},
	"reactor_methane": {
		"name": "Methane Synthesis Reactor",
		"type": "reactor",
		"recipe": "hydrocarbon_methane",
		"power_draw_watts": 0.0,
		"build_cost_joules": 800000.0
	}
}

static func get_def(def_id: String) -> Dictionary:
	return DEFS.get(def_id, {})

static func get_build_cost(def_id: String) -> float:
	return float(get_def(def_id).get("build_cost_joules", 0.0))

## Instantiates a machine from its definition. Returns null for unknown ids.
static func create(def_id: String) -> Machine:
	var def: Dictionary = get_def(def_id)
	if def.is_empty():
		return null

	var machine: Machine
	match def.get("type", ""):
		"extractor":
			var extractor := AutoExtractor.new()
			extractor.element_id = def["element"]
			extractor.rate_per_sec = def["rate_per_sec"]
			machine = extractor
		"reactor":
			var reactor := ReactorMachine.new()
			reactor.recipe_id = def["recipe"]
			machine = reactor
		_:
			return null

	machine.def_id = def_id
	machine.display_name = def["name"]
	machine.power_draw_watts = def.get("power_draw_watts", 0.0)
	return machine
