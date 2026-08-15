class_name DirAudioFeedback
extends Node

const ERROR_RED_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/error/error_005.ogg"
)
const INTERACT_HINT_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/hint/bong_001.ogg"
)
const TRIGGER_ACTIVATION_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/release/dragon-studio-simple-whoosh-382724.mp3"
)
const TRIGGER_ACTIVATION_VOLUME_DB := -4.0
const TRIGGER_ACTIVATION_COLLISION_VOLUME_DB := -16.0
const INSTALL_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/confirm/switch28.ogg"
)
const INSTALL_VOLUME_DB := -4.0
const BLOCK_PUSH_STREAM: AudioStream = preload(
	"res://assets/audio/sfx/push/handleSmallLeather2.ogg"
)
const BLOCK_PUSH_VOLUME_DB := 10.0
const RELEASE_DISSIPATE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/release/impactPlank_medium_000.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_001.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_002.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_003.ogg"),
	preload("res://assets/audio/sfx/release/impactPlank_medium_004.ogg"),
]
const COLLISION_IMPACT_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/collision/impactWood_light_000.ogg"),
	preload("res://assets/audio/sfx/collision/impactWood_light_001.ogg"),
	preload("res://assets/audio/sfx/collision/impactWood_light_002.ogg"),
	preload("res://assets/audio/sfx/collision/impactWood_light_003.ogg"),
	preload("res://assets/audio/sfx/collision/impactWood_light_004.ogg"),
]
const COLLISION_IMPACT_VOLUME_DB := 2.0
const PLAYER_MOVE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/move/footstep_concrete_000.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_001.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_002.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_003.ogg"),
	preload("res://assets/audio/sfx/move/footstep_concrete_004.ogg"),
]

var error_player: AudioStreamPlayer
var hint_player: AudioStreamPlayer
var trigger_activation_player: AudioStreamPlayer
var release_dissipate_player: AudioStreamPlayer
var collision_impact_player: AudioStreamPlayer
var move_player: AudioStreamPlayer
var install_player: AudioStreamPlayer
var block_push_player: AudioStreamPlayer
var last_release_dissipate_index := -1
var last_collision_impact_index := -1
var last_player_move_index := -1


func _ready() -> void:
	error_player = add_audio_player("ErrorPlayer")
	hint_player = add_audio_player("HintPlayer")
	trigger_activation_player = add_audio_player("TriggerActivationPlayer")
	trigger_activation_player.volume_db = TRIGGER_ACTIVATION_VOLUME_DB
	release_dissipate_player = add_audio_player("ReleaseDissipatePlayer")
	collision_impact_player = add_audio_player("CollisionImpactPlayer")
	collision_impact_player.volume_db = COLLISION_IMPACT_VOLUME_DB
	move_player = add_audio_player("MovePlayer")
	install_player = add_audio_player("InstallPlayer")
	install_player.volume_db = INSTALL_VOLUME_DB
	block_push_player = add_audio_player("BlockPushPlayer")
	block_push_player.volume_db = BLOCK_PUSH_VOLUME_DB


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


func play_trigger_activation() -> void:
	if trigger_activation_player == null:
		return

	trigger_activation_player.volume_db = TRIGGER_ACTIVATION_VOLUME_DB
	trigger_activation_player.stream = TRIGGER_ACTIVATION_STREAM
	trigger_activation_player.play()


func play_install() -> void:
	if install_player == null:
		return

	install_player.stream = INSTALL_STREAM
	install_player.play()


func play_block_push() -> void:
	if block_push_player == null:
		return

	block_push_player.stream = BLOCK_PUSH_STREAM
	block_push_player.play()


func play_release_dissipate() -> void:
	if release_dissipate_player == null or RELEASE_DISSIPATE_STREAMS.is_empty():
		return

	var stream_index := nonrepeating_index(
		RELEASE_DISSIPATE_STREAMS.size(),
		last_release_dissipate_index
	)
	last_release_dissipate_index = stream_index
	release_dissipate_player.stream = RELEASE_DISSIPATE_STREAMS[stream_index]
	release_dissipate_player.play()


func play_collision_impact() -> void:
	if collision_impact_player == null or COLLISION_IMPACT_STREAMS.is_empty():
		return

	if trigger_activation_player != null and trigger_activation_player.playing:
		trigger_activation_player.volume_db = (
			TRIGGER_ACTIVATION_COLLISION_VOLUME_DB
		)
	var stream_index := nonrepeating_index(
		COLLISION_IMPACT_STREAMS.size(),
		last_collision_impact_index
	)
	last_collision_impact_index = stream_index
	collision_impact_player.stream = COLLISION_IMPACT_STREAMS[stream_index]
	collision_impact_player.play()


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
