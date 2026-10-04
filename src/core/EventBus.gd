extends Node
# シーン横断のシグナル中継役。
#
# UI 側はドメインオブジェクトを直接参照せず、必ず本ノード経由で通知を受け取る。
# これにより「UI とロジックの疎結合」(clinerules) を担保する。

signal scene_change_requested(scene_path: String, transition: String)
signal bgm_changed(track_id: String)
signal se_played(sound_id: String)
signal dialogue_requested(lines: Array)
signal battle_started(battle_setup: Dictionary)
signal battle_ended(result: String)
signal flag_changed(flag_name: String, value: Variant)
signal message_logged(message: String)
