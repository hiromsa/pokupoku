extends Node
# フィールド画面を 1 枚キャプチャして tmp_preview/ に書き出すデバッグ用シーン。
#
# headless のユニットテストでは見た目を確認できないため、
# 描画の破損を人間の目で確かめる手段として使う。
#
# 実行:
#   tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . \
#       --rendering-driver opengl3 res://tools/debug/CaptureField.tscn
#
# 待機アニメのように時間を置いた状態を見たいときは、`--` の後ろで
# 出力先と待機フレーム数 (60fps 想定) を差し替える:
#   ... res://tools/debug/CaptureField.tscn -- res://tmp_preview/idle_b.png 45

const OUTPUT_PATH: String = "res://tmp_preview/field_scene.png"

# マップ生成と 1 回目の描画が完了するまで待つフレーム数。
const FRAMES_BEFORE_CAPTURE: int = 10

var _frames: int = 0
var _output_path: String = OUTPUT_PATH
var _frames_before_capture: int = FRAMES_BEFORE_CAPTURE


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() > 0 and not String(arguments[0]).is_empty():
		_output_path = String(arguments[0])
	if arguments.size() > 1:
		_frames_before_capture = maxi(1, int(String(arguments[1])))


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < _frames_before_capture:
		return
	_capture()


func _capture() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Captured image is empty")
		get_tree().quit(1)
		return
	image.save_png(_output_path)
	print("captured field scene -> %s" % _output_path)
	get_tree().quit(0)
