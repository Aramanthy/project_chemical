extends Control

## Main controller demonstrating Phase 1 core logic:
## Element harvesting, chemical reaction energy release, real-time power rate
## tracking, and deployable automation driven by a fixed-step SimulationLoop.

const MACHINE_LIST_REFRESH_SEC: float = 0.2

var game_state: GameState
var sim: SimulationLoop
var energy_system: EnergySystem
var inventory: PlayerInventory
var chamber: ReactionChamber  # The player's handheld chamber (manual reactions)

var _machine_list_timer: float = 0.0

@onready var energy_label: Label = $VBoxContainer/Header/VBox/EnergyLabel
@onready var power_label: Label = $VBoxContainer/Header/VBox/PowerLabel
@onready var inventory_label: Label = $VBoxContainer/Body/LeftCol/InventoryPanel/VBox/InventoryText
@onready var progress_bar: ProgressBar = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/ProgressBar
@onready var status_label: Label = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/StatusLabel
@onready var log_box: RichTextLabel = $VBoxContainer/Footer/LogBox
@onready var auto_repeat_check: CheckBox = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/AutoRepeatCheck
@onready var build_buttons: VBoxContainer = $VBoxContainer/Body/AutoCol/BuildButtons
@onready var machine_list: RichTextLabel = $VBoxContainer/Body/AutoCol/MachinePanel/MachineList
@onready var upgrade_buttons: VBoxContainer = $VBoxContainer/Body/TechCol/UpgradeButtons
@onready var hub_buttons: VBoxContainer = $VBoxContainer/Body/TechCol/HubButtons

var _upgrade_btn_map: Dictionary = {}  # { upgrade_id: Button }
var _build_btn_map: Dictionary = {}    # { def_id: Button }
var _hub_btn_map: Dictionary = {}      # { hub_id: Button }

func _ready() -> void:
	# Initialize Headless Systems
	game_state = GameState.new()
	sim = SimulationLoop.new(game_state)
	energy_system = game_state.energy
	inventory = game_state.inventory
	chamber = ReactionChamber.new()
	game_state.sync_chamber_modifiers(chamber)
	
	# Connect Signals
	energy_system.energy_changed.connect(_on_energy_changed)
	energy_system.power_rate_updated.connect(_on_power_rate_updated)
	inventory.inventory_updated.connect(_on_inventory_updated)
	game_state.machine_added.connect(_on_machine_added)
	game_state.tech_tree.upgrade_purchased.connect(_on_upgrade_purchased)
	game_state.planet.hub_activated.connect(_on_hub_activated)
	game_state.planet.planet_awakened.connect(_on_planet_awakened)
	
	chamber.reaction_started.connect(_on_reaction_started)
	chamber.reaction_progress_updated.connect(_on_reaction_progress)
	chamber.reaction_completed.connect(_on_reaction_completed)
	
	_create_build_buttons()
	_create_upgrade_buttons()
	_create_hub_buttons()
	
	# Initial UI Refresh
	_update_energy_ui()
	_update_inventory_ui()
	_update_machine_list()
	_update_upgrade_buttons()
	_update_hub_buttons()
	_log("[color=yellow]System initialized.[/color] Ready to synthesize elements and produce power.")

func _process(delta: float) -> void:
	# Manual chamber follows real time; automation runs on the fixed-step loop
	# (which also updates the power-rate measurement).
	chamber.tick(delta, inventory, energy_system)
	sim.advance(delta)
	
	_machine_list_timer += delta
	if _machine_list_timer >= MACHINE_LIST_REFRESH_SEC:
		_machine_list_timer = 0.0
		_update_machine_list()

# --- AUTOMATION ---

func _create_build_buttons() -> void:
	for def_id in MachineCatalog.DEFS.keys():
		var def: Dictionary = MachineCatalog.get_def(def_id)
		var button := Button.new()
		button.text = "Build %s (%s)" % [def["name"], EnergySystem.format_joules(def["build_cost_joules"])]
		button.pressed.connect(_on_build_pressed.bind(def_id))
		build_buttons.add_child(button)
		_build_btn_map[def_id] = button

