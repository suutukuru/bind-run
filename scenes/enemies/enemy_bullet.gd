class_name EnemyBullet
extends Node2D
## ボスの弾。まっすぐ飛び、キャラに触れると共有 HP にダメージを与えて消える。
## 物理エンジンは使わず距離で判定する（ADR-014）。紐や武器では消せない（避けるもの）。

const RADIUS: float = 9.0
## 画面外へ飛んでいった弾を消すまでの時間（秒）
const LIFETIME: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 8.0

var _age: float = 0.0
var _characters: Array[Node] = []
var _run_state: RunState


func _ready() -> void:
	add_to_group("enemy_bullets")
	_characters = get_tree().get_nodes_in_group("characters")
	_run_state = get_tree().get_first_node_in_group("run_state") as RunState


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	for node: Node in _characters:
		var character: Character = node as Character
		if character == null:
			continue
		if global_position.distance_to(character.global_position) <= RADIUS + Character.RADIUS:
			if _run_state != null:
				_run_state.take_damage(damage)
			queue_free()
			return


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.35, 0.8))
	draw_circle(Vector2.ZERO, RADIUS * 0.45, Color.WHITE)
