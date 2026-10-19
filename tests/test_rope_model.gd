extends "res://tests/test_case.gd"
## RopeModel の単体テスト（TC-002〜006, TC-007 の一部）。


func test_hub_of_two_points_is_midpoint() -> void:
	var hub: Vector2 = RopeModel.hub_position(PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]))
	check_vec_near(hub, Vector2(5, 0))


func test_hub_of_three_points_is_centroid() -> void:
	var hub: Vector2 = RopeModel.hub_position(
		PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(0, 6)])
	)
	check_vec_near(hub, Vector2(4.0 / 3.0, 2.0))


func test_hub_of_empty_is_zero() -> void:
	check_vec_near(RopeModel.hub_position(PackedVector2Array()), Vector2.ZERO)


func test_constrain_inside_is_unchanged() -> void:
	check_vec_near(RopeModel.constrain(Vector2(100, 0), Vector2.ZERO, 160.0), Vector2(100, 0))


func test_constrain_on_the_edge_is_unchanged() -> void:
	check_vec_near(RopeModel.constrain(Vector2(160, 0), Vector2.ZERO, 160.0), Vector2(160, 0))


func test_constrain_outside_axis() -> void:
	check_vec_near(RopeModel.constrain(Vector2(200, 0), Vector2.ZERO, 160.0), Vector2(160, 0))


func test_constrain_outside_diagonal() -> void:
	# 距離 500 の点を 160 に縮める: (300,400) * 0.32 = (96,128)
	check_vec_near(RopeModel.constrain(Vector2(300, 400), Vector2.ZERO, 160.0), Vector2(96, 128))


func test_constrain_uses_hub_as_center() -> void:
	var result: Vector2 = RopeModel.constrain(Vector2(300, 100), Vector2(100, 100), 160.0)
	check_vec_near(result, Vector2(260, 100))


func test_constrain_at_hub_is_safe() -> void:
	var result: Vector2 = RopeModel.constrain(Vector2(50, 50), Vector2(50, 50), 160.0)
	check_vec_near(result, Vector2(50, 50))
	check_true(is_finite(result.x) and is_finite(result.y), "no NaN/inf")


func test_constrain_zero_radius_collapses_to_hub() -> void:
	check_vec_near(RopeModel.constrain(Vector2(10, 0), Vector2.ZERO, 0.0), Vector2.ZERO)


func test_stretch_ratio_table() -> void:
	check_near(RopeModel.stretch_ratio(50.0, 100.0, 160.0), 0.0, "slack")
	check_near(RopeModel.stretch_ratio(100.0, 100.0, 160.0), 0.0, "at natural")
	check_near(RopeModel.stretch_ratio(130.0, 100.0, 160.0), 0.5, "half")
	check_near(RopeModel.stretch_ratio(160.0, 100.0, 160.0), 1.0, "at max")
	check_near(RopeModel.stretch_ratio(999.0, 100.0, 160.0), 1.0, "beyond max")


func test_stretch_ratio_degenerate_range() -> void:
	# 自然長 >= 最大長でもゼロ除算せず、最大長で 1 になる
	check_near(RopeModel.stretch_ratio(50.0, 160.0, 160.0), 0.0, "below")
	check_near(RopeModel.stretch_ratio(160.0, 160.0, 160.0), 1.0, "at max")


func test_two_members_end_up_within_two_radii() -> void:
	# detailed-design の数値例: A=(0,0), B=(400,0), R=160 → 補正後の A〜B は 320
	var a: Vector2 = Vector2(0, 0)
	var b: Vector2 = Vector2(400, 0)
	var hub: Vector2 = RopeModel.hub_position(PackedVector2Array([a, b]))
	var a2: Vector2 = RopeModel.constrain(a, hub, 160.0)
	var b2: Vector2 = RopeModel.constrain(b, hub, 160.0)
	check_vec_near(a2, Vector2(40, 0), "A")
	check_vec_near(b2, Vector2(360, 0), "B")
	check_near(a2.distance_to(b2), 320.0, "distance")


func test_elastic_pull_moves_toward_hub_by_excess_share() -> void:
	# 超過 30、stiffness 3、delta 1/60 → 30 * 3 / 60 = 1.5 だけ寄る
	var result: Vector2 = RopeModel.elastic_pull(Vector2(130, 0), Vector2.ZERO, 100.0, 3.0, 1.0 / 60.0)
	check_vec_near(result, Vector2(128.5, 0))


func test_elastic_pull_does_nothing_inside_natural_length_or_without_stiffness() -> void:
	check_vec_near(RopeModel.elastic_pull(Vector2(80, 0), Vector2.ZERO, 100.0, 3.0, 0.1), Vector2(80, 0), "inside")
	check_vec_near(RopeModel.elastic_pull(Vector2(130, 0), Vector2.ZERO, 100.0, 0.0, 0.1), Vector2(130, 0), "no stiffness")
	check_vec_near(RopeModel.elastic_pull(Vector2.ZERO, Vector2.ZERO, 100.0, 3.0, 0.1), Vector2.ZERO, "at hub")


func test_elastic_pull_never_overshoots_natural_length() -> void:
	var result: Vector2 = RopeModel.elastic_pull(Vector2(130, 0), Vector2.ZERO, 100.0, 1000.0, 1.0)
	check_vec_near(result, Vector2(100, 0))


func test_follow_hub() -> void:
	check_vec_near(RopeModel.follow_hub(Vector2(0, 0), Vector2(10, 0), 0.0, 0.016), Vector2(10, 0), "no inertia")
	check_vec_near(RopeModel.follow_hub(Vector2(0, 0), Vector2(10, 0), 10.0, 0.05), Vector2(5, 0), "half way")
	check_vec_near(RopeModel.follow_hub(Vector2(0, 0), Vector2(10, 0), 1000.0, 1.0), Vector2(10, 0), "clamped to target")


func test_distance_to_segment() -> void:
	check_near(RopeModel.distance_to_segment(Vector2(0, 5), Vector2(-10, 0), Vector2(10, 0)), 5.0, "beside")
	check_near(RopeModel.distance_to_segment(Vector2(20, 0), Vector2(-10, 0), Vector2(10, 0)), 10.0, "beyond the end")
	check_near(RopeModel.distance_to_segment(Vector2(3, 4), Vector2(0, 0), Vector2(0, 0)), 5.0, "degenerate segment")
