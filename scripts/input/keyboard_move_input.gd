class_name KeyboardMoveInput
extends Node
## キーボードの入力を、対象キャラの move_intent に書き込む。
## action_prefix が "a" なら a_left / a_right / a_up / a_down を読む。

@export var target: Character
@export var action_prefix: String = "a"


func _init() -> void:
	# 入力 → キャラの移動 → 紐の補正、の順で処理するため、キャラ（0）より先に動かす
	process_priority = -10


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	target.move_intent = Input.get_vector(
		action_prefix + "_left",
		action_prefix + "_right",
		action_prefix + "_up",
		action_prefix + "_down",
	)
