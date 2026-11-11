extends Control

## Main controller demonstrating Phase 1 core logic:
## Element harvesting, chemical reaction energy release, and real-time power rate tracking.

var energy_system: EnergySystem
var inventory: PlayerInventory
var chamber: ReactionChamber

@onready var energy_label: Label = $VBoxContainer/Header/VBox/EnergyLabel
@onready var power_label: Label = $VBoxContainer/Header/VBox/PowerLabel
@onready var inventory_label: Label = $VBoxContainer/Body/LeftCol/InventoryPanel/VBox/InventoryText
@onready var progress_bar: ProgressBar = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/ProgressBar
@onready var status_label: Label = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/StatusLabel
@onready var log_box: RichTextLabel = $VBoxContainer/Footer/LogBox
@onready var auto_repeat_check: CheckBox = $VBoxContainer/Body/RightCol/ChamberPanel/VBox/AutoRepeatCheck

func _ready() -> void:
	# Initialize Headless Systems
	energy_system = EnergySystem.new()
	inventory = PlayerInventory.new()
	chamber = ReactionChamber.new()
	
	# Connect Signals
	energy_system.energy_changed.connect(_on_energy_changed)
	energy_system.power_rate_updated.connect(_on_power_rate_updated)
	inventory.inventory_updated.connect(_on_inventory_updated)
	
	chamber.reaction_started.connect(_on_reaction_started)
	chamber.reaction_progress_updated.connect(_on_reaction_progress)
	chamber.reaction_completed.connect(_on_reaction_completed)
	
	# Initial UI Refresh
	_update_energy_ui()
	_update_inventory_ui()
	_log("[color=yellow]System initialized.[/color] Ready to synthesize elements and produce power.")

func _process(delta: float) -> void:
	# Tick systems
	chamber.tick(delta, inventory, energy_system)
	energy_system.update_tick(delta)

# --- USER INTERACTIONS (GATHERING & REACTIONS) ---

func _on_mine_hydrogen_pressed() -> void:
	var added: float = inventory.add_element("H", 2.0)
	_log("Mined [color=cyan]+%.1f Hydrogen (H)[/color]" % added)

func _on_mine_oxygen_pressed() -> void:
	var added: float = inventory.add_element("O", 1.0)
	_log("Mined [color=deep_sky_blue]+%.1f Oxygen (O)[/color]" % added)

func _on_mine_carbon_pressed() -> void:
	var added: float = inventory.add_element("C", 1.0)
	_log("Mined [color=light_gray]+%.1f Carbon (C)[/color]" % added)

func _on_mine_uranium_pressed() -> void:
	var added: float = inventory.add_element("U", 1.0)
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

func _trigger_recipe(recipe_id: String) -> void:
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
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
		inventory_label.text = "\n".join(lines)

func _log(msg: String) -> void:
	if log_box:
		log_box.append_text(msg + "\n")
