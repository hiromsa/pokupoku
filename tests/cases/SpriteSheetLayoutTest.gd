class_name SpriteSheetLayoutTest
extends TestCase
# SpriteSheetLayout のフレーム解決ロジックを検証する。
#
# シーン側は「アセットID + フレーム名」だけで画像を参照するため、
# この解決が壊れるとフィールド / 戦闘の描画がすべて止まる。
# 列順やセルサイズを変えたときに region 計算が追随しているかをここで押さえる。

const LAYOUT_SCRIPT_PATH: String = "res://src/core/SpriteSheetLayout.gd"

const HERO_FIELD: String = "hero.field"
const HERO_FIELD_CELL: Vector2i = Vector2i(24, 32)
const HERO_FIELD_COLS: int = 3
const HERO_FIELD_FRAME_COUNT: int = 12

const POKU_SHEET: String = "enemy.poku"
const POKU_CELL: Vector2i = Vector2i(32, 32)
const POKU_PATTERNS: Array[String] = ["idle_a", "idle_b", "attack", "damage"]


func test_hero_field_sheet_registers_twelve_frames() -> void:
	var layout: Node = _create_layout()
	assert_true(layout.has_sheet(HERO_FIELD), "hero.field sheet known")
	assert_eq(layout.frame_count(HERO_FIELD), HERO_FIELD_FRAME_COUNT, "hero.field frame count")
	assert_eq(layout.frame_names(HERO_FIELD).size(), HERO_FIELD_FRAME_COUNT, "hero.field names size")
	_free_layout(layout)


func test_frame_index_matches_row_major_order() -> void:
	var layout: Node = _create_layout()
	# 行 = 向き (down/up/left/right)、列 = 歩行位相 (stand/step_l/step_r)
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.down.stand"), 0, "down.stand")
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.down.step_l"), 1, "down.step_l")
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.down.step_r"), 2, "down.step_r")
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.up.stand"), 3, "up.stand")
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.right.step_r"), 11, "right.step_r")
	assert_eq(layout.frame_index(HERO_FIELD, "hero.field.nope.nope"), -1, "unknown frame -> -1")
	_free_layout(layout)


func test_atlas_region_is_derived_from_grid_geometry() -> void:
	var layout: Node = _create_layout()

	var first: AtlasTexture = layout.get_frame_texture(HERO_FIELD, "hero.field.down.stand")
	assert_true(first != null, "down.stand atlas built")
	if first != null:
		assert_eq(first.region, Rect2(Vector2(0, 0), Vector2(HERO_FIELD_CELL)), "down.stand region")

	var same_row: AtlasTexture = layout.get_frame_texture(HERO_FIELD, "hero.field.down.step_l")
	if same_row != null:
		assert_eq(same_row.region, Rect2(Vector2(HERO_FIELD_CELL.x, 0), Vector2(HERO_FIELD_CELL)),
			"down.step_l region")

	# 最終フレーム: 列 = 11 % 3, 行 = 11 / 3
	var last: AtlasTexture = layout.get_frame_texture(HERO_FIELD, "hero.field.right.step_r")
	if last != null:
		var expected := Rect2(
			Vector2((11 % HERO_FIELD_COLS) * HERO_FIELD_CELL.x, (11 / HERO_FIELD_COLS) * HERO_FIELD_CELL.y),
			Vector2(HERO_FIELD_CELL),
		)
		assert_eq(last.region, expected, "right.step_r region")
	_free_layout(layout)


func test_enemy_sheet_exposes_four_animation_patterns() -> void:
	var layout: Node = _create_layout()
	for pattern: String in POKU_PATTERNS:
		var frame_name: String = "%s.%s" % [POKU_SHEET, pattern]
		var atlas: AtlasTexture = layout.get_frame_texture(POKU_SHEET, frame_name)
		assert_true(atlas != null, "atlas built: %s" % frame_name)
		if atlas == null:
			continue
		assert_eq(atlas.region.size, Vector2(POKU_CELL), "cell size: %s" % pattern)
		assert_eq(atlas.region.position.x, POKU_PATTERNS.find(pattern) * POKU_CELL.x,
			"column offset: %s" % pattern)
		assert_true(atlas.atlas != null, "backing texture set: %s" % pattern)
	_free_layout(layout)


func test_unknown_asset_or_frame_returns_null_without_crash() -> void:
	var layout: Node = _create_layout()
	assert_false(layout.has_sheet("nope.not.a.sheet"), "unknown sheet reported")
	assert_true(layout.get_frame_texture("nope.not.a.sheet", "x") == null, "unknown sheet -> null")
	assert_true(layout.get_frame_texture(HERO_FIELD, "hero.field.bogus") == null, "unknown frame -> null")
	_free_layout(layout)


func test_atlas_instances_are_cached_per_frame() -> void:
	var layout: Node = _create_layout()
	var first: AtlasTexture = layout.get_frame_texture(HERO_FIELD, "hero.field.down.stand")
	var second: AtlasTexture = layout.get_frame_texture(HERO_FIELD, "hero.field.down.stand")
	assert_true(first != null and first == second, "same atlas reused for same frame")
	_free_layout(layout)


func _create_layout() -> Node:
	# autoload のノードを複製せず、スクリプトから直接インスタンス化して検証する。
	# _ready はツリー追加時に走るため、同じ処理である reload_layouts() を明示的に呼ぶ。
	var script: GDScript = load(LAYOUT_SCRIPT_PATH)
	var layout: Node = script.new() as Node
	layout.reload_layouts()
	return layout


func _free_layout(layout: Node) -> void:
	if layout != null:
		layout.free()
