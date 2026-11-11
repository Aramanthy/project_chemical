extends TestCase

var state: GameState
var sim: SimulationLoop

func before_each() -> void:
	state = GameState.new()
	sim = SimulationLoop.new(state)

func test_player_movement_clamped_to_world_bounds() -> void:
	state.planet.set_player_position(Vector3(999.0, 15.0, -999.0))
	assert_almost_eq(state.planet.player_position.x, PlanetGrid.WORLD_HALF_EXTENT)
	assert_almost_eq(state.planet.player_position.y, 0.0)
	assert_almost_eq(state.planet.player_position.z, -PlanetGrid.WORLD_HALF_EXTENT)

func test_mine_nearest_deposit_uses_richness_and_tech_multiplier() -> void:
	# Move out of range of any deposit -> fails
	state.planet.set_player_position(Vector3(50.0, 0.0, 50.0))
	var miss: Dictionary = state.planet.mine_nearest_deposit(state, 2.0)
	assert_false(miss.get("ok", true))

	# Move next to dep_h_landing at (-6, 0, -5), richness 1.5
	state.planet.set_player_position(Vector3(-6.0, 0.0, -5.0))
	var hit: Dictionary = state.planet.mine_nearest_deposit(state, 2.0)
	assert_true(hit.get("ok", false))
	assert_eq(str(hit["element"]), "H")
	assert_almost_eq(float(hit["added"]), 3.0, 0.001, "2.0 base * 1.5 richness = 3.0")

	# Upgrade mining_laser -> 1.5x multiplier -> 4.5 H
	state.energy.add_energy(100000.0)
	assert_true(state.purchase_upgrade("mining_laser"))
	var hit2: Dictionary = state.planet.mine_nearest_deposit(state, 2.0)
	assert_almost_eq(float(hit2["added"]), 4.5, 0.001)

func test_tier_locked_deposit_requires_tech_unlock() -> void:
	# Move to Uranium Fissure at (18, 0, -16)
	state.planet.set_player_position(Vector3(18.0, 0.0, -16.0))
	var locked: Dictionary = state.planet.mine_nearest_deposit(state, 2.0)
	assert_false(locked.get("ok", true))
	assert_eq(str(locked.get("reason", "")), "tier_locked")

	state.energy.add_energy(5000000.0)
	assert_true(state.purchase_upgrade("unlock_tier_3_nuclear"))
	var unlocked: Dictionary = state.planet.mine_nearest_deposit(state, 2.0)
	assert_true(unlocked.get("ok", false))
	assert_eq(str(unlocked["element"]), "U")

func test_dormant_hub_activation_and_passive_power_generation() -> void:
	# hub_alpha requires 1 MJ + 3 H2O, generates 50 kW
	assert_false(state.planet.activate_hub("hub_alpha", state))
	state.energy.add_energy(1500000.0)
	state.inventory.add_element("H2O", 3.0)

	# Range check when player is far away fails
	state.planet.set_player_position(Vector3.ZERO)
	assert_false(state.planet.activate_hub("hub_alpha", state, true))

	# Move within range of hub_alpha (-12, 0, -12) and activate
	state.planet.set_player_position(Vector3(-12.0, 0.0, -12.0))
	assert_true(state.planet.activate_hub("hub_alpha", state, true))
	assert_true(state.planet.is_hub_activated("hub_alpha"))
	assert_almost_eq(state.energy.current_energy_joules, 500000.0)
	assert_almost_eq(state.inventory.get_amount("H2O"), 0.0)

	# Simulating 2.0s produces 2 * 50,000 = 100,000 J from the hub
	sim.advance(2.0)
	assert_almost_eq(state.energy.current_energy_joules, 600000.0, 0.1)

func test_planetary_core_awakens_planet_and_persists_in_save() -> void:
	state.energy.add_energy(600000000.0)
	state.inventory.add_element("H2O", 10.0)
	state.inventory.add_element("CH4", 5.0)
	state.planet.set_player_position(Vector3(0.0, 0.0, -24.0))
	assert_true(state.planet.activate_hub("planetary_core", state, true))
	assert_true(state.planet.is_planet_awakened)

	var saved: Dictionary = SaveSystem.to_dict(state, 2000)
	var restored := GameState.new()
	assert_true(SaveSystem.from_dict(saved, restored))
	assert_true(restored.planet.is_planet_awakened)
	assert_true(restored.planet.is_hub_activated("planetary_core"))
	assert_almost_eq(restored.planet.player_position.z, -24.0)
