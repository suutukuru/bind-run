extends Node2D
## ゲーム本編の進行役: レベルアップ・ポーズ・結果のメニューを出し、強化を適用する。
## ホームで選んだ遊び方（RunSetup: ステージ / エンドレス）に合わせてランを設定し、結果を SaveData に記録する。

const HOME_SCENE: String = "res://scenes/home/home.tscn"
## レベルアップで提示する強化の数（FR-043 の仮決定）
const CHOICES: int = 3

@onready var _rope: Rope = $Rope
@onready var _run_state: RunState = $RunState
@onready var _menu: MenuPanel = $MenuPanel
@onready var _hud: Hud = $Hud
@onready var _spawner: EnemySpawner = $EnemySpawner
@onready var _tuning: TuningPanel = $TuningPanel
@onready var _overlay: DebugOverlay = $DebugOverlay

## エンドレスで、敵の HP の倍率に 1 分ごとに足す量（時間とともに硬くなる）
@export var endless_hp_growth_per_minute: float = 0.25
## エンドレスでボスが出る間隔（秒）
@export var endless_boss_interval: float = 300.0

var _upgrade_counts: Dictionary = {}
var _pending_level_ups: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	InputActions.register()
	_rng.randomize()
	_run_state.leveled_up.connect(_on_leveled_up)
	_run_state.finished.connect(_on_finished)
	_hud.pause_requested.connect(_open_pause)
	_spawner.boss_spawned.connect(_hud.show_boss)
	_spawner.boss_defeated.connect(_on_boss_defeated)
	_apply_settings()
	_apply_run_setup()


# ホームの設定画面で選んだ表示（開発用の調整ボタン・デバッグ文字・ハブの点）
func _apply_settings() -> void:
	_tuning.set_toggle_visible(bool(SaveData.get_setting("show_tuning", true)))
	_overlay.set_text_visible(bool(SaveData.get_setting("debug_text", true)))
	_rope.show_hub = bool(SaveData.get_setting("show_hub", false))


func _apply_run_setup() -> void:
	if RunSetup.mode == RunSetup.STAGE:
		var stage: StageDef = StagePool.get_stage(RunSetup.stage_number)
		if stage == null:
			push_error("Main: ステージ %d がありません" % RunSetup.stage_number)
			return
		# 時間切れでのクリアはなく、5 分でボスが出て、倒すとクリア
		_run_state.run_duration = 0.0
		_run_state.boss_at = stage.boss_time
		_spawner.interval_scale = stage.spawn_interval_scale
		_spawner.hp_scale = stage.enemy_hp_scale
		_hud.caption = "ステージ %d" % stage.number
	elif RunSetup.mode == RunSetup.ENDLESS:
		_run_state.run_duration = 0.0
		_run_state.boss_at = endless_boss_interval
		_hud.show_elapsed = true
		_spawner.hp_growth_per_minute = endless_hp_growth_per_minute
		_hud.caption = "エンドレス"


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
		{"text": "ホームへ", "callback": _to_home},
	])


func _on_finished(victory: bool) -> void:
	_pending_level_ups = 0
	var stats: String = "時間 %s   レベル %d   撃破 %d" % [RunState.format_time(_run_state.elapsed), _run_state.level, _run_state.kills]
	if RunSetup.mode == RunSetup.STAGE:
		_finish_stage(victory, stats)
	elif RunSetup.mode == RunSetup.ENDLESS:
		_finish_endless(stats)
	else:
		_menu.open("クリア！" if victory else "ゲームオーバー", stats, _retry_and_home())


func _on_boss_defeated(_boss: Boss) -> void:
	if RunSetup.mode == RunSetup.STAGE:
		_run_state.win()
	elif RunSetup.mode == RunSetup.ENDLESS:
		# エンドレスは続く。次のボスは倒してから一定時間後
		_run_state.boss_at = _run_state.elapsed + endless_boss_interval
		_hud.announce("ボス撃破！")


func _finish_stage(victory: bool, stats: String) -> void:
	var number: int = RunSetup.stage_number
	if not victory:
		_menu.open("ステージ %d 失敗" % number, stats, _retry_and_home())
		return
	SaveData.record_stage_clear(number)
	var options: Array = []
	var body: String = stats + "\n全ステージクリア！"
	if StagePool.get_stage(number + 1) != null:
		options.append({"text": "次のステージへ", "callback": _next_stage})
		body = stats + "\nステージ %d が開放された" % (number + 1)
	options.append_array(_retry_and_home())
	_menu.open("ステージ %d クリア！" % number, body, options)


func _finish_endless(stats: String) -> void:
	var new_best: bool = SaveData.record_endless(_run_state.elapsed)
	var best_line: String = "最高記録を更新！" if new_best else "最高記録 %s" % RunState.format_time(SaveData.endless_best())
	_menu.open("記録 %s" % RunState.format_time(_run_state.elapsed), stats + "\n" + best_line, _retry_and_home())


func _retry_and_home() -> Array:
	return [
		{"text": "もう一度", "callback": _restart},
		{"text": "ホームへ", "callback": _to_home},
	]


func _next_stage() -> void:
	RunSetup.start_stage(RunSetup.stage_number + 1)
	get_tree().reload_current_scene()


func _restart() -> void:
	get_tree().reload_current_scene()


func _to_home() -> void:
	get_tree().change_scene_to_file(HOME_SCENE)
