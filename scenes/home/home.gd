class_name Home
extends Control
## ホーム画面。下のツールバー（左から ？？？・装備・ホーム・ガチャ・設定）で画面を切り替える。
## ホームからステージ（番号順に開放）とエンドレスを始める。装備・ガチャ・？？？は画面の枠だけ（中身は未定）。
## UI はコードで組み立てる: 文字やボタンの大きさを画面の短辺（UiScale）に合わせて作り直すため。

const GAME_SCENE: String = "res://scenes/main/main.tscn"
## ツールバーの並び（左から）。中央がホーム
const TAB_NAMES: Array = ["？？？", "装備", "ホーム", "ガチャ", "設定"]
const TAB_UNDECIDED: int = 0
const TAB_EQUIPMENT: int = 1
const TAB_HOME: int = 2
const TAB_GACHA: int = 3
const TAB_SETTINGS: int = 4
## 設定の項目 [保存キー, 表示名, 既定値]。本編（Main）が同じキーを読む
const SETTINGS: Array = [
	["show_tuning", "調整ボタンを表示（開発用）", true],
	["debug_text", "デバッグ文字を表示（開発用）", true],
	["show_hub", "紐の中心（ハブ）を表示", false],
]
## 設定「CPU 担当」の選択肢（Main の CPU_NONE / CPU_BLUE / CPU_ORANGE と同じ順）
const CPU_CHOICES: Array = ["自分で両方を操作", "青（A）を CPU に任せる", "橙（B）を CPU に任せる"]
## 文字の折り返す幅の基準（_layout で px にする）
const WRAP_PAGE: int = 0
const WRAP_CARD: int = 1
const WRAP_HOME_CARD: int = 2
## カードの内側の余白（_add_card の content_margin）
const CARD_MARGIN: float = 16.0
## 設定「固定ボタン」の選択肢（RopeConfig の PIN_OFF / PIN_FIXED / PIN_DRAG と同じ順。試作の比べ用）
const PIN_CHOICES: Array = ["固定ボタンなし", "固定: 完全に固定", "固定: 錨（引きずる）"]
const ACCENT: Color = Color(1.0, 0.82, 0.4)
const DIM: Color = Color(1, 1, 1, 0.65)

var selected_stage: int = 1
var current_tab: int = TAB_HOME

var _content: Control
var _tab_bar: HBoxContainer
var _tab_buttons: Array[Button] = []
## タブごとのページ（TAB_NAMES と同じ順）。ステージ選択はホームのタブの中で切り替える別ページ
var _pages: Array[Control] = []
var _stage_page: Control
## ページの中身の箱（幅を画面に合わせる）
var _boxes: Array[Control] = []
## 文字の大きさ・ボタンの高さを画面に合わせるもの（meta に単位数を持つ）
var _scaled: Array[Control] = []
var _cards: GridContainer
var _home_cards: Array[Control] = []
var _stage_grid: GridContainer
var _stage_buttons: Array[Button] = []
var _stage_title: Label
var _stage_note: Label
var _stage_status: Label
var _start_button: Button
var _prev_button: Button
var _next_button: Button
var _endless_best: Label
var _reset_button: Button
var _reset_armed: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	selected_stage = clampi(SaveData.unlocked_stage(), 1, StagePool.count())
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	show_tab(TAB_HOME)
	# キーボード（Enter）でも出撃できるようにする（CI のブラウザテストもこれで本編へ進む）
	_start_button.grab_focus()


func show_tab(index: int) -> void:
	current_tab = index
	for i: int in _pages.size():
		_pages[i].visible = i == index
	_stage_page.visible = false
	for i: int in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == index)
	if index == TAB_HOME:
		refresh()


func show_stage_select() -> void:
	refresh()
	for page: Control in _pages:
		page.visible = false
	_stage_page.visible = true


func select_stage(number: int) -> void:
	selected_stage = clampi(number, 1, StagePool.count())
	refresh()


