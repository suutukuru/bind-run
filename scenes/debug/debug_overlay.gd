class_name DebugOverlay
extends CanvasLayer
## 開発用の状態表示。画面が見えない・動かないといった報告を、数値で受け取れるようにする。
## F3 で表示切替（キーボードがある環境）。

@export var rope_path: NodePath

var _rope: Rope
var _label: Label
var _elapsed: float = 0.0


func _ready() -> void:
	layer = 100
	_rope = get_node_or_null(rope_path) as Rope
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh()


func _process(delta: float) -> void:
	# 毎フレーム文字を作り直すと重いので、0.2 秒ごとに更新する
	_elapsed += delta
	if _elapsed >= 0.2:
		_elapsed = 0.0
		_refresh()


func set_text_visible(on: bool) -> void:
	_label.visible = on
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_overlay"):
		_label.visible = not _label.visible


func _refresh() -> void:
	if _label == null or not _label.visible:
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	# 文字の大きさは画面の短辺に比例させる（端末が違っても読める大きさにする）
	_label.add_theme_font_size_override("font_size", int(minf(view.x, view.y) * 0.03))
	_label.position = Vector2(UiScale.unit(get_viewport()) * 1.5, UiScale.unit(get_viewport()) * 14.0)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("FPS %d  view %dx%d  win %s" % [Engine.get_frames_per_second(), view.x, view.y, str(DisplayServer.window_get_size())])
	if _rope != null and _rope.stretch_ratios.size() >= 2:
		var members: Array[Character] = _rope.members()
		lines.append("A %s  B %s" % [str(members[0].global_position.round()), str(members[1].global_position.round())])
		lines.append("dist %d  stretch %.2f / %.2f" % [members[0].global_position.distance_to(members[1].global_position), _rope.stretch_ratios[0], _rope.stretch_ratios[1]])
	lines.append("enemies %d" % get_tree().get_nodes_in_group("enemies").size())
	_label.text = "\n".join(lines)
