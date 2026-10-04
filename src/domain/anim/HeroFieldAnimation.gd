class_name HeroFieldAnimation
extends RefCounted
# 主人公のフィールド用アニメーション。歩く系と待機系 (足踏み) を持ち、
# 「いまどの位相を見せるか」だけを決める。画像もノードも知らない純ロジック。
#
# 位相の名前は hero.field.<dir>.<phase> の末尾そのもの。実際のテクスチャ解決は
# SpriteSheetLayout が受け持つため、フレーム順を変えても这里是影響を受けない。
# 進行に使う時間は advance() で外部から注入する (domain は時間を知らない)。

const PHASE_STAND: String = "stand"
const PHASE_STEP_LEFT: String = "step_l"
const PHASE_STEP_RIGHT: String = "step_r"

# 歩行は足が入れ替わる速さ。待機は足踏みなので、足を上げる間隔を大きく取る。
const WALK_FRAME_SECONDS: float = 0.16
const IDLE_FRAME_SECONDS: float = 0.5

var _walk: FrameAnimator = FrameAnimator.new()
var _idle: FrameAnimator = FrameAnimator.new()
var _is_moving: bool = false


static func create() -> HeroFieldAnimation:
	var animation := HeroFieldAnimation.new()
	animation._walk = FrameAnimator.looping(animation.walk_phases(), WALK_FRAME_SECONDS)
	animation._idle = FrameAnimator.looping(animation.idle_phases(), IDLE_FRAME_SECONDS)
	return animation


# 定数に PackedStringArray は書けないため、毎回組み立てる。
static func walk_phases() -> PackedStringArray:
	return PackedStringArray([PHASE_STEP_LEFT, PHASE_STEP_RIGHT])


# 待機は左右の足を交互に上げる足踏み。間に stand を挟むと体重移動の間ができて
# 静止と区別できる。1 周期 2 秒で、止まっていることも分かる程度の遅さにする。
static func idle_phases() -> PackedStringArray:
	return PackedStringArray([PHASE_STAND, PHASE_STEP_RIGHT, PHASE_STAND, PHASE_STEP_LEFT])


func is_moving() -> bool:
	return _is_moving


func current_phase() -> String:
	if _is_moving:
		return _walk.current_frame_name()
	return _idle.current_frame_name()


func advance(delta_seconds: float) -> void:
	if _is_moving:
		_walk.advance(delta_seconds)
		return
	_idle.advance(delta_seconds)


# 歩行と待機の切り替え。始点は毎回戻して、足が中途半端な位置から始まらないようにする。
func set_moving(is_moving: bool) -> void:
	if _is_moving == is_moving:
		return
	_is_moving = is_moving
	if _is_moving:
		_walk.reset()
		return
	_idle.reset()


# 向きを変えたときは歩行の始点だけ戻す。待機はそのまま続けるとカクつかない。
func restart_walk() -> void:
	_walk.reset()
