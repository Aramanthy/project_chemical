extends TestCase

var state: GameState
var sim: SimulationLoop

func before_each() -> void:
	state = GameState.new()
	sim = SimulationLoop.new(state)

func test_initial_multipliers_and_tier() -> void:
	assert_almost_eq(state.tech_tree.get_mining_multiplier(), 1.0)
	assert_almost_eq(state.tech_tree.get_max_storage_capacity(), 100.0)
	assert_almost_eq(state.tech_tree.get_extractor_rate_multiplier(), 1.0)
	assert_almost_eq(state.tech_tree.get_reaction_speed_multiplier(), 1.0)
	assert_almost_eq(state.tech_tree.get_reaction_yield_multiplier(), 1.0)
	assert_eq(state.tech_tree.get_max_unlocked_tier(), ElementData.Tier.TIER_2_REFINED)

func test_purchase_fails_without_energy() -> void:
	assert_false(state.purchase_upgrade("mining_laser"))
	assert_eq(state.tech_tree.get_level("mining_laser"), 0)

func test_purchase_scales_cost_and_updates_multipliers() -> void:
	state.energy.add_energy(500000.0)
	assert_almost_eq(state.tech_tree.get_next_cost("mining_laser"), 50000.0)
	assert_true(state.purchase_upgrade("mining_laser"))
	assert_eq(state.tech_tree.get_level("mining_laser"), 1)
	assert_almost_eq(state.tech_tree.get_mining_multiplier(), 1.5)
	assert_almost_eq(state.tech_tree.get_next_cost("mining_laser"), 100000.0)

func test_storage_expansion_immediately_updates_inventory_capacity() -> void:
	state.energy.add_energy(150000.0)
	assert_true(state.purchase_upgrade("storage_expansion"))
	assert_almost_eq(state.inventory.max_capacity, 200.0)

func test_extractor_and_reactor_upgrades_propagate_to_existing_and_new_machines() -> void:
	state.energy.add_energy(2000000.0)
	var ext: AutoExtractor = state.add_machine(MachineCatalog.create("extractor_h")) as AutoExtractor
	var react: ReactorMachine = state.add_machine(MachineCatalog.create("reactor_water")) as ReactorMachine
	assert_almost_eq(ext.rate_multiplier, 1.0)
	assert_almost_eq(react.chamber.speed_multiplier, 1.0)

	assert_true(state.purchase_upgrade("extractor_overclock"))
	assert_true(state.purchase_upgrade("reactor_catalysts"))
	assert_almost_eq(ext.rate_multiplier, 1.25, 0.001, "Existing extractor updated")
	assert_almost_eq(react.chamber.speed_multiplier, 1.20, 0.001, "Existing reactor speed updated")
	assert_almost_eq(react.chamber.yield_multiplier, 1.25, 0.001, "Existing reactor yield updated")

	var ext2: AutoExtractor = state.add_machine(MachineCatalog.create("extractor_o")) as AutoExtractor
	assert_almost_eq(ext2.rate_multiplier, 1.25, 0.001, "Newly added extractor receives multiplier")

func test_tier_3_and_tier_4_unlock_gates_machines_and_prerequisites() -> void:
	state.energy.add_energy(10000000000.0)
	# Cannot build Tier 3 or purchase Tier 4 before Tier 3 is unlocked
	assert_false(state.is_machine_unlocked("extractor_u"))
	assert_eq(state.build_machine("extractor_u"), null)
	assert_false(state.purchase_upgrade("unlock_tier_4_exotic"), "Tier 4 requires Tier 3 first")

	# Unlock Tier 3
	assert_true(state.purchase_upgrade("unlock_tier_3_nuclear"))
	assert_true(state.is_machine_unlocked("extractor_u"))
	assert_true(state.build_machine("extractor_u") != null)
	assert_false(state.is_machine_unlocked("reactor_astral"))

	# Now Tier 4 can be unlocked
	assert_true(state.purchase_upgrade("unlock_tier_4_exotic"))
	assert_true(state.is_machine_unlocked("reactor_astral"))
	assert_true(state.build_machine("reactor_astral") != null)

func test_max_level_caps_purchases() -> void:
	state.energy.add_energy(10000000.0)
	assert_true(state.purchase_upgrade("unlock_tier_3_nuclear"))
	assert_true(state.tech_tree.is_maxed("unlock_tier_3_nuclear"))
	assert_false(state.purchase_upgrade("unlock_tier_3_nuclear"))
