class_name PanelFrame
extends NinePatchRect
# docs/specification/ui.md §2 のパネル枠 (地: 濃紺 / 枠: 白 2px / 角丸 / 右下影)。
# 画像は tools/asset_gen が生成した 48x48 の 9 スライスを使う。

const PANEL_SHEET_ID: String = "ui.parts"
const PANEL_FRAME_NAME: String = "ui.panel_9slice"

# 枠 2px + 角丸 4px を保ったまま引き伸ばせる余白。
const PATCH_MARGIN: int = 8


static func create_panel(rect: Rect2, panel_name: String) -> PanelFrame:
	var panel := PanelFrame.new()
	panel.name = panel_name
	panel.position = rect.position
	panel.size = rect.size
	return panel


func _ready() -> void:
	texture = SpriteSheetLayout.get_frame_texture(PANEL_SHEET_ID, PANEL_FRAME_NAME)
	patch_margin_left = PATCH_MARGIN
	patch_margin_top = PATCH_MARGIN
	patch_margin_right = PATCH_MARGIN
	patch_margin_bottom = PATCH_MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
