extends SceneTree

## Headless test runner.
## Usage: godot --headless --path <project> -s res://src/tests/run_tests.gd
## Discovers every res://src/tests/test_*.gd file, runs all test_* methods,
## and exits with code 0 on success or 1 on any failure.

const TEST_DIR: String = "res://src/tests"

func _initialize() -> void:
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
			# Untyped on purpose: the -s entry script is compiled before global
			# class_name types (like TestCase) are registered.
			var instance: RefCounted = script.new()
			instance.call("before_each")
			instance.call(method_name)
			var failures: Array = instance.call("take_failures")
			if failures.is_empty():
				print("  PASS  " + method_name)
			else:
				failed += 1
				print("  FAIL  " + method_name)
				for f in failures:
					print("        - " + f)

	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 or total == 0 else 0)

func _discover_test_files() -> Array[String]:
	var files: Array[String] = []
	for file_name in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_case.gd":
			files.append(file_name)
	files.sort()
	return files
