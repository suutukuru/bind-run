class_name Character
extends CharacterBody2D
## 1 体のキャラクター。入力デバイスも紐も知らず、move_intent に従って動くだけ（ADR-004, 005）。
## 紐による位置の補正は Rope の責任で、ここには書かない。

## 見た目の円の半径。CollisionShape2D の半径（character.tscn）と合わせる
const RADIUS: float = 24.0

## 最大移動速度（px/秒）
@export var move_speed: float = 320.0
## A と B を見分けるための色
@export var body_color: Color = Color.WHITE:
	set(value):
		body_color = value
		queue_redraw()

## 動きたい方向。長さ 0〜1。入力ノードが毎フレーム書き込む
var move_intent: Vector2 = Vector2.ZERO


## intent と最大速度から速度を決める。斜めでも速くならないよう長さを 1 以下にする
static func velocity_for(intent: Vector2, speed: float) -> Vector2:
	return intent.limit_length(1.0) * speed


func _init() -> void:
	# 敵や紐より手前に描く
	z_index = 1


func _ready() -> void:
	add_to_group("characters")


func _physics_process(_delta: float) -> void:
	velocity = velocity_for(move_intent, move_speed)
	move_and_slide()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, body_color)
