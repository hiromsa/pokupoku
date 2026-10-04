class_name HeroFieldAnimationTest
extends TestCase
# 主人公の歩行 / 足踏み (待機) アニメの位相選択を検証する。
#
# 画像は使わず「どの位相名を選ぶか」だけを見る。
# 経過時間は注入するので、実行環境の負荷に関係なく決定的に動く。

const IDLE_SECONDS: float = HeroFieldAnimation.IDLE_FRAME_SECONDS
const WALK_SECONDS: float = HeroFieldAnimation.WALK_FRAME_SECONDS

# hero.py の WALK_PHASES (シートに実在する位相) と同じもの。
const SHEET_PHASES: Array = ["stand", "step_l", "step_r"]


func test_idle_starts_on_stand_and_holds_it_a_while() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STAND, "idle starts standing")
	animation.advance(IDLE_SECONDS - 0.01)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STAND, "not a step yet")


func test_idle_taps_feet_alternately() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	animation.advance(IDLE_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_RIGHT, "right foot first")
	animation.advance(IDLE_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STAND, "stand between the two feet")
	animation.advance(IDLE_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_LEFT, "then the left foot")
	animation.advance(IDLE_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STAND, "the cycle wraps")


func test_idle_is_clearly_slower_than_walking() -> void:
	assert_true(IDLE_SECONDS > WALK_SECONDS * 2.0, "foot tapping must not read as walking")


func test_walk_alternates_feet() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	animation.set_moving(true)
	assert_true(animation.is_moving(), "moving flag follows set_moving")
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_LEFT, "a step starts with the left foot")
	animation.advance(WALK_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_RIGHT, "then the right foot")
	animation.advance(WALK_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_LEFT, "and back again")


func test_stopping_settles_back_to_stand() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	animation.set_moving(true)
	animation.advance(WALK_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_RIGHT, "mid-step")
	animation.set_moving(false)
	assert_false(animation.is_moving(), "no longer moving")
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STAND, "stopping does not leave a foot raised")


func test_resuming_walk_starts_from_the_left_foot() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	animation.set_moving(true)
	animation.advance(WALK_SECONDS * 3.0)
	animation.set_moving(false)
	animation.set_moving(true)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_LEFT, "a new step always starts clean")


func test_restart_walk_does_not_disturb_the_idle_cycle() -> void:
	var animation: HeroFieldAnimation = HeroFieldAnimation.create()
	animation.advance(IDLE_SECONDS)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_RIGHT, "mid tap")
	animation.restart_walk()
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_RIGHT, "turning keeps the tap going")
	animation.set_moving(true)
	assert_eq(animation.current_phase(), HeroFieldAnimation.PHASE_STEP_LEFT, "but walking starts from the left foot")


func test_both_sequences_only_use_frames_that_exist() -> void:
	for phase: String in HeroFieldAnimation.walk_phases():
		assert_true(SHEET_PHASES.has(phase), "walk phase exists in the sheet: %s" % phase)
	for phase: String in HeroFieldAnimation.idle_phases():
		assert_true(SHEET_PHASES.has(phase), "idle phase exists in the sheet: %s" % phase)
