class_name TechTree
extends RefCounted

## Manages energy-purchased upgrades, scaling multipliers, and tier unlocks
## (kW -> MW -> GW -> TW progression).

signal upgrade_purchased(upgrade_id: String, new_level: int)

const UPGRADES: Dictionary = {
	"mining_laser": {
		"name": "Laser Extraction Power",
		"description": "+50% manual mining yield per level.",
		"base_cost_joules": 50000.0,
		"cost_scale": 2.0,
		"max_level": 10,
		"requires": ""
	},
	"storage_expansion": {
		"name": "Pressurized Storage Silos",
		"description": "+100 raw-element storage capacity per level.",
		"base_cost_joules": 100000.0,
		"cost_scale": 1.8,
		"max_level": 10,
		"requires": ""
	},
	"extractor_overclock": {
		"name": "Extractor Turbine Overclock",
		"description": "+25% extraction rate on all AutoExtractors per level.",
		"base_cost_joules": 200000.0,
		"cost_scale": 2.2,
		"max_level": 10,
		"requires": ""
	},
	"reactor_catalysts": {
		"name": "Exothermic Catalyst Matrix",
		"description": "+20% reaction speed and +25% energy yield per level.",
		"base_cost_joules": 400000.0,
		"cost_scale": 2.5,
		"max_level": 10,
		"requires": ""
	},
	"unlock_tier_3_nuclear": {
		"name": "Unlock Tier 3: Nuclear Physics",
		"description": "Unlocks Hydrogen Fusion, Uranium Fission, and Tier 3 machines (GW scale).",
		"base_cost_joules": 2000000.0,
		"cost_scale": 1.0,
		"max_level": 1,
		"requires": ""
	},
	"unlock_tier_4_exotic": {
		"name": "Unlock Tier 4: Island of Stability",
		"description": "Unlocks superheavy Astralium (EX_119) synthesis and cosmic reactors (TW scale).",
		"base_cost_joules": 500000000.0,
		"cost_scale": 1.0,
		"max_level": 1,
		"requires": "unlock_tier_3_nuclear"
	}
}

const BASE_STORAGE_CAPACITY: float = 100.0

var levels: Dictionary = {}  # { upgrade_id: int }

func get_level(upgrade_id: String) -> int:
	return int(levels.get(upgrade_id, 0))

func get_max_level(upgrade_id: String) -> int:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	return int(def.get("max_level", 0))

func is_maxed(upgrade_id: String) -> bool:
	var max_lvl: int = get_max_level(upgrade_id)
	return max_lvl > 0 and get_level(upgrade_id) >= max_lvl

func is_prerequisite_met(upgrade_id: String) -> bool:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty():
		return false
	var req: String = str(def.get("requires", ""))
	if req == "":
		return true
	return get_level(req) >= 1

## Cost in Joules for the next level of `upgrade_id`. Returns INF if invalid or maxed.
func get_next_cost(upgrade_id: String) -> float:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty() or is_maxed(upgrade_id):
		return INF
	var lvl: int = get_level(upgrade_id)
	var base: float = float(def["base_cost_joules"])
	var scale: float = float(def["cost_scale"])
	return round(base * pow(scale, lvl))

func can_purchase(upgrade_id: String, energy: EnergySystem) -> bool:
	if not UPGRADES.has(upgrade_id):
		return false
	if is_maxed(upgrade_id) or not is_prerequisite_met(upgrade_id):
		return false
	return energy.has_energy(get_next_cost(upgrade_id))

func purchase(upgrade_id: String, energy: EnergySystem) -> bool:
	if not can_purchase(upgrade_id, energy):
		return false
	var cost: float = get_next_cost(upgrade_id)
	if not energy.consume_energy(cost):
		return false
	var new_level: int = get_level(upgrade_id) + 1
	levels[upgrade_id] = new_level
	upgrade_purchased.emit(upgrade_id, new_level)
	return true

# --- DERIVED MULTIPLIERS & UNLOCKS ---

func get_mining_multiplier() -> float:
	return 1.0 + 0.5 * float(get_level("mining_laser"))

func get_max_storage_capacity() -> float:
	return BASE_STORAGE_CAPACITY + 100.0 * float(get_level("storage_expansion"))

func get_extractor_rate_multiplier() -> float:
	return 1.0 + 0.25 * float(get_level("extractor_overclock"))

func get_reaction_speed_multiplier() -> float:
	return 1.0 + 0.20 * float(get_level("reactor_catalysts"))

func get_reaction_yield_multiplier() -> float:
	return 1.0 + 0.25 * float(get_level("reactor_catalysts"))

func get_max_unlocked_tier() -> int:
	if get_level("unlock_tier_4_exotic") >= 1:
		return ElementData.Tier.TIER_4_EXOTIC
	if get_level("unlock_tier_3_nuclear") >= 1:
		return ElementData.Tier.TIER_3_HEAVY
	return ElementData.Tier.TIER_2_REFINED

func is_tier_unlocked(tier: int) -> bool:
	return tier <= get_max_unlocked_tier()
