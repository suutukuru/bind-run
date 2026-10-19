class_name XpOrb
extends Node2D
## 敵が倒れたときに落とす経験値。どちらかのキャラが近づくと吸い寄せられ、触れると経験値になる（共有）。

const RADIUS: float = 8.0
const MAGNET_SPEED: float = 420.0

var value: int = 1
## 拾える距離を持つ EnemySpawner（強化「Magnet」で変わる値の持ち主）
var spawner: EnemySpawner

var _characters: Array[Node] = []
var _run_state: RunState
var _collected: bool = false


func _ready() -> void:
	add_to_group("orbs")
	_characters = get_tree().get_nodes_in_group("characters")
	_run_state = get_tree().get_first_node_in_group("run_state") as RunState


func _physics_process(delta: float) -> void:
	if _collected:
		return
	var nearest: Character = null
	var best: float = INF
	for node: Node in _characters:
		var character: Character = node as Character
		if character == null:
			continue
		var d: float = global_position.distance_to(character.global_position)
		if d < best:
			best = d
			nearest = character
	if nearest == null:
		return
	if best <= Character.RADIUS + RADIUS:
		_collected = true
		if _run_state != null:
			_run_state.add_xp(value)
		queue_free()
		return
	var pickup: float = spawner.orb_pickup_radius if spawner != null else 70.0
	if best <= pickup:
		global_position += (nearest.global_position - global_position) / best * MAGNET_SPEED * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.4, 0.9, 1.0))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, Color(1, 1, 1, 0.7), 2.0)
