class_name DirAudioFeedback
extends Node

const ERROR_RED_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/error/error_005.ogg"
)
const INTERACT_HINT_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/hint/bong_001.ogg"
)
const RELEASE_DISSIPATE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/release/impactPlank_medium_000.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_001.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_002.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_003.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_004.ogg"),
]

var error_player: AudioStreamPlayer
var hint_player: AudioStreamPlayer
var release_player: AudioStreamPlayer
var last_release_dissipate_index := -1


func _ready() -> void:
	error_player = add_audio_player("ErrorPlayer")
	hint_player = add_audio_player("HintPlayer")
	release_player = add_audio_player("ReleasePlayer")


func add_audio_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	add_child(player)
	return player


func play_error_red() -> void:
	if error_player == null:
		return

	error_player.stream = ERROR_RED_STREAM
	error_player.play()


func play_interact_hint() -> void:
	if hint_player == null:
		return

	hint_player.stream = INTERACT_HINT_STREAM
	hint_player.play()


func play_release_dissipate() -> void:
	if release_player == null or RELEASE_DISSIPATE_STREAMS.is_empty():
		return

	var stream_index := randi_range(0, RELEASE_DISSIPATE_STREAMS.size() - 1)
	if RELEASE_DISSIPATE_STREAMS.size() > 1 and stream_index == last_release_dissipate_index:
		stream_index = (stream_index + 1) % RELEASE_DISSIPATE_STREAMS.size()

	last_release_dissipate_index = stream_index
	release_player.stream = RELEASE_DISSIPATE_STREAMS[stream_index]
	release_player.play()
