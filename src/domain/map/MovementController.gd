class_name MovementController
extends RefCounted
# フィールドでの 4 方向移動。当たり判定と方向保持を受け持つ純ロジック。
#
# 論理位置は常にタイル座標で持つ。描画なめらかさのための補間値だけを持ち、
# 実際の時間経過は advance() で外部から注入される (domain は時間を知らない)。

const STEP_DURATION_SECONDS: float = 0.16

const DIRECTION_UP: String = "up"
const DIRECTION_DOWN: String = "down"
const DIRECTION_LEFT: String = "left"
const DIRECTION_RIGHT: String = "right"

const DIRECTION_VECTORS: Dictionary = {
	DIRECTION_UP: Vector2i(0, -1),
	DIRECTION_DOWN: Vector2i(0, 1),
	DIRECTION_LEFT: Vector2i(-1, 0),
	DIRECTION_RIGHT: Vector2i(1, 0),
}

var _map: TileMapModel = null
var _tile: Vector2i = Vector2i.ZERO
var _facing: String = DIRECTION_DOWN
var _step_from: Vector2i = Vector2i.ZERO
var _step_to: Vector2i = Vector2i.ZERO
var _is_stepping: bool = false
var _elapsed: float = 0.0


static func create(map: TileMapModel, spawn_tile: Vector2i) -> MovementController:
	var controller := MovementController.new()
	controller._setup(map, spawn_tile)
	return controller


func _setup(map: TileMapModel, spawn_tile: Vector2i) -> void:
	_map = map
	_tile = _clamp_to_passable(map, spawn_tile)


# 出現地点が塞がっていても動ける場所に寄せる。マップデータの抜けで固まらないための保険。
func _clamp_to_passable(map: TileMapModel, spawn_tile: Vector2i) -> Vector2i:
	if map == null or map.is_passable(spawn_tile):
		return spawn_tile
	var nearest: Vector2i = spawn_tile
	var nearest_distance: int = 1 << 30
	for candidate: Vector2i in map.iter_tiles():
		if not map.is_passable(candidate):
			continue
		var distance: int = absi(candidate.x - spawn_tile.x) + absi(candidate.y - spawn_tile.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func tile_position() -> Vector2i:
	return _tile


func facing() -> String:
	return _facing


func is_stepping() -> bool:
	return _is_stepping


func step_progress() -> float:
	if not _is_stepping:
		return 1.0
	return clampf(_elapsed / STEP_DURATION_SECONDS, 0.0, 1.0)


# 描画用の補間済みタイル位置。移動中は 2 点間を線形補間する。
func interpolated_tile() -> Vector2:
	if not _is_stepping:
		return Vector2(_tile)
	return Vector2(_step_from).lerp(Vector2(_step_to), step_progress())


func direction_vector(direction: String) -> Vector2i:
	return DIRECTION_VECTORS.get(direction, Vector2i.ZERO)


# その場で向きだけ変える。移動中は向きを固定して斜め見えを防ぐ。
func turn_to(direction: String) -> bool:
	if not DIRECTION_VECTORS.has(direction):
		return false
	if _is_stepping:
		return false
	_facing = direction
	return true


# 指定方向へ 1 タイル移動を開始する。塞いでいれば false (向きだけ反映する)。
func try_step(direction: String) -> bool:
	if not DIRECTION_VECTORS.has(direction):
		return false
	_facing = direction
	if _is_stepping or _map == null:
		return false

	var target: Vector2i = _tile + direction_vector(direction)
	if not _map.is_passable(target):
		return false

	_step_from = _tile
	_step_to = target
	_is_stepping = true
	_elapsed = 0.0
	return true


func advance(delta_seconds: float) -> void:
	if not _is_stepping:
		return
	_elapsed = maxf(0.0, _elapsed + delta_seconds)
	if _elapsed < STEP_DURATION_SECONDS:
		return
	_tile = _step_to
	_is_stepping = false
	_elapsed = 0.0
