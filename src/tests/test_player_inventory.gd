extends TestCase

var inv: PlayerInventory

func before_each() -> void:
	inv = PlayerInventory.new()
	inv.max_capacity = 10.0

func test_add_element_within_capacity() -> void:
	assert_almost_eq(inv.add_element("H", 4.0), 4.0)
	assert_almost_eq(inv.get_amount("H"), 4.0)

func test_add_element_clamped_to_capacity() -> void:
	inv.add_element("H", 8.0)
	assert_almost_eq(inv.add_element("O", 5.0), 2.0, 0.0001, "Only 2 slots remain")
	assert_almost_eq(inv.get_capacity_usage(), 10.0)

func test_compounds_do_not_consume_capacity() -> void:
	inv.add_element("H2O", 50.0)
	assert_almost_eq(inv.get_amount("H2O"), 50.0)
	assert_almost_eq(inv.get_capacity_usage(), 0.0)
	assert_almost_eq(inv.add_element("H", 10.0), 10.0, 0.0001, "Byproducts must never block mining")

func test_consume_element() -> void:
	inv.add_element("C", 3.0)
	assert_true(inv.consume_element("C", 2.0))
	assert_almost_eq(inv.get_amount("C"), 1.0)
	assert_false(inv.consume_element("C", 5.0))
	assert_almost_eq(inv.get_amount("C"), 1.0)

func test_consume_to_zero_removes_entry() -> void:
	inv.add_element("C", 1.0)
	inv.consume_element("C", 1.0)
	assert_false(inv.elements.has("C"))

func test_consume_recipe_inputs_is_atomic() -> void:
	inv.add_element("H", 2.0)  # Water needs 2 H + 1 O; O missing
	var recipe: Dictionary = ElementData.get_recipe("combustion_water")
	assert_false(inv.consume_recipe_inputs(recipe))
	assert_almost_eq(inv.get_amount("H"), 2.0, 0.0001, "Nothing consumed on failure")
	inv.add_element("O", 1.0)
	assert_true(inv.consume_recipe_inputs(recipe))
	assert_almost_eq(inv.get_capacity_usage(), 0.0)
