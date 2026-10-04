class_name FrameAnimator
extends RefCounted
# スプライトアニメーションのフレーム進行。画像もノードも知らない純ロジック。
#
# 「どのフレーム名を今表示するか」だけを決める。実際のテクスチャ解決は
# SpriteSheetLayout が受け持つため、フレーム順を変えても这里是影響を受けない。
# 経過時間は advance() で外部から注入する (domain は時間を知らない)。

var _frame_names: PackedStringArray = PackedStringArray()
var _frame_seconds: float = 0.15
var _index: int = 0
var _elapsed: float = 0.0
var _playing: bool = true


static func looping(frame_names: PackedStringArray, frame_seconds: float) -> FrameAnimator:
	var animator := FrameAnimator.new()
	animator.setup(frame_names, frame_seconds)
	return animator


static func holding(frame_name: String) -> FrameAnimator:
	var animator := FrameAnimator.new()
	animator.setup(PackedStringArray([frame_name]), 1.0)
	animator.stop()
	return animator


func setup(frame_names: PackedStringArray, frame_seconds: float) -> void:
	_frame_names = frame_names
	_frame_seconds = maxf(frame_seconds, 0.01)
	_index = 0
	_elapsed = 0.0


func play() -> void:
	_playing = true


func stop() -> void:
	_playing = false


func reset() -> void:
	_index = 0
	_elapsed = 0.0


func is_playing() -> bool:
	return _playing


func frame_count() -> int:
	return _frame_names.size()


func current_index() -> int:
	return _index


func current_frame_name() -> String:
	if _frame_names.is_empty():
		return ""
	return _frame_names[_index]


func advance(delta_seconds: float) -> void:
	if not _playing or _frame_names.size() < 2:
		return
	_elapsed = maxf(0.0, _elapsed + delta_seconds)
	while _elapsed >= _frame_seconds:
		_elapsed -= _frame_seconds
		_index = (_index + 1) % _frame_names.size()
