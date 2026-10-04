class_name FieldHeroSprite
extends Sprite2D
# フィールドの主人公スプライト。向きと歩行位相に応じてフレームを差し替える。
#
# AnimatedSprite2D + SpriteFrames を使わない理由:
# フレームは SpriteSheetLayout がランタイムで解決する設計のため、
# エディタにアトラスを焼き込むとアセット差し替えが効かなくなる。
# 位相の進行自体は domain/anim/FrameAnimator が持つので、ここでは描画だけを行う。

const HERO_SHEET_ID: String = "hero.field"
const WALK_FRAME_SECONDS: float = 0.16
const STAND_PHASE: String = "stand"

var _facing: String = MovementController.DIRECTION_DOWN
var _animator: FrameAnimator = FrameAnimator.new()


# 定数に PackedStringArray は書けないため、毎回組み立てる。
static func walk_phases() -> PackedStringArray:
	return PackedStringArray(["step_l", "step_r"])


func _ready() -> void:
	_animator = FrameAnimator.looping(walk_phases(), WALK_FRAME_SECONDS)
	_animator.stop()
	_apply_frame()


func set_facing(direction: String) -> void:
	if _facing == direction:
		return
	_facing = direction
	_animator.reset()
	_apply_frame()


func set_moving(is_moving: bool) -> void:
	if is_moving:
		_animator.play()
		return
	if not _animator.is_playing():
		return
	_animator.stop()
	_animator.reset()
	_apply_frame()


func advance(delta_seconds: float) -> void:
	if not _animator.is_playing():
		return
	_animator.advance(delta_seconds)
	_apply_frame()


func _apply_frame() -> void:
	var frame_name: String = "%s.%s.%s" % [HERO_SHEET_ID, _facing, _current_phase()]
	var texture: AtlasTexture = SpriteSheetLayout.get_frame_texture(HERO_SHEET_ID, frame_name)
	if texture == null:
		return
	self.texture = texture


func _current_phase() -> String:
	if not _animator.is_playing():
		return STAND_PHASE
	return _animator.current_frame_name()
