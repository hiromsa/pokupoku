extends SceneTree
# AssetRegistry / SpriteSheetLayout の実行時挙動を確認する一時デバッグスクリプト。
# 実行:
#   tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . \
#     --script res://tests/diag_assets.gd


func _initialize() -> void:
	var registry: Node = root.get_node_or_null("AssetRegistry")
	print("autoload present: ", registry != null)
	if registry == null:
		quit(1)
		return

	print("manifest exists: ", FileAccess.file_exists("res://assets/images/manifest.json"))
	var raw: String = FileAccess.get_file_as_string("res://assets/images/manifest.json")
	print("manifest bytes: ", raw.length())
	print("manifest head: ", raw.substr(0, 120))
	var parsed: Variant = JSON.parse_string(raw)
	print("parsed type: ", typeof(parsed))
	if typeof(parsed) == TYPE_DICTIONARY:
		print("parsed keys: ", (parsed as Dictionary).size())

	print("registered ids: ", registry.registered_ids().size())
	print("has hero.field: ", registry.has_asset("hero.field"))
	print("path hero.field: ", registry.get_asset_path("hero.field"))
	print("loader exists: ", ResourceLoader.exists(registry.get_asset_path("hero.field")))
	var texture: Texture2D = registry.get_texture("hero.field")
	print("texture: ", texture, " size: ", texture.get_size() if texture != null else Vector2.ZERO)
	quit(0)
