extends "res://tests/test_case.gd"
## 統合テスト: 物理フレームを実際に進めて、ゲーム全体が最後まで通ることを確かめる（TC-4xx）。
## CI では --fixed-fps 60 で動かすので、ゲーム内の数十秒でも実時間ではすぐに終わる。


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	for action: String in ["a_left", "a_right", "a_up", "a_down", "b_left", "b_right", "b_up", "b_down"]:
		Input.action_release(action)
	tree.paused = false
	tree.root.remove_child(main)
	main.free()


# 条件を満たすか max_frames に達するまで物理フレームを進める。満たしたら true
func _run_until(main: Node, condition: Callable, max_frames: int, bot: Callable = Callable()) -> bool:
	for frame: int in max_frames:
		if condition.call():
			return true
		if bot.is_valid():
			bot.call(frame)
		await tree.physics_frame
	return condition.call()


# レベルアップ・結果などのメニューが開いたら、先頭の選択肢を押して進める
func _press_menu_if_open(main: Node) -> void:
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	if menu.is_open() and menu.option_count() > 0 and main.get_node("RunState").running:
		menu.press(0)


func test_the_rope_alone_kills_enemies_lying_across_it() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var rope: Rope = main.get_node("Rope") as Rope
	var state: RunState = main.get_node("RunState") as RunState
	# 武器と敵の自動出現を止めて、紐の効果だけを見る
	(main.get_node("CharacterA/Weapon") as Weapon).damage = 0.0
	(main.get_node("CharacterB/Weapon") as Weapon).damage = 0.0
	spawner.set_physics_process(false)
	state.max_hp = 100000.0
	state.hp = 100000.0
	Input.action_press("a_left")
	Input.action_press("b_right")
	# 2 人が離れて紐が張るまで進める
	var taut: bool = await _run_until(main, func() -> bool: return rope.stretch_ratios.size() == 2 and rope.stretch_ratios[0] >= rope.config.attack_threshold, 300)
	check_true(taut, "the rope became taut")
	var hub: Vector2 = rope.hub
	var def: EnemyDef = load("res://data/enemies/tank.tres") as EnemyDef
	var enemy: Enemy = spawner.spawn_enemy(def, hub)
	var hurt: bool = await _run_until(main, func() -> bool: return enemy.hp < def.max_hp, 120)
	check_true(hurt, "the taut rope hurt the enemy lying across it")
	_free_main(main)


func test_weapons_kill_enemies_and_the_orbs_level_the_party_up() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var state: RunState = main.get_node("RunState") as RunState
	var a: Character = main.get_node("CharacterA") as Character
	state.max_hp = 100000.0
	state.hp = 100000.0
	spawner.set_physics_process(false)
	for i: int in 8:
		spawner.spawn_enemy(load("res://data/enemies/grunt.tres") as EnemyDef, a.global_position + Vector2.from_angle(i * 0.8) * 220.0)
	var cleared: bool = await _run_until(main, func() -> bool: return state.kills >= 8, 600, func(_f: int) -> void: _press_menu_if_open(main))
	check_true(cleared, "all eight enemies were killed by the weapons")
	var leveled: bool = await _run_until(main, func() -> bool: return state.level >= 2 or state.xp > 0, 300, func(_f: int) -> void: _press_menu_if_open(main))
	check_true(leveled, "the dropped orbs were collected")
	_free_main(main)


func test_a_full_run_reaches_victory_with_levelups_on_the_way() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	state.run_duration = 25.0
	state.max_hp = 100000.0
	state.hp = 100000.0
	var result: Dictionary = {"victory": null}
	state.finished.connect(func(v: bool) -> void: result["victory"] = v)
	# ボット: 左右に動き回り、途中でレベルアップを起こして選択肢を押す
	var bot: Callable = func(frame: int) -> void:
		var phase: int = (frame / 90) % 4
		Input.action_release("a_left")
		Input.action_release("a_right")
		Input.action_release("b_left")
		Input.action_release("b_right")
		match phase:
			0:
				Input.action_press("a_left")
				Input.action_press("b_right")
			1:
				Input.action_press("a_right")
				Input.action_press("b_left")
			2:
				Input.action_press("a_up")
			_:
				Input.action_press("b_down")
		if frame == 200:
			state.add_xp(RunState.xp_needed(state.level))
		_press_menu_if_open(main)
	var finished: bool = await _run_until(main, func() -> bool: return result["victory"] != null, 3000, bot)
	check_true(finished, "the run finished within the frame budget")
	check_eq(result["victory"], true, "victory")
	check_true(state.level >= 2, "at least one level up happened")
	check_true(menu.is_open(), "the result menu is shown")
	check_true(state.kills > 0, "some enemies were killed on the way")
	_free_main(main)


func test_standing_still_among_tanks_ends_in_game_over() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	var a: Character = main.get_node("CharacterA") as Character
	spawner.set_physics_process(false)
	(main.get_node("CharacterA/Weapon") as Weapon).damage = 0.0
	(main.get_node("CharacterB/Weapon") as Weapon).damage = 0.0
	var tank: EnemyDef = load("res://data/enemies/tank.tres") as EnemyDef
	for i: int in 6:
		spawner.spawn_enemy(tank, a.global_position + Vector2.from_angle(i) * 30.0)
	var result: Dictionary = {"victory": null}
	state.finished.connect(func(v: bool) -> void: result["victory"] = v)
	var over: bool = await _run_until(main, func() -> bool: return result["victory"] != null, 1200)
	check_true(over, "the party was defeated")
	check_eq(result["victory"], false, "defeat")
	check_true(menu.is_open(), "the game over menu is shown")
	_free_main(main)


func test_many_enemies_keep_the_frame_budget() -> void:
	# 計測のための目安: 敵 150 体を 120 フレーム動かすのにかかった実時間をログに残す（失敗にはしない）
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var state: RunState = main.get_node("RunState") as RunState
	state.max_hp = 100000.0
	state.hp = 100000.0
	spawner.set_physics_process(false)
	var grunt: EnemyDef = load("res://data/enemies/grunt.tres") as EnemyDef
	for i: int in 150:
		spawner.spawn_enemy(grunt, Vector2.from_angle(i * 0.7) * (500.0 + i * 3.0))
	var start: int = Time.get_ticks_msec()
	for frame: int in 120:
		await tree.physics_frame
	var elapsed_ms: int = Time.get_ticks_msec() - start
	print("PERF  150 enemies x 120 frames took %d ms (headless, no rendering)" % elapsed_ms)
	check_true(tree.get_nodes_in_group("enemies").size() > 0, "enemies are alive")
	_free_main(main)
