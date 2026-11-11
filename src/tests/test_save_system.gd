extends TestCase

const TEST_SAVE_PATH: String = "user://test_save_stage3.json"

var state: GameState
var sim: SimulationLoop

func before_each() -> void:
	state = GameState.new()
	sim = SimulationLoop.new(state)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

func test_round_trip_dict_preserves_full_state() -> void:
	state.energy.add_energy(2500000.0)
	assert_true(state.purchase_upgrade("mining_laser"))
	assert_true(state.purchase_upgrade("storage_expansion"))
	assert_true(state.purchase_upgrade("extractor_overclock"))
	state.inventory.add_element("H", 42.5)
	state.inventory.add_element("H2O", 12.0)
	var m1: Machine = state.build_machine("extractor_h")
	var m2: Machine = state.build_machine("reactor_water")
	m1.enabled = false
	sim.advance(0.5)

	var saved: Dictionary = SaveSystem.to_dict(state, 1700000000)
	var loaded_state := GameState.new()
	assert_true(SaveSystem.from_dict(saved, loaded_state))

	assert_almost_eq(loaded_state.energy.current_energy_joules, state.energy.current_energy_joules, 0.01)
	assert_almost_eq(loaded_state.energy.total_lifetime_energy, state.energy.total_lifetime_energy, 0.01)
	assert_almost_eq(loaded_state.inventory.max_capacity, 200.0)
	assert_almost_eq(loaded_state.inventory.get_amount("H"), state.inventory.get_amount("H"), 0.001)
	assert_almost_eq(loaded_state.inventory.get_amount("H2O"), state.inventory.get_amount("H2O"), 0.001)
	assert_eq(loaded_state.tech_tree.get_level("mining_laser"), 1)
	assert_eq(loaded_state.tech_tree.get_level("extractor_overclock"), 1)
	assert_eq(loaded_state.machines.size(), 2)
	assert_false(loaded_state.get_machine(m1.id).enabled)
	assert_almost_eq((loaded_state.get_machine(m1.id) as AutoExtractor).rate_multiplier, 1.25)
	assert_true(loaded_state.get_machine(m2.id) != null)

func test_save_and_load_file_with_offline_progress() -> void:
	state.energy.add_energy(500000.0)
	for i in 2:
		state.add_machine(MachineCatalog.create("extractor_h"))
		state.add_machine(MachineCatalog.create("extractor_o"))
	state.add_machine(MachineCatalog.create("reactor_water"))

	assert_true(SaveSystem.save_to_file(state, TEST_SAVE_PATH, 1000))

	var loaded_state := GameState.new()
	var loaded_sim := SimulationLoop.new(loaded_state)
	var res: Dictionary = SaveSystem.load_from_file(loaded_state, loaded_sim, TEST_SAVE_PATH, 1060)
	assert_true(res.get("ok", false))
	var offline: Dictionary = res["offline"]
	assert_almost_eq(float(offline["elapsed_seconds"]), 60.0)
	assert_true(float(offline["energy_gained"]) >= 286000.0 * 50.0, "60s offline should yield ~50+ water reactions")

	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

func test_offline_progress_clamps_to_24_hours_and_stays_bounded() -> void:
	state.energy.add_energy(10000000.0)
	for i in 2:
		state.add_machine(MachineCatalog.create("extractor_h"))
		state.add_machine(MachineCatalog.create("extractor_o"))
	state.add_machine(MachineCatalog.create("reactor_water"))

	var report: Dictionary = SaveSystem.apply_offline_progress(state, sim, 999999.0)
	assert_almost_eq(float(report["elapsed_seconds"]), SaveSystem.MAX_OFFLINE_SECONDS)
	assert_true(int(report["steps_simulated"]) <= SaveSystem.MAX_OFFLINE_STEPS + 2)
	assert_true(float(report["energy_gained"]) > 0.0)

func test_load_missing_or_invalid_file_fails_gracefully() -> void:
	var res: Dictionary = SaveSystem.load_from_file(state, sim, "user://definitely_missing_12345.json")
	assert_false(res.get("ok", true))
	assert_false(SaveSystem.from_dict({}, state))
