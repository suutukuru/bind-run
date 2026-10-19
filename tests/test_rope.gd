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
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(400, 0)
	rope.step()
	var limit: float = rope.config.max_radius * 2.0
	check_near(a.global_position.distance_to(b.global_position), limit, "distance", MAX_DISTANCE_TOLERANCE)
	check_vec_near(rope.hub, Vector2(200, 0), "hub stays at the midpoint")
	check_vec_near(a.global_position, Vector2(40, 0), "A")
	check_vec_near(b.global_position, Vector2(360, 0), "B")
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
		b.global_position = Vector2(400, 0)
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
