class_name FieldTileLayer
extends Node2D
# フィールドのタイルを描画する。TileMapModel を読むだけで、状態を変えない。
#
# 画像パスは扱わない。タイル ID を SpriteSheetLayout のフレーム名
# ("tile.<id>") に変換して AtlasTexture を受け取る。
# 各マスは「下地の地面 -> 障害物」の順に重ねる (順序は TileMapModel が決める)。

const TILE_SIZE: int = 32
const TILE_SHEET_ID: String = "tiles.field"

var _model: TileMapModel = null


func set_map(model: TileMapModel) -> void:
	_model = model
	queue_redraw()


func _draw() -> void:
	if _model == null:
		return
	for tile: Vector2i in _model.iter_tiles():
		_draw_tile(tile)


func _draw_tile(tile: Vector2i) -> void:
	var tile_id: String = _model.tile_id_at(tile)
	if tile_id.is_empty():
		return
	# 下地の地面 -> 障害物の順に重ねる。順序を間違えると樹木が消える。
	_draw_frame(tile, _model.base_tile_id_at(tile))
	_draw_frame(tile, tile_id)


func _draw_frame(tile: Vector2i, tile_id: String) -> void:
	if tile_id.is_empty():
		return
	var frame_name: String = "tile.%s" % tile_id
	var texture: AtlasTexture = SpriteSheetLayout.get_frame_texture(TILE_SHEET_ID, frame_name)
	if texture == null:
		push_warning("Missing tile frame: %s" % frame_name)
		return
	var origin := Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
	draw_texture_rect(texture, Rect2(origin, Vector2(TILE_SIZE, TILE_SIZE)), false)