func _on_build_pressed(def_id: String) -> void:
	if not game_state.is_machine_unlocked(def_id):
		_log("[color=red]%s requires a higher Tech Tier unlock![/color]" % MachineCatalog.get_def(def_id).get("name", def_id))
		return
	var cost: float = MachineCatalog.get_build_cost(def_id)
	if game_state.build_machine(def_id) == null:
		_log("[color=red]Not enough energy to build %s (needs %s).[/color]" % [
			MachineCatalog.get_def(def_id).get("name", def_id), EnergySystem.format_joules(cost)])

func _create_upgrade_buttons() -> void:
	if not upgrade_buttons:
		return
	for upgrade_id in TechTree.UPGRADES.keys():
		var button := Button.new()
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		upgrade_buttons.add_child(button)
		_upgrade_btn_map[upgrade_id] = button

func _on_upgrade_pressed(upgrade_id: String) -> void:
	var def: Dictionary = TechTree.UPGRADES.get(upgrade_id, {})
	if not game_state.tech_tree.is_prerequisite_met(upgrade_id):
		_log("[color=red]Upgrade prerequisite not met for %s.[/color]" % def.get("name", upgrade_id))
		return
	if game_state.tech_tree.is_maxed(upgrade_id):
		_log("[color=orange]%s is already at max level.[/color]" % def.get("name", upgrade_id))
		return
	var cost: float = game_state.tech_tree.get_next_cost(upgrade_id)
	if not game_state.purchase_upgrade(upgrade_id):
		_log("[color=red]Not enough energy for %s (needs %s).[/color]" % [
			def.get("name", upgrade_id), EnergySystem.format_joules(cost)])

func _on_upgrade_purchased(upgrade_id: String, new_level: int) -> void:
	var def: Dictionary = TechTree.UPGRADES.get(upgrade_id, {})
	game_state.sync_chamber_modifiers(chamber)
	_update_upgrade_buttons()
	_update_inventory_ui()
	_log("[color=gold]Upgrade purchased: %s (Lv.%d)![/color]" % [def.get("name", upgrade_id), new_level])

func _update_upgrade_buttons() -> void:
	for upgrade_id in _upgrade_btn_map.keys():
		var btn: Button = _upgrade_btn_map[upgrade_id]
		var def: Dictionary = TechTree.UPGRADES[upgrade_id]
		var lvl: int = game_state.tech_tree.get_level(upgrade_id)
		var max_lvl: int = game_state.tech_tree.get_max_level(upgrade_id)
		if game_state.tech_tree.is_maxed(upgrade_id):
			btn.text = "%s [MAX Lv.%d]" % [def["name"], lvl]
			btn.disabled = true
		elif not game_state.tech_tree.is_prerequisite_met(upgrade_id):
			btn.text = "%s [LOCKED]" % def["name"]
			btn.disabled = true
		else:
			var cost: float = game_state.tech_tree.get_next_cost(upgrade_id)
			btn.text = "%s (Lv.%d/%d) — %s" % [def["name"], lvl, max_lvl, EnergySystem.format_joules(cost)]
			btn.disabled = false
	for def_id in _build_btn_map.keys():
		var bbtn: Button = _build_btn_map[def_id]
		var mdef: Dictionary = MachineCatalog.get_def(def_id)
		if game_state.is_machine_unlocked(def_id):
			bbtn.text = "Build %s (%s)" % [mdef["name"], EnergySystem.format_joules(mdef["build_cost_joules"])]
			bbtn.disabled = false
		else:
			bbtn.text = "[Locked Tier] %s (%s)" % [mdef["name"], EnergySystem.format_joules(mdef["build_cost_joules"])]
			bbtn.disabled = true

func _create_hub_buttons() -> void:
	if not hub_buttons:
		return
	for hub_id in PlanetGrid.HUB_DEFS.keys():
		var button := Button.new()
		button.pressed.connect(_on_hub_pressed.bind(hub_id))
		hub_buttons.add_child(button)
		_hub_btn_map[hub_id] = button

func _on_hub_pressed(hub_id: String) -> void:
	var h: Dictionary = game_state.planet.hubs.get(hub_id, {})
	if bool(h.get("activated", false)):
		return
	if not game_state.planet.activate_hub(hub_id, game_state, false):
		var req_e: String = EnergySystem.format_joules(float(h.get("required_energy", 0.0)))
		_log("[color=red]Cannot ignite %s yet (requires %s + %s).[/color]" % [
			h.get("name", hub_id), req_e, str(h.get("required_elements", {}))
		])

