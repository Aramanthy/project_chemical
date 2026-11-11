class_name PlanetGrid
extends RefCounted

## Coordinate-based planetary surface holding resource deposits, dormant alien
## power hubs, and the player's 3D exploration coordinates.

signal player_moved(new_position: Vector3)
signal hub_activated(hub_id: String)
signal planet_awakened()

const WORLD_HALF_EXTENT: float = 60.0
const INTERACTION_RANGE: float = 4.5

const DEPOSIT_DEFS: Array[Dictionary] = [
	{
		"id": "dep_h_landing",
		"name": "Hydrogen Ice Vent",
		"element": "H",
		"position": Vector3(-6.0, 0.0, -5.0),
		"richness": 1.5
	},
	{
		"id": "dep_o_landing",
		"name": "Liquid Oxygen Basin",
		"element": "O",
		"position": Vector3(6.0, 0.0, -5.0),
		"richness": 1.5
	},
	{
		"id": "dep_c_ridge",
		"name": "Carbon Outcrop",
		"element": "C",
		"position": Vector3(0.0, 0.0, -12.0),
		"richness": 2.0
	},
	{
		"id": "dep_h_geyser",
		"name": "Deuterium Geyser",
		"element": "H",
		"position": Vector3(-16.0, 0.0, 8.0),
		"richness": 2.5
	},
	{
		"id": "dep_u_crater",
		"name": "Uranium Fissure",
		"element": "U",
		"position": Vector3(18.0, 0.0, -16.0),
		"richness": 2.0
	},
	{
		"id": "dep_ex_rift",
		"name": "Astralium Anomaly Rift",
		"element": "EX_119",
		"position": Vector3(0.0, 0.0, -34.0),
		"richness": 3.0
	}
]

const HUB_DEFS: Dictionary = {
	"hub_alpha": {
		"id": "hub_alpha",
		"name": "Alpha Thermal Conduit",
		"position": Vector3(-12.0, 0.0, -12.0),
		"required_energy": 1000000.0,
		"required_elements": { "H2O": 3.0 },
		"passive_power_watts": 50000.0,
		"is_core": false
	},
	"hub_beta": {
		"id": "hub_beta",
		"name": "Beta Fusion Pylon",
		"position": Vector3(14.0, 0.0, 10.0),
		"required_energy": 25000000.0,
		"required_elements": { "CH4": 5.0 },
		"passive_power_watts": 1000000.0,
		"is_core": false
	},
	"planetary_core": {
		"id": "planetary_core",
		"name": "Central Planetary Core",
		"position": Vector3(0.0, 0.0, -24.0),
		"required_energy": 500000000.0,
		"required_elements": { "H2O": 10.0, "CH4": 5.0 },
		"passive_power_watts": 100000000.0,
		"is_core": true
	}
}

var player_position: Vector3 = Vector3.ZERO
var deposits: Array[Dictionary] = []
var hubs: Dictionary = {}  # { hub_id: Dictionary (copy of HUB_DEFS entry + "activated": bool) }
var is_planet_awakened: bool = false

func _init() -> void:
	reset()

func reset() -> void:
	player_position = Vector3.ZERO
	is_planet_awakened = false
	deposits.clear()
	for d in DEPOSIT_DEFS:
		deposits.append(d.duplicate(true))
	hubs.clear()
	for hub_id in HUB_DEFS.keys():
		var h: Dictionary = HUB_DEFS[hub_id].duplicate(true)
		h["activated"] = false
		hubs[hub_id] = h

func set_player_position(pos: Vector3) -> void:
	player_position = Vector3(
		clamp(pos.x, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT),
		0.0,
		clamp(pos.z, -WORLD_HALF_EXTENT, WORLD_HALF_EXTENT)
	)
	player_moved.emit(player_position)

func move_player(delta_pos: Vector3) -> void:
	set_player_position(player_position + delta_pos)

## Returns the closest deposit within `max_range` of `pos`, or an empty Dictionary if none.
func get_nearest_deposit(pos: Vector3, max_range: float = INTERACTION_RANGE) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = max_range
	for d in deposits:
		var d_pos: Vector3 = d["position"]
		var dist: float = Vector2(pos.x - d_pos.x, pos.z - d_pos.z).length()
		if dist <= best_dist:
			best_dist = dist
			best = d
	return best

