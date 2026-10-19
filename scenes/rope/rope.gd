class_name Rope
extends Node2D
## メンバー（キャラ）をゴム紐でつなぐ。毎物理フレーム、ハブを計算し、
## 最大長を超えたキャラの位置を戻す。計算そのものは RopeModel に任せる。
## キャラの移動の「後」に動かすため process_priority を大きくする（入力 -10 → キャラ 0 → 紐 10）。

@export var member_paths: Array[NodePath] = []
@export var config: RopeConfig

## 最新のハブ位置。表示の有無に関係なく、ロジックはこの値だけを使う（FR-008）
var hub: Vector2 = Vector2.ZERO
## メンバーごとの伸び率（0.0 たるみ 〜 1.0 伸びきり）。member_paths と同じ順
var stretch_ratios: PackedFloat32Array = PackedFloat32Array()

var _members: Array[Character] = []


func _init() -> void:
	process_priority = 10


func _ready() -> void:
	if config == null:
		push_error("Rope: config が未設定です")
	for path: NodePath in member_paths:
		var member: Character = get_node_or_null(path) as Character
		if member == null:
			push_error("Rope: メンバーが見つかりません: %s" % path)
		else:
			_members.append(member)
	if _members.size() < 2:
		push_error("Rope: メンバーが 2 人未満です")


func _physics_process(_delta: float) -> void:
	step()


## 1 回分の更新。テストから直接呼べるよう、_physics_process と分けている
func step() -> void:
	if config == null or _members.size() < 2:
		return
	var points: PackedVector2Array = PackedVector2Array()
	for member: Character in _members:
		points.append(member.global_position)
	# ハブは補正前の位置から 1 回だけ計算し、全員に同じハブを使う
	hub = RopeModel.hub_position(points)

	stretch_ratios.resize(_members.size())
	for i: int in _members.size():
		var member: Character = _members[i]
		var fixed: Vector2 = RopeModel.constrain(member.global_position, hub, config.max_radius)
		member.global_position = fixed
		stretch_ratios[i] = RopeModel.stretch_ratio(
			fixed.distance_to(hub), config.natural_radius, config.max_radius
		)
