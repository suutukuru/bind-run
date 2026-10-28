class_name Hud
extends CanvasLayer
## 画面上部の HP バー・経験値バー・時間（残り / ボスまで / 経過）・レベル、ボスの HP バーと告知、ポーズボタン。表示だけを担当する。

signal pause_requested
signal pin_requested

@export var run_state_path: NodePath
## 先頭に出す文字（「ステージ 3」「エンドレス」など）
var caption: String = "":
	set(value):
		caption = value
		if _info != null:
			_refresh_info()
## true なら経過時間を出す（エンドレスは生き残った時間が記録になるため）
var show_elapsed: bool = false

var _run_state: RunState
var _boss: Enemy
var _boss_bar: ProgressBar
var _banner: Label
var _banner_time: float = 0.0
var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _info: Label
var _pause: Button
var _pin_button: Button
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


func _process(delta: float) -> void:
	if _run_state == null:
		return
	if _boss != null and (not is_instance_valid(_boss) or _boss.is_dead()):
		_boss = null
		_boss_bar.visible = false
		_refresh_info()
	if _boss != null:
		_boss_bar.max_value = _boss.max_hp()
		_boss_bar.value = _boss.hp
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.visible = _banner_time > 0.0
	# 文字は 1 秒ごとにだけ作り直す
	var shown: int = int(_run_state.elapsed)
	if shown != _shown_second:
		_shown_second = shown
		_refresh_info()


## ボスの HP バーを出し、出現を告知する
func show_boss(boss: Enemy) -> void:
	_boss = boss
	_boss_bar.visible = true
	announce("ボス出現！")
	_refresh_info()


## 固定ボタンの表示（試作）。文字が同じなら何もしない
func set_pin_state(text: String, enabled: bool, shown: bool) -> void:
	if _pin_button == null:
		return
	_pin_button.visible = shown
	_pin_button.disabled = not enabled
	if _pin_button.text != text:
		_pin_button.text = text


## 画面の中央に大きな文字を少しの間だけ出す
func announce(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_time = 2.5


func _time_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if show_elapsed or (_run_state.run_duration <= 0.0 and _run_state.boss_at <= 0.0 and _boss == null):
		parts.append(RunState.format_time(_run_state.elapsed))
	elif _run_state.run_duration > 0.0:
		parts.append(RunState.format_time(ceilf(_run_state.run_duration - _run_state.elapsed)))
	if _boss != null:
		parts.append("ボス戦")
	elif _run_state.boss_at > 0.0:
		parts.append("ボスまで %s" % RunState.format_time(ceilf(_run_state.boss_at - _run_state.elapsed)))
	return "   ".join(parts)


func _build() -> void:
	_hp_bar = _make_bar(Color(0.85, 0.2, 0.2))
	_xp_bar = _make_bar(Color(0.3, 0.6, 1.0))
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	add_child(_info)
	_boss_bar = _make_bar(Color(0.75, 0.15, 0.25))
	_boss_bar.visible = false
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.visible = false
	add_child(_banner)
	_pin_button = Button.new()
	_pin_button.text = "固定"
	_pin_button.focus_mode = Control.FOCUS_NONE
	_pin_button.visible = false
	_pin_button.pressed.connect(func() -> void: pin_requested.emit())
	add_child(_pin_button)
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
	_info.text = "%sLv %d   %s   撃破 %d" % [head, _run_state.level, _time_text(), _run_state.kills]


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
	_boss_bar.position = Vector2(view.x * 0.2, 9.0 * u)
	_boss_bar.size = Vector2(view.x * 0.6, 2.2 * u)
	_boss_bar.custom_minimum_size = _boss_bar.size
	_banner.add_theme_font_size_override("font_size", int(9.0 * u))
	_banner.position = Vector2(0, view.y * 0.3)
	_banner.size = Vector2(view.x, 12.0 * u)
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = int(3.4 * u)
	_pause.theme = ui_theme
	_pin_button.theme = ui_theme
	# 画面の下の中央: 左右の親指が乗る位置の間。押している間は片方の親指がスティックから離れる
	_pin_button.custom_minimum_size = Vector2(24.0 * u, 10.0 * u)
	_pin_button.size = _pin_button.custom_minimum_size
	_pin_button.position = Vector2((view.x - 24.0 * u) * 0.5, view.y - 12.0 * u)
	_pause.custom_minimum_size = Vector2(10.0 * u, 6.0 * u)
	_pause.position = Vector2(1.5 * u, 6.5 * u)
