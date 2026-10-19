class_name Enemy
extends Node2D
## 敵 1 体。最も近いキャラへ向かって進み、触れると共有 HP にダメージを与える。
## 物理エンジンは使わず距離の計算だけで判定する。敵が増えても軽く、
## 武器・紐攻撃の判定も同じ「距離の計算」に揃えられるため。

signal died(enemy: Enemy)

## 同じ敵が続けて接触ダメージを与える間隔（秒）
const CONTACT_INTERVAL: float = 0.7

var def: EnemyDef
var hp: float = 1.0
## 紐攻撃で次にダメージを受けられる時刻（RopeAttack の時計で測る）
var rope_hit_ready_at: float = 0.0

var _contact_cooldown: float = 0.0
var _flash: float = 0.0
var _dead: bool = false
var _characters: Array[Node] = []
var _run_state: RunState


func _ready() -> void:
	add_to_group("enemies")
	if def == null:
		push_error("Enemy: def が未設定です")
		return
	hp = def.max_hp
	_characters = get_tree().get_nodes_in_group("characters")
	_run_state = get_tree().get_first_node_in_group("run_state") as RunState


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	_flash = 0.1
	queue_redraw()
	if hp <= 0.0:
		_dead = true
		died.emit(self)
		queue_free()


func is_dead() -> bool:
	return _dead


func _physics_process(delta: float) -> void:
	if def == null or _dead:
		return
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()
	var target: Character = _nearest_character()
	if target == null:
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	if dist > 0.001:
		global_position += to_target / dist * def.move_speed * delta

	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	if dist <= def.radius + Character.RADIUS and _contact_cooldown <= 0.0 and _run_state != null:
		_run_state.take_damage(def.contact_damage)
		_contact_cooldown = CONTACT_INTERVAL


func _nearest_character() -> Character:
	var best: Character = null
	var best_dist: float = INF
	for node: Node in _characters:
		var character: Character = node as Character
		if character == null:
			continue
		var d: float = global_position.distance_squared_to(character.global_position)
		if d < best_dist:
			best_dist = d
			best = character
	return best


func _draw() -> void:
	if def == null:
		return
	var fill: Color = def.color.lerp(Color.WHITE, 0.8) if _flash > 0.0 else def.color
	draw_circle(Vector2.ZERO, def.radius, fill)
	draw_arc(Vector2.ZERO, def.radius, 0.0, TAU, 24, Color(0, 0, 0, 0.5), 3.0)