func _on_hub_activated(hub_id: String) -> void:
	var h: Dictionary = game_state.planet.hubs.get(hub_id, {})
	_update_hub_buttons()
	_log("[color=aqua]Alien Hub Ignited: %s (+%s passive power)![/color]" % [
		h.get("name", hub_id), EnergySystem.format_watts(float(h.get("passive_power_watts", 0.0)))
	])

func _on_planet_awakened() -> void:
	_log("[color=gold][b]*** CENTRAL PLANETARY CORE IGNITED — PLANET AWAKENED! ***[/b][/color]")

func _update_hub_buttons() -> void:
	for hub_id in _hub_btn_map.keys():
		var btn: Button = _hub_btn_map[hub_id]
		var h: Dictionary = game_state.planet.hubs[hub_id]
		var watts_str: String = EnergySystem.format_watts(float(h["passive_power_watts"]))
		if bool(h.get("activated", false)):
			btn.text = "%s [ONLINE +%s]" % [h["name"], watts_str]
			btn.disabled = true
		else:
			var cost_e: String = EnergySystem.format_joules(float(h["required_energy"]))
			btn.text = "Ignite %s (%s -> +%s)" % [h["name"], cost_e, watts_str]
			btn.disabled = false

func _on_machine_added(machine: Machine) -> void:
	_log("[color=violet]Deployed #%d %s.[/color]" % [machine.id, machine.display_name])
	_update_machine_list()

func _update_machine_list() -> void:
	if not machine_list:
		return
	if game_state.machines.is_empty():
		machine_list.text = "No machines deployed.\nGenerate energy manually, then build extractors."
		return
	var lines: Array[String] = []
	lines.append("Total draw: %s" % EnergySystem.format_watts(game_state.get_total_power_draw()))
	for m in game_state.machines:
		var color: String = "lime" if m.status == Machine.Status.RUNNING else "orange"
		var extra: String = ""
		if m is ReactorMachine:
			extra = " %d%%" % int((m as ReactorMachine).get_progress() * 100.0)
		lines.append("#%d %s — [color=%s]%s[/color]%s" % [
			m.id, m.display_name, color, Machine.status_to_string(m.status), extra])
	machine_list.text = "\n".join(lines)

# --- USER INTERACTIONS (GATHERING & REACTIONS) ---

func _on_mine_hydrogen_pressed() -> void:
	var added: float = inventory.add_element("H", 2.0 * game_state.tech_tree.get_mining_multiplier())
	_log("Mined [color=cyan]+%.1f Hydrogen (H)[/color]" % added)

func _on_mine_oxygen_pressed() -> void:
	var added: float = inventory.add_element("O", 1.0 * game_state.tech_tree.get_mining_multiplier())
	_log("Mined [color=deep_sky_blue]+%.1f Oxygen (O)[/color]" % added)

func _on_mine_carbon_pressed() -> void:
	var added: float = inventory.add_element("C", 1.0 * game_state.tech_tree.get_mining_multiplier())
	_log("Mined [color=light_gray]+%.1f Carbon (C)[/color]" % added)

func _on_mine_uranium_pressed() -> void:
	if not game_state.is_element_unlocked("U"):
		_log("[color=red]Uranium (U) requires Unlock Tier 3: Nuclear Physics![/color]")
		return
	var added: float = inventory.add_element("U", 1.0 * game_state.tech_tree.get_mining_multiplier())
	_log("Mined [color=lawn_green]+%.1f Uranium (U)[/color]" % added)

func _on_start_water_reaction_pressed() -> void:
	_trigger_recipe("combustion_water")

func _on_start_methane_reaction_pressed() -> void:
	_trigger_recipe("hydrocarbon_methane")

func _on_start_fission_reaction_pressed() -> void:
	_trigger_recipe("uranium_fission")

func _on_auto_repeat_toggled(button_pressed: bool) -> void:
	chamber.auto_repeat = button_pressed
	_log("Auto-repeat reactor set to: [b]%s[/b]" % ("ON" if button_pressed else "OFF"))

