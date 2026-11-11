class_name PlayerInventory
extends RefCounted

## PlayerInventory manages all chemical elements, compounds, and minerals carried by the player.
## Completely headless, deterministic, and signal-driven.
##
## Capacity rule: only raw elements (keys of ElementData.ELEMENTS) count toward
## max_capacity. Compounds produced by reactions (e.g. H2O, CH4) are stored
## without limit so that byproducts can never block manual mining.

signal inventory_updated(element_id: String, new_amount: float)
signal capacity_changed(current_total: float, max_capacity: float)

const EPSILON: float = 0.00001

var elements: Dictionary = {}  # { "H": 15.0, "O": 8.0, "H2O": 3.0, ... }
var max_capacity: float = 100.0  # Upgradeable raw-element carry limit

## Returns true if the given id counts toward the carry capacity.
static func is_capacity_limited(element_id: String) -> bool:
	return ElementData.ELEMENTS.has(element_id)

## Adds up to `amount` of the item. Raw elements are clamped to remaining capacity.
## Returns the amount actually added.
func add_element(element_id: String, amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var amount_to_add: float = amount
	if is_capacity_limited(element_id):
		var space_left: float = max(0.0, max_capacity - get_capacity_usage())
		amount_to_add = min(amount, space_left)

	if amount_to_add > 0.0:
		elements[element_id] = elements.get(element_id, 0.0) + amount_to_add
		inventory_updated.emit(element_id, elements[element_id])
		capacity_changed.emit(get_capacity_usage(), max_capacity)

	return amount_to_add

func consume_element(element_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	var current_val: float = elements.get(element_id, 0.0)
	if current_val + EPSILON < amount:
		return false
	elements[element_id] = current_val - amount
	if elements[element_id] <= EPSILON:
		elements.erase(element_id)
	inventory_updated.emit(element_id, elements.get(element_id, 0.0))
	capacity_changed.emit(get_capacity_usage(), max_capacity)
	return true

func has_elements(requirements: Dictionary) -> bool:
	for elem_id in requirements.keys():
		if elements.get(elem_id, 0.0) + EPSILON < float(requirements[elem_id]):
			return false
	return true

## Atomically consumes all recipe inputs. Consumes nothing if any input is missing.
func consume_recipe_inputs(recipe: Dictionary) -> bool:
	var inputs: Dictionary = recipe.get("inputs", {})
	if not has_elements(inputs):
		return false
	for elem_id in inputs.keys():
		consume_element(elem_id, inputs[elem_id])
	return true

func get_amount(element_id: String) -> float:
	return elements.get(element_id, 0.0)

## Total of capacity-limited raw elements only.
func get_capacity_usage() -> float:
	var total: float = 0.0
	for elem_id in elements.keys():
		if is_capacity_limited(elem_id):
			total += elements[elem_id]
	return total

## Total of every stored item, including uncapped compounds.
func get_total_items() -> float:
	var total: float = 0.0
	for count in elements.values():
		total += count
	return total

func clear() -> void:
	elements.clear()
	capacity_changed.emit(0.0, max_capacity)
