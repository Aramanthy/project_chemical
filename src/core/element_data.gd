class_name ElementData
extends RefCounted

## ElementData defines chemical elements, compounds, and stoichiometric energy recipes.
## All thermodynamic and elemental properties for Phase 1 simulation live here.

enum Tier {
	TIER_1_LIGHT,       # H, He, C, O (Combustion & light reactions, kW)
	TIER_2_REFINED,     # Acids, Catalysts, Hydrocarbons, Fe (Concentrated synthesis, MW)
	TIER_3_HEAVY,       # Uranium, Plutonium, Fusion reactions (Nuclear, GW)
	TIER_4_EXOTIC       # Stable superheavies, Island of Stability (Cosmic, TW)
}

# --- ELEMENT DEFINITIONS ---
const ELEMENTS: Dictionary = {
	"H": {
		"name": "Hydrogen",
		"symbol": "H",
		"atomic_number": 1,
		"tier": Tier.TIER_1_LIGHT,
		"description": "Lightest and most abundant element. Highly flammable fuel source."
	},
	"He": {
		"name": "Helium",
		"symbol": "He",
		"atomic_number": 2,
		"tier": Tier.TIER_1_LIGHT,
		"description": "Noble gas produced by nuclear fusion."
	},
	"C": {
		"name": "Carbon",
		"symbol": "C",
		"atomic_number": 6,
		"tier": Tier.TIER_1_LIGHT,
		"description": "Fundamental building block for advanced hydrocarbons and structural polymers."
	},
	"O": {
		"name": "Oxygen",
		"symbol": "O",
		"atomic_number": 8,
		"tier": Tier.TIER_1_LIGHT,
		"description": "Powerful oxidizer essential for combustion energy generation."
	},
	"S": {
		"name": "Sulfur",
		"symbol": "S",
		"atomic_number": 16,
		"tier": Tier.TIER_2_REFINED,
		"description": "Volcanic element used to synthesize high-energy industrial acids."
	},
	"Fe": {
		"name": "Iron",
		"symbol": "Fe",
		"atomic_number": 26,
		"tier": Tier.TIER_2_REFINED,
		"description": "Structural metal and catalytic agent for high-pressure chambers."
	},
	"U": {
		"name": "Uranium",
		"symbol": "U",
		"atomic_number": 92,
		"tier": Tier.TIER_3_HEAVY,
		"description": "Heavy radioactive element capable of triggering fission chain reactions."
	},
	"EX_119": {
		"name": "Astralium",
		"symbol": "AsX",
		"atomic_number": 119,
		"tier": Tier.TIER_4_EXOTIC,
		"description": "Theoretical superheavy element from the Island of Stability. Releases immense energy."
	}
}

# --- REACTION RECIPES (Inputs -> Outputs + Energy Joules) ---
const RECIPES: Dictionary = {
	"combustion_water": {
		"id": "combustion_water",
		"name": "Water Synthesis (Exothermic)",
		"tier": Tier.TIER_1_LIGHT,
		"inputs": { "H": 2.0, "O": 1.0 },
		"outputs": { "H2O": 1.0 },
		"energy_joules": 286000.0,  # ~286 kJ per mol equivalent
		"duration_sec": 1.0,
		"description": "2H + O -> H2O + 286 kJ energy"
	},
	"hydrocarbon_methane": {
		"id": "hydrocarbon_methane",
		"name": "Methane Synthesis",
		"tier": Tier.TIER_1_LIGHT,
		"inputs": { "C": 1.0, "H": 4.0 },
		"outputs": { "CH4": 1.0 },
		"energy_joules": 890000.0,  # ~890 kJ
		"duration_sec": 2.0,
		"description": "C + 4H -> CH4 + 890 kJ energy"
	},
	"hydrogen_fusion": {
		"id": "hydrogen_fusion",
		"name": "Proton-Proton Fusion",
		"tier": Tier.TIER_3_HEAVY,
		"inputs": { "H": 4.0 },
		"outputs": { "He": 1.0 },
		"energy_joules": 25000000.0, # 25 MJ
		"duration_sec": 3.0,
		"description": "4H -> He + 25 MJ thermonuclear energy"
	},
	"uranium_fission": {
		"id": "uranium_fission",
		"name": "Uranium Fission Reaction",
		"tier": Tier.TIER_3_HEAVY,
		"inputs": { "U": 1.0 },
		"outputs": {},
		"energy_joules": 500000000.0, # 500 MJ
		"duration_sec": 5.0,
		"description": "Induced fission releasing massive subatomic energy"
	},
	"astral_annihilation": {
		"id": "astral_annihilation",
		"name": "Superheavy Element Stabilization",
		"tier": Tier.TIER_4_EXOTIC,
		"inputs": { "EX_119": 1.0, "He": 2.0 },
		"outputs": {},
		"energy_joules": 10000000000.0, # 10 GJ (Gigajoules)
		"duration_sec": 4.0,
		"description": "Cosmic lattice reaction producing planetary-scale terawatts"
	}
}

static func get_element(id: String) -> Dictionary:
	return ELEMENTS.get(id, {})

static func get_recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})

static func get_all_recipes() -> Array:
	return RECIPES.values()
