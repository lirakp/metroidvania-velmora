class_name InputSetup
extends RefCounted
## Legt die Eingabe-Aktionen (Tastatur + Gamepad) zur Laufzeit an.

const KEYS := {
	"links": [KEY_A, KEY_LEFT],
	"rechts": [KEY_D, KEY_RIGHT],
	"springen": [KEY_SPACE],
	"schlagen": [KEY_J],
	"befehl": [KEY_K],
	"karte": [KEY_M],
	"interagieren": [KEY_W, KEY_UP],
	"runter": [KEY_S, KEY_DOWN],
}
const PAD := {
	"springen": JOY_BUTTON_A,
	"schlagen": JOY_BUTTON_X,
	"befehl": JOY_BUTTON_Y,
	"karte": JOY_BUTTON_BACK,
	"links": JOY_BUTTON_DPAD_LEFT,
	"rechts": JOY_BUTTON_DPAD_RIGHT,
	"interagieren": JOY_BUTTON_DPAD_UP,
	"runter": JOY_BUTTON_DPAD_DOWN,
}


static func ensure() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.3)
		for k in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		if PAD.has(action):
			var jb := InputEventJoypadButton.new()
			jb.button_index = PAD[action]
			InputMap.action_add_event(action, jb)
	for pair in [["links", JOY_AXIS_LEFT_X, -1.0], ["rechts", JOY_AXIS_LEFT_X, 1.0]]:
		var jm := InputEventJoypadMotion.new()
		jm.axis = pair[1]
		jm.axis_value = pair[2]
		InputMap.action_add_event(pair[0], jm)
