class_name TestRunner
extends RefCounted
# tests/cases 配下の .gd を自動収集して test_ メソッドを実行するランナー。
# 終了コードが 0 なら全成功 (CI・pre-commit フックからそのまま使える)。

var total_cases: int = 0
var total_assertions: int = 0
var total_failures: int = 0
var report_lines: PackedStringArray = PackedStringArray()


func run_directory(dir_path: String) -> int:
	var suite_paths: Array[String] = _collect_script_paths(dir_path)
	report_lines.append("=== Pokupoku test run (%d suites in %s) ===" % [suite_paths.size(), dir_path])
	for suite_path: String in suite_paths:
		_run_suite(suite_path)
	return 0 if total_failures == 0 else 1


func summary_line() -> String:
	return "cases=%d assertions=%d failures=%d" % [total_cases, total_assertions, total_failures]


func _run_suite(suite_path: String) -> void:
	var suite_script: GDScript = load(suite_path)
	if suite_script == null:
		total_failures += 1
		report_lines.append("LOAD-FAIL %s" % suite_path)
		return

	var suite: RefCounted = suite_script.new()
	if not suite is TestCase:
		total_failures += 1
		report_lines.append("SKIP (not a TestCase) %s" % suite_path)
		return

	var method_names: PackedStringArray = (suite as TestCase).discover_case_methods()
	report_lines.append("-- %s (%d cases)" % [suite_path, method_names.size()])

	for method_name: String in method_names:
		var test_case := suite as TestCase
		test_case.failure_lines.clear()
		test_case.assertion_count = 0
		test_case.call(method_name)

		total_cases += 1
		total_assertions += test_case.assertion_count
		if test_case.failure_lines.is_empty():
			report_lines.append("  PASS  %s" % method_name)
		else:
			total_failures += test_case.failure_lines.size()
			report_lines.append("  FAIL  %s" % method_name)
			for failure_line: String in test_case.failure_lines:
				report_lines.append("        %s" % failure_line)


func _collect_script_paths(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		report_lines.append("WARN  cannot open %s" % dir_path)
		return paths

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".gd"):
			paths.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()

	paths.sort()
	return paths
