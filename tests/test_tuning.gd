extends "res://tests/test_case.gd"
## 調整パネル（TC-108）。スライダーの操作そのものはスマホで確認する。


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.root.remove_child(main)
	main.free()


func test_set_param_changes_only_this_ropes_config() -> void:
	var main: Node = _make_main()
	var panel: TuningPanel = main.get_node("TuningPanel") as TuningPanel
	var rope: Rope = main.get_node("Rope") as Rope
	var shared: RopeConfig = load("res://data/rope/default_rope_config.tres") as RopeConfig
	var before: float = shared.stiffness
	panel.set_param("stiffness", 7.0)
	check_near(rope.config.stiffness, 7.0, "rope config changed")
	check_near(shared.stiffness, before, "the shared .tres is untouched")
	_free_main(main)


func test_limit_mode_can_be_switched() -> void:
	var main: Node = _make_main()
	var panel: TuningPanel = main.get_node("TuningPanel") as TuningPanel
	var rope: Rope = main.get_node("Rope") as Rope
	panel.set_limit_mode(1)
	check_eq(rope.config.limit_mode, RopeConfig.BLOCK, "block mode")
	panel.set_limit_mode(0)
	check_eq(rope.config.limit_mode, RopeConfig.DRAG, "drag mode")
	_free_main(main)


func test_sliders_start_at_the_current_values() -> void:
	var main: Node = _make_main()
	var panel: TuningPanel = main.get_node("TuningPanel") as TuningPanel
	var rope: Rope = main.get_node("Rope") as Rope
	var slider: HSlider = panel._sliders["max_radius"] as HSlider
	check_near(slider.value, rope.config.max_radius, "max_radius slider")
	_free_main(main)


func test_view_size_slider_changes_the_camera() -> void:
	var main: Node = _make_main()
	var panel: TuningPanel = main.get_node("TuningPanel") as TuningPanel
	var camera: FollowCamera = main.get_node("Camera") as FollowCamera
	panel.set_view_size(1200.0)
	check_near(camera.view_short_side, 1200.0, "camera view size")
	_free_main(main)


func test_japanese_ui_font_covers_the_game_text() -> void:
	var font: Font = load("res://assets/fonts/ui_font.ttf") as Font
	check_true(font != null, "font loads")
	if font == null:
		return
	for text: String in ["スタート", "撃破", "紐の最大長", "レベルアップ"]:
		for i: int in text.length():
			check_true(font.has_char(text.unicode_at(i)), "glyph for %s" % text[i])


func test_skip_to_boss_moves_the_clock_just_before_the_boss() -> void:
	SaveData.path = "user://test_save.cfg"
	RunSetup.start_stage(1)
	var main: Node = _make_main()
	var panel: TuningPanel = main.get_node("TuningPanel") as TuningPanel
	var state: RunState = main.get_node("RunState") as RunState
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	panel.skip_to_boss()
	check_near(state.elapsed, 300.0 - TuningPanel.BOSS_SKIP_LEAD, "just before the boss")
	check_true(spawner.boss == null, "the boss is not out yet")
	state.elapsed = 400.0
	panel.skip_to_boss()
	check_near(state.elapsed, 400.0, "never goes backwards")
	_free_main(main)
	SaveData.delete_file()
	SaveData.path = "user://save.cfg"
	RunSetup.reset()