## Returns the closest dormant or active hub within `max_range` of `pos`, or empty Dictionary.
func get_nearest_hub(pos: Vector3, max_range: float = INTERACTION_RANGE) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = max_range
	for hub_id in hubs.keys():
		var h: Dictionary = hubs[hub_id]
		var h_pos: Vector3 = h["position"]
		var dist: float = Vector2(pos.x - h_pos.x, pos.z - h_pos.z).length()
		if dist <= best_dist:
			best_dist = dist
			best = h
	return best

## Mines the nearest deposit within `max_range` of `player_position`, scaling by richness and tech.
func mine_nearest_deposit(state: GameState, base_amount: float = 2.0, max_range: float = INTERACTION_RANGE) -> Dictionary:
	var dep: Dictionary = get_nearest_deposit(player_position, max_range)
	if dep.is_empty():
		return { "ok": false, "reason": "no_deposit_in_range" }
	var elem_id: String = str(dep["element"])
	if not state.is_element_unlocked(elem_id):
		return { "ok": false, "reason": "tier_locked", "element": elem_id, "deposit": dep["name"] }
	var richness: float = float(dep.get("richness", 1.0))
	var raw_yield: float = base_amount * richness * state.tech_tree.get_mining_multiplier()
	var added: float = state.inventory.add_element(elem_id, raw_yield)
	return {
		"ok": true,
		"deposit_id": dep["id"],
		"deposit_name": dep["name"],
		"element": elem_id,
		"added": added
	}

func is_hub_activated(hub_id: String) -> bool:
	if not hubs.has(hub_id):
		return false
	return bool(hubs[hub_id].get("activated", false))

func can_activate_hub(hub_id: String, state: GameState, check_range: bool = false) -> bool:
	if not hubs.has(hub_id):
		return false
	var h: Dictionary = hubs[hub_id]
	if bool(h.get("activated", false)):
		return false
	if check_range:
		var h_pos: Vector3 = h["position"]
		var dist: float = Vector2(player_position.x - h_pos.x, player_position.z - h_pos.z).length()
		if dist > INTERACTION_RANGE:
			return false
	var req_energy: float = float(h.get("required_energy", 0.0))
	var req_elems: Dictionary = h.get("required_elements", {})
	return state.energy.has_energy(req_energy) and state.inventory.has_elements(req_elems)

func activate_hub(hub_id: String, state: GameState, check_range: bool = false) -> bool:
	if not can_activate_hub(hub_id, state, check_range):
		return false
	var h: Dictionary = hubs[hub_id]
	var req_energy: float = float(h.get("required_energy", 0.0))
	var req_elems: Dictionary = h.get("required_elements", {})
	if not state.energy.consume_energy(req_energy):
		return false
	for elem_id in req_elems.keys():
		state.inventory.consume_element(elem_id, float(req_elems[elem_id]))
	h["activated"] = true
	hub_activated.emit(hub_id)
	if bool(h.get("is_core", false)) and not is_planet_awakened:
		is_planet_awakened = true
		planet_awakened.emit()
	return true

## Total continuous passive power (Watts) generated by all activated alien hubs.
func get_total_hub_power_watts() -> float:
	var total: float = 0.0
	for h in hubs.values():
		if bool(h.get("activated", false)):
			total += float(h.get("passive_power_watts", 0.0))
	return total

func step(dt: float, state: GameState) -> void:
	var watts: float = get_total_hub_power_watts()
	if watts > 0.0:
		state.energy.add_energy(watts * dt)

func to_dict() -> Dictionary:
	var activated_ids: Array[String] = []
	for hub_id in hubs.keys():
		if bool(hubs[hub_id].get("activated", false)):
			activated_ids.append(str(hub_id))
	return {
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z
		},
		"activated_hubs": activated_ids,
		"is_planet_awakened": is_planet_awakened
	}

func from_dict(data: Dictionary) -> void:
	reset()
	var pos_dict: Dictionary = data.get("player_position", {})
	set_player_position(Vector3(
		float(pos_dict.get("x", 0.0)),
		float(pos_dict.get("y", 0.0)),
		float(pos_dict.get("z", 0.0))
	))
	var act_list: Array = data.get("activated_hubs", [])
	for raw_id in act_list:
		var hub_id: String = str(raw_id)
		if hubs.has(hub_id):
			hubs[hub_id]["activated"] = true
			if bool(hubs[hub_id].get("is_core", false)):
				is_planet_awakened = true
	if bool(data.get("is_planet_awakened", false)):
		is_planet_awakened = true
