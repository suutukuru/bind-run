class_name GridBackground
extends Node2D
## 床のマス目。ワールド座標に固定された線なので、動くとマス目が流れて移動量が分かる。
## 無限に続くように、カメラに映る範囲だけを毎フレーム描く。

@export var camera_path: NodePath
## 1 マスの大きさ（px）。キャラの直径（48）の約 2 倍
@export var cell_size: float = 100.0
## 太い線を引く間隔（マス数）。距離の目安になる
@export var major_every: int = 5
@export var minor_color: Color = Color(1, 1, 1, 0.07)
@export var major_color: Color = Color(1, 1, 1, 0.16)

var _camera: FollowCamera


## 範囲 [from, to] に入る線の番号（cell_size 単位）を返す
static func line_indices(from: float, to: float, size: float) -> Array[int]:
	var result: Array[int] = []
	if size <= 0.0 or to < from:
		return result
	var first: int = ceili(from / size)
	var last: int = floori(to / size)
	for i: int in range(first, last + 1):
		result.append(i)
	return result


func _ready() -> void:
	z_index = -10  # 紐(-1)・キャラ(1)より後ろ
	_camera = get_node_or_null(camera_path) as FollowCamera
	if _camera == null:
		push_error("GridBackground: Camera が見つかりません: %s" % camera_path)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _camera == null:
		return
	var half: Vector2 = _camera.visible_world_size() * 0.5
	var center: Vector2 = _camera.global_position
	var left: float = center.x - half.x
	var right: float = center.x + half.x
	var top: float = center.y - half.y
	var bottom: float = center.y + half.y
	# 線の太さが拡大縮小で変わらないよう、画面上で約 1.5px になるよう補正する
	var width: float = 1.5 / maxf(_camera.zoom.x, 0.01)
	for i: int in line_indices(left, right, cell_size):
		var x: float = i * cell_size
		draw_line(Vector2(x, top), Vector2(x, bottom), _color_for(i), width)
	for j: int in line_indices(top, bottom, cell_size):
		var y: float = j * cell_size
		draw_line(Vector2(left, y), Vector2(right, y), _color_for(j), width)


func _color_for(index: int) -> Color:
	return major_color if index % major_every == 0 else minor_color
