extends "res://tests/test_case.gd"
## キーボード割り当てと、入力 → move_intent の流れの確認（TC-103 の自動で確認できる部分）。


func test_actions_are_registered_with_keys() -> void:
	InputActions.register()
	for action: String in InputActions.KEYS:
		check_true(InputMap.has_action(action), "%s is registered" % action)
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		check_eq(events.size(), 1, "%s has exactly one event" % action)
		if events.size() == 1:
			var key: InputEventKey = events[0] as InputEventKey
			check_true(key != null, "%s event is a key" % action)
			if key != null:
				check_eq(key.physical_keycode, InputActions.KEYS[action], "%s keycode" % action)


func test_register_twice_does_not_duplicate_events() -> void:
	InputActions.register()
	InputActions.register()
	check_eq(InputMap.action_get_events("a_left").size(), 1, "a_left events after 2 calls")


func test_a_and_b_do_not_share_keys() -> void:
	var seen: Dictionary = {}
	for action: String in InputActions.KEYS:
		var code: int = InputActions.KEYS[action]
		check_true(not seen.has(code), "key of %s is not used twice" % action)
		seen[code] = true


func test_key_input_moves_only_its_target() -> void:
	InputActions.register()
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var a: Character = main.get_node("CharacterA") as Character
	var input_a: KeyboardMoveInput = main.get_node("InputA") as KeyboardMoveInput
	check_true(input_a.target == a, "InputA targets CharacterA")

	Input.action_press("a_right")
	input_a._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2(1, 0), "A moves right")

	Input.action_release("a_right")
	input_a._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2.ZERO, "A stops")

	root.remove_child(main)
	main.free()


func test_b_moves_independently_of_a() -> void:
	InputActions.register()
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	var input_a: KeyboardMoveInput = main.get_node("InputA") as KeyboardMoveInput
	var input_b: KeyboardMoveInput = main.get_node("InputB") as KeyboardMoveInput
	check_true(input_b.target == b, "InputB targets CharacterB")

	# B だけを押す: A は動かない
	Input.action_press("b_up")
	input_a._physics_process(0.016)
	input_b._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2.ZERO, "A stays while only B is pressed")
	check_vec_near(b.move_intent, Vector2(0, -1), "B moves up")

	# 同時に押す: それぞれが自分の方向へ（同時操作、FR-001/002）
	Input.action_press("a_left")
	input_a._physics_process(0.016)
	input_b._physics_process(0.016)
	check_vec_near(a.move_intent, Vector2(-1, 0), "A moves left")
	check_vec_near(b.move_intent, Vector2(0, -1), "B keeps moving up")

	Input.action_release("a_left")
	Input.action_release("b_up")
	root.remove_child(main)
	main.free()
