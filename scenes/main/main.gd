extends Node2D
## ゲーム本編の進行役: レベルアップ・ポーズ・結果のメニューを出し、強化を適用する。

const TITLE_SCENE: String = "res://scenes/title/title.tscn"
## レベルアップで提示する強化の数（FR-043 の仮決定）
const CHOICES: int = 3

@onready var _rope: Rope = $Rope
@onready var _run_state: RunState = $RunState
@onready var _menu: MenuPanel = $MenuPanel
@onready var _hud: Hud = $Hud

var _upgrade_counts: Dictionary = {}
var _pending_level_ups: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	InputActions.register()
	_rng.randomize()
	_run_state.leveled_up.connect(_on_leveled_up)
	_run_state.finished.connect(_on_finished)
	_hud.pause_requested.connect(_open_pause)


func _unhandled_input(event: InputEvent) -> void:
	# F1: ハブの点の表示切替。見た目だけで、ロジックは変わらない
	if event.is_action_pressed("debug_toggle_hub"):
		_rope.show_hub = not _rope.show_hub


## 何回選んだかの記録（テスト・結果表示用）
func upgrade_count(id: StringName) -> int:
	return int(_upgrade_counts.get(id, 0))


func _on_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	if not _menu.is_open():
		_show_level_up()


func _show_level_up() -> void:
	if _pending_level_ups <= 0 or not _run_state.running:
		return
	var choices: Array = UpgradePicker.pick(UpgradePool.all(), _upgrade_counts, CHOICES, _rng)
	if choices.is_empty():
		_pending_level_ups = 0
		return
	var options: Array = []
	for item: Variant in choices:
		var def: UpgradeDef = item as UpgradeDef
		options.append({"text": "%s\n%s" % [def.title, def.description], "callback": _on_upgrade_chosen.bind(def)})
	_menu.open("レベルアップ！  Lv %d" % _run_state.level, "強化を 1 つ選ぼう", options)


func _on_upgrade_chosen(def: UpgradeDef) -> void:
	def.apply_to(self)
	_upgrade_counts[def.id] = upgrade_count(def.id) + 1
	_pending_level_ups -= 1
	# 一度に複数レベル上がったときは、続けて次の選択を出す
	_show_level_up()


func _open_pause() -> void:
	if _menu.is_open() or not _run_state.running:
		return
	_menu.open("ポーズ", "", [
		{"text": "つづける", "callback": func() -> void: pass},
		{"text": "やり直す", "callback": _restart},
		{"text": "タイトルへ", "callback": _to_title},
	])


func _on_finished(victory: bool) -> void:
	_pending_level_ups = 0
	var minutes: int = int(_run_state.elapsed) / 60
	var seconds: int = int(_run_state.elapsed) % 60
	var stats: String = "時間 %02d:%02d   レベル %d   撃破 %d" % [minutes, seconds, _run_state.level, _run_state.kills]
	_menu.open("クリア！" if victory else "ゲームオーバー", stats, [
		{"text": "もう一度", "callback": _restart},
		{"text": "タイトルへ", "callback": _to_title},
	])


func _restart() -> void:
	get_tree().reload_current_scene()


func _to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)
