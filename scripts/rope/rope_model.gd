class_name RopeModel
extends RefCounted
## ゴム紐の純粋な計算（ノードや描画を知らない）。
## ハブの位置や拘束の方式を変えるときは、ここだけを差し替えればよい（ADR-002, 003）。


## ハブ（接続点）の位置。全メンバーの位置の平均（ADR-002 案 A）。
static func hub_position(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for point: Vector2 in points:
		sum += point
	return sum / float(points.size())


## pos をハブから max_radius 以内に収める。範囲内ならそのまま返す。
## 距離 0 のとき（ゼロ除算）は範囲内として扱うので安全。
static func constrain(pos: Vector2, hub: Vector2, max_radius: float) -> Vector2:
	var radius: float = maxf(max_radius, 0.0)
	var offset: Vector2 = pos - hub
	var dist: float = offset.length()
	if dist <= radius:
		return pos
	return hub + offset / dist * radius


## 伸び率 0.0（たるみ）〜 1.0（伸びきり）。natural 以下は 0、max_radius 以上は 1。
static func stretch_ratio(dist: float, natural: float, max_radius: float) -> float:
	if max_radius <= natural:
		return 1.0 if dist >= max_radius else 0.0
	return clampf((dist - natural) / (max_radius - natural), 0.0, 1.0)


## 伸びたゴムの引き戻し。自然長を超えた分に比例して、pos をハブ側へ寄せる。
## 1 フレームで自然長より内側へ行き過ぎないよう、寄せる量は超過分を上限にする。
static func elastic_pull(pos: Vector2, hub: Vector2, natural: float, stiffness: float, delta: float) -> Vector2:
	var offset: Vector2 = pos - hub
	var dist: float = offset.length()
	var excess: float = dist - natural
	if stiffness <= 0.0 or excess <= 0.0 or dist <= 0.0:
		return pos
	var step: float = minf(excess, excess * stiffness * delta)
	return pos - offset / dist * step


## 慣性ハブ: ハブが目標位置に遅れてついてくる（ADR-002 案 B）。rate が 0 以下なら遅れなし。
static func follow_hub(current: Vector2, target: Vector2, rate: float, delta: float) -> Vector2:
	if rate <= 0.0:
		return target
	return current.lerp(target, minf(1.0, rate * delta))


## 点 p と線分 a-b の距離（紐攻撃の当たり判定に使う）
static func distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
