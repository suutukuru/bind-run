class_name Rope
extends Node2D
## メンバー（キャラ）をゴム紐でつなぐ。毎物理フレーム、ハブを計算し、
## 最大長を超えたキャラの位置を戻す。計算そのものは RopeModel に任せる。
## キャラの移動の「後」に動かすため process_priority を大きくする（入力 -10 → キャラ 0 → 紐 10）。

@export var member_paths: Array[NodePath] = []
@export var config: RopeConfig
## ハブの点を描くか。見た目だけの設定で、ロジックは参照しない（FR-008）
@export var show_hub: bool = true:
	set(value):
		show_hub = value
		queue_redraw()

## 紐攻撃が有効な間 true（RopeAttack が書く）。見た目の強調にだけ使う
var attack_active: bool = false:
	set(value):
		if value != attack_active:
			attack_active = value
			queue_redraw()

## 最新のハブ位置。表示の有無に関係なく、ロジックはこの値だけを使う（FR-008）
var hub: Vector2 = Vector2.ZERO
## メンバーごとの伸び率（0.0 たるみ 〜 1.0 伸びきり）。member_paths と同じ順
var stretch_ratios: PackedFloat32Array = PackedFloat32Array()

var _members: Array[Character] = []


func _init() -> void:
	process_priority = 10
	# 紐はキャラクターの下に描く
	z_index = -1


## 伸び率に応じた紐の色: 白（たるみ）→ 黄 → 赤（伸びきり）
static func color_for_stretch(ratio: float) -> Color:
	var t: float = clampf(ratio, 0.0, 1.0)
	if t < 0.5:
		return Color.WHITE.lerp(Color.YELLOW, t * 2.0)
	return Color.YELLOW.lerp(Color.RED, (t - 0.5) * 2.0)


func _ready() -> void:
	if config == null:
		push_error("Rope: config が未設定です")
	else:
		# 調整パネルで値を変えても、元の .tres（共有リソース）を書き換えないよう複製する
		config = config.duplicate()
	for path: NodePath in member_paths:
		var member: Character = get_node_or_null(path) as Character
		if member == null:
			push_error("Rope: メンバーが見つかりません: %s" % path)
		else:
			_members.append(member)
	if _members.size() < 2:
		push_error("Rope: メンバーが 2 人未満です")
		return
	# カメラが最初のフレームから正しい位置を向けるよう、ハブだけ先に求めておく
	hub = RopeModel.hub_position(_member_positions())


func _physics_process(delta: float) -> void:
	step(delta)


## 1 回分の更新。テストから直接呼べるよう、_physics_process と分けている。
## 1) ハブを決める  2) 自然長を超えた分を引き戻す（弾性）  3) 最大長を超えないよう位置を戻す（限界）
func step(delta: float = 1.0 / 60.0) -> void:
	if config == null or _members.size() < 2:
		return
	var mean: Vector2 = RopeModel.hub_position(_member_positions())
	var block: bool = config.limit_mode == RopeConfig.BLOCK
	if not block:
		# DRAG: 移動後の位置からハブを決める。押した側が止まる分、ハブが動いて相方も引きずられる
		hub = RopeModel.follow_hub(hub, mean, config.hub_follow_rate, delta)

	# BLOCK: 前フレームのハブを基準にする。押した側はその円で止まり、相方は引きずられない
	var center: Vector2 = hub
	stretch_ratios.resize(_members.size())
	for i: int in _members.size():
		var member: Character = _members[i]
		var pos: Vector2 = RopeModel.elastic_pull(
			member.global_position, center, config.natural_radius, config.stiffness, delta
		)
		pos = RopeModel.constrain(pos, center, config.max_radius)
		member.global_position = pos
		stretch_ratios[i] = RopeModel.stretch_ratio(
			pos.distance_to(center), config.natural_radius, config.max_radius
		)

	if block:
		hub = RopeModel.follow_hub(hub, RopeModel.hub_position(_member_positions()), config.hub_follow_rate, delta)
	queue_redraw()


## つながっているキャラ（読み取り用のコピー）
func members() -> Array[Character]:
	return _members.duplicate()


func _member_positions() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for member: Character in _members:
		points.append(member.global_position)
	return points


func _draw() -> void:
	if config == null or stretch_ratios.size() != _members.size():
		return
	var hub_local: Vector2 = to_local(hub)
	for i: int in _members.size():
		var ratio: float = stretch_ratios[i]
		# 張るほど細く・赤くして、限界が近いことを見た目で伝える
		var end: Vector2 = to_local(_members[i].global_position)
		if attack_active:
			# 紐攻撃が有効な間は太い光を重ねて、触れると痛いことを伝える
			draw_line(hub_local, end, Color(1, 1, 1, 0.35), 18.0, true)
		draw_line(hub_local, end, color_for_stretch(ratio), 6.0 - 3.0 * ratio, true)
	if show_hub:
		draw_circle(hub_local, 5.0, Color.WHITE)
