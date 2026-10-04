class_name FrameAnimatorTest
extends TestCase
# 歩行アニメのフレーム進行を検証する。
#
# 画像は使わず「どのフレーム名を選ぶか」だけを検証する。
# 経過時間は注入するので、実行環境の負荷に関係なく決定的に動く。

const FRAME_SECONDS: float = 0.2


# 定数に PackedStringArray は書けないため、毎回組み立てるヘルパーにする。
static func walk_frames() -> PackedStringArray:
	return PackedStringArray(["stand", "step_l", "step_r"])


func test_cycles_through_frames_and_wraps_around() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), FRAME_SECONDS)
	assert_eq(animator.current_frame_name(), "stand", "starts on the first frame")
	animator.advance(FRAME_SECONDS)
	assert_eq(animator.current_frame_name(), "step_l", "advanced one frame")
	animator.advance(FRAME_SECONDS)
	assert_eq(animator.current_frame_name(), "step_r", "advanced again")
	animator.advance(FRAME_SECONDS)
	assert_eq(animator.current_frame_name(), "stand", "wraps back to the first frame")
	assert_eq(animator.current_index(), 0, "index wrapped")


func test_partial_time_does_not_advance_a_frame() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), FRAME_SECONDS)
	animator.advance(FRAME_SECONDS * 0.9)
	assert_eq(animator.current_frame_name(), "stand", "still on the first frame")
	animator.advance(FRAME_SECONDS * 0.1)
	assert_eq(animator.current_frame_name(), "step_l", "crossing the boundary advances once")


func test_leftover_time_carries_into_the_next_frame() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), FRAME_SECONDS)
	animator.advance(FRAME_SECONDS * 2.5)
	assert_eq(animator.current_index(), 2, "a long frame gap skips exactly the frames it covers")


func test_stopped_animator_holds_its_frame() -> void:
	var animator: FrameAnimator = FrameAnimator.holding("stand")
	assert_false(animator.is_playing(), "holding animator is stopped")
	animator.advance(FRAME_SECONDS * 10.0)
	assert_eq(animator.current_frame_name(), "stand", "frame never changes while stopped")


func test_playing_again_resumes_cycling() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), FRAME_SECONDS)
	animator.stop()
	animator.advance(FRAME_SECONDS * 3.0)
	assert_eq(animator.current_frame_name(), "stand", "frozen while stopped")
	animator.play()
	animator.advance(FRAME_SECONDS)
	assert_eq(animator.current_frame_name(), "step_l", "resumes from the held frame")


func test_reset_returns_to_the_first_frame() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), FRAME_SECONDS)
	animator.advance(FRAME_SECONDS * 2.0)
	animator.reset()
	assert_eq(animator.current_frame_name(), "stand", "reset rewinds to the first frame")


func test_single_frame_never_advances_even_while_playing() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(PackedStringArray(["only"]), 0.01)
	assert_true(animator.is_playing(), "single frame setup still counts as playing")
	animator.advance(5.0)
	assert_eq(animator.current_frame_name(), "only", "nothing to cycle to")


func test_empty_frame_list_is_safe() -> void:
	var animator: FrameAnimator = FrameAnimator.new()
	assert_eq(animator.frame_count(), 0, "no frames configured")
	assert_eq(animator.current_frame_name(), "", "empty name instead of a crash")
	animator.advance(1.0)
	assert_eq(animator.current_frame_name(), "", "still empty after advancing")


func test_zero_frame_duration_is_clamped_to_avoid_a_stall() -> void:
	var animator: FrameAnimator = FrameAnimator.looping(walk_frames(), 0.0)
	animator.advance(0.05)
	assert_ne(animator.current_frame_name(), "", "still resolves a frame with a degenerate duration")
