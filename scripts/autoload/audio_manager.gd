extends Node
## AudioManager - Handles all audio playback
## 音频管理器 - 处理所有音频播放

## Audio players / 音频播放器
var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _typewriter_player: AudioStreamPlayer

## Current BGM / 当前背景音乐
var _current_bgm: String = ""


func _ready() -> void:
	_setup_audio_players()


## Setup audio player nodes / 设置音频播放器节点
func _setup_audio_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = "Master"
	add_child(_voice_player)

	_typewriter_player = AudioStreamPlayer.new()
	_typewriter_player.name = "TypewriterPlayer"
	_typewriter_player.bus = "Master"
	add_child(_typewriter_player)

	# Apply volume settings
	_apply_volume_settings()


## Apply volume settings from config / 应用配置中的音量设置
func _apply_volume_settings() -> void:
	var volumes = DataManager.get_audio_volumes()
	_bgm_player.volume_db = volumes.get("bgm", -10)
	_sfx_player.volume_db = volumes.get("sfx", 0)
	_voice_player.volume_db = volumes.get("voice", 0)
	_typewriter_player.volume_db = volumes.get("sfx", 0) - 5  # Typewriter slightly quieter


## Play background music / 播放背景音乐
func play_bgm(path: String, fade_in: bool = true) -> void:
	if path == _current_bgm and _bgm_player.playing:
		return

	_current_bgm = path

	if path.is_empty():
		stop_bgm()
		return

	var stream = _load_audio(path)
	if stream:
		if fade_in:
			_bgm_player.volume_db = -40
			_bgm_player.stream = stream
			_bgm_player.play()
			var tween = create_tween()
			tween.tween_property(_bgm_player, "volume_db", DataManager.get_audio_volumes().get("bgm", -10), 1.0)
		else:
			_bgm_player.stream = stream
			_bgm_player.play()


## Stop background music / 停止背景音乐
func stop_bgm(fade_out: bool = true) -> void:
	if not _bgm_player.playing:
		return

	if fade_out:
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -40, 1.0)
		tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()

	_current_bgm = ""


## Play sound effect / 播放音效
func play_sfx(path: String) -> void:
	var stream = _load_audio(path)
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()


## Play voice / 播放语音
func play_voice(path: String) -> void:
	var stream = _load_audio(path)
	if stream:
		_voice_player.stream = stream
		_voice_player.play()


## Stop voice / 停止语音
func stop_voice() -> void:
	_voice_player.stop()


## Check if voice is playing / 检查语音是否在播放
func is_voice_playing() -> bool:
	return _voice_player.playing


## Play typewriter sound / 播放打字机音效
func play_typewriter() -> void:
	if not _typewriter_player.playing:
		var stream = _load_audio("res://assets/audio/sfx/typewriter.ogg")
		if stream:
			_typewriter_player.stream = stream
			_typewriter_player.play()


## Stop typewriter sound / 停止打字机音效
func stop_typewriter() -> void:
	_typewriter_player.stop()


## Play scream sound effect / 播放尖叫音效
func play_scream() -> void:
	play_sfx("res://assets/audio/sfx/scream.ogg")


## Play scale weighing sound / 播放天秤称量音效
func play_scale_weigh() -> void:
	play_sfx("res://assets/audio/sfx/scale_weigh.ogg")


## Play button click sound / 播放按钮点击音效
func play_click() -> void:
	play_sfx("res://assets/audio/sfx/click.ogg")


## Load audio stream / 加载音频流
func _load_audio(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		# Return null silently for placeholder audio
		return null

	return load(path) as AudioStream
