class_name TileMapModel
extends RefCounted
# フィールドのタイルグリッド。描画・入力・時間を知らない純データ + 通行判定。
#
# 通行可否は TileCatalog (tile_index.json) からのみ導出する。
# 「このタイルは壁」という個別判断をここに書かないため、
# データ側を変えるだけで全シーンに反映される。

const EMPTY_TILE: String = ""

var _width: int = 0
var _height: int = 0
var _cells: PackedStringArray = PackedStringArray()
var _catalog: TileCatalog = null


static func create(width: int, height: int, catalog: TileCatalog) -> TileMapModel:
	var model := TileMapModel.new()
	model._build_grid(width, height, catalog)
	return model


func _build_grid(width: int, height: int, catalog: TileCatalog) -> void:
	_width = maxi(width, 0)
	_height = maxi(height, 0)
	_catalog = catalog
	_cells.resize(_width * _height)
	_cells.fill(EMPTY_TILE)


func width() -> int:
	return _width


func height() -> int:
	return _height


func is_inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < _width and tile.y < _height


func set_tile(tile: Vector2i, tile_id: String) -> bool:
	if not is_inside(tile):
		return false
	_cells[tile.y * _width + tile.x] = tile_id
	return true


func tile_id_at(tile: Vector2i) -> String:
	if not is_inside(tile):
		return EMPTY_TILE
	return _cells[tile.y * _width + tile.x]


# 範囲外・空タイル・未登録タイルはすべて通行不可 (安全側へ倒す)
func is_passable(tile: Vector2i) -> bool:
	if not is_inside(tile):
		return false
	var tile_id: String = tile_id_at(tile)
	if tile_id == EMPTY_TILE or _catalog == null:
		return false
	return not _catalog.is_solid(tile_id)


func is_solid(tile: Vector2i) -> bool:
	return not is_passable(tile)


# 描画層が下へ敷く地面タイル。障害物タイルの透明部分を埋める。
# 判定 (is_passable) は常に上のタイルだけで決まるため、描画と当たり判定は独立。
func base_tile_id_at(tile: Vector2i) -> String:
	var tile_id: String = tile_id_at(tile)
	if tile_id == EMPTY_TILE or _catalog == null:
		return EMPTY_TILE
	return _catalog.base_tile_id(tile_id)


# 全タイルを (x, y) 昇順でたどる。描画層がまとめて走査できるようにする。
func iter_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y: int in range(_height):
		for x: int in range(_width):
			tiles.append(Vector2i(x, y))
	return tiles
