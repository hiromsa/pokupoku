class_name MovementControllerTest
extends TestCase
# 4 方向移動・当たり判定・向き変更を検証する。
#
# 時間は advance() で注入するので、フレームレートに依存しない決定的なテストになる。

const SPAWN: Vector2i = Vector2i(1, 2)
const STEP_SECONDS: float = MovementController.STEP_DURATION_SECONDS


func test_steps_exactly_one_tile() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	assert_eq(controller.tile_position(), SPAWN, "spawn kept when walkable")
	assert_eq(controller.facing(), MovementController.DIRECTION_DOWN, "starts facing down")

	assert_true(controller.try_step("right"), "step onto grass accepted")
	assert_eq(controller.facing(), "right", "facing set as the step starts")
	assert_true(controller.is_stepping(), "step in progress")
	assert_eq(controller.tile_position(), SPAWN, "logical tile only moves on completion")

	controller.advance(STEP_SECONDS)
	assert_false(controller.is_stepping(), "step finished")
	assert_eq(controller.tile_position(), Vector2i(2, 2), "moved exactly one tile right")


func test_blocked_tile_rejects_the_step_but_still_turns() -> void:
	var map: TileMapModel = TestFixtures.open_field()
	map.set_tile(Vector2i(2, 2), "tree")
	var controller: MovementController = MovementController.create(map, SPAWN)

	assert_false(controller.try_step("right"), "step into a wall rejected")
	assert_eq(controller.facing(), "right", "hero still faces the wall")
	assert_false(controller.is_stepping(), "no step started")

	controller.advance(STEP_SECONDS * 4.0)
	assert_eq(controller.tile_position(), SPAWN, "hero never enters the wall")


func test_map_edge_blocks_movement() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), Vector2i(0, 0))
	assert_false(controller.try_step("up"), "walking off the top edge is blocked")
	assert_false(controller.try_step("left"), "walking off the left edge is blocked")
	assert_true(controller.try_step("down"), "inward move still works")


func test_a_second_step_cannot_start_midway() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	assert_true(controller.try_step("right"), "first step started")
	assert_false(controller.try_step("right"), "second step rejected while stepping")
	controller.advance(STEP_SECONDS * 0.5)
	assert_false(controller.is_stepping() and controller.tile_position() == Vector2i(3, 2),
		"still travelling between two tiles")


func test_interpolated_position_travels_between_tiles() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	assert_eq(controller.interpolated_tile(), Vector2(SPAWN), "idle position is the tile centre")
	controller.try_step("right")
	controller.advance(STEP_SECONDS * 0.5)
	assert_approx(controller.interpolated_tile().x, SPAWN.x + 0.5, 0.01, "halfway between tiles")
	assert_approx(controller.interpolated_tile().y, SPAWN.y, 0.01, "no drift on the idle axis")
	controller.advance(STEP_SECONDS)
	assert_eq(controller.interpolated_tile(), Vector2(Vector2i(2, 2)), "lands on the target tile")


func test_turning_in_place_updates_facing_only() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	assert_true(controller.turn_to("up"), "turn accepted")
	assert_eq(controller.facing(), "up", "facing changed")
	assert_eq(controller.tile_position(), SPAWN, "turning does not move the hero")
	assert_false(controller.turn_to("sideways"), "unknown direction rejected")


func test_turning_is_locked_while_stepping() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	controller.try_step("right")
	assert_false(controller.turn_to("up"), "cannot turn mid-step")
	assert_eq(controller.facing(), "right", "facing stays on the active step")


func test_spawn_on_a_blocked_tile_snaps_to_the_nearest_walkable() -> void:
	var map: TileMapModel = TestFixtures.open_field()
	map.set_tile(Vector2i(2, 2), "water")
	var controller: MovementController = MovementController.create(map, Vector2i(2, 2))
	assert_ne(controller.tile_position(), Vector2i(2, 2), "hero is not stuck inside the water")
	assert_true(map.is_passable(controller.tile_position()), "hero snapped onto walkable ground")


func test_unknown_direction_is_ignored() -> void:
	var controller: MovementController = MovementController.create(TestFixtures.open_field(), SPAWN)
	assert_false(controller.try_step("diagonal"), "unknown direction rejected")
	assert_eq(controller.facing(), MovementController.DIRECTION_DOWN, "facing unchanged")
	assert_eq(controller.tile_position(), SPAWN, "position unchanged")
