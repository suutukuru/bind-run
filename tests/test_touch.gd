extends "res://tests/test_case.gd"
## TouchMoveInput のテスト（TC-107 の自動で確認できる部分）。実際の指の操作はスマホで確認する。


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.root.remove_child(main)
	main.free()


func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func test_intent_from_drag() -> void:
	check_vec_near(TouchMoveInput.intent_from_drag(Vector2(100, 100), Vector2(180, 100), 80.0), Vector2(1, 0), "full right")
	check_vec_near(TouchMoveInput.intent_from_drag(Vector2(100, 100), Vector2(140, 100), 80.0), Vector2(0.5, 0), "half right")
	check_vec_near(TouchMoveInput.intent_from_drag(Vector2(100, 100), Vector2(100, 20), 80.0), Vector2(0, -1), "up")


func test_intent_is_clamped_to_length_one() -> void:
	var intent: Vector2 = TouchMoveInput.intent_from_drag(Vector2.ZERO, Vector2(1000, 1000), 80.0)
	check_near(intent.length(), 1.0, "length")


func test_intent_with_zero_radius_is_zero() -> void:
	check_vec_near(TouchMoveInput.intent_from_drag(Vector2.ZERO, Vector2(10, 10), 0.0), Vector2.ZERO)


func test_left_finger_moves_only_a() -> void:
	var main: Node = _make_main()
	var width: float = main.get_viewport().get_visible_rect().size.x
	var touch_a: TouchMoveInput = main.get_node("TouchLayer/TouchA") as TouchMoveInput
	var touch_b: TouchMoveInput = main.get_node("TouchLayer/TouchB") as TouchMoveInput
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	check_true(touch_a.target == a and touch_b.target == b, "targets resolved")

	var start: Vector2 = Vector2(width * 0.25, 300)
	touch_a._input(_touch(0, true, start))
	touch_b._input(_touch(0, true, start))
	check_true(touch_a.is_active(), "left node takes the left finger")
	check_true(not touch_b.is_active(), "right node ignores the left finger")

	touch_a._input(_drag(0, start + Vector2(80, 0)))
	touch_a._physics_process(0.016)
	touch_b._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2(1, 0), "A moves right")
	check_vec_near(b.move_intent, Vector2.ZERO, "B untouched")

	touch_a._input(_touch(0, false, start))
	check_true(not touch_a.is_active(), "finger released")
	_free_main(main)


func test_two_fingers_move_both_independently() -> void:
	var main: Node = _make_main()
	var width: float = main.get_viewport().get_visible_rect().size.x
	var touch_a: TouchMoveInput = main.get_node("TouchLayer/TouchA") as TouchMoveInput
	var touch_b: TouchMoveInput = main.get_node("TouchLayer/TouchB") as TouchMoveInput
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character

	var left: Vector2 = Vector2(width * 0.25, 300)
	var right: Vector2 = Vector2(width * 0.75, 300)
	# 同じ画面で、指 0 が左・指 1 が右（FR-001/002 の同時操作）
	for node: TouchMoveInput in [touch_a, touch_b]:
		node._input(_touch(0, true, left))
		node._input(_touch(1, true, right))
	touch_a._input(_drag(0, left + Vector2(0, -80)))
	touch_b._input(_drag(1, right + Vector2(-80, 0)))
	touch_a._physics_process(0.016)
	touch_b._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2(0, -1), "A up")
	check_vec_near(b.move_intent, Vector2(-1, 0), "B left")
	_free_main(main)


func test_released_finger_stops_writing_intent() -> void:
	var main: Node = _make_main()
	var width: float = main.get_viewport().get_visible_rect().size.x
	var touch_a: TouchMoveInput = main.get_node("TouchLayer/TouchA") as TouchMoveInput
	var a: Character = main.get_node("CharacterA") as Character
	var start: Vector2 = Vector2(width * 0.25, 300)
	touch_a._input(_touch(0, true, start))
	touch_a._input(_drag(0, start + Vector2(80, 0)))
	touch_a._physics_process(0.016)
	touch_a._input(_touch(0, false, start))
	a.move_intent = Vector2.ZERO  # キーボード側が 0 を書いた状況
	touch_a._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2.ZERO, "touch does not override after release")
	_free_main(main)
