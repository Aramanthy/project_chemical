extends TestCase

var state: GameState
var world: PlanetWorld3D

func before_each() -> void:
	state = GameState.new()
	world = load("res://src/scenes/world_3d.tscn").instantiate() as PlanetWorld3D
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(world)
	world.bind_state(state)

func _cleanup() -> void:
	if world and world.get_parent():
		world.get_parent().remove_child(world)
		world.free()

func test_spawns_player_camera_deposits_and_hubs() -> void:
	assert_true(world.player_root != null)
	assert_true(world.camera_3d != null)
	assert_eq(world.deposits_root.get_child_count(), PlanetGrid.DEPOSIT_DEFS.size())
	assert_eq(world.hubs_root.get_child_count(), PlanetGrid.HUB_DEFS.size())
	_cleanup()

func test_third_person_movement_and_camera_rotation() -> void:
	world.rotate_camera_yaw(0.5)
	assert_almost_eq(world.camera_pivot.rotation.y, 0.5)
	world.move_in_view_direction(Vector2(0.0, -1.0), 1.0)
	assert_true(state.planet.player_position.length() > 5.0, "Player moved on XZ plane")
	assert_almost_eq(world.player_root.position.x, state.planet.player_position.x)
	assert_almost_eq(world.player_root.position.z, state.planet.player_position.z)
	_cleanup()

func test_3d_interact_mines_deposit_and_ignites_hub() -> void:
	# 1. Move to Hydrogen deposit at (-6, 0, -5) and interact
	state.planet.set_player_position(Vector3(-6.0, 0.0, -5.0))
	var mine_res: Dictionary = world.interact_at_player()
	assert_true(mine_res.get("ok", false))
	assert_eq(str(mine_res.get("type", "")), "mine")
	assert_almost_eq(state.inventory.get_amount("H"), 3.0)

	# 2. Move to hub_alpha at (-12, 0, -12), supply requirements, and interact
	state.energy.add_energy(1500000.0)
	state.inventory.add_element("H2O", 3.0)
	state.planet.set_player_position(Vector3(-12.0, 0.0, -12.0))
	var hub_res: Dictionary = world.interact_at_player()
	assert_true(hub_res.get("ok", false))
	assert_eq(str(hub_res.get("type", "")), "hub_activated")
	assert_true(state.planet.is_hub_activated("hub_alpha"))
	_cleanup()

func test_deployed_machines_spawn_and_remove_3d_nodes() -> void:
	state.energy.add_energy(500000.0)
	var m: Machine = state.build_machine("extractor_h")
	assert_true(m != null)
	assert_eq(world.machines_root.get_child_count(), 1)
	assert_true(m.world_position.length() > 0.1, "Machine placed near player in 3D space")

	assert_true(state.remove_machine(m.id))
	assert_eq(world._machine_nodes.size(), 0)
	_cleanup()
