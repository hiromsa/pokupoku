extends Node
# セーブデータ (user:// の JSON) の読み書き。
#
# 保存対象は「ドメインがシリアライズした Dictionary」だけ。ノード参照は保存しないため、
# セーブフォーマットとシーン構造が結合しない。

const SAVE_DIR: String = "user://saves"
const SLOT_COUNT: int = 3


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(save_path(slot))


func save_game(slot: int, payload: Dictionary) -> bool:
	var file := FileAccess.open(save_path(slot), FileAccess.WRITE)
	if file == null:
		push_warning("Failed to open save file: %s" % save_path(slot))
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_game(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var raw_text: String = FileAccess.get_file_as_string(save_path(slot))
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Corrupted save file: %s" % save_path(slot))
		return {}
	return parsed as Dictionary


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path(slot)))


func save_summary(slot: int) -> Dictionary:
	var payload: Dictionary = load_game(slot)
	if payload.is_empty():
		return {}
	return {
		"slot": slot,
		"hero_name": payload.get("hero_name", ""),
		"level": payload.get("level", 0),
		"play_seconds": payload.get("play_seconds", 0),
		"saved_at": payload.get("saved_at", ""),
	}
