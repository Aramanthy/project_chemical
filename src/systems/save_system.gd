class_name SaveSystem
extends RefCounted

## Handles JSON state serialization, file persistence, and deterministic offline
## progress replay for GameState.

const SAVE_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://savegame.json"
const MAX_OFFLINE_SECONDS: float = 86400.0  # 24 hours cap
const MAX_OFFLINE_STEPS: int = 2000

## Serializes the entire GameState into a JSON-compatible Dictionary.
static func to_dict(state: GameState, timestamp_unix: int = -1) -> Dictionary:
	var saved_at: int = timestamp_unix if timestamp_unix >= 0 else int(Time.get_unix_time_from_system())
	var machines_data: Array[Dictionary] = []
	for m in state.machines:
		var m_dict: Dictionary = {
			"id": m.id,
			"def_id": m.def_id,
			"enabled": m.enabled
		}
		if m is ReactorMachine:
			var rm := m as ReactorMachine
			m_dict["chamber_state"] = int(rm.chamber.state)
			m_dict["chamber_recipe"] = rm.chamber.active_recipe_id
			m_dict["chamber_progress_sec"] = rm.chamber.current_progress_sec
			m_dict["chamber_duration_sec"] = rm.chamber.total_duration_sec
		machines_data.append(m_dict)

	var result: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at_unix": saved_at,
		"energy": {
			"current_joules": state.energy.current_energy_joules,
			"lifetime_joules": state.energy.total_lifetime_energy
		},
		"inventory": {
			"elements": state.inventory.elements.duplicate()
		},
		"tech_tree": {
			"levels": state.tech_tree.levels.duplicate()
		},
		"machines": machines_data
	}
	if state.has_method("serialize_extra"):
		result["extra"] = state.call("serialize_extra")
	return result

## Restores `state` from a Dictionary produced by `to_dict`. Returns true on success.
static func from_dict(data: Dictionary, state: GameState) -> bool:
	if not data.has("version") or not data.has("energy") or not data.has("inventory"):
		return false

	# 1. Restore TechTree first so storage capacity and multipliers are accurate
	state.tech_tree.levels.clear()
	var tech_data: Dictionary = data.get("tech_tree", {}).get("levels", {})
	for k in tech_data.keys():
		state.tech_tree.levels[str(k)] = int(tech_data[k])
	state.apply_tech_modifiers()

	# 2. Restore Energy
	var energy_data: Dictionary = data.get("energy", {})
	state.energy.current_energy_joules = max(0.0, float(energy_data.get("current_joules", 0.0)))
	state.energy.total_lifetime_energy = max(
		state.energy.current_energy_joules,
		float(energy_data.get("lifetime_joules", state.energy.current_energy_joules))
	)
	state.energy.energy_changed.emit(state.energy.current_energy_joules, 0.0)

	# 3. Restore Inventory
	state.inventory.clear()
	var elems: Dictionary = data.get("inventory", {}).get("elements", {})
	for elem_id in elems.keys():
		var amt: float = float(elems[elem_id])
		if amt > PlayerInventory.EPSILON:
			state.inventory.elements[str(elem_id)] = amt
			state.inventory.inventory_updated.emit(str(elem_id), amt)
	state.inventory.capacity_changed.emit(state.inventory.get_capacity_usage(), state.inventory.max_capacity)

	# 4. Restore Deployed Machines
	state.machines.clear()
	state._next_machine_id = 1
	var machines_list: Array = data.get("machines", [])
	for item in machines_list:
		if not (item is Dictionary):
			continue
		var m_dict: Dictionary = item
		var def_id: String = str(m_dict.get("def_id", ""))
		var machine: Machine = MachineCatalog.create(def_id)
		if machine == null:
			continue
		machine.enabled = bool(m_dict.get("enabled", true))
		state.add_machine(machine)
		if m_dict.has("id"):
			machine.id = int(m_dict["id"])
			state._next_machine_id = max(state._next_machine_id, machine.id + 1)
		if machine is ReactorMachine:
			var rm := machine as ReactorMachine
			var c_state: int = int(m_dict.get("chamber_state", ReactionChamber.State.IDLE))
			if c_state == ReactionChamber.State.PROCESSING:
				rm.chamber.state = ReactionChamber.State.PROCESSING
				rm.chamber.active_recipe_id = str(m_dict.get("chamber_recipe", rm.recipe_id))
				rm.chamber.current_progress_sec = float(m_dict.get("chamber_progress_sec", 0.0))
				rm.chamber.total_duration_sec = max(0.05, float(m_dict.get("chamber_duration_sec", 1.0)))

	if state.has_method("deserialize_extra") and data.has("extra"):
		state.call("deserialize_extra", data["extra"])
	return true

## Simulates `elapsed_seconds` of offline production (clamped to `max_offline_seconds`).
## Uses bounded step counts so even 24 hours completes in milliseconds.
static func apply_offline_progress(
		state: GameState,
		sim: SimulationLoop,
		elapsed_seconds: float,
		max_offline_seconds: float = MAX_OFFLINE_SECONDS) -> Dictionary:
	var clamped: float = clamp(elapsed_seconds, 0.0, max_offline_seconds)
	var lifetime_before: float = state.energy.total_lifetime_energy
	var current_before: float = state.energy.current_energy_joules
	var steps_run: int = 0

	if clamped > SimulationLoop.TIME_EPSILON:
		var dt: float = max(SimulationLoop.FIXED_STEP, clamped / float(MAX_OFFLINE_STEPS))
		var remaining: float = clamped
		while remaining > SimulationLoop.TIME_EPSILON:
			var step_size: float = min(dt, remaining)
			sim.step_dt(step_size)
			remaining -= step_size
			steps_run += 1

	return {
		"elapsed_seconds": clamped,
		"energy_gained": state.energy.total_lifetime_energy - lifetime_before,
		"net_energy_delta": state.energy.current_energy_joules - current_before,
		"steps_simulated": steps_run
	}

## Writes the serialized GameState as formatted JSON to `path`.
static func save_to_file(
		state: GameState,
		path: String = DEFAULT_SAVE_PATH,
		timestamp_unix: int = -1) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var payload: Dictionary = to_dict(state, timestamp_unix)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

## Loads GameState from `path` and optionally applies offline progress if `sim` is provided.
static func load_from_file(
		state: GameState,
		sim: SimulationLoop = null,
		path: String = DEFAULT_SAVE_PATH,
		current_unix: int = -1) -> Dictionary:
	if not FileAccess.file_exists(path):
		return { "ok": false, "error": "file_not_found" }
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { "ok": false, "error": "open_failed" }
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return { "ok": false, "error": "invalid_json" }
	var data: Dictionary = parsed
	if not from_dict(data, state):
		return { "ok": false, "error": "invalid_schema" }

	var offline_report: Dictionary = {
		"elapsed_seconds": 0.0,
		"energy_gained": 0.0,
		"net_energy_delta": 0.0,
		"steps_simulated": 0
	}
	if sim != null and data.has("saved_at_unix"):
		var now_ts: int = current_unix if current_unix >= 0 else int(Time.get_unix_time_from_system())
		var elapsed: float = max(0.0, float(now_ts - int(data["saved_at_unix"])))
		offline_report = apply_offline_progress(state, sim, elapsed)

	return {
		"ok": true,
		"saved_at_unix": int(data.get("saved_at_unix", 0)),
		"offline": offline_report
	}
