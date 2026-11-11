extends TestCase

var energy: EnergySystem

func before_each() -> void:
	energy = EnergySystem.new()

func test_add_energy_accumulates() -> void:
	energy.add_energy(500.0)
	energy.add_energy(250.0)
	assert_almost_eq(energy.current_energy_joules, 750.0)
	assert_almost_eq(energy.total_lifetime_energy, 750.0)

func test_add_non_positive_energy_is_ignored() -> void:
	energy.add_energy(0.0)
	energy.add_energy(-100.0)
	assert_almost_eq(energy.current_energy_joules, 0.0)

func test_consume_energy_succeeds_when_sufficient() -> void:
	energy.add_energy(1000.0)
	assert_true(energy.consume_energy(400.0))
	assert_almost_eq(energy.current_energy_joules, 600.0)
	assert_almost_eq(energy.total_lifetime_energy, 1000.0, 0.0001, "Lifetime total must not decrease")

func test_consume_energy_fails_when_insufficient() -> void:
	energy.add_energy(100.0)
	assert_false(energy.consume_energy(400.0))
	assert_almost_eq(energy.current_energy_joules, 100.0)

func test_power_rate_measured_per_second() -> void:
	energy.add_energy(3000.0)
	energy.update_tick(0.5)
	assert_almost_eq(energy.current_power_watts, 0.0, 0.0001, "No update before 1s")
	energy.update_tick(0.5)
	assert_almost_eq(energy.current_power_watts, 3000.0)

func test_format_joules_units() -> void:
	assert_eq(EnergySystem.format_joules(500.0), "500.0 J")
	assert_eq(EnergySystem.format_joules(286000.0), "286.00 kJ")
	assert_eq(EnergySystem.format_joules(500000000.0), "500.00 MJ")
	assert_eq(EnergySystem.format_joules(10000000000.0), "10.00 GJ")

func test_format_watts_units() -> void:
	assert_eq(EnergySystem.format_watts(999.0), "999.0 W")
	assert_eq(EnergySystem.format_watts(2500000.0), "2.50 MW")
