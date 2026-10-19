class_name TuningPanel
extends CanvasLayer
## 紐のパラメータをスマホ上で触って、手触りを比べるための調整パネル（TASK-022）。
## 値は Rope が持つ config の複製を直接書き換える（元の .tres は変わらない）。
## 表示は英語のみ: Web 版の標準フォントには日本語の文字が入っていないため。

@export var rope_path: NodePath
@export var overlay_path: NodePath

## [プロパティ名, 表示名, 最小, 最大, 刻み]
const SLIDERS: Array = [
	["max_radius", "Max length", 60.0, 400.0, 5.0],
	["natural_radius", "Slack length", 0.0, 300.0, 5.0],
	["stiffness", "Elastic pull", 0.0, 12.0, 0.5],
	["hub_follow_rate", "Hub inertia", 0.0, 20.0, 0.5],
	["attack_damage", "Rope damage", 1.0, 60.0, 1.0],
	["attack_threshold", "Rope attack at", 0.3, 1.0, 0.05],
]

var _rope: Rope
var _overlay: DebugOverlay
var _root: Control
var _toggle: Button
var _panel: PanelContainer
var _mode: OptionButton
var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}


func _ready() -> void:
	layer = 90
	_rope = get_node_or_null(rope_path) as Rope
	_overlay = get_node_or_null(overlay_path) as DebugOverlay
	if _rope == null or _rope.config == null:
		push_error("TuningPanel: Rope が見つかりません: %s" % rope_path)
		return
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()


## スライダーと同じ経路で値を変える（テストからも呼べる）
func set_param(property: String, value: float) -> void:
	_rope.config.set(property, value)
	_update_label(property)


func set_limit_mode(index: int) -> void:
	_rope.config.limit_mode = index


func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_toggle = Button.new()
	_toggle.text = "TUNE"
	_toggle.pressed.connect(func() -> void: _panel.visible = not _panel.visible)
	_root.add_child(_toggle)

	_panel = PanelContainer.new()
	_panel.visible = false
	_root.add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	_panel.add_child(box)

	for def: Array in SLIDERS:
		var property: String = def[0]
		var row: HBoxContainer = HBoxContainer.new()
		box.add_child(row)
		var label: Label = Label.new()
		_value_labels[property] = label
		row.add_child(label)
		var slider: HSlider = HSlider.new()
		slider.min_value = def[2]
		slider.max_value = def[3]
		slider.step = def[4]
		slider.value = _rope.config.get(property)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(func(v: float) -> void: set_param(property, v))
		_sliders[property] = slider
		row.add_child(slider)
		_update_label(property)

	_mode = OptionButton.new()
	_mode.add_item("Limit: drag partner")
	_mode.add_item("Limit: block")
	_mode.selected = _rope.config.limit_mode
	_mode.item_selected.connect(set_limit_mode)
	box.add_child(_mode)

	var hub_check: CheckButton = CheckButton.new()
	hub_check.text = "Show hub dot"
	hub_check.button_pressed = _rope.show_hub
	hub_check.toggled.connect(func(on: bool) -> void: _rope.show_hub = on)
	box.add_child(hub_check)

	if _overlay != null:
		var text_check: CheckButton = CheckButton.new()
		text_check.text = "Show debug text"
		text_check.button_pressed = true
		text_check.toggled.connect(func(on: bool) -> void: _overlay.set_text_visible(on))
		box.add_child(text_check)


func _update_label(property: String) -> void:
	for def: Array in SLIDERS:
		if def[0] == property:
			var value: float = _rope.config.get(property)
			(_value_labels[property] as Label).text = "%s %s" % [def[1], str(snappedf(value, 0.01))]


# 画面の大きさ（向き）が変わるたびに、文字・ボタン・パネルの大きさと位置を合わせ直す
func _layout() -> void:
	var u: float = UiScale.unit(get_viewport())
	var view: Vector2 = get_viewport().get_visible_rect().size
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = int(3.0 * u)
	_root.theme = ui_theme
	var margin: float = 1.5 * u
	var top: float = 6.5 * u  # HUD のバーの下
	_toggle.custom_minimum_size = Vector2(12.0 * u, 6.0 * u)
	_toggle.position = Vector2(view.x - 12.0 * u - margin, top)
	_panel.position = Vector2(view.x - 58.0 * u - margin, top + 7.5 * u)
	for property: String in _sliders:
		(_sliders[property] as HSlider).custom_minimum_size = Vector2(26.0 * u, 5.0 * u)
		(_value_labels[property] as Label).custom_minimum_size = Vector2(28.0 * u, 0)
