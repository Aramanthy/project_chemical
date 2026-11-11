class_name MachineCatalog
extends RefCounted

## Data definitions and factory for all buildable machines across all tiers.

const DEFS: Dictionary = {
	"extractor_h": {
		"name": "Hydrogen Extractor",
		"type": "extractor",
		"tier": ElementData.Tier.TIER_1_LIGHT,
		"element": "H",
		"rate_per_sec": 1.0,
		"power_draw_watts": 2000.0,
		"build_cost_joules": 100000.0
	},
	"extractor_o": {
		"name": "Oxygen Extractor",
		"type": "extractor",
		"tier": ElementData.Tier.TIER_1_LIGHT,
		"element": "O",
		"rate_per_sec": 0.5,
		"power_draw_watts": 2000.0,
		"build_cost_joules": 100000.0
	},
	"extractor_c": {
		"name": "Carbon Extractor",
		"type": "extractor",
		"tier": ElementData.Tier.TIER_1_LIGHT,
		"element": "C",
		"rate_per_sec": 0.25,
		"power_draw_watts": 3000.0,
		"build_cost_joules": 250000.0
	},
	"reactor_water": {
		"name": "Water Synthesis Reactor",
		"type": "reactor",
		"tier": ElementData.Tier.TIER_1_LIGHT,
		"recipe": "combustion_water",
		"power_draw_watts": 0.0,
		"build_cost_joules": 300000.0
	},
	"reactor_methane": {
		"name": "Methane Synthesis Reactor",
		"type": "reactor",
		"tier": ElementData.Tier.TIER_1_LIGHT,
		"recipe": "hydrocarbon_methane",
		"power_draw_watts": 0.0,
		"build_cost_joules": 800000.0
	},
	"extractor_u": {
		"name": "Uranium Deep Drill",
		"type": "extractor",
		"tier": ElementData.Tier.TIER_3_HEAVY,
		"element": "U",
		"rate_per_sec": 0.2,
		"power_draw_watts": 50000.0,
		"build_cost_joules": 5000000.0
	},
	"reactor_fusion": {
		"name": "Proton-Proton Fusion Tokamak",
		"type": "reactor",
		"tier": ElementData.Tier.TIER_3_HEAVY,
		"recipe": "hydrogen_fusion",
		"power_draw_watts": 25000.0,
		"build_cost_joules": 10000000.0
	},
	"reactor_fission": {
		"name": "Uranium Fission Core",
		"type": "reactor",
		"tier": ElementData.Tier.TIER_3_HEAVY,
		"recipe": "uranium_fission",
		"power_draw_watts": 100000.0,
		"build_cost_joules": 50000000.0
	},
	"extractor_ex119": {
		"name": "Astralium Synthesizer Rig",
		"type": "extractor",
		"tier": ElementData.Tier.TIER_4_EXOTIC,
		"element": "EX_119",
		"rate_per_sec": 0.25,
		"power_draw_watts": 5000000.0,
		"build_cost_joules": 1000000000.0
	},
	"reactor_astral": {
		"name": "Astral Annihilation Matrix",
		"type": "reactor",
		"tier": ElementData.Tier.TIER_4_EXOTIC,
		"recipe": "astral_annihilation",
		"power_draw_watts": 10000000.0,
		"build_cost_joules": 2500000000.0
	}
}

static func get_def(def_id: String) -> Dictionary:
	return DEFS.get(def_id, {})

static func get_build_cost(def_id: String) -> float:
	return float(get_def(def_id).get("build_cost_joules", 0.0))

static func get_tier(def_id: String) -> int:
	return int(get_def(def_id).get("tier", ElementData.Tier.TIER_1_LIGHT))

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
