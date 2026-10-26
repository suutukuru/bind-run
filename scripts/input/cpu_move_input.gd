class_name CpuMoveInput
extends Node
## CPU が対象キャラを動かす（デバッグ用）。敵・ボス・弾から逃げ、何もなければ相方の近くに戻る。
## 人の入力と同じく move_intent を書き込むだけ（ADR-005）。ホームの設定「CPU 担当」で選ぶ。

@export var target_path: NodePath
@export var partner_path: NodePath
## 敵の表面からこの距離以内に入ると逃げ始める（px）
@export var danger_margin: float = 260.0
## 弾は小さくて速いので、見た目より大きく避ける（px）
@export var bullet_extra_radius: float = 50.0
## 何もないとき、相方との距離がこれを超えたら寄っていく（px）。紐の最大長より短くする
@export var stay_distance: float = 300.0

var target: Character
var partner: Character


## 逃げる方向と強さ（長さ 0〜1）を求める純粋な計算。
## threats_pos / threats_radius は同じ長さ。逃げる力は近いほど強く、敵の表面から margin で 0 になる。
## 逃げる必要がなければ、相方から離れすぎている分だけ相方へ寄る。
static func compute_intent(pos: Vector2, partner_pos: Vector2, threats_pos: PackedVector2Array, threats_radius: PackedFloat32Array, margin: float, stay: float) -> Vector2:
	var flee: Vector2 = Vector2.ZERO
	for i: int in threats_pos.size():
		var away: Vector2 = pos - threats_pos[i]
		var dist: float = away.length()
		var gap: float = maxf(dist - threats_radius[i], 0.0)
		if gap >= margin:
			continue
		var closeness: float = 1.0 - gap / margin
		# 真上に重なったときは向きが決まらないので、適当な向きに逃げる
		var direction: Vector2 = away / dist if dist > 0.001 else Vector2.RIGHT
		flee += direction * closeness * closeness
	var to_partner: Vector2 = partner_pos - pos
	var pull: Vector2 = Vector2.ZERO
	if to_partner.length() > stay:
		pull = to_partner.normalized() * minf((to_partner.length() - stay) / stay, 1.0)
	# 逃げる力が強いほど、相方へ寄る力は弱める（危ない所を通って戻らない）
	var flee_strength: float = minf(flee.length(), 1.0)
	return (flee + pull * (1.0 - flee_strength)).limit_length(1.0)


func _init() -> void:
	# キーボード(-10)・タッチ(-9)と同じ段階で、キャラ(0)より先に書き込む
	process_priority = -8


func _ready() -> void:
	target = get_node_or_null(target_path) as Character
	partner = get_node_or_null(partner_path) as Character
	if target == null or partner == null:
		push_error("CpuMoveInput: 対象または相方が見つかりません: %s / %s" % [target_path, partner_path])


func _physics_process(_delta: float) -> void:
	if target == null or partner == null:
		return
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.def == null or enemy.is_dead():
			continue
		positions.append(enemy.global_position)
		radii.append(enemy.def.radius + Character.RADIUS)
	for node: Node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet: EnemyBullet = node as EnemyBullet
		if bullet == null:
			continue
		positions.append(bullet.global_position)
		radii.append(EnemyBullet.RADIUS + Character.RADIUS + bullet_extra_radius)
	target.move_intent = compute_intent(target.global_position, partner.global_position, positions, radii, danger_margin, stay_distance)
