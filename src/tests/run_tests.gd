extends SceneTree

## Headless test runner.
## Usage: godot --headless --path <project> -s res://src/tests/run_tests.gd
## Discovers every res://src/tests/test_*.gd file, runs all test_* methods,
## and exits with code 0 on success or 1 on any failure.
##
## A test fails if it records an assertion failure OR raises any engine/script
## error while running (GDScript has no exceptions, so errors are captured via
## a custom Logger and attributed to the test that was executing).

const TEST_DIR: String = "res://src/tests"

class ErrorCounter extends Logger:
	var count: int = 0
	var last_message: String = ""
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		count += 1
		last_message = "%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function]
		_mutex.unlock()

var _error_counter := ErrorCounter.new()
var _started: bool = false

func _initialize() -> void:
	OS.add_logger(_error_counter)

## Tests run on the first frame so the tree is live and added nodes receive _ready().
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_run_all()
	return false

func _run_all() -> void:
	var total: int = 0
	var failed: int = 0

	for file_name in _discover_test_files():
		var script: GDScript = load(TEST_DIR + "/" + file_name)
		print("\n== %s ==" % file_name)
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("  FAIL  could not load script (parse error?)")
			continue
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var errors_before: int = _error_counter.count
			# Untyped on purpose: the -s entry script is compiled before global
			# class_name types (like TestCase) are registered.
			var instance: RefCounted = script.new()
			instance.call("before_each")
			instance.call(method_name)
			var failures: Array = instance.call("take_failures")
			var new_errors: int = _error_counter.count - errors_before
			if new_errors > 0:
				failures.append("%d runtime error(s); last: %s" % [new_errors, _error_counter.last_message])
			if failures.is_empty():
				print("  PASS  " + method_name)
			else:
				failed += 1
				print("  FAIL  " + method_name)
				for f in failures:
					print("        - " + f)

	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	OS.remove_logger(_error_counter)
	quit(1 if failed > 0 or total == 0 else 0)

func _discover_test_files() -> Array[String]:
	var files: Array[String] = []
	for file_name in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			files.append(file_name)
	files.sort()
	return files
