extends TestCase

var inv: PlayerInventory
var energy: EnergySystem
var chamber: ReactionChamber

func before_each() -> void:
	inv = PlayerInventory.new()
	energy = EnergySystem.new()
	chamber = ReactionChamber.new()

func test_start_fails_without_ingredients() -> void:
	assert_false(chamber.start_reaction("combustion_water", inv))
	assert_eq(chamber.state, ReactionChamber.State.IDLE)

func test_start_fails_for_unknown_recipe() -> void:
	assert_false(chamber.start_reaction("does_not_exist", inv))

func test_full_reaction_produces_energy_and_output() -> void:
	inv.add_element("H", 2.0)
	inv.add_element("O", 1.0)
	assert_true(chamber.start_reaction("combustion_water", inv))
	assert_eq(chamber.state, ReactionChamber.State.PROCESSING)
	chamber.tick(0.5, inv, energy)
	assert_almost_eq(energy.current_energy_joules, 0.0, 0.0001, "No energy before completion")
	chamber.tick(0.6, inv, energy)
	assert_eq(chamber.state, ReactionChamber.State.IDLE)
	assert_almost_eq(energy.current_energy_joules, 286000.0)
	assert_almost_eq(inv.get_amount("H2O"), 1.0)

func test_cannot_start_while_processing() -> void:
	inv.add_element("H", 4.0)
	inv.add_element("O", 2.0)
	assert_true(chamber.start_reaction("combustion_water", inv))
	assert_false(chamber.start_reaction("combustion_water", inv))

func test_auto_repeat_runs_until_inputs_exhausted() -> void:
	inv.add_element("H", 4.0)
	inv.add_element("O", 2.0)
	chamber.auto_repeat = true
	chamber.start_reaction("combustion_water", inv)
	for i in 10:
		chamber.tick(0.5, inv, energy)
	assert_almost_eq(energy.current_energy_joules, 572000.0, 0.01, "Exactly two reactions")
	assert_eq(chamber.state, ReactionChamber.State.IDLE)

func test_speed_and_yield_multipliers() -> void:
	inv.add_element("H", 2.0)
	inv.add_element("O", 1.0)
	chamber.speed_multiplier = 2.0
	chamber.yield_multiplier = 1.5
	chamber.start_reaction("combustion_water", inv)
	chamber.tick(0.5, inv, energy)
	assert_eq(chamber.state, ReactionChamber.State.IDLE, "2x speed halves 1s duration")
	assert_almost_eq(energy.current_energy_joules, 429000.0, 0.01)

func test_completes_on_time_with_small_fixed_steps() -> void:
	# Regression: 10 x 0.1s sums to 0.9999999 in floating point and must still complete.
	inv.add_element("H", 2.0)
	inv.add_element("O", 1.0)
	chamber.start_reaction("combustion_water", inv)
	for i in 10:
		chamber.tick(0.1, inv, energy)
	assert_eq(chamber.state, ReactionChamber.State.IDLE, "1s reaction must finish after 10 x 0.1s")

func test_auto_repeat_carries_over_excess_time() -> void:
	inv.add_element("H", 4.0)
	inv.add_element("O", 2.0)
	chamber.auto_repeat = true
	chamber.start_reaction("combustion_water", inv)
	chamber.tick(1.5, inv, energy)  # Finishes #1, 0.5s carries into #2
	chamber.tick(0.5, inv, energy)  # Finishes #2
	assert_almost_eq(energy.current_energy_joules, 572000.0, 0.01, "No time lost between repeats")

func test_huge_time_jump_does_not_overflow_stack() -> void:
	inv.max_capacity = 100000.0
	inv.add_element("H", 20000.0)
	inv.add_element("O", 10000.0)
	chamber.auto_repeat = true
	chamber.start_reaction("combustion_water", inv)
	chamber.tick(10000.0, inv, energy)
	assert_almost_eq(energy.current_energy_joules, 286000.0 * 10000.0, 1.0, "10,000 reactions in one tick")
