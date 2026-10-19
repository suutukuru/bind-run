class_name MenuPanel
extends CanvasLayer
## 中央に出す汎用メニュー: タイトル・ポーズ・レベルアップ・結果で使い回す。
## ゲームを止めている間も動くよう process_mode を ALWAYS にする。表示は英語のみ（標準フォントに日本語がない）。

var _root: Control
var _dim: ColorRect
var _title: Label
var _body: Label
var _buttons: VBoxContainer
var _open: bool = false
var _options: Array = []


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95


func _ready() -> void:
	_build()
	_root.visible = false
	get_viewport().size_changed.connect(_layout)


func is_open() -> bool:
	return _open


func option_count() -> int:
	return _options.size()


## options は {"text": String, "callback": Callable} の配列。押すとメニューを閉じてから callback を呼ぶ
func open(title: String, body: String, options: Array, pause_game: bool = true) -> void:
	_options = options
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	for option: Dictionary in options:
		var button: Button = Button.new()
		button.text = option["text"]
		button.pressed.connect(_choose.bind(option["callback"], pause_game))
		_buttons.add_child(button)
	_open = true
	_root.visible = true
	if pause_game:
		get_tree().paused = true
	_layout()


## 押したのと同じ処理をコードから起こす（テスト用）
func press(index: int) -> void:
	var option: Dictionary = _options[index]
	_choose(option["callback"], get_tree().paused)


func _choose(callback: Callable, was_paused: bool) -> void:
	_open = false
	_root.visible = false
	if was_paused:
		get_tree().paused = false
	callback.call()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_body)
	_buttons = VBoxContainer.new()
	box.add_child(_buttons)


# 文字・ボタンの大きさは画面の短辺に合わせる（縦持ち・横持ちのどちらでも押しやすい大きさにする）
func _layout() -> void:
	if _root == null:
		return
	var u: float = UiScale.unit(get_viewport())
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = int(3.6 * u)
	_root.theme = ui_theme
	_title.add_theme_font_size_override("font_size", int(7.0 * u))
	for child: Node in _buttons.get_children():
		(child as Button).custom_minimum_size = Vector2(70.0 * u, 11.0 * u)
	_buttons.add_theme_constant_override("separation", int(1.5 * u))
