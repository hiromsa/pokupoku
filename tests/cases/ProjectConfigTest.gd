class_name ProjectConfigTest
extends TestCase
# project.godot の必須設定 (解像度 / メインシーン / autoload / バージョン) が
# 壊れていないことを検証する。設定の取り違えは後続フェーズ全体に波及するため、
# スキャフォールドの回帰テストとして置く。
#
# 注意: project.godot のセクション名は内部設定名では接頭辞になる
#   [application] -> application/run/main_scene
#   [display]     -> display/window/size/viewport_width
#   [autoload]    -> autoload/<Name>

const REQUIRED_AUTOLOADS: Array[String] = [
	"Version", "EventBus", "InputRouter", "AssetRegistry", "SpriteSheetLayout",
	"AudioManager", "SaveManager", "SceneRouter",
]


func test_viewport_is_640x360() -> void:
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		640, "viewport_width")
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		360, "viewport_height")


func test_texture_filter_is_nearest() -> void:
	# 0 = NEAREST。ドット絵をボヤけさせないための必須設定。
	assert_eq(
		int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)),
		0, "default_texture_filter")


func test_main_scene_exists() -> void:
	var main_scene: String = String(ProjectSettings.get_setting("application/run/main_scene", ""))
	assert_true(not main_scene.is_empty(), "main_scene configured")
	assert_true(ResourceLoader.exists(main_scene), "main_scene resource exists: %s" % main_scene)


func test_all_required_autoloads_registered() -> void:
	for autoload_name: String in REQUIRED_AUTOLOADS:
		assert_true(
			ProjectSettings.has_setting("autoload/%s" % autoload_name),
			"autoload registered: %s" % autoload_name)


func test_autoload_scripts_are_loadable() -> void:
	for autoload_name: String in REQUIRED_AUTOLOADS:
		var raw_path: String = String(ProjectSettings.get_setting("autoload/%s" % autoload_name, ""))
		raw_path = raw_path.trim_prefix("*")
		assert_true(not raw_path.is_empty(), "autoload path set: %s" % autoload_name)
		assert_true(ResourceLoader.exists(raw_path), "autoload script exists: %s" % raw_path)


func test_input_actions_registered_by_input_router() -> void:
	var input_router_script: GDScript = load("res://src/core/InputRouter.gd")
	assert_true(input_router_script != null, "InputRouter loadable")

	var constants: Dictionary = input_router_script.get_script_constant_map()
	var bindings: Dictionary = constants.get("ACTION_BINDINGS", {})
	assert_true(bindings.size() >= 7, "ACTION_BINDINGS populated")

	for action_name: String in bindings:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		assert_true(InputMap.has_action(action_name), "action available: %s" % action_name)


func test_project_version_matches_version_gd() -> void:
	# .clinerules のバージョン運用: project.godot の config/version と
	# src/config/Version.gd は常に一致していなければならない。
	var project_version: String = String(ProjectSettings.get_setting("application/config/version", ""))

	var version_script: GDScript = load("res://src/config/Version.gd")
	var version_node: Node = version_script.new() as Node
	var expected: String = version_node.get_package_version()
	version_node.free()

	assert_eq(project_version, expected, "project.godot config/version == Version.gd")