## 保存データに合わせて、ステージの表示・ボタンの有効/無効・記録を作り直す
func refresh() -> void:
	var stage: StageDef = StagePool.get_stage(selected_stage)
	_stage_title.text = "ステージ %d" % selected_stage
	_stage_note.text = "%s でボス出現、倒せばクリア ／ %s" % [RunState.format_time(stage.boss_time), stage.note]
	if not SaveData.is_unlocked(selected_stage):
		_stage_status.text = "未開放（ステージ %d をクリアすると開放）" % (selected_stage - 1)
	elif SaveData.is_cleared(selected_stage):
		_stage_status.text = "クリア済み ★"
	else:
		_stage_status.text = "未クリア"
	_start_button.disabled = not SaveData.is_unlocked(selected_stage)
	_prev_button.disabled = selected_stage <= 1
	_next_button.disabled = selected_stage >= StagePool.count()
	var best: float = SaveData.endless_best()
	_endless_best.text = "最高記録 %s" % RunState.format_time(best) if best > 0.0 else "最高記録 なし"
	for i: int in _stage_buttons.size():
		var number: int = i + 1
		var mark: String = "未開放"
		if SaveData.is_cleared(number):
			mark = "★"
		elif SaveData.is_unlocked(number):
			mark = "挑戦できる"
		_stage_buttons[i].text = "ステージ %d\n%s" % [number, mark]
		_stage_buttons[i].disabled = not SaveData.is_unlocked(number)


func start_stage() -> void:
	if not SaveData.is_unlocked(selected_stage):
		return
	RunSetup.start_stage(selected_stage)
	get_tree().change_scene_to_file(GAME_SCENE)


func start_endless() -> void:
	RunSetup.start_endless()
	get_tree().change_scene_to_file(GAME_SCENE)


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.13, 0.13, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_content = Control.new()
	add_child(_content)
	_pages.append(_build_undecided())
	_pages.append(_build_equipment())
	_pages.append(_build_home())
	_pages.append(_build_gacha())
	_pages.append(_build_settings())
	_stage_page = _build_stage_select()

	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 0)
	add_child(_tab_bar)
	for i: int in TAB_NAMES.size():
		var button: Button = Button.new()
		button.text = TAB_NAMES[i]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_tab.bind(i))
		_tab_bar.add_child(button)
		_tab_buttons.append(button)


func _build_home() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "BIND RUN", 9.0, ACCENT)
	_add_label(box, "ゴム紐でつながった 2 人で、敵の群れを生き残れ", 3.0, DIM)
	_cards = GridContainer.new()
	box.add_child(_cards)

	var stage_card: VBoxContainer = _add_card(_cards)
	_home_cards.append(stage_card.get_parent() as Control)
	_stage_title = _add_label(stage_card, "", 6.0)
	_stage_note = _add_label(stage_card, "", 3.0, DIM)
	_stage_status = _add_label(stage_card, "", 3.2, ACCENT)
	var row: HBoxContainer = HBoxContainer.new()
	stage_card.add_child(row)
	_prev_button = _add_button(row, "<", 10.0, func() -> void: select_stage(selected_stage - 1))
	_prev_button.set_meta("width_units", 10.0)
	_start_button = _add_button(row, "出撃", 10.0, start_stage)
	_start_button.set_meta("font_units", 4.6)
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_button = _add_button(row, ">", 10.0, func() -> void: select_stage(selected_stage + 1))
	_next_button.set_meta("width_units", 10.0)
	_add_button(stage_card, "ステージを選ぶ", 7.0, show_stage_select)

	var endless_card: VBoxContainer = _add_card(_cards)
	_home_cards.append(endless_card.get_parent() as Control)
	_add_label(endless_card, "エンドレス", 6.0)
	_add_label(endless_card, "時間制限なし。5 分ごとにボスが出て、敵はどんどん硬くなる", 3.0, DIM)
	_endless_best = _add_label(endless_card, "", 3.2, ACCENT)
	var endless_button: Button = _add_button(endless_card, "挑戦", 10.0, start_endless)
	endless_button.set_meta("font_units", 4.6)

	_add_label(box, "操作: 画面の左半分をドラッグで青、右半分で橙が動く", 2.8, DIM)
	return _page_of(box)


