class_name HudLayout
extends Control
# フィールドの HUD。画面下部にステータス窓・メッセージ窓・コマンドを並べる。
#
# 位置とサイズは docs/specification/ui.md §1 の実測値。
# 表示専用で状態を持たないため、値は set_* 経由で上から注入する。

const STATUS_RECT := Rect2(6, 240, 180, 114)
const MESSAGE_RECT := Rect2(192, 240, 316, 82)
const COMMAND_TAB_RECT := Rect2(198, 326, 90, 28)
const COMMAND_MENU_RECT := Rect2(514, 240, 120, 114)

const HEADING_FONT_SIZE: int = 12
const BODY_FONT_SIZE: int = 12
const VALUE_FONT_SIZE: int = 11
const HEADING_CHARACTER_SPACING: int = 1

# ui.md §5: 1 行 1 項目・行ピッチ 18px
const COMMAND_LINE_PITCH: int = 18

var _status_values: Label = null
var _message_body: Label = null
var _command_list: Label = null


func build() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_window(STATUS_RECT, "StatusWindow", "ステータス")
	_build_window(MESSAGE_RECT, "MessageWindow", "")
	_build_window(COMMAND_TAB_RECT, "CommandTab", "コ マ ン ド")
	_build_window(COMMAND_MENU_RECT, "CommandMenu", "")

	_status_values = _add_label(
		STATUS_RECT.position + Vector2(10, 26), STATUS_RECT.size - Vector2(20, 30),
		"", VALUE_FONT_SIZE, UiPalette.TEXT_PRIMARY)
	_message_body = _add_label(
		MESSAGE_RECT.position + Vector2(10, 8), MESSAGE_RECT.size - Vector2(20, 16),
		"", BODY_FONT_SIZE, UiPalette.TEXT_PRIMARY)
	_command_list = _add_label(
		COMMAND_MENU_RECT.position + Vector2(8, 8), COMMAND_MENU_RECT.size - Vector2(16, 16),
		"", BODY_FONT_SIZE, UiPalette.TEXT_PRIMARY)
	_command_list.add_theme_constant_override(
		"line_spacing", COMMAND_LINE_PITCH - BODY_FONT_SIZE)


func set_status(hero_name: String, hit_points: int, max_hit_points: int,
		magic_points: int, max_magic_points: int) -> void:
	_status_values.text = "名前：%s\nHP：%d/%d\nMP：%d/%d" % [
		hero_name, hit_points, max_hit_points, magic_points, max_magic_points,
	]


func set_message(message: String) -> void:
	_message_body.text = message


# ui.md §5: 選択中のみ【】で囲む。
func set_commands(items: PackedStringArray, selected_index: int) -> void:
	var lines := PackedStringArray()
	for index: int in range(items.size()):
		if index == selected_index:
			lines.append("【%s】" % items[index])
		else:
			lines.append(items[index])
	_command_list.text = "\n".join(lines)


func _build_window(rect: Rect2, window_name: String, heading: String) -> void:
	add_child(PanelFrame.create_panel(rect, window_name))
	if heading.is_empty():
		return
	var heading_label := _add_label(
		Vector2(rect.position.x, rect.position.y + 5), Vector2(rect.size.x, 16),
		heading, HEADING_FONT_SIZE, UiPalette.TEXT_PRIMARY)
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.add_theme_constant_override("character_spacing", HEADING_CHARACTER_SPACING)


func _add_label(origin: Vector2, label_size: Vector2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = origin
	label.size = label_size
	label.text = text
	label.add_theme_font_override("font", UiFonts.pixel_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
