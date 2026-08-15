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
const PLAYER_MOVE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/move/footstep_concrete_000.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_001.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_002.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_003.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_004.ogg"),
]

var error_player: AudioStreamPlayer
var hint_player: AudioStreamPlayer
var release_player: AudioStreamPlayer
var move_player: AudioStreamPlayer
var last_release_dissipate_index := -1
var last_player_move_index := -1


func _ready() -> void:
	error_player = add_audio_player("ErrorPlayer")
	hint_player = add_audio_player("HintPlayer")
	release_player = add_audio_player("ReleasePlayer")
	move_player = add_audio_player("MovePlayer")


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

	var stream_index := nonrepeating_index(
		RELEASE_DISSIPATE_STREAMS.size(),
		last_release_dissipate_index
	)
	last_release_dissipate_index = stream_index
	release_player.stream = RELEASE_DISSIPATE_STREAMS[stream_index]
	release_player.play()


func play_player_move() -> void:
	if move_player == null or PLAYER_MOVE_STREAMS.is_empty():
		return

	var stream_index := nonrepeating_index(
		PLAYER_MOVE_STREAMS.size(),
		last_player_move_index
	)
	last_player_move_index = stream_index
	move_player.stream = PLAYER_MOVE_STREAMS[stream_index]
	move_player.play()


func nonrepeating_index(stream_count: int, previous_index: int) -> int:
	var stream_index := randi_range(0, stream_count - 1)
	if stream_count > 1 and stream_index == previous_index:
		stream_index = (stream_index + 1) % stream_count
	return stream_index
