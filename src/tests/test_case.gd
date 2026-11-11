class_name TestCase
extends RefCounted

## Minimal base class for headless unit tests.
## Any method whose name starts with "test_" is executed by run_tests.gd.

var _failures: Array[String] = []

func before_each() -> void:
	pass

func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_failures.append("Expected true. " + message)

func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_failures.append("Expected false. " + message)

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_failures.append("Expected <%s> but got <%s>. %s" % [str(expected), str(actual), message])

func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		_failures.append("Expected ~<%s> but got <%s>. %s" % [str(expected), str(actual), message])

func take_failures() -> Array[String]:
	var result: Array[String] = _failures.duplicate()
	_failures.clear()
	return result
