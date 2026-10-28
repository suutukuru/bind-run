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

## 固定中か。固定中はハブが平均に追従せず、固定した点のまま（ハブの表示とは無関係に、ロジックはこの値で動く）
var pinned: bool = false
var pin_time_left: float = 0.0
var pin_cooldown_left: float = 0.0

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
	pin_cooldown_left = maxf(0.0, pin_cooldown_left - delta)
	if pinned:
		pin_time_left -= delta
		if pin_time_left <= 0.0 or config.pin_mode == RopeConfig.PIN_OFF:
			set_pinned(false)
	if pinned:
		_step_pinned(delta)
		queue_redraw()
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


## いま固定を始められるか（モードが有効で、固定中でなく、待ち時間が終わっている）
func can_pin() -> bool:
	return config != null and config.pin_mode != RopeConfig.PIN_OFF and not pinned and pin_cooldown_left <= 0.0


## 固定の開始 / 解除。解除すると待ち時間が始まる。始められないときは何もしない
func set_pinned(on: bool) -> void:
	if on == pinned:
		return
	if on:
		if not can_pin():
			return
		pinned = true
		pin_time_left = config.pin_max_seconds
	else:
		pinned = false
		pin_cooldown_left = config.pin_cooldown
	queue_redraw()


func toggle_pin() -> void:
	set_pinned(not pinned)


## カメラが映す中心。固定中はハブ（固定の点）ではなく 2 人の中心を映す（固定の点は端に寄ることがあるため）
func view_center() -> Vector2:
	if pinned:
		return RopeModel.hub_position(_member_positions())
	return hub


# 固定中: ハブは固定の点のまま（錨モードでは最大長を超えた分だけゆっくり動く）。弾性は使わない
# （自然長で引き戻されると、最大長まで広げて囲む形が作れないため）
func _step_pinned(delta: float) -> void:
	if config.pin_mode == RopeConfig.PIN_DRAG:
		hub = RopeModel.drag_anchor(hub, _member_positions(), config.max_radius, config.pin_drag_speed * delta)
	stretch_ratios.resize(_members.size())
	for i: int in _members.size():
		var member: Character = _members[i]
		var pos: Vector2 = RopeModel.constrain(member.global_position, hub, config.max_radius)
		member.global_position = pos
		stretch_ratios[i] = RopeModel.stretch_ratio(pos.distance_to(hub), config.natural_radius, config.max_radius)


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
	if pinned and _members.size() >= 2:
		_draw_pin(hub_local)
	for i: int in _members.size():
		var ratio: float = stretch_ratios[i]
		# 張るほど細く・赤くして、限界が近いことを見た目で伝える
		var end: Vector2 = to_local(_members[i].global_position)
		if attack_active:
			# 紐攻撃が有効な間は当たり判定と同じ太さの光を重ねて、触れると痛い範囲を伝える
			draw_line(hub_local, end, Color(1, 1, 1, 0.35), config.attack_half_width * 2.0, true)
		draw_line(hub_local, end, color_for_stretch(ratio), 6.0 - 3.0 * ratio, true)
	if show_hub:
		draw_circle(hub_local, 5.0, Color.WHITE)


# 固定中の見た目: 囲みの三角形（塗り + 縁）と、固定の点（残り時間の輪つき）
func _draw_pin(hub_local: Vector2) -> void:
	var a: Vector2 = to_local(_members[0].global_position)
	var b: Vector2 = to_local(_members[1].global_position)
	# 三角形がつぶれているとき（3 点が一直線）は塗れない
	if absf((a - hub_local).cross(b - hub_local)) > 100.0:
		draw_colored_polygon(PackedVector2Array([hub_local, a, b]), Color(1.0, 0.85, 0.3, 0.18))
	draw_line(a, b, Color(1.0, 0.85, 0.3, 0.8), 4.0, true)
	draw_circle(hub_local, 9.0, Color(1.0, 0.85, 0.3))
	var fraction: float = clampf(pin_time_left / maxf(config.pin_max_seconds, 0.001), 0.0, 1.0)
	draw_arc(hub_local, 20.0, -PI * 0.5, -PI * 0.5 + TAU * fraction, 32, Color(1.0, 0.85, 0.3), 4.0, true)
