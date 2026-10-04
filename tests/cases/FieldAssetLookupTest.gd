class_name FieldAssetLookupTest
extends TestCase
# フィールド画面が実際に引くフレーム名が、すべて解決できることを確認する。
#
# フレーム名は実行時に決まるため、名前の打ち間違いは画面に出ないまま終わる。
# 名前を組み立てる唯一の場所として、ここで先に壊れを取る。

const TILE_INDEX_PATH: String = "res://assets/images/tiles/tile_index.json"

const HERO_CELL: Vector2i = Vector2i(24, 32)
const TILE_CELL: Vector2i = Vector2i(32, 32)
const FIELD_TILE_COUNT: int = 24


static func hero_directions() -> PackedStringArray:
	return PackedStringArray([
		MovementController.DIRECTION_DOWN,
		MovementController.DIRECTION_UP,
		MovementController.DIRECTION_LEFT,
		MovementController.DIRECTION_RIGHT,
	])


func test_every_hero_field_frame_resolves() -> void:
	var layout: Node = TestFixtures.create_sprite_sheet_layout()
	# 主人公スプライトが実際に組み立てる名前だけを、実装から直接拾って検証する。
	# 歩行と待機 (足踏み) で使う位相を両方見る。
	for direction: String in hero_directions():
		for phase: String in _hero_phases():
			var frame_name: String = "%s.%s.%s" % [FieldHeroSprite.HERO_SHEET_ID, direction, phase]
			var atlas: AtlasTexture = layout.get_frame_texture(FieldHeroSprite.HERO_SHEET_ID, frame_name)
			assert_true(atlas != null, "hero frame resolves: %s" % frame_name)
			if atlas == null:
				continue
			assert_eq(atlas.region.size, Vector2(HERO_CELL), "hero cell size: %s" % frame_name)
			assert_true(atlas.atlas != null, "hero sheet bound: %s" % frame_name)
	TestFixtures.free_node(layout)


func _hero_phases() -> PackedStringArray:
	var phases: PackedStringArray = HeroFieldAnimation.walk_phases()
	for phase: String in HeroFieldAnimation.idle_phases():
		if not phases.has(phase):
			phases.append(phase)
	return phases


func test_every_map_tile_frame_resolves() -> void:
	var layout: Node = TestFixtures.create_sprite_sheet_layout()
	var catalog: TileCatalog = TileCatalog.from_dictionary(read_json(TILE_INDEX_PATH))
	assert_eq(catalog.count(), FIELD_TILE_COUNT, "tile catalog loaded for lookup")
	for tile_id: String in catalog.tile_ids():
		_assert_tile_frame(layout, "tile.%s" % tile_id)
		# 下地として敷く地面も、同じシートから引けることが必要。
		var base_id: String = catalog.base_tile_id(tile_id)
		if not base_id.is_empty():
			_assert_tile_frame(layout, "tile.%s" % base_id)
	TestFixtures.free_node(layout)


func _assert_tile_frame(layout: Node, frame_name: String) -> void:
	var atlas: AtlasTexture = layout.get_frame_texture(FieldTileLayer.TILE_SHEET_ID, frame_name)
	assert_true(atlas != null, "tile frame resolves: %s" % frame_name)
	if atlas == null:
		return
	assert_eq(atlas.region.size, Vector2(TILE_CELL), "tile cell size: %s" % frame_name)
	assert_true(atlas.atlas != null, "tile sheet bound: %s" % frame_name)


func test_hud_frames_resolve() -> void:
	var layout: Node = TestFixtures.create_sprite_sheet_layout()
	var panel: AtlasTexture = layout.get_frame_texture(
		PanelFrame.PANEL_SHEET_ID, PanelFrame.PANEL_FRAME_NAME)
	assert_true(panel != null, "panel nine-slice frame resolves")
	if panel != null:
		assert_true(panel.region.size.x > PanelFrame.PATCH_MARGIN * 2,
			"nine-slice margins fit inside the source frame")
	TestFixtures.free_node(layout)
