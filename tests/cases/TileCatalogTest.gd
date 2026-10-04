class_name TileCatalogTest
extends TestCase
# タイルカタログ (tile_index.json) の読み出しを検証する。
#
# 当たり判定の唯一の定義元なので、ここが壊れるとフィールド全体が
# 壁を突き抜けたり、 everywhere 通行止めになったりする。

const TILE_INDEX_PATH: String = "res://assets/images/tiles/tile_index.json"
const FIELD_TILE_COUNT: int = 24


func test_reads_frame_index_and_solid_flag() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({
		"grass": {"frame": 0, "solid": false},
		"tree": {"frame": 7, "solid": true},
	})
	assert_eq(catalog.count(), 2, "catalog size")
	assert_true(catalog.is_registered("grass"), "grass registered")
	assert_eq(catalog.frame_index("grass"), 0, "grass frame index")
	assert_eq(catalog.frame_index("tree"), 7, "tree frame index")
	assert_false(catalog.is_solid("grass"), "grass is passable")
	assert_true(catalog.is_solid("tree"), "tree is solid")


func test_unknown_tile_falls_back_to_solid() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({"grass": {"frame": 0, "solid": false}})
	assert_false(catalog.is_registered("nope"), "unknown tile reported")
	assert_eq(catalog.frame_index("nope"), -1, "unknown frame index")
	assert_true(catalog.is_solid("nope"), "unknown tile blocks movement by default")


func test_non_object_entries_are_skipped() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({
		"grass": {"frame": 0, "solid": false},
		"legacy_form": 3,
	})
	assert_eq(catalog.count(), 1, "malformed entry skipped")
	assert_true(catalog.is_solid("legacy_form"), "malformed entry blocks movement")


func test_generated_tile_index_is_loadable() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary(read_json(TILE_INDEX_PATH))
	assert_eq(catalog.count(), FIELD_TILE_COUNT, "every field tile is registered")
	assert_true(catalog.is_registered("town_road"), "town_road present")
	assert_false(catalog.is_solid("grass"), "grass passable in generated data")
	assert_false(catalog.is_solid("town_road"), "town_road passable in generated data")
	for blocker: String in ["tree", "rock", "big_rock", "house_wall", "water", "fence"]:
		assert_true(catalog.is_solid(blocker), "generated blocker: %s" % blocker)


func test_tile_ids_are_reported_sorted() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({
		"tree": {"frame": 1, "solid": true},
		"grass": {"frame": 0, "solid": false},
	})
	var ids: PackedStringArray = catalog.tile_ids()
	assert_eq(ids.size(), 2, "tile id count")
	assert_eq(ids[0], "grass", "ids sorted deterministically")


func test_declared_base_tile_is_resolved() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({
		"grass": {"frame": 0, "solid": false},
		"tree": {"frame": 1, "solid": true, "base": "grass"},
	})
	assert_eq(catalog.base_tile_id("tree"), "grass", "obstacle resolves its ground")
	assert_eq(catalog.base_tile_id("grass"), TileCatalog.NO_BASE, "ground needs no base")


func test_unusable_base_falls_back_to_no_base() -> void:
	var catalog: TileCatalog = TileCatalog.from_dictionary({
		"grass": {"frame": 0, "solid": false},
		"tree": {"frame": 1, "solid": true, "base": "grass"},
		"unregistered_base": {"frame": 2, "solid": true, "base": "not_in_catalog"},
		"self_base": {"frame": 3, "solid": true, "base": "self_base"},
		"wrong_type_base": {"frame": 4, "solid": true, "base": 7},
	})
	assert_eq(catalog.base_tile_id("unregistered_base"), TileCatalog.NO_BASE,
		"base pointing at an unknown tile is ignored")
	assert_eq(catalog.base_tile_id("self_base"), TileCatalog.NO_BASE,
		"a tile cannot be its own ground")
	assert_eq(catalog.base_tile_id("wrong_type_base"), TileCatalog.NO_BASE,
		"a non-string base is ignored")
	assert_eq(catalog.base_tile_id("not_in_catalog"), TileCatalog.NO_BASE,
		"unknown tile has no base")
