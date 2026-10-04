class_name UiPaletteTest
extends TestCase
# UiPalette の色値が docs/sample_image から抽出したパレットと一致していることを検証する。
# デザインの一貫性をテストで固定しておくためのケース。


func test_panel_navy_matches_sample_extraction() -> void:
	assert_eq(UiPalette.PANEL_NAVY.to_html(false), "0d124a", "PANEL_NAVY")
	assert_eq(UiPalette.PANEL_NAVY_DEEP.to_html(false), "0b1048", "PANEL_NAVY_DEEP")


func test_field_colors_match_sample_extraction() -> void:
	assert_eq(UiPalette.SKY.to_html(false), "89cdce", "SKY")
	assert_eq(UiPalette.GRASS.to_html(false), "75a947", "GRASS")
	assert_eq(UiPalette.DIRT.to_html(false), "956c40", "DIRT")
	assert_eq(UiPalette.WATER.to_html(false), "2b7ac5", "WATER")


func test_text_colors_defined() -> void:
	assert_eq(UiPalette.PANEL_BORDER.to_html(false), "ffffff", "PANEL_BORDER")
	assert_eq(UiPalette.TEXT_NAME.to_html(false), "f2c64c", "TEXT_NAME")
