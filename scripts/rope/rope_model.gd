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
