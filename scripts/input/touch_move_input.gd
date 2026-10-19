class_name TouchMoveInput
extends Node2D
## 画面の左半分 / 右半分のドラッグで、対象キャラの move_intent を決める（フローティング仮想スティック）。
## 指を置いた位置が中心になり、そこからのドラッグ量が方向と強さになる。
## CanvasLayer の下に置くと、カメラに影響されず画面座標で動く。
## 1 インスタンスが 1 本の指・1 キャラを担当する（A は LEFT、B は RIGHT）。

enum Side { LEFT, RIGHT }

@export var target_path: NodePath
@export var side: Side = Side.LEFT
## スティックの最大半径（画面座標の px）。ここまで引くと intent の長さが 1 になる
@export var stick_radius: float = 80.0

## 動かす対象。target_path から _ready で解決する
var target: Character

var _finger: int = -1
var _origin: Vector2 = Vector2.ZERO
var _intent: Vector2 = Vector2.ZERO


func _init() -> void:
	# キーボード入力（-10）の後に書き込み、指が触れている間はタッチを優先する
	process_priority = -9


## 指の移動量から intent（長さ 0〜1）を求める。ゼロ除算を避けるため半径 0 以下は 0
static func intent_from_drag(origin: Vector2, position: Vector2, radius: float) -> Vector2:
	if radius <= 0.0:
		return Vector2.ZERO
	return (position - origin).limit_length(radius) / radius


func is_active() -> bool:
	return _finger != -1


func _ready() -> void:
	target = get_node_or_null(target_path) as Character
	if target == null:
		push_error("TouchMoveInput: 対象が見つかりません: %s" % target_path)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _finger == -1 and _is_my_side(touch.position.x):
				_finger = touch.index
				_origin = touch.position
				_intent = Vector2.ZERO
				queue_redraw()
		elif touch.index == _finger:
			_finger = -1
			_intent = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _finger:
			_intent = intent_from_drag(_origin, drag.position, stick_radius)
			queue_redraw()


func _physics_process(_delta: float) -> void:
	# 指が離れている間は書き込まない（キーボード側が毎フレーム intent を決める）
	if target != null and _finger != -1:
		target.move_intent = _intent


func _is_my_side(x: float) -> bool:
	var half: float = get_viewport().get_visible_rect().size.x * 0.5
	return x < half if side == Side.LEFT else x >= half


func _draw() -> void:
	if _finger == -1:
		return
	var color: Color = target.body_color if target != null else Color.WHITE
	draw_circle(_origin, stick_radius, Color(color, 0.15))
	draw_circle(_origin + _intent * stick_radius, 24.0, Color(color, 0.6))
