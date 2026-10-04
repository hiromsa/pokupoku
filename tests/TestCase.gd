class_name TestCase
extends RefCounted
# 依存ゼロのテストケース基底クラス。
#
# 規約: test_ で始まるメソッドが TestRunner により自動収集される。
# domain 層は RefCounted のみで構成しているので、Node ツリー無しで検証できる。

var assertion_count: int = 0
var failure_lines: PackedStringArray = PackedStringArray()


func assert_eq(actual: Variant, expected: Variant, label: String = "eq") -> void:
	assertion_count += 1
	if actual != expected:
		_record_failure(label, "expected <%s> but got <%s>" % [str(expected), str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, label: String = "ne") -> void:
	assertion_count += 1
	if actual == unexpected:
		_record_failure(label, "expected anything but <%s>" % str(unexpected))


func assert_true(condition: bool, label: String = "true") -> void:
	assertion_count += 1
	if not condition:
		_record_failure(label, "expected true but got false")


func assert_false(condition: bool, label: String = "false") -> void:
	assertion_count += 1
	if condition:
		_record_failure(label, "expected false but got true")


func assert_between(actual: int, low: int, high: int, label: String = "between") -> void:
	assertion_count += 1
	if actual < low or actual > high:
		_record_failure(label, "expected %d..%d but got %d" % [low, high, actual])


func assert_approx(actual: float, expected: float, tolerance: float, label: String = "approx") -> void:
	assertion_count += 1
	if absf(actual - expected) > tolerance:
		_record_failure(label, "expected %f+/-%f but got %f" % [expected, tolerance, actual])


func fail_test(label: String, detail: String) -> void:
	assertion_count += 1
	_record_failure(label, detail)


# データとして生成された JSON を読み込む。壊れていればその場で失敗として記録する。
func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		fail_test("read_json", "missing file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		fail_test("read_json", "not a json object: %s" % path)
		return {}
	return parsed as Dictionary


func discover_case_methods() -> PackedStringArray:
	var names := PackedStringArray()
	var seen := {}
	for entry: Dictionary in get_method_list():
		var method_name: String = String(entry.get("name", ""))
		if not method_name.begins_with("test_"):
			continue
		if seen.has(method_name):
			continue
		seen[method_name] = true
		names.append(method_name)
	names.sort()
	return names


func _record_failure(label: String, detail: String) -> void:
	failure_lines.append("%s: %s" % [label, detail])
