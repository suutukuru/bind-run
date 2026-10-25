class_name Hud
extends CanvasLayer
## 画面上部の HP バー・経験値バー・残り時間（エンドレスでは経過時間）・レベル、ポーズボタン。表示だけを担当する。

signal pause_requested

@export var run_state_path: NodePath
## 先頭に出す文字（「ステージ 3」「エンドレス」など）
var caption: String = "":
	set(value):
		caption = value
		if _info != null:
			_refresh_info()

var _run_state: RunState
var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _info: Label
var _pause: Button
var _shown_second: int = -1


func _ready() -> void:
	layer = 80
	_run_state = get_node_or_null(run_state_path) as RunState
	if _run_state == null:
		push_error("Hud: RunState が見つかりません: %s" % run_state_path)
		return
	_build()
	_run_state.hp_changed.connect(_on_hp_changed)
	_run_state.xp_changed.connect(_on_xp_changed)
	_on_hp_changed(_run_state.hp, _run_state.max_hp)
	_on_xp_changed(_run_state.xp, RunState.xp_needed(_run_state.level), _run_state.level)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _process(_delta: float) -> void:
	if _run_state == null:
		return
	# 文字は 1 秒ごとにだけ作り直す
	var shown: int = _shown_time()
	if shown != _shown_second:
		_shown_second = shown
		_refresh_info()


# 時間制限があれば残り時間、なければ（エンドレス）経過時間
func _shown_time() -> int:
	if _run_state.run_duration <= 0.0:
		return int(_run_state.elapsed)
	return maxi(0, ceili(_run_state.run_duration - _run_state.elapsed))


func _build() -> void:
	_hp_bar = _make_bar(Color(0.85, 0.2, 0.2))
	_xp_bar = _make_bar(Color(0.3, 0.6, 1.0))
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	add_child(_info)
	_pause = Button.new()
	_pause.text = "II"
	_pause.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause)


func _make_bar(color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.5)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	return bar


func _on_hp_changed(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func _on_xp_changed(xp: int, needed: int, _level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = xp
	_refresh_info()


func _refresh_info() -> void:
	var head: String = caption + "   " if caption != "" else ""
	_info.text = "%sLv %d   %s   撃破 %d" % [head, _run_state.level, RunState.format_time(_shown_time()), _run_state.kills]


# 画面の大きさ（向き）が変わるたびに、バー・文字・ボタンの大きさと位置を合わせ直す
func _layout() -> void:
	var u: float = UiScale.unit(get_viewport())
	var view: Vector2 = get_viewport().get_visible_rect().size
	_hp_bar.position = Vector2.ZERO
	_hp_bar.size = Vector2(view.x, 2.4 * u)
	_hp_bar.custom_minimum_size = _hp_bar.size
	_xp_bar.position = Vector2(0, 2.4 * u)
	_xp_bar.size = Vector2(view.x, 1.2 * u)
	_xp_bar.custom_minimum_size = _xp_bar.size
	_info.add_theme_font_size_override("font_size", int(3.4 * u))
	_info.position = Vector2(0, 4.0 * u)
	_info.size = Vector2(view.x, 4.5 * u)
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = int(3.4 * u)
	_pause.theme = ui_theme
	_pause.custom_minimum_size = Vector2(10.0 * u, 6.0 * u)
	_pause.position = Vector2(1.5 * u, 6.5 * u)
