class_name RopeAttack
extends Node
## 紐攻撃: 紐が張っている（伸び率が閾値以上の）間、紐に触れた敵にダメージを与える。
## 武器とは別のシステムで、互いを参照しない（FR-033）。同じ敵への連続ヒットは間隔で制限する。

@export var rope_path: NodePath

var _rope: Rope
var _clock: float = 0.0


func _init() -> void:
	# 紐の補正（10）の後に判定する
	process_priority = 11


func _ready() -> void:
	_rope = get_node_or_null(rope_path) as Rope
	if _rope == null:
		push_error("RopeAttack: Rope が見つかりません: %s" % rope_path)


func _physics_process(delta: float) -> void:
	step(delta)


## 1 回分の判定。テストから直接呼べるよう分けている
func step(delta: float) -> void:
	_clock += delta
	if _rope == null or _rope.config == null or _rope.stretch_ratios.size() < 2:
		return
	var config: RopeConfig = _rope.config
	var members: Array[Character] = _rope.members()
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var active: bool = false
	for i: int in members.size():
		if _rope.stretch_ratios[i] < config.attack_threshold:
			continue
		active = true
		var end: Vector2 = members[i].global_position
		for node: Node in enemies:
			var enemy: Enemy = node as Enemy
			if enemy == null or enemy.def == null or enemy.is_dead():
				continue
			if enemy.rope_hit_ready_at > _clock:
				continue
			var reach: float = enemy.def.radius + config.attack_half_width
			if RopeModel.distance_to_segment(enemy.global_position, _rope.hub, end) <= reach:
				enemy.take_damage(config.attack_damage * enemy.def.rope_damage_multiplier)
				enemy.rope_hit_ready_at = _clock + config.attack_rehit_interval
	if _rope.pinned and members.size() >= 2:
		active = true
		_hit_inside_triangle(config, members[0].global_position, members[1].global_position, enemies)
	_rope.attack_active = active


# 固定中: 固定の点・A・B の三角形の中（縁を含む）の敵に囲みダメージ。再ヒット間隔は紐攻撃と共通
func _hit_inside_triangle(config: RopeConfig, a: Vector2, b: Vector2, enemies: Array[Node]) -> void:
	for node: Node in enemies:
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.def == null or enemy.is_dead() or enemy.rope_hit_ready_at > _clock:
			continue
		if RopeModel.near_triangle(enemy.global_position, _rope.hub, a, b, enemy.def.radius + config.attack_half_width):
			enemy.take_damage(config.loop_damage * enemy.def.rope_damage_multiplier)
			enemy.rope_hit_ready_at = _clock + config.attack_rehit_interval
