extends Node
# シーン遷移と画面切り替え演出 (フェード) を一元管理する。
#
# 各シーンは SceneRouter.goto(...) を呼ぶだけで、演出の実装知識を持たない。

const FADE_DURATION: float = 0.22

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()
	EventBus.scene_change_requested.connect(_on_scene_change_requested)


func goto(scene_path: String, transition: String = "fade") -> void:
	if _is_transitioning:
		return
	if transition == "none":
		get_tree().change_scene_to_file(scene_path)
		return
	_run_fade(scene_path)


func is_transitioning() -> bool:
	return _is_transitioning


func fade_in() -> void:
	_fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)


func _run_fade(scene_path: String) -> void:
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void:
		_is_transitioning = false
	)


func _on_scene_change_requested(scene_path: String, transition: String) -> void:
	goto(scene_path, transition)


func _build_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)
