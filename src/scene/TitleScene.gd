extends Node2D
# タイトル画面 (Phase 0 の暫定実装)。
#
# タイトルバナー本実装は ui/TitleBanner として Phase 2 で切り出す予定。
# ここでは「フォント / 解像度 / 入力 / シーン遷移」が通っていることの確認のみを目的とする。

const FIELD_SCENE_PATH: String = "res://src/scene/FieldScene.tscn"

var _prompt_label: Label


func _ready() -> void:
	_build_placeholder_background()
	_build_title_labels()
	SceneRouter.fade_in()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_confirm"):
		SceneRouter.goto(FIELD_SCENE_PATH, "fade")


func _process(_delta: float) -> void:
	# プロンプトを明滅させて入力可能状態を示す
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	_prompt_label.modulate.a = 0.35 + 0.65 * pulse


func _build_placeholder_background() -> void:
	var background := ColorRect.new()
	background.color = UiPalette.PANEL_NAVY
	background.size = Vector2(640, 360)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _build_title_labels() -> void:
	var title_label := Label.new()
	title_label.text = "ポクポク"
	title_label.add_theme_font_override("font", UiFonts.pixel_font())
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", UiPalette.TEXT_PRIMARY)
	title_label.position = Vector2(0, 110)
	title_label.size = Vector2(640, 64)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "(・.・)  スーパーファミコン風コマンドバトルRPG"
	subtitle_label.add_theme_font_override("font", UiFonts.pixel_font())
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	subtitle_label.position = Vector2(0, 178)
	subtitle_label.size = Vector2(640, 20)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle_label)

	_prompt_label = Label.new()
	_prompt_label.text = "Z キー で はじめる"
	_prompt_label.add_theme_font_override("font", UiFonts.pixel_font())
	_prompt_label.add_theme_font_size_override("font_size", 14)
	_prompt_label.add_theme_color_override("font_color", UiPalette.TEXT_PRIMARY)
	_prompt_label.position = Vector2(0, 260)
	_prompt_label.size = Vector2(640, 20)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt_label)

	var version_label := Label.new()
	version_label.text = Version.get_short_version()
	version_label.add_theme_font_override("font", UiFonts.pixel_font())
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	version_label.position = Vector2(0, 340)
	version_label.size = Vector2(640, 16)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(version_label)
