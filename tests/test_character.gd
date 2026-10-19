extends "res://tests/test_case.gd"
## Character の速度計算（TC-103 の「斜めで速くならない」の自動版）と、メインシーンの構成確認（TC-102 の一部）。


func test_velocity_scales_with_intent() -> void:
	check_vec_near(Character.velocity_for(Vector2(1, 0), 200.0), Vector2(200, 0))
	check_vec_near(Character.velocity_for(Vector2(0.5, 0), 200.0), Vector2(100, 0))
	check_vec_near(Character.velocity_for(Vector2.ZERO, 200.0), Vector2.ZERO)


func test_diagonal_is_not_faster() -> void:
	# 斜め入力 (1,1) の長さは約 1.41 だが、1 に抑えられる
	var v: Vector2 = Character.velocity_for(Vector2(1, 1), 200.0)
	check_near(v.length(), 200.0, "speed")


func test_main_scene_has_two_distinct_characters() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn")
	check_true(packed != null, "main.tscn loads")
	if packed == null:
		return
	var main: Node = packed.instantiate()
	var a: Character = main.get_node_or_null("CharacterA") as Character
	var b: Character = main.get_node_or_null("CharacterB") as Character
	check_true(a != null, "CharacterA exists")
	check_true(b != null, "CharacterB exists")
	if a != null and b != null:
		check_true(a.body_color != b.body_color, "A and B have different colors")
		check_true(a.position != b.position, "A and B start at different positions")
	main.free()
