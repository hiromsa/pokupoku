extends Node
# フィールド画面を 1 枚キャプチャして tmp_preview/ に書き出すデバッグ用シーン。
#
# headless のユニットテストでは見た目を確認できないため、
# 描画の破損を人間の目で確かめる手段として使う。
#
# 実行:
#   tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . \
#       --rendering-driver opengl3 res://tools/debug/CaptureField.tscn

const OUTPUT_PATH: String = "res://tmp_preview/field_scene.png"

# マップ生成と 1 回目の描画が完了するまで待つフレーム数。
const FRAMES_BEFORE_CAPTURE: int = 10

var _frames: int = 0


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < FRAMES_BEFORE_CAPTURE:
		return
	_capture()


func _capture() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Captured image is empty")
		get_tree().quit(1)
		return
	image.save_png(OUTPUT_PATH)
	print("captured field scene -> %s" % OUTPUT_PATH)
	get_tree().quit(0)
