class_name FieldHeroSprite
extends Sprite2D
# フィールドの主人公スプライト。向きと歩行位相に応じてフレームを差し替える。
#
# AnimatedSprite2D + SpriteFrames を使わない理由:
# フレームは SpriteSheetLayout がランタイムで解決する設計のため、
# エディタにアトラスを焼き込むとアセット差し替えが効かなくなる。
# 位相の選択と進行自体は domain/anim/HeroFieldAnimation が持つので、ここでは描画だけを行う。

const HERO_SHEET_ID: String = "hero.field"

var _facing: String = MovementController.DIRECTION_DOWN
var _animation: HeroFieldAnimation = HeroFieldAnimation.create()
var _applied_frame_name: String = ""


func _ready() -> void:
	_animation = HeroFieldAnimation.create()
	_apply_frame()


func set_facing(direction: String) -> void:
	if _facing == direction:
		return
	_facing = direction
	_animation.restart_walk()
	_apply_frame()


func set_moving(is_moving: bool) -> void:
	if _animation.is_moving() == is_moving:
		return
	_animation.set_moving(is_moving)
	_apply_frame()


# 歩行中でも待機中でも毎フレーム呼ぶ。位相が変わったときだけテクスチャを差し替える。
func advance(delta_seconds: float) -> void:
	_animation.advance(delta_seconds)
	_apply_frame()


func _apply_frame() -> void:
	var frame_name: String = "%s.%s.%s" % [HERO_SHEET_ID, _facing, _animation.current_phase()]
	if frame_name == _applied_frame_name:
		return
	var texture: AtlasTexture = SpriteSheetLayout.get_frame_texture(HERO_SHEET_ID, frame_name)
	if texture == null:
		return
	_applied_frame_name = frame_name
	self.texture = texture
