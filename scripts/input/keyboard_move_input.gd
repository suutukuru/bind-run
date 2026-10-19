class_name KeyboardMoveInput
extends Node
## キーボードの入力を、対象キャラの move_intent に書き込む。
## action_prefix が "a" なら a_left / a_right / a_up / a_down を読む。

@export var target_path: NodePath
@export var action_prefix: String = "a"

## 動かす対象。target_path から _ready で解決する（Rope と同じ方式）
var target: Character


func _init() -> void:
	# 入力 → キャラの移動 → 紐の補正、の順で処理するため、キャラ（0）より先に動かす
	process_priority = -10


func _ready() -> void:
	target = get_node_or_null(target_path) as Character
	if target == null:
		push_error("KeyboardMoveInput: 対象が見つかりません: %s" % target_path)


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	target.move_intent = Input.get_vector(
		action_prefix + "_left",
		action_prefix + "_right",
		action_prefix + "_up",
		action_prefix + "_down",
	)
