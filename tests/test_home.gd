extends "res://tests/test_case.gd"
## ホーム画面・ステージの開放・エンドレス・保存データ（TC-160〜）。見た目と押しやすさはスマホで確認する。

const TEST_SAVE: String = "user://test_save.cfg"
const REAL_SAVE: String = "user://save.cfg"


# 本物の保存データを汚さないよう、テスト用のファイルに差し替える
func _use_test_save() -> void:
	SaveData.path = TEST_SAVE
	SaveData.delete_file()


func _restore() -> void:
	SaveData.delete_file()
	SaveData.path = REAL_SAVE
	RunSetup.reset()
	tree.paused = false


func _make(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	tree.root.add_child(node)
	return node


func _free(node: Node) -> void:
	tree.paused = false
	tree.root.remove_child(node)
	node.free()


func test_stages_are_numbered_and_get_harder() -> void:
	check_eq(StagePool.count(), 10, "ten stages")
	var previous: StageDef = null
	for i: int in StagePool.count():
		var stage: StageDef = StagePool.get_stage(i + 1)
		check_eq(stage.number, i + 1, "stage %d number" % (i + 1))
		check_true(stage.note != "", "stage %d has a note" % (i + 1))
		if previous != null:
			check_true(stage.duration >= previous.duration, "stage %d is not shorter" % stage.number)
			check_true(stage.spawn_interval_scale <= previous.spawn_interval_scale, "stage %d spawns no less" % stage.number)
			check_true(stage.enemy_hp_scale >= previous.enemy_hp_scale, "stage %d enemies are not weaker" % stage.number)
		previous = stage
	check_true(StagePool.get_stage(0) == null and StagePool.get_stage(StagePool.count() + 1) == null, "out of range is null")


func test_clearing_a_stage_unlocks_the_next() -> void:
	_use_test_save()
	check_eq(SaveData.unlocked_stage(), 1, "only stage 1 at first")
	check_true(not SaveData.is_unlocked(2), "stage 2 locked")
	SaveData.record_stage_clear(1)
	check_true(SaveData.is_cleared(1), "stage 1 cleared")
	check_eq(SaveData.unlocked_stage(), 2, "stage 2 unlocked")
	SaveData.record_stage_clear(3)
	SaveData.record_stage_clear(1)
	check_eq(SaveData.unlocked_stage(), 4, "replaying an earlier stage does not lock later ones")
	SaveData.reset_progress()
	check_eq(SaveData.unlocked_stage(), 1, "reset")
	_restore()


func test_endless_keeps_the_longest_record_and_settings_persist() -> void:
	_use_test_save()
	check_near(SaveData.endless_best(), 0.0, "no record")
	check_true(SaveData.record_endless(30.0), "first record")
	check_true(not SaveData.record_endless(10.0), "shorter is not a record")
	check_true(SaveData.record_endless(60.0), "longer is a record")
	check_near(SaveData.endless_best(), 60.0, "best")
	check_eq(SaveData.get_setting("show_hub", false), false, "default setting")
	SaveData.set_setting("show_hub", true)
	check_eq(SaveData.get_setting("show_hub", false), true, "saved setting")
	SaveData.reset_progress()
	check_eq(SaveData.get_setting("show_hub", false), true, "reset keeps settings")
	_restore()


func test_home_has_five_tabs_and_locks_stages() -> void:
	_use_test_save()
	var home: Home = _make("res://scenes/home/home.tscn") as Home
	check_eq(home._tab_buttons.size(), 5, "five tabs")
	check_eq(home._tab_buttons[Home.TAB_HOME].text, "ホーム", "home is in the middle")
	check_eq(home.current_tab, Home.TAB_HOME, "starts on home")
	check_true(home._pages[Home.TAB_HOME].visible, "home page shown")
	home.show_tab(Home.TAB_GACHA)
	check_true(home._pages[Home.TAB_GACHA].visible and not home._pages[Home.TAB_HOME].visible, "gacha page shown")
	home.show_tab(Home.TAB_HOME)
	home.show_stage_select()
	check_true(home._stage_page.visible and not home._pages[Home.TAB_HOME].visible, "stage list shown")
	check_true(not home._stage_buttons[0].disabled and home._stage_buttons[1].disabled, "only stage 1 can be chosen")
	home.select_stage(2)
	check_true(home._start_button.disabled, "locked stage cannot start")
	SaveData.record_stage_clear(1)
	home.refresh()
	check_true(not home._start_button.disabled, "unlocked after clearing stage 1")
	check_true(home._stage_buttons[0].text.contains("★"), "cleared mark")
	_free(home)
	_restore()


func test_a_stage_run_uses_the_stage_settings() -> void:
	_use_test_save()
	RunSetup.start_stage(3)
	var main: Node = _make("res://scenes/main/main.tscn")
	var stage: StageDef = StagePool.get_stage(3)
	var state: RunState = main.get_node("RunState") as RunState
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	check_near(state.run_duration, stage.duration, "duration")
	check_near(spawner.interval_scale, stage.spawn_interval_scale, "spawn rate")
	check_near(spawner.hp_scale, stage.enemy_hp_scale, "enemy hp")
	check_eq((main.get_node("Hud") as Hud).caption, "ステージ 3", "hud caption")
	var enemy: Enemy = spawner.spawn_enemy(load("res://data/enemies/grunt.tres") as EnemyDef, Vector2(3000, 3000))
	check_near(enemy.hp, enemy.def.max_hp * stage.enemy_hp_scale, "spawned enemy hp is scaled")
	_free(main)
	_restore()


func test_clearing_a_stage_in_the_game_records_it_and_offers_the_next() -> void:
	_use_test_save()
	RunSetup.start_stage(1)
	var main: Node = _make("res://scenes/main/main.tscn")
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	state.elapsed = state.run_duration
	state._physics_process(0.016)
	check_true(menu.is_open(), "result menu")
	check_eq(menu.option_count(), 3, "next, retry and home")
	check_true(SaveData.is_cleared(1) and SaveData.is_unlocked(2), "progress saved")
	_free(main)
	_restore()


func test_endless_has_no_time_limit_and_records_the_time() -> void:
	_use_test_save()
	RunSetup.start_endless()
	var main: Node = _make("res://scenes/main/main.tscn")
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	check_near(state.run_duration, 0.0, "no limit")
	state.elapsed = 10000.0
	state._physics_process(0.016)
	check_true(state.running and not menu.is_open(), "still running after a long time")
	check_true((main.get_node("EnemySpawner") as EnemySpawner).hp_growth_per_minute > 0.0, "enemies toughen over time")
	state.take_damage(state.max_hp)
	check_true(menu.is_open(), "game over menu")
	check_true(SaveData.endless_best() >= 10000.0, "time recorded")
	_free(main)
	_restore()


func test_settings_hide_the_tuning_button_in_the_game() -> void:
	_use_test_save()
	SaveData.set_setting("show_tuning", false)
	SaveData.set_setting("show_hub", true)
	var main: Node = _make("res://scenes/main/main.tscn")
	check_true(not (main.get_node("TuningPanel") as TuningPanel)._toggle.visible, "tuning button hidden")
	check_true((main.get_node("Rope") as Rope).show_hub, "hub dot shown")
	_free(main)
	_restore()


func test_time_format() -> void:
	check_eq(RunState.format_time(0.0), "00:00", "zero")
	check_eq(RunState.format_time(125.9), "02:05", "minutes and seconds")
	check_eq(RunState.format_time(-3.0), "00:00", "negative is zero")
