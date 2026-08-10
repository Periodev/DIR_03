class_name CharacterData

enum Direction { NONE = 0, UP = 1, DOWN = 2, LEFT = 3, RIGHT = 4, NEUTRAL = 5 }

enum CellType { LIVE, DEAD }

enum AttackMode { DASH, STRIKE }

enum GameStateEnum { IDLE, PRESENTING, GAME_OVER }

const DIR_VECTOR := {
	Direction.UP:    Vector2i(0, -1),
	Direction.DOWN:  Vector2i(0, 1),
	Direction.LEFT:  Vector2i(-1, 0),
	Direction.RIGHT: Vector2i(1, 0),
}

const OPPOSITE := {
	Direction.UP:    Direction.DOWN,
	Direction.DOWN:  Direction.UP,
	Direction.LEFT:  Direction.RIGHT,
	Direction.RIGHT: Direction.LEFT,
}

const DIR_ARROWS := {
	Direction.NONE:    "",
	Direction.UP:      "^",
	Direction.DOWN:    "v",
	Direction.LEFT:    "<",
	Direction.RIGHT:   ">",
	Direction.NEUTRAL: "○",
}

const CHARACTERS := {
	"PLN": {
		"seq":       4,
		"has_hold":  false,
		"has_charge_marker": false,
		"charge_max": 0,
		"has_ult":   true,
		"attack_mode": AttackMode.DASH,
		"has_pierce": false,
		"color":     Color(0.2, 0.8, 0.3),
		"shape":     "blade_diamond",
	},
}

static func key_to_direction(keycode: Key) -> Direction:
	match keycode:
		KEY_UP, KEY_W:
			return Direction.UP
		KEY_DOWN, KEY_S:
			return Direction.DOWN
		KEY_LEFT, KEY_A:
			return Direction.LEFT
		KEY_RIGHT, KEY_D:
			return Direction.RIGHT
		_:
			return Direction.NONE
