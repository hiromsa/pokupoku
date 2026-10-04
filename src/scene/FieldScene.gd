extends Node2D
# フィールド画面。マップを読み、主人公を歩かせ、HUD に値を流す。
#
# シーン層は「組み立てと配線」だけを受け持つ。
# 当たり判定も移動もアニメ進行も domain 側が持ち、View はそれを読むだけ。

const MAP_PATH: String = "res://assets/data/maps/prototype_village.json"
const TILE_INDEX_PATH: String = "res://assets/images/tiles/tile_index.json"
const TITLE_SCENE_PATH: String = "res://src/scene/TitleScene.tscn"

const HERO_Z_INDEX: int = 10
const HUD_LAYER: int = 10
const CAMERA_SMOOTHING_SPEED: float = 8.0

# Phase 2 はステータスシステムが未実装のため、HUD 用の暫定値をここに置く。
const PROTOTYPE_HERO_NAME: String = "ゆうしゃ"
const PROTOTYPE_MAX_HIT_POINTS: int = 25
const PROTOTYPE_MAX_MAGIC_POINTS: int = 5

const HELP_MESSAGE: String = "はじまりの草原\n矢印キー：あるく　　X：タイトルにもどる"


var _movement: MovementController = null
var _tile_layer: FieldTileLayer = null
var _hero: FieldHeroSprite = null
var _hud: HudLayout = null
var _camera: Camera2D = null


func _ready() -> void:
	var definition: MapDefinition = MapDefinition.from_dictionary(_read_json(MAP_PATH))
	var catalog: TileCatalog = TileCatalog.from_dictionary(_read_json(TILE_INDEX_PATH))
	var map: TileMapModel = definition.build_tile_map(catalog)

	_movement = MovementController.create(map, definition.spawn_tile)
	_build_world(map)
	_build_hud()


func _process(delta: float) -> void:
	if _movement == null:
		return
	_read_move_input()
	_movement.advance(delta)
	_sync_hero(delta)
	_camera.position = _hero_center()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_cancel"):
		SceneRouter.goto(TITLE_SCENE_PATH, "fade")


func _build_world(map: TileMapModel) -> void:
	_tile_layer = FieldTileLayer.new()
	_tile_layer.name = "TileLayer"
	add_child(_tile_layer)
	_tile_layer.set_map(map)

	_hero = FieldHeroSprite.new()
	_hero.name = "Hero"
	_hero.z_index = HERO_Z_INDEX
	add_child(_hero)
	_hero.position = _hero_center()

	_camera = Camera2D.new()
	_camera.name = "Camera"
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map.width() * FieldTileLayer.TILE_SIZE
	_camera.limit_bottom = map.height() * FieldTileLayer.TILE_SIZE
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTHING_SPEED
	_camera.position = _hero_center()
	add_child(_camera)
	_camera.make_current()
	# 補正開始点を現在の位置へ固定し、シーン開始直後に画面が滑らないようにする。
	_camera.reset_smoothing()


func _build_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = HUD_LAYER
	add_child(hud_layer)

	_hud = HudLayout.new()
	_hud.name = "Hud"
	hud_layer.add_child(_hud)
	_hud.build()
	_hud.set_status(PROTOTYPE_HERO_NAME, PROTOTYPE_MAX_HIT_POINTS, PROTOTYPE_MAX_HIT_POINTS,
		PROTOTYPE_MAX_MAGIC_POINTS, PROTOTYPE_MAX_MAGIC_POINTS)
	_hud.set_message(HELP_MESSAGE)
	_hud.set_commands(_field_commands(), 0)


# 入力された方向へ 1 タイルの移動を試みる。同時に複数押されても上から順に採用する。
func _read_move_input() -> void:
	for binding: Array in _direction_bindings():
		if Input.is_action_pressed(String(binding[1])):
			_movement.try_step(String(binding[0]))
			return


func _sync_hero(delta: float) -> void:
	_hero.set_facing(_movement.facing())
	_hero.set_moving(_movement.is_stepping())
	_hero.advance(delta)
	_hero.position = _hero_center()


# 主人公はタイルの中央に立つ。移動中は MovementController の補間値を使う。
func _hero_center() -> Vector2:
	var tile: Vector2 = _movement.interpolated_tile()
	var tile_size: int = FieldTileLayer.TILE_SIZE
	return Vector2((tile.x + 0.5) * tile_size, (tile.y + 0.5) * tile_size)


func _direction_bindings() -> Array:
	return [
		[MovementController.DIRECTION_UP, "move_up"],
		[MovementController.DIRECTION_DOWN, "move_down"],
		[MovementController.DIRECTION_LEFT, "move_left"],
		[MovementController.DIRECTION_RIGHT, "move_right"],
	]


# ui.md §5 のフィールドコマンド。Phase 2 は表示のみ。
func _field_commands() -> PackedStringArray:
	return PackedStringArray(["はなす", "しらべる", "つかう", "システム"])


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Field data missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Malformed field data: %s" % path)
		return {}
	return parsed as Dictionary
