class_name UiFonts
extends RefCounted
# 日本語ドットフォント (DotGothic16, SIL Open Font License 1.1) の取得口。
# アセット欠損時はフォールバックフォントで動作を継続する。

const PIXEL_FONT_PATH: String = "res://assets/fonts/DotGothic16-Regular.ttf"

static var _cached_font: Font = null


static func pixel_font() -> Font:
	if _cached_font != null:
		return _cached_font
	if ResourceLoader.exists(PIXEL_FONT_PATH):
		_cached_font = load(PIXEL_FONT_PATH)
	else:
		push_warning("Pixel font missing, falling back: %s" % PIXEL_FONT_PATH)
		_cached_font = ThemeDB.fallback_font
	return _cached_font


static func has_pixel_font() -> bool:
	return ResourceLoader.exists(PIXEL_FONT_PATH)
