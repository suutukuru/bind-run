extends "res://tests/test_case.gd"
## 紐の固定（試作）: 固定の点が動かないこと、錨モード、時間と待ち時間、三角形の囲みダメージ、ボタンの表示。
## 触り心地・囲みやすさはスマホで確認する。

const TEST_SAVE: String = "user://test_save.cfg"


func _make_main() -> Node:
	SaveData.path = TEST_SAVE
	SaveData.delete_file()
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.paused = false
	tree.root.remove_child(main)
	main.free()
	SaveData.delete_file()
	SaveData.path = "user://save.cfg"
	RunSetup.reset()


func _setup(main: Node) -> Dictionary:
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(200, 0)
	rope.hub = Vector2(100, 0)
	return {"rope": rope, "a": a, "b": b}


func test_drag_anchor_moves_only_by_the_excess_within_the_budget() -> void:
	var points: PackedVector2Array = PackedVector2Array([Vector2(-600, 0), Vector2(600, 0)])
	check_vec_near(RopeModel.drag_anchor(Vector2.ZERO, points, 480.0, 50.0), Vector2(-50, 0), "budget caps the move, the second pull gets nothing")
	check_vec_near(RopeModel.drag_anchor(Vector2.ZERO, points, 480.0, 0.0), Vector2.ZERO, "no budget, no move")
	check_vec_near(RopeModel.drag_anchor(Vector2.ZERO, points, 700.0, 50.0), Vector2.ZERO, "inside the limit, no move")
	check_vec_near(RopeModel.drag_anchor(Vector2.ZERO, PackedVector2Array([Vector2(500, 0)]), 480.0, 50.0), Vector2(20, 0), "never moves more than the excess")


func test_near_triangle() -> void:
	var a: Vector2 = Vector2.ZERO
	var b: Vector2 = Vector2(400, 0)
	var c: Vector2 = Vector2(0, 400)
	check_true(RopeModel.near_triangle(Vector2(100, 100), a, b, c, 0.0), "inside")
	check_true(not RopeModel.near_triangle(Vector2(350, 350), a, b, c, 10.0), "outside")
	check_true(RopeModel.near_triangle(Vector2(205, 205), a, b, c, 10.0), "near the far edge counts")


func test_pinned_hub_stays_and_members_are_limited_around_it() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.set_pinned(true)
	check_true(rope.pinned, "pinned")
	(s["a"] as Character).global_position = Vector2(-1000, 0)
	rope.step(1.0 / 60.0)
	check_vec_near(rope.hub, Vector2(100, 0), "the pin does not move")
	check_vec_near((s["a"] as Character).global_position, Vector2(100.0 - rope.config.max_radius, 0), "A is held at the max length from the pin")
	check_near(rope.stretch_ratios[0], 1.0, "fully stretched")
	_free_main(main)


func test_a_pinned_rope_does_not_pull_back_inside_the_natural_length() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.config.stiffness = 12.0
	rope.set_pinned(true)
	(s["a"] as Character).global_position = Vector2(100.0 - rope.config.max_radius, 0)
	rope.step(1.0)
	check_near((s["a"] as Character).global_position.x, 100.0 - rope.config.max_radius, "no elastic pull while pinned")
	_free_main(main)


func test_anchor_mode_drags_the_pin_slowly() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.config.pin_mode = RopeConfig.PIN_DRAG
	rope.set_pinned(true)
	(s["a"] as Character).global_position = Vector2(-1000, 0)
	rope.step(0.1)
	check_vec_near(rope.hub, Vector2(100.0 - rope.config.pin_drag_speed * 0.1, 0), "the anchor moves by speed x time toward the pull")
	_free_main(main)


func test_pin_lasts_a_limited_time_then_cools_down() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.config.pin_max_seconds = 1.0
	rope.config.pin_cooldown = 3.0
	rope.set_pinned(true)
	rope.step(0.6)
	check_true(rope.pinned, "still pinned")
	rope.step(0.6)
	check_true(not rope.pinned, "released after the time")
	check_true(not rope.can_pin(), "cooling down")
	rope.set_pinned(true)
	check_true(not rope.pinned, "cannot pin during the cooldown")
	rope.step(3.1)
	check_true(rope.can_pin(), "ready again")
	_free_main(main)


func test_releasing_early_also_starts_the_cooldown() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.toggle_pin()
	check_true(rope.pinned, "pinned by the button")
	rope.toggle_pin()
	check_true(not rope.pinned and rope.pin_cooldown_left > 0.0, "released and cooling down")
	_free_main(main)


func test_pin_mode_off_ignores_requests() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	rope.config.pin_mode = RopeConfig.PIN_OFF
	rope.toggle_pin()
	check_true(not rope.pinned, "off")
	_free_main(main)


func test_camera_shows_the_members_center_while_pinned() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	check_vec_near(rope.view_center(), rope.hub, "not pinned: the hub")
	rope.set_pinned(true)
	(s["a"] as Character).global_position = Vector2(-100, 0)
	(s["b"] as Character).global_position = Vector2(300, 0)
	check_vec_near(rope.view_center(), Vector2(100, 0), "pinned: the center of the members")
	_free_main(main)


func test_pinned_triangle_hurts_enemies_inside_only() -> void:
	var main: Node = _make_main()
	var s: Dictionary = _setup(main)
	var rope: Rope = s["rope"]
	var attack: RopeAttack = main.get_node("RopeAttack") as RopeAttack
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var def: EnemyDef = load("res://data/enemies/grunt.tres") as EnemyDef
	(s["a"] as Character).global_position = Vector2(400, 0)
	(s["b"] as Character).global_position = Vector2(0, 400)
	rope.hub = Vector2.ZERO
	var inside: Enemy = spawner.spawn_enemy(def, Vector2(130, 130))
	var outside: Enemy = spawner.spawn_enemy(def, Vector2(400, 400))
	rope.set_pinned(true)
	rope.step(1.0 / 60.0)
	attack.step(0.016)
	check_near(inside.hp, def.max_hp - rope.config.loop_damage, "the enemy inside the triangle is hurt")
	check_near(outside.hp, def.max_hp, "the enemy outside is not")
	var after_first: float = inside.hp
	attack.step(0.016)
	check_near(inside.hp, after_first, "re-hit interval respected")
	_free_main(main)


func test_the_pin_button_follows_the_mode_and_state() -> void:
	var main: Node = _make_main()
	var hud: Hud = main.get_node("Hud") as Hud
	var rope: Rope = main.get_node("Rope") as Rope
	main._process(0.016)
	check_true(hud._pin_button.visible and not hud._pin_button.disabled, "visible and ready by default")
	rope.set_pinned(true)
	main._process(0.016)
	check_true(hud._pin_button.text.begins_with("解除"), "shows release while pinned")
	rope.set_pinned(false)
	main._process(0.016)
	check_true(hud._pin_button.disabled, "disabled while cooling down")
	_free_main(main)


func test_the_pin_setting_can_hide_the_button() -> void:
	SaveData.path = TEST_SAVE
	SaveData.delete_file()
	SaveData.set_setting("pin_mode", RopeConfig.PIN_OFF)
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	main._process(0.016)
	check_eq((main.get_node("Rope") as Rope).config.pin_mode, RopeConfig.PIN_OFF, "mode from the setting")
	check_true(not (main.get_node("Hud") as Hud)._pin_button.visible, "button hidden")
	_free_main(main)
