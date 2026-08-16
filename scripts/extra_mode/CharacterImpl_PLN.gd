extends RefCounted

const PLNSlashEffect = preload("res://scripts/extra_mode/PLNSlashEffect.gd")
const PLNChargeGlow  = preload("res://scripts/extra_mode/PLNChargeGlow.gd")
const PLNMoveTrail   = preload("res://scripts/extra_mode/PLNMoveTrail.gd")
const MOVE_SOUND: AudioStream = preload(
	"res://assets/audio/sfx/extra_attack/slash_666herohero_21834.mp3"
)
const ATTACK_SOUND: AudioStream = preload(
	"res://assets/audio/sfx/extra_attack/sword_freesound_36274.wav"
)
const ULT_ATTACK_SOUND: AudioStream = preload(
	"res://assets/audio/sfx/extra_attack/sword_slash_54427377.wav"
)

const WINDUP := PLNSlashEffect.WINDUP
const NORMAL_CHARGE_SCALE := 0.8
const ULT_WINDUP := WINDUP * 1.1
const MOVE_DURATION := 0.07
const ULT_MOVE_DURATION := 0.05
const NORMAL_SLASH_LENGTH := 145.0
const NORMAL_SLASH_WIDTH := 8.0
const ULT_SLASH_WIDTH := PLNSlashEffect.MAX_WIDTH

var pending_kill_pos: Vector2i = Vector2i(-1, -1)
var defer_player_move: bool = false

func play_move(
	player: Node2D,
	from_pos: Vector2,
	to_pos: Vector2,
	move_duration_override: float = -1.0,
	play_sound: bool = true
) -> Tween:
	var move_duration: float = MOVE_DURATION if move_duration_override < 0.0 else move_duration_override
	var trail := Node2D.new()
	trail.set_script(PLNMoveTrail)
	player.get_parent().add_child(trail)
	trail.setup(from_pos, to_pos)
	var tw := player.create_tween()
	tw.tween_property(player, "position", to_pos, move_duration)\
	  .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if play_sound:
		play_move_sound(player)
	return tw

func play_attack(player: Node2D, dir: int, success: bool, is_dash: bool, is_ult: bool = false) -> void:
	if is_dash:
		play_charge_preview(player, dir)
		var dv: Vector2 = Vector2(CharacterData.DIR_VECTOR[dir])
		var fx: Node2D = Node2D.new()
		fx.set_script(PLNSlashEffect)
		player.add_child(fx)
		fx.setup(dv, not success)   # short=true when blocked
		play_attack_sound(player, is_ult)
	else:
		var dv: Vector2i = CharacterData.DIR_VECTOR[dir]
		var origin := player.position
		var lunge_dist: float = 30.0 if success else 12.0
		var out_dur: float    = 0.08 if success else 0.05
		var back_dur: float   = 0.12 if success else 0.10
		var tip := origin + Vector2(dv) * lunge_dist
		var tw := player.create_tween()
		tw.tween_property(player, "position", tip, out_dur)\
		  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(player, "position", origin, back_dur)\
		  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func get_hit_delay(
	is_dash: bool,
	move_duration_override: float = -1.0,
	windup_override: float = -1.0
) -> float:
	if is_dash:
		var move_duration: float = MOVE_DURATION if move_duration_override < 0.0 else move_duration_override
		var windup_duration: float = WINDUP if windup_override < 0.0 else windup_override
		return windup_duration + 0.03 + 0.10 + move_duration
	return 0.25

func play_charge_preview(
	player: Node2D,
	dir: int,
	body_scale: float = NORMAL_CHARGE_SCALE,
	windup_duration: float = WINDUP
) -> void:
	var glow: Node2D = Node2D.new()
	glow.set_script(PLNChargeGlow)
	player.add_child(glow)
	glow.setup(dir, windup_duration, body_scale)

func on_kill(_board: Node2D, _pos: Vector2i, _attack_dir: int) -> void:
	pass

# Called by Board when a DASH kill triggers post-kill reposition.
# Sets state and spawns the board-level slash + deferred move timer.
func begin_kill_anim(
	board: Node2D,
	origin: Vector2i,
	target: Vector2i,
	dir: int,
	slash_length_override: float = -1.0,
	slash_width_override: float = NORMAL_SLASH_WIDTH,
	move_duration_override: float = MOVE_DURATION,
	charge_scale: float = NORMAL_CHARGE_SCALE,
	windup_duration: float = WINDUP,
	is_ult: bool = false
) -> void:
	pending_kill_pos = target
	defer_player_move = true
	board.player_node.play_charge_preview(dir, charge_scale, windup_duration)
	var dv: Vector2i = CharacterData.DIR_VECTOR[dir]
	var slash_fx: Node2D = Node2D.new()
	slash_fx.set_script(PLNSlashEffect)
	slash_fx.position = Vector2(
		origin.x * board.CELL_STEP + board.CELL_SIZE / 2.0,
		origin.y * board.CELL_STEP + board.CELL_SIZE / 2.0
	)
	board.add_child(slash_fx)
	var slash_length: float = NORMAL_SLASH_LENGTH if slash_length_override < 0.0 else slash_length_override
	slash_fx.setup(Vector2(dv), false, windup_duration, true, slash_length, slash_width_override)
	play_attack_sound(board, is_ult)
	board.get_tree().create_timer(windup_duration + 0.03 + 0.10).timeout.connect(
		func(): trigger_move(board, move_duration_override))

func trigger_move(board: Node2D, move_duration: float = MOVE_DURATION) -> void:
	if not defer_player_move:
		return
	defer_player_move = false
	var from_pos: Vector2 = board.player_node.position
	var to_pos := Vector2(
		board.player_pos.x * board.CELL_STEP + board.CELL_SIZE / 2.0,
		board.player_pos.y * board.CELL_STEP + board.CELL_SIZE / 2.0
	)
	if from_pos != to_pos:
		board.player_node.position = to_pos
		board.player_node.play_move(from_pos, move_duration, false)

func resolve_kill_visual() -> void:
	pending_kill_pos = Vector2i(-1, -1)

func play_attack_sound(host: Node2D, is_ult: bool = false) -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = ULT_ATTACK_SOUND if is_ult else ATTACK_SOUND
	host.add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func play_move_sound(host: Node2D) -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = MOVE_SOUND
	host.add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()
