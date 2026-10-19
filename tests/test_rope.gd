extends "res://tests/test_case.gd"
## Rope ノードの拘束（TC-104 の自動で確認できる部分）。メインシーンを実際に組み立てて確かめる。

const MAX_DISTANCE_TOLERANCE: float = 0.001


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.root.remove_child(main)
	main.free()


func test_rope_wires_both_characters_and_config() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	check_true(rope.config != null, "config is set")
	check_eq(rope.member_paths.size(), 2, "two members")
	rope.step()
	check_eq(rope.stretch_ratios.size(), 2, "stretch ratio per member")
	_free_main(main)


func test_far_apart_characters_are_pulled_to_two_radii() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0  # 弾性なしの純粋な最大長の拘束を確かめる
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(600, 0)
	rope.step()
	var limit: float = rope.config.max_radius * 2.0
	check_near(a.global_position.distance_to(b.global_position), limit, "distance", MAX_DISTANCE_TOLERANCE)
	check_vec_near(rope.hub, Vector2(300, 0), "hub stays at the midpoint")
	check_vec_near(a.global_position, Vector2(60, 0), "A")
	check_vec_near(b.global_position, Vector2(540, 0), "B")
	check_near(rope.stretch_ratios[0], 1.0, "fully stretched")
	_free_main(main)


func test_close_characters_are_not_moved() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	a.global_position = Vector2(100, 100)
	b.global_position = Vector2(150, 100)
	rope.step()
	check_vec_near(a.global_position, Vector2(100, 100), "A unchanged")
	check_vec_near(b.global_position, Vector2(150, 100), "B unchanged")
	check_near(rope.stretch_ratios[0], 0.0, "slack")
	_free_main(main)


func test_one_sided_pull_drags_the_other() -> void:
	# A が遠くへ行こうとすると、A は止められ、ハブが動いて B も引きずられる（ADR-003 の仮決定）
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(0, 0)
	for step_count: int in 30:
		a.global_position += Vector2(50, 0)  # A だけが毎フレーム右へ進む
		rope.step()
	check_true(a.global_position.distance_to(b.global_position) <= rope.config.max_radius * 2.0 + MAX_DISTANCE_TOLERANCE, "never exceeds 2R")
	check_true(b.global_position.x > 0.0, "B was dragged along")
	_free_main(main)


func test_stretch_color_runs_white_yellow_red() -> void:
	check_eq(Rope.color_for_stretch(0.0), Color.WHITE, "slack is white")
	check_eq(Rope.color_for_stretch(0.5), Color.YELLOW, "half is yellow")
	check_eq(Rope.color_for_stretch(1.0), Color.RED, "taut is red")
	check_eq(Rope.color_for_stretch(5.0), Color.RED, "clamped above 1")


func test_show_hub_does_not_change_the_result() -> void:
	# FR-008 / AC-003: ハブの表示を切り替えても、同じ入力から同じ位置になる
	var results: Array[Vector2] = []
	for visible_hub: bool in [true, false]:
		var main: Node = _make_main()
		var rope: Rope = main.get_node("Rope") as Rope
		var a: Character = main.get_node("CharacterA") as Character
		var b: Character = main.get_node("CharacterB") as Character
		rope.show_hub = visible_hub
		a.global_position = Vector2(0, 0)
		b.global_position = Vector2(600, 0)
		rope.step()
		results.append(a.global_position)
		results.append(b.global_position)
		_free_main(main)
	check_vec_near(results[0], results[2], "A position")
	check_vec_near(results[1], results[3], "B position")


func test_camera_zoom_keeps_short_side_constant() -> void:
	# 横 1280x720 でも縦 390x844 に相当する比率でも、短辺に映る長さは同じ（600）
	check_near(FollowCamera.zoom_for(Vector2(1280, 720), 600.0), 1.2, "landscape")
	check_near(FollowCamera.zoom_for(Vector2(1280, 2772), 600.0), 1280.0 / 600.0, "portrait")
	check_near(FollowCamera.zoom_for(Vector2(1280, 720), 0.0), 1.0, "guard")


func test_camera_follows_the_hub() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var camera: FollowCamera = main.get_node("Camera") as FollowCamera
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	a.global_position = Vector2(1000, 500)
	b.global_position = Vector2(1100, 500)
	rope.step()
	camera._process(0.016)
	check_vec_near(camera.global_position, Vector2(1050, 500), "camera on hub")
	_free_main(main)


func _push_a_for_30_frames(rope: Rope, a: Character, b: Character) -> void:
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(0, 0)
	rope.hub = Vector2(0, 0)
	for frame: int in 30:
		a.global_position += Vector2(50, 0)  # A だけが毎フレーム右へ進もうとする
		rope.step()


func test_drag_mode_pulls_the_partner_along() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0
	rope.config.limit_mode = RopeConfig.DRAG
	_push_a_for_30_frames(rope, a, b)
	check_true(b.global_position.x > 50.0, "B was dragged")
	_free_main(main)


func test_block_mode_stops_the_pusher_without_dragging_the_partner() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0
	rope.config.limit_mode = RopeConfig.BLOCK
	_push_a_for_30_frames(rope, a, b)
	check_near(b.global_position.x, 0.0, "B stays")
	check_true(a.global_position.x <= rope.config.max_radius * 2.0 + 0.01, "A is stopped at 2R")
	check_true(a.global_position.x > rope.config.max_radius * 1.5, "A got close to the limit")
	_free_main(main)


func test_elasticity_pulls_a_stretched_member_back() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 3.0
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(260, 0)  # 各自ハブ(130)から 130 離れている → 自然長 100 を超える
	rope.hub = Vector2(130, 0)
	rope.step()
	check_true(a.global_position.x > 0.0, "A moved toward the hub")
	check_true(b.global_position.x < 260.0, "B moved toward the hub")
	_free_main(main)


func test_inertial_hub_lags_behind_the_midpoint() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0
	rope.config.hub_follow_rate = 5.0
	rope.hub = Vector2(50, 0)
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(120, 0)  # 中点は (60, 0)
	rope.step()
	check_true(rope.hub.x > 50.0 and rope.hub.x < 60.0, "hub is between old hub and midpoint")
	for frame: int in 300:
		rope.step()
	check_true(rope.hub.distance_to(Vector2(60, 0)) < 1.0, "hub catches up")
	_free_main(main)


func test_grid_line_indices_cover_the_visible_range() -> void:
	check_eq(GridBackground.line_indices(-150.0, 250.0, 100.0), [-1, 0, 1, 2] as Array[int], "negative to positive")
	check_eq(GridBackground.line_indices(10.0, 90.0, 100.0).size(), 0, "no line inside one cell")
	check_eq(GridBackground.line_indices(0.0, 100.0, 100.0), [0, 1] as Array[int], "edges are included")
	check_eq(GridBackground.line_indices(0.0, 100.0, 0.0).size(), 0, "zero size is safe")
