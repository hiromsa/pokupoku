extends Node
# ブートストラップ。autoload 初期化が完了した直後にタイトルシーンへ遷移する。
#
# Main 自身の _ready 中に change_scene_to_file を呼ぶとツリー構築と衝突するため
# 必ず call_deferred 経由で遅延させる。

const TITLE_SCENE_PATH: String = "res://src/scene/TitleScene.tscn"


func _ready() -> void:
	SceneRouter.goto.call_deferred(TITLE_SCENE_PATH, "none")
	SceneRouter.fade_in.call_deferred()
