class_name GameState
extends RefCounted

## Aggregate root holding all simulation state: energy, storage, and deployed machines.
## Contains no rendering code; views observe it through signals.

signal machine_added(machine: Machine)
signal machine_removed(machine: Machine)

var energy: EnergySystem = EnergySystem.new()
var inventory: PlayerInventory = PlayerInventory.new()
var machines: Array[Machine] = []

var _next_machine_id: int = 1

## Registers an already-constructed machine and assigns it a unique id.
func add_machine(machine: Machine) -> Machine:
	machine.id = _next_machine_id
	_next_machine_id += 1
	machines.append(machine)
	machine_added.emit(machine)
	return machine

## Pays the build cost in energy and deploys the machine.
## Returns null (and spends nothing) if the id is unknown or energy is insufficient.
func build_machine(def_id: String) -> Machine:
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
