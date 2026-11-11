extends TestCase

var state: GameState
var sim: SimulationLoop

func before_each() -> void:
	state = GameState.new()
	sim = SimulationLoop.new(state)

# --- Building ---

func test_build_fails_without_energy() -> void:
	assert_eq(state.build_machine("extractor_h"), null)
	assert_eq(state.machines.size(), 0)

func test_build_consumes_cost_and_assigns_unique_ids() -> void:
	state.energy.add_energy(1000000.0)
	var a: Machine = state.build_machine("extractor_h")
	var b: Machine = state.build_machine("extractor_o")
	assert_true(a != null and b != null)
	assert_true(a.id != b.id, "Ids must be unique")
	assert_almost_eq(state.energy.current_energy_joules, 800000.0)

func test_build_unknown_machine_spends_nothing() -> void:
	state.energy.add_energy(1000000.0)
	assert_eq(state.build_machine("nope"), null)
	assert_almost_eq(state.energy.current_energy_joules, 1000000.0)

func test_remove_machine() -> void:
	var m: Machine = state.add_machine(MachineCatalog.create("extractor_h"))
	assert_true(state.remove_machine(m.id))
	assert_false(state.remove_machine(m.id))
	assert_eq(state.machines.size(), 0)

# --- Extractor ---

func test_extractor_produces_at_rate_and_draws_power() -> void:
	state.energy.add_energy(10000.0)
	state.add_machine(MachineCatalog.create("extractor_h"))  # 1 H/s, 2 kW
	sim.advance(1.0)
	assert_almost_eq(state.inventory.get_amount("H"), 1.0, 0.001)
	assert_almost_eq(state.energy.current_energy_joules, 8000.0, 0.01)

func test_extractor_stalls_without_power() -> void:
	var m: Machine = state.add_machine(MachineCatalog.create("extractor_h"))
	sim.advance(1.0)
	assert_almost_eq(state.inventory.get_amount("H"), 0.0)
	assert_eq(m.status, Machine.Status.NO_POWER)

func test_extractor_stops_when_storage_full_without_wasting_power() -> void:
	state.energy.add_energy(10000.0)
	state.inventory.max_capacity = 5.0
	state.inventory.add_element("O", 5.0)
	var m: Machine = state.add_machine(MachineCatalog.create("extractor_h"))
	sim.advance(1.0)
	assert_eq(m.status, Machine.Status.OUTPUT_BLOCKED)
	assert_almost_eq(state.energy.current_energy_joules, 10000.0, 0.01, "No power drawn when blocked")

func test_disabled_machine_does_nothing() -> void:
	state.energy.add_energy(10000.0)
	var m: Machine = state.add_machine(MachineCatalog.create("extractor_h"))
	m.enabled = false
	sim.advance(1.0)
	assert_eq(m.status, Machine.Status.DISABLED)
	assert_almost_eq(state.inventory.get_amount("H"), 0.0)

# --- Reactor ---

func test_reactor_reports_no_input() -> void:
	var m: Machine = state.add_machine(MachineCatalog.create("reactor_water"))
	sim.advance(0.5)
	assert_eq(m.status, Machine.Status.NO_INPUT)

func test_full_production_chain_generates_energy() -> void:
	# 2 H extractors (2 H/s) + 2 O extractors (1 O/s) exactly feed one water reactor (1 run/s).
	state.energy.add_energy(100000.0)
	for i in 2:
		state.add_machine(MachineCatalog.create("extractor_h"))
		state.add_machine(MachineCatalog.create("extractor_o"))
	state.add_machine(MachineCatalog.create("reactor_water"))
	sim.advance(10.0)
	var produced: float = state.energy.total_lifetime_energy - 100000.0
	assert_true(produced >= 286000.0 * 8.0, "Chain should complete ~8+ reactions in 10s, got %s" % produced)
	assert_true(state.inventory.get_amount("H2O") >= 8.0)

# --- Simulation loop ---

func test_fixed_step_is_frame_rate_independent() -> void:
	var state_b := GameState.new()
	var sim_b := SimulationLoop.new(state_b)
	for s in [state, state_b]:
		s.energy.add_energy(100000.0)
		s.add_machine(MachineCatalog.create("extractor_h"))
		s.add_machine(MachineCatalog.create("extractor_o"))
		s.add_machine(MachineCatalog.create("reactor_water"))
	# A: one big frame. B: many uneven small frames. Same total time.
	sim.advance(6.0)
	for i in 40:
		sim_b.advance(0.15)
	assert_eq(sim.total_steps, sim_b.total_steps)
	assert_almost_eq(state.energy.current_energy_joules, state_b.energy.current_energy_joules, 0.01)
	assert_almost_eq(state.inventory.get_amount("H2O"), state_b.inventory.get_amount("H2O"), 0.0001)

func test_advance_keeps_remainder() -> void:
	assert_eq(sim.advance(0.25), 2)
	assert_eq(sim.advance(0.05), 1, "0.05 remainder + 0.05 = one more step")
