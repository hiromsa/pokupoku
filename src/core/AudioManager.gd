extends Node
# BGM / SE の再生管理。
#
# 再生は常に AssetRegistry の論理ID経由。WAV アセットが未入手の段階でも
# 例外を投げず無音で通過するため、開発初期から呼び出し側の実装を確定できる。

const SE_CHANNEL_COUNT: int = 6

var _bgm_player: AudioStreamPlayer
var _se_players: Array[AudioStreamPlayer] = []
var _current_bgm_id: String = ""
var _bgm_volume_db: float = 0.0
var _se_volume_db: float = 0.0


func _ready() -> void:
	_build_players()
	EventBus.bgm_changed.connect(play_bgm)
	EventBus.se_played.connect(play_se)


func play_bgm(track_id: String, crossfade_seconds: float = 0.5) -> void:
	if track_id == _current_bgm_id and _bgm_player.playing:
		return

	var stream: AudioStream = AssetRegistry.get_audio_stream(track_id)
	if stream == null:
		_current_bgm_id = ""
		return

	_current_bgm_id = track_id
	_bgm_player.stream = stream
	_bgm_player.volume_db = _bgm_volume_db
	if crossfade_seconds > 0.0:
		_bgm_player.volume_db = -80.0
		_bgm_player.play()
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", _bgm_volume_db, crossfade_seconds)
	else:
		_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm_id = ""


func play_se(sound_id: String) -> void:
	var stream: AudioStream = AssetRegistry.get_audio_stream(sound_id)
	if stream == null:
		return
	for player: AudioStreamPlayer in _se_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = _se_volume_db
			player.play()
			return
	push_warning("All SE channels busy: %s" % sound_id)


func set_bgm_volume_db(volume_db: float) -> void:
	_bgm_volume_db = volume_db
	_bgm_player.volume_db = volume_db


func set_se_volume_db(volume_db: float) -> void:
	_se_volume_db = volume_db


func current_bgm_id() -> String:
	return _current_bgm_id


func _build_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	add_child(_bgm_player)

	for channel_index: int in SE_CHANNEL_COUNT:
		var se_player := AudioStreamPlayer.new()
		se_player.name = "SePlayer%d" % channel_index
		add_child(se_player)
		_se_players.append(se_player)
