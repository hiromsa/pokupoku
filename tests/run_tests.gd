extends SceneTree
# ユニットテストのエントリポイント。
#
# 実行:
#   tools/godot/Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/run_tests.gd

const CASES_DIR: String = "res://tests/cases"
const TEST_RUNNER_PATH: String = "res://tests/TestRunner.gd"


func _initialize() -> void:
	var runner_script: GDScript = load(TEST_RUNNER_PATH)
	if runner_script == null:
		push_error("Cannot load %s" % TEST_RUNNER_PATH)
		quit(1)
		return

	var runner: RefCounted = runner_script.new()
	var exit_code: int = runner.run_directory(CASES_DIR)

	for line: String in runner.report_lines:
		print(line)
	print("")
	print(runner.summary_line())
	print("RESULT: %s" % ("OK" if exit_code == 0 else "FAILED"))
	quit(exit_code)
