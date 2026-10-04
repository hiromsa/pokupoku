extends Node2D
# フィールド画面 (Phase 0 の暫定実装)。
# Phase 2 で TileMapModel / MovementController / HudLayout を組み込んで本格実装する。

const TITLE_SCENE_PATH: String = "res://src/scene/TitleScene.tscn"


func _ready() -> void:
	var background := ColorRect.new()
	background.color = UiPalette.GRASS
	background.size = Vector2(640, 360)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var hint_label := Label.new()
	hint_label.text = "フィールド (Phase 2 で実装)\nX キー でタイトルへ"
	hint_label.add_theme_font_override("font", UiFonts.pixel_font())
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", UiPalette.TEXT_PRIMARY)
	hint_label.position = Vector2(0, 150)
	hint_label.size = Vector2(640, 48)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_cancel"):
		SceneRouter.goto(TITLE_SCENE_PATH, "fade")
