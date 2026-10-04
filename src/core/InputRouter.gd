extends Node
# 論理入力アクションの実行時登録。
#
# project.godot の [input] セクションはシリアライズ形式が複雑で手編集だと壊れやすいため、
# 論理名 -> 物理キー の対応はここでコードとして一元管理する。
# ゲームロジックは "move_left" 等の論理名のみを使い、キー配線から独立させる。

const ACTION_BINDINGS: Dictionary = {
	"action_confirm": [KEY_Z, KEY_ENTER, KEY_SPACE],
	"action_cancel": [KEY_X, KEY_ESCAPE],
	"action_menu": [KEY_C],
	"move_left": [KEY_LEFT],
	"move_right": [KEY_RIGHT],
	"move_up": [KEY_UP],
	"move_down": [KEY_DOWN],
}

# 連打時のキーリピートを無効化して、メニューが飛びするのを防ぐ
const IGNORE_ECHO: bool = true


func _ready() -> void:
	register_actions()


func register_actions() -> void:
	for action_name: String in ACTION_BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for keycode: Key in ACTION_BINDINGS[action_name]:
			if _action_has_key(action_name, keycode):
				continue
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			key_event.echo = not IGNORE_ECHO
			InputMap.action_add_event(action_name, key_event)


func is_action_registered(action_name: String) -> bool:
	return InputMap.has_action(action_name)


func _action_has_key(action_name: String, keycode: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false
