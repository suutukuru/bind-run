class_name FollowCamera
extends Camera2D
## ハブに追従し、画面の短辺に映るワールドの長さを一定に保つ。
## 画面設定が expand のため、縦持ちでは見える範囲が縦に大きく広がり、そのままだと
## キャラが点のように小さくなる。ズームで補正して、縦持ち・横持ちのどちらでも同じ大きさに見せる。

@export var rope_path: NodePath
## 画面の短辺に映すワールド座標の長さ（px）
@export var view_short_side: float = 1350.0

var _rope: Rope


## 画面の短辺に view_short_side だけ映すためのズーム倍率
static func zoom_for(viewport_size: Vector2, short_side_world: float) -> float:
	if short_side_world <= 0.0:
		return 1.0
	return minf(viewport_size.x, viewport_size.y) / short_side_world


func _ready() -> void:
	_rope = get_node_or_null(rope_path) as Rope
	if _rope == null:
		push_error("FollowCamera: Rope が見つかりません: %s" % rope_path)
	_update_view()


func _process(_delta: float) -> void:
	_update_view()


## 今映っているワールドの大きさ（px）
func visible_world_size() -> Vector2:
	return get_viewport_rect().size / zoom


func _update_view() -> void:
	var factor: float = zoom_for(get_viewport_rect().size, view_short_side)
	zoom = Vector2(factor, factor)
	if _rope != null:
		global_position = _rope.view_center()
