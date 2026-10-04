class_name TileMapModelTest
extends TestCase
# タイルグリッドの境界・通行判定を検証する。
#
# 移動・当たり判定・描画のすべてがこのモデルの上で動くため、
# 境界の扱いを間違えるとフィールド画面が総崩れになる。

const MAP_WIDTH: int = 4
const MAP_HEIGHT: int = 3


func test_grid_starts_empty_and_out_of_bounds_is_rejected() -> void:
	var map: TileMapModel = TileMapModel.create(MAP_WIDTH, MAP_HEIGHT, TestFixtures.sample_catalog())
	assert_eq(map.width(), MAP_WIDTH, "width kept")
	assert_eq(map.height(), MAP_HEIGHT, "height kept")
	assert_true(map.is_inside(Vector2i(MAP_WIDTH - 1, MAP_HEIGHT - 1)), "last cell inside")
	assert_false(map.is_inside(Vector2i(MAP_WIDTH, 0)), "column past the edge is outside")
	assert_false(map.is_inside(Vector2i(-1, 0)), "negative column is outside")
	assert_eq(map.tile_id_at(Vector2i(0, 0)), TileMapModel.EMPTY_TILE, "cells start empty")
	assert_false(map.is_passable(Vector2i(0, 0)), "empty cell is not walkable")


func test_set_and_read_a_tile() -> void:
	var map: TileMapModel = TileMapModel.create(MAP_WIDTH, MAP_HEIGHT, TestFixtures.sample_catalog())
	assert_true(map.set_tile(Vector2i(1, 1), "grass"), "write inside accepted")
	assert_false(map.set_tile(Vector2i(9, 9), "grass"), "write outside rejected")
	assert_eq(map.tile_id_at(Vector2i(1, 1)), "grass", "value read back")
	assert_true(map.is_passable(Vector2i(1, 1)), "walkable tile reported")

	map.set_tile(Vector2i(2, 0), "tree")
	assert_true(map.is_solid(Vector2i(2, 0)), "solid tile reported")
	assert_false(map.is_passable(Vector2i(2, 0)), "solid tile not walkable")


func test_outside_is_never_walkable() -> void:
	var map: TileMapModel = TileMapModel.create(MAP_WIDTH, MAP_HEIGHT, TestFixtures.sample_catalog())
	map.set_tile(Vector2i(0, 0), "grass")
	assert_false(map.is_passable(Vector2i(-1, 0)), "left of the map blocks")
	assert_false(map.is_passable(Vector2i(MAP_WIDTH, 0)), "right of the map blocks")
	assert_false(map.is_passable(Vector2i(0, MAP_HEIGHT)), "below the map blocks")


func test_unregistered_tile_id_blocks_movement() -> void:
	var map: TileMapModel = TileMapModel.create(MAP_WIDTH, MAP_HEIGHT, TestFixtures.sample_catalog())
	map.set_tile(Vector2i(1, 1), "not_in_catalog")
	assert_false(map.is_passable(Vector2i(1, 1)), "unknown tile id is treated as a wall")


func test_iter_tiles_covers_every_cell_once() -> void:
	var map: TileMapModel = TileMapModel.create(MAP_WIDTH, MAP_HEIGHT, TestFixtures.sample_catalog())
	var tiles: Array[Vector2i] = map.iter_tiles()
	assert_eq(tiles.size(), MAP_WIDTH * MAP_HEIGHT, "every cell visited once")
	assert_eq(tiles[0], Vector2i(0, 0), "row-major order starts at the origin")
	assert_eq(tiles[tiles.size() - 1], Vector2i(MAP_WIDTH - 1, MAP_HEIGHT - 1), "ends at the far corner")