func _build_stage_select() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "ステージ選択", 6.0)
	_stage_grid = GridContainer.new()
	box.add_child(_stage_grid)
	for number: int in range(1, StagePool.count() + 1):
		var button: Button = _add_button(_stage_grid, "", 12.0, _on_stage_chosen.bind(number))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stage_buttons.append(button)
	_add_button(box, "戻る", 8.0, show_tab.bind(TAB_HOME))
	return _page_of(box)


func _build_equipment() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "装備", 6.0)
	var card: VBoxContainer = _add_card(box)
	var blaster: WeaponDef = load("res://data/weapons/blaster.tres") as WeaponDef
	var shockwave: WeaponDef = load("res://data/weapons/shockwave.tres") as WeaponDef
	for line: String in [
		"青（A）の武器: %s" % blaster.display_name,
		"橙（B）の武器: %s" % shockwave.display_name,
		"紐: ふつうの紐",
		"アクセサリ: なし",
	]:
		_add_label(card, line, 3.4)
	_add_label(box, "装備の入れ替えは準備中です", 3.0, DIM)
	return _page_of(box)


func _build_gacha() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "ガチャ", 6.0)
	var card: VBoxContainer = _add_card(box)
	_add_label(card, "準備中", 5.0, ACCENT)
	_add_label(card, "何が出るか・必要な通貨は未定です", 3.0, DIM)
	var row: HBoxContainer = HBoxContainer.new()
	card.add_child(row)
	for text: String in ["1 回引く", "10 回引く"]:
		var button: Button = _add_button(row, text, 9.0, func() -> void: pass)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = true
	return _page_of(box)


func _build_undecided() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "？？？", 6.0)
	var card: VBoxContainer = _add_card(box)
	_add_label(card, "ここに何を置くかは未定です", 3.4)
	_add_label(card, "候補: ミッション / 図鑑 / ショップ / ランキング", 3.0, DIM)
	return _page_of(box)


func _build_settings() -> Control:
	var box: VBoxContainer = _new_page()
	_add_label(box, "設定", 6.0)
	var card: VBoxContainer = _add_card(box)
	for item: Array in SETTINGS:
		var key: String = item[0]
		var check: CheckButton = CheckButton.new()
		check.text = item[1]
		check.button_pressed = bool(SaveData.get_setting(key, item[2]))
		check.toggled.connect(func(on: bool) -> void: SaveData.set_setting(key, on))
		check.set_meta("height_units", 8.0)
		card.add_child(check)
		_scaled.append(check)
	_add_label(card, "CPU 担当（デバッグ用。片方を CPU に任せる）", 2.8, DIM)
	var cpu: OptionButton = OptionButton.new()
	for text: String in CPU_CHOICES:
		cpu.add_item(text)
	cpu.selected = clampi(int(SaveData.get_setting("cpu_side", 0)), 0, CPU_CHOICES.size() - 1)
	cpu.item_selected.connect(func(index: int) -> void: SaveData.set_setting("cpu_side", index))
	cpu.set_meta("height_units", 8.0)
	card.add_child(cpu)
	_scaled.append(cpu)
	_add_label(card, "紐の固定ボタン（試作。完全固定と錨を比べる）", 2.8, DIM)
	var pin: OptionButton = OptionButton.new()
	for text: String in PIN_CHOICES:
		pin.add_item(text)
	pin.selected = clampi(int(SaveData.get_setting("pin_mode", RopeConfig.PIN_FIXED)), 0, PIN_CHOICES.size() - 1)
	pin.item_selected.connect(func(index: int) -> void: SaveData.set_setting("pin_mode", index))
	pin.set_meta("height_units", 8.0)
	card.add_child(pin)
	_scaled.append(pin)
	_reset_button = _add_button(card, "記録を消す", 8.0, _on_reset_pressed)
	_add_label(box, "開発版（Web）", 2.6, DIM)
	return _page_of(box)


func _on_stage_chosen(number: int) -> void:
	select_stage(number)
	show_tab(TAB_HOME)


# 誤って消さないよう、2 回押したときだけ消す
func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "もう一度押すと消えます"
		return
	_reset_armed = false
	SaveData.reset_progress()
	selected_stage = 1
	_reset_button.text = "記録を消しました"
	refresh()


