class_name PrototypeMapTest
extends TestCase
# モックマップ (assets/data/maps/prototype_village.json) のプレイ可能性を検証する。
#
# 地形はデータなので、Godot を動かさなくても
# 「歩けるはずの場所が塞がっている」事故をここで検出できる。

const MAP_PATH: String = "res://assets/data/maps/prototype_village.json"
const TILE_INDEX_PATH: String = "res://assets/images/tiles/tile_index.json"

const MAP_WIDTH: int = 30
const MAP_HEIGHT: int = 20
const SPAWN: Vector2i = Vector2i(5, 11)

# 森・村の通り・池のほとり。出現地点から歩いて到達できるべき目印。
const LANDMARKS: Array[Vector2i] = [
	Vector2i(5, 5),
	Vector2i(20, 11),
	Vector2i(23, 16),
]


func test_map_definition_is_readable() -> void:
	var definition: MapDefinition = MapDefinition.from_dictionary(read_json(MAP_PATH))
	assert_eq(definition.map_id, "prototype_village", "map id")
	assert_eq(definition.width(), MAP_WIDTH, "map width")
	assert_eq(definition.height(), MAP_HEIGHT, "map height")
	assert_eq(definition.spawn_tile, SPAWN, "spawn point")
	assert_false(definition.glyph_table.is_empty(), "glyph table present")


func test_map_builds_a_walkable_grid() -> void:
	var map: TileMapModel = _build_map()
	assert_eq(map.width(), MAP_WIDTH, "grid width matches the layout")
	assert_eq(map.height(), MAP_HEIGHT, "grid height matches the layout")
	assert_true(map.is_passable(SPAWN), "spawn point is walkable")
	assert_true(map.is_passable(Vector2i(12, 11)), "village road is walkable")
	assert_true(map.is_solid(Vector2i(0, 0)), "map corner is sealed")


func test_border_seals_the_player_in() -> void:
	var map: TileMapModel = _build_map()
	for x: int in range(MAP_WIDTH):
		assert_true(map.is_solid(Vector2i(x, 0)), "top edge sealed at column %d" % x)
		assert_true(map.is_solid(Vector2i(x, MAP_HEIGHT - 1)), "bottom edge sealed at column %d" % x)
	for y: int in range(MAP_HEIGHT):
		assert_true(map.is_solid(Vector2i(0, y)), "left edge sealed at row %d" % y)
		assert_true(map.is_solid(Vector2i(MAP_WIDTH - 1, y)), "right edge sealed at row %d" % y)


func test_every_landmark_is_reachable_on_foot() -> void:
	var definition: MapDefinition = MapDefinition.from_dictionary(read_json(MAP_PATH))
	var map: TileMapModel = definition.build_tile_map(_catalog())
	var reachable: Dictionary = _reachable_from(map, definition.spawn_tile)
	for landmark: Vector2i in LANDMARKS:
		assert_true(map.is_passable(landmark), "landmark is walkable: %s" % str(landmark))
		assert_true(reachable.has(landmark), "landmark reachable from spawn: %s" % str(landmark))


func test_water_and_houses_actually_block() -> void:
	var map: TileMapModel = _build_map()
	assert_true(map.is_solid(Vector2i(18, 16)), "pond water blocks walking")
	assert_true(map.is_solid(Vector2i(17, 13)), "a house wall blocks walking")
	assert_true(map.is_solid(Vector2i(15, 12)), "a house roof blocks walking")
	assert_true(map.is_solid(Vector2i(15, 13)), "a door is not walkable ground yet")


# 樹木や柵は画像が透明背景のため、下地の指定漏れは画面に穴として現れる。
func test_every_obstacle_sits_on_declared_ground() -> void:
	var map: TileMapModel = _build_map()
	var catalog: TileCatalog = _catalog()
	var obstacles_checked: int = 0
	for tile: Vector2i in map.iter_tiles():
		var tile_id: String = map.tile_id_at(tile)
		if tile_id == TileMapModel.EMPTY_TILE:
			continue
		var base_id: String = map.base_tile_id_at(tile)
		if base_id == TileMapModel.EMPTY_TILE:
			continue
		obstacles_checked += 1
		assert_true(catalog.is_registered(base_id), "base tile registered at %s" % str(tile))
		assert_false(catalog.is_solid(base_id), "base tile is walkable ground at %s" % str(tile))
	assert_true(obstacles_checked > 0, "the prototype map actually uses tiles with a base")


func _build_map() -> TileMapModel:
	var definition: MapDefinition = MapDefinition.from_dictionary(read_json(MAP_PATH))
	return definition.build_tile_map(_catalog())


func _catalog() -> TileCatalog:
	return TileCatalog.from_dictionary(read_json(TILE_INDEX_PATH))


# 出現地点から 4 方向移動で到達できるタイルの集合。
func _reachable_from(map: TileMapModel, from: Vector2i) -> Dictionary:
	var visited := {}
	var queue: Array[Vector2i] = []
	if not map.is_passable(from):
		return visited
	visited[from] = true
	queue.append(from)
	var head: int = 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = current + offset
			if visited.has(next) or not map.is_passable(next):
				continue
			visited[next] = true
			queue.append(next)
	return visited
