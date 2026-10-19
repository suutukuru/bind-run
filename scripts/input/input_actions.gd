class_name InputActions
extends RefCounted
## キーボード操作の割り当て。InputMap に実行時に登録する。
## project.godot に手書きせずコードで登録する理由: エディタを開けない環境でも
## 割り当てをテストで検証でき、間違った書式で起動できなくなる事故を避けられる。
## ゲームパッドやタッチはここではなく、別の入力ノードで扱う（ADR-005）。

const KEYS: Dictionary = {
	"a_left": KEY_A,
	"a_right": KEY_D,
	"a_up": KEY_W,
	"a_down": KEY_S,
	"b_left": KEY_LEFT,
	"b_right": KEY_RIGHT,
	"b_up": KEY_UP,
	"b_down": KEY_DOWN,
	"debug_toggle_hub": KEY_F1,
	"debug_toggle_overlay": KEY_F3,
}


## 未登録のアクションだけを登録する（何度呼んでもイベントが重複しない）
static func register() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event: InputEventKey = InputEventKey.new()
		# 物理キー位置で指定すると、キー配列が違っても WASD の並びで使える
		event.physical_keycode = KEYS[action]
		InputMap.action_add_event(action, event)