# ページの土台: 縦に並べる箱を返す。画面に収まらないときは縦にスクロールできる
# （縦持ち・小さい端末で、下のボタンが画面の外に出て押せなくなるのを防ぐ）。
# ページ本体は _page_of(box)。中身が短いときは ScrollContainer の中で中央に寄る
func _new_page() -> VBoxContainer:
	var page: ScrollContainer = ScrollContainer.new()
	page.visible = false
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(page)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	_boxes.append(box)
	return box


func _page_of(box: Control) -> Control:
	return box.get_parent().get_parent() as Control


func _add_card(parent: Control) -> VBoxContainer:
	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.07)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(CARD_MARGIN)
	card.add_theme_stylebox_override("panel", style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_meta("in_home_cards", parent == _cards)
	card.add_child(box)
	return box


func _add_label(parent: Control, text: String, font_units: float, color: Color = Color.WHITE) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.set_meta("font_units", font_units)
	# 折り返す幅は _layout で決める。幅が決まらないと 1 文字ずつ折り返して縦に伸びる
	if parent.has_meta("in_home_cards"):
		label.set_meta("wrap", WRAP_HOME_CARD if parent.get_meta("in_home_cards") else WRAP_CARD)
	else:
		label.set_meta("wrap", WRAP_PAGE)
	parent.add_child(label)
	_scaled.append(label)
	return label


func _add_button(parent: Control, text: String, height_units: float, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.set_meta("height_units", height_units)
	button.pressed.connect(callback)
	parent.add_child(button)
	_scaled.append(button)
	return button


# 画面の大きさ（向き）が変わるたびに、文字・ボタン・ページの大きさと並びを合わせ直す
func _layout() -> void:
	var u: float = UiScale.unit(get_viewport())
	var view: Vector2 = get_viewport().get_visible_rect().size
	var landscape: bool = view.x > view.y
	var ui_theme: Theme = Theme.new()
	ui_theme.default_font_size = int(3.6 * u)
	theme = ui_theme

	var bar_height: float = 12.0 * u
	_content.position = Vector2.ZERO
	_content.size = Vector2(view.x, view.y - bar_height)
	for page: Node in _content.get_children():
		(page as Control).position = Vector2.ZERO
		(page as Control).size = _content.size
	_tab_bar.position = Vector2(0, view.y - bar_height)
	_tab_bar.size = Vector2(view.x, bar_height)
	for button: Button in _tab_buttons:
		button.custom_minimum_size = Vector2(0, bar_height)
		button.add_theme_font_size_override("font_size", int(3.2 * u))

	var width: float = minf(view.x - 6.0 * u, 150.0 * u)
	for box: Control in _boxes:
		box.custom_minimum_size.x = width
		box.add_theme_constant_override("separation", int(1.5 * u))
	# 横持ちではステージとエンドレスを横に並べる（縦の余裕が少ないため）
	_cards.columns = 2 if landscape else 1
	_cards.add_theme_constant_override("h_separation", int(2.0 * u))
	_cards.add_theme_constant_override("v_separation", int(2.0 * u))
	for card: Control in _home_cards:
		card.custom_minimum_size.x = (width - 2.0 * u) / _cards.columns
	_stage_grid.columns = 5 if landscape else 2
	_stage_grid.add_theme_constant_override("h_separation", int(1.5 * u))
	_stage_grid.add_theme_constant_override("v_separation", int(1.5 * u))

	var home_card_width: float = (width - 2.0 * u) / _cards.columns
	for control: Control in _scaled:
		if control is Label and control.has_meta("wrap"):
			var wrap: int = int(control.get_meta("wrap"))
			var wrap_width: float = width
			if wrap == WRAP_CARD:
				wrap_width = width - 2.0 * CARD_MARGIN
			elif wrap == WRAP_HOME_CARD:
				wrap_width = home_card_width - 2.0 * CARD_MARGIN
			control.custom_minimum_size.x = wrap_width
		if control.has_meta("font_units"):
			control.add_theme_font_size_override("font_size", int(float(control.get_meta("font_units")) * u))
		if control.has_meta("height_units"):
			control.custom_minimum_size.y = float(control.get_meta("height_units")) * u
		if control.has_meta("width_units"):
			control.custom_minimum_size.x = float(control.get_meta("width_units")) * u
