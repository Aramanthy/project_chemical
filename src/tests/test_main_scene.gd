extends TestCase

## Integration test: instantiates the real main scene and drives it through
## its UI handlers, verifying node paths and wiring are correct.

var scene: Node

func before_each() -> void:
	scene = load("res://src/scenes/main.tscn").instantiate()
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(scene)  # Triggers _ready and @onready lookups

func _cleanup() -> void:
	scene.get_parent().remove_child(scene)
	scene.free()

func test_all_onready_nodes_resolve() -> void:
	for prop in ["energy_label", "power_label", "inventory_label", "progress_bar",
			"status_label", "log_box", "auto_repeat_check", "build_buttons",
			"machine_list", "upgrade_buttons", "hub_buttons", "planet_status_label", "world_3d"]:
		assert_true(scene.get(prop) != null, "Node for '%s' not found" % prop)
	_cleanup()

func test_build_buttons_created_for_every_machine() -> void:
	assert_eq(scene.build_buttons.get_child_count(), MachineCatalog.DEFS.size())
	assert_eq(scene.upgrade_buttons.get_child_count(), TechTree.UPGRADES.size())
	assert_eq(scene.hub_buttons.get_child_count(), PlanetGrid.HUB_DEFS.size())
	_cleanup()

func test_manual_play_to_first_automation() -> void:
	# Mine and react manually until enough energy to build an extractor.
	for i in 3:
		scene._on_mine_hydrogen_pressed()
		scene._on_mine_oxygen_pressed()
		scene._on_start_water_reaction_pressed()
		scene._process(1.1)
	assert_true(scene.energy_system.current_energy_joules >= 286000.0 * 3.0 - 1.0)
	assert_true(scene.energy_label.text.contains("kJ") or scene.energy_label.text.contains("MJ"),
		"Energy label must update, got '%s'" % scene.energy_label.text)

	scene._on_build_pressed("extractor_h")
	assert_eq(scene.game_state.machines.size(), 1)
	var h_before: float = scene.inventory.get_amount("H")
	scene._process(1.0)
	assert_true(scene.inventory.get_amount("H") > h_before, "Deployed extractor must produce")
	_cleanup()
