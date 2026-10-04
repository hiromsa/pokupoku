class_name VersionTest
extends TestCase
# src/config/Version.gd のバージョン文字列生成を検証する。
# .clinerules のバージョン体系 v<Major>.<Minor>.<Patch>-beta.<CommitCount> に準拠していること。

const VERSION_SCRIPT_PATH: String = "res://src/config/Version.gd"


func test_short_version_format() -> void:
	var version_node: Node = _make_version_instance()
	version_node.app_build_number = 69
	version_node.app_commit_hash = "18a7f84"
	assert_eq(version_node.get_short_version(), "v0.0.1-beta.69", "short_version")
	version_node.free()


func test_detailed_version_appends_commit_hash() -> void:
	var version_node: Node = _make_version_instance()
	version_node.app_build_number = 69
	version_node.app_commit_hash = "18a7f84"
	assert_eq(version_node.get_detailed_version(), "v0.0.1-beta.69 (18a7f84)", "detailed_version")
	version_node.free()


func test_package_version_has_no_leading_v() -> void:
	var version_node: Node = _make_version_instance()
	version_node.app_build_number = 12
	assert_eq(version_node.get_package_version(), "0.0.1-beta.12", "package_version")
	version_node.free()


func _make_version_instance() -> Node:
	var version_script: GDScript = load(VERSION_SCRIPT_PATH)
	assert_true(version_script != null, "version script loadable")
	return version_script.new() as Node