func _on_save_pressed() -> void:
	if SaveSystem.save_to_file(game_state):
		_log("[color=lime]Game saved to %s.[/color]" % SaveSystem.DEFAULT_SAVE_PATH)
	else:
		_log("[color=red]Failed to save game![/color]")

func _on_load_pressed() -> void:
	var res: Dictionary = SaveSystem.load_from_file(game_state, sim)
	if not res.get("ok", false):
		_log("[color=red]Load failed (%s).[/color]" % str(res.get("error", "unknown")))
		return
	game_state.sync_chamber_modifiers(chamber)
	_update_energy_ui()
	_update_inventory_ui()
	_update_machine_list()
	_update_upgrade_buttons()
	_update_hub_buttons()
	var offline: Dictionary = res.get("offline", {})
	var elapsed: float = float(offline.get("elapsed_seconds", 0.0))
	var gained: float = float(offline.get("energy_gained", 0.0))
	_log("[color=lime]Game loaded![/color] Offline %.1fs -> Generated [b]+%s[/b]." % [
		elapsed, EnergySystem.format_joules(gained)
	])

func _on_simulate_offline_pressed() -> void:
	var report: Dictionary = SaveSystem.apply_offline_progress(game_state, sim, 60.0)
	_update_energy_ui()
	_update_inventory_ui()
	_update_machine_list()
	_update_upgrade_buttons()
	_log("[color=aqua]Offline +60s simulated:[/color] Generated [b]+%s[/b]." % EnergySystem.format_joules(report["energy_gained"]))

func _trigger_recipe(recipe_id: String) -> void:
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
	if not game_state.is_recipe_unlocked(recipe_id):
		_log("[color=red]%s requires a higher Tech Tier unlock![/color]" % recipe.get("name", recipe_id))
		return
	if chamber.state == ReactionChamber.State.PROCESSING:
		_log("[color=orange]Reaction Chamber is currently busy![/color]")
		return
		
	if not inventory.has_elements(recipe.get("inputs", {})):
		_log("[color=red]Missing required ingredients for %s![/color]" % recipe.get("name", recipe_id))
		return
		
	chamber.start_reaction(recipe_id, inventory)

# --- SIGNAL HANDLERS ---

func _on_energy_changed(_current: float, _delta: float) -> void:
	_update_energy_ui()

func _on_power_rate_updated(watts: float) -> void:
	if power_label:
		power_label.text = "Output Power: " + EnergySystem.format_watts(watts)

func _on_inventory_updated(_elem_id: String, _amount: float) -> void:
	_update_inventory_ui()

func _on_reaction_started(recipe_id: String) -> void:
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
	status_label.text = "Reacting: " + recipe.get("name", recipe_id)
	progress_bar.value = 0.0

func _on_reaction_progress(_recipe_id: String, ratio: float) -> void:
	progress_bar.value = ratio * 100.0

func _on_reaction_completed(recipe_id: String, energy_generated: float) -> void:
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
	status_label.text = "Status: Idle"
	progress_bar.value = 0.0
	_log("[color=green]Reaction complete (%s)![/color] Produced [b]+%s[/b]" % [
		recipe.get("name", recipe_id),
		EnergySystem.format_joules(energy_generated)
	])

# --- UI REFRESH HELPERS ---

func _update_energy_ui() -> void:
	if energy_label:
		energy_label.text = "Stored Energy: " + EnergySystem.format_joules(energy_system.current_energy_joules)

func _update_inventory_ui() -> void:
	if not inventory_label:
		return
	var lines: Array[String] = []
	for elem_id in inventory.elements.keys():
		var amount: float = inventory.elements[elem_id]
		var elem_info: Dictionary = ElementData.get_element(elem_id)
		var display_name: String = elem_info.get("name", elem_id)
		lines.append("• %s (%s): %.1f" % [display_name, elem_id, amount])
	
	if lines.is_empty():
		inventory_label.text = "Inventory empty.\nClick elements above to mine."
	else:
		lines.insert(0, "Capacity: %.1f / %.0f (raw elements)" % [inventory.get_capacity_usage(), inventory.max_capacity])
		inventory_label.text = "\n".join(lines)

func _log(msg: String) -> void:
	if log_box:
		log_box.append_text(msg + "\n")
