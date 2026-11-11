class_name GameState
extends RefCounted

## Aggregate root holding all simulation state: energy, storage, tech tree,
## and deployed machines. Contains no rendering code; views observe it via signals.

signal machine_added(machine: Machine)
signal machine_removed(machine: Machine)

var energy: EnergySystem = EnergySystem.new()
var inventory: PlayerInventory = PlayerInventory.new()
var tech_tree: TechTree = TechTree.new()
var planet: PlanetGrid = PlanetGrid.new()
var machines: Array[Machine] = []

var _next_machine_id: int = 1

func _init() -> void:
	tech_tree.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_upgrade_purchased(_upgrade_id: String, _new_level: int) -> void:
	apply_tech_modifiers()

## Synchronizes inventory capacity and all machine multipliers with current TechTree levels.
func apply_tech_modifiers() -> void:
	inventory.max_capacity = tech_tree.get_max_storage_capacity()
	var ext_mult: float = tech_tree.get_extractor_rate_multiplier()
	var spd_mult: float = tech_tree.get_reaction_speed_multiplier()
	var yld_mult: float = tech_tree.get_reaction_yield_multiplier()
	for m in machines:
		_apply_modifiers_to_machine(m, ext_mult, spd_mult, yld_mult)

func _apply_modifiers_to_machine(m: Machine, ext_mult: float, spd_mult: float, yld_mult: float) -> void:
	if m is AutoExtractor:
		(m as AutoExtractor).rate_multiplier = ext_mult
	elif m is ReactorMachine:
		var rm := m as ReactorMachine
		rm.chamber.speed_multiplier = spd_mult
		rm.chamber.yield_multiplier = yld_mult

## Applies current reaction speed and yield multipliers to a handheld ReactionChamber.
func sync_chamber_modifiers(chamber: ReactionChamber) -> void:
	chamber.speed_multiplier = tech_tree.get_reaction_speed_multiplier()
	chamber.yield_multiplier = tech_tree.get_reaction_yield_multiplier()

## Purchases an upgrade through the TechTree and immediately applies its effects.
func purchase_upgrade(upgrade_id: String) -> bool:
	return tech_tree.purchase(upgrade_id, energy)

func is_element_unlocked(element_id: String) -> bool:
	var elem: Dictionary = ElementData.get_element(element_id)
	if elem.is_empty():
		return false
	return tech_tree.is_tier_unlocked(int(elem.get("tier", ElementData.Tier.TIER_1_LIGHT)))

func is_recipe_unlocked(recipe_id: String) -> bool:
	var recipe: Dictionary = ElementData.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	return tech_tree.is_tier_unlocked(int(recipe.get("tier", ElementData.Tier.TIER_1_LIGHT)))

func is_machine_unlocked(def_id: String) -> bool:
	var def: Dictionary = MachineCatalog.get_def(def_id)
	if def.is_empty():
		return false
	return tech_tree.is_tier_unlocked(MachineCatalog.get_tier(def_id))

## Registers an already-constructed machine, applies tech modifiers, and assigns a unique id.
func add_machine(machine: Machine) -> Machine:
	machine.id = _next_machine_id
	_next_machine_id += 1
	_apply_modifiers_to_machine(
		machine,
		tech_tree.get_extractor_rate_multiplier(),
		tech_tree.get_reaction_speed_multiplier(),
		tech_tree.get_reaction_yield_multiplier()
	)
	machines.append(machine)
	machine_added.emit(machine)
	return machine

## Pays the build cost in energy and deploys the machine if unlocked and affordable.
## Returns null (and spends nothing) if unknown, locked, or energy is insufficient.
func build_machine(def_id: String) -> Machine:
	if not is_machine_unlocked(def_id):
		return null
	var machine: Machine = MachineCatalog.create(def_id)
	if machine == null:
		return null
	if not energy.consume_energy(MachineCatalog.get_build_cost(def_id)):
		return null
	return add_machine(machine)

func remove_machine(machine_id: int) -> bool:
	for i in machines.size():
		if machines[i].id == machine_id:
			var removed: Machine = machines[i]
			machines.remove_at(i)
			machine_removed.emit(removed)
			return true
	return false

func get_machine(machine_id: int) -> Machine:
	for m in machines:
		if m.id == machine_id:
			return m
	return null

## Total continuous power demand of all enabled machines (W).
func get_total_power_draw() -> float:
	var total: float = 0.0
	for m in machines:
		if m.enabled:
			total += m.power_draw_watts
	return total

func serialize_extra() -> Dictionary:
	return {
		"planet": planet.to_dict()
	}

func deserialize_extra(extra: Dictionary) -> void:
	if extra.has("planet") and extra["planet"] is Dictionary:
		planet.from_dict(extra["planet"])
