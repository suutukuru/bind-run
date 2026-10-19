extends "res://tests/test_case.gd"
## 戦闘まわり（敵・武器・紐攻撃・共有 HP）のテスト。TC-201〜。メインシーンを組み立てて、時間を進めずに直接呼ぶ。

const GRUNT: String = "res://data/enemies/grunt.tres"


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.root.remove_child(main)
	main.free()


func _spawn(main: Node, pos: Vector2, path: String = GRUNT) -> Enemy:
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	return spawner.spawn_enemy(load(path) as EnemyDef, pos)


func test_enemy_takes_damage_and_dies() -> void:
	var main: Node = _make_main()
	var enemy: Enemy = _spawn(main, Vector2(2000, 2000))
	var state: Dictionary = {"died": false}
	enemy.died.connect(func(_e: Enemy) -> void: state["died"] = true)
	enemy.take_damage(10.0)
	check_near(enemy.hp, 14.0, "hp after 10 damage")
	check_true(not state["died"], "still alive")
	enemy.take_damage(100.0)
	check_true(state["died"], "died signal")
	check_true(enemy.is_dead(), "dead flag")
	_free_main(main)


func test_enemy_moves_toward_the_nearest_character() -> void:
	var main: Node = _make_main()
	var a: Character = main.get_node("CharacterA") as Character
	var enemy: Enemy = _spawn(main, a.global_position + Vector2(300, 0))
	var before: float = enemy.global_position.distance_to(a.global_position)
	enemy._physics_process(0.5)
	check_true(enemy.global_position.distance_to(a.global_position) < before, "got closer")
	_free_main(main)


func test_contact_damage_hits_the_shared_hp_with_a_cooldown() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var a: Character = main.get_node("CharacterA") as Character
	var enemy: Enemy = _spawn(main, a.global_position)
	var full: float = state.hp
	enemy._physics_process(0.016)
	check_true(state.hp < full, "damaged on contact")
	var after_first: float = state.hp
	enemy._physics_process(0.016)
	check_near(state.hp, after_first, "no second hit during the cooldown")
	enemy._physics_process(Enemy.CONTACT_INTERVAL)
	check_true(state.hp < after_first, "hits again after the interval")
	_free_main(main)


func test_run_state_game_over_and_victory() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var result: Dictionary = {"count": 0, "victory": null}
	state.finished.connect(func(v: bool) -> void:
		result["count"] += 1
		result["victory"] = v)
	state.take_damage(state.max_hp)
	check_eq(result["count"], 1, "finished once")
	check_eq(result["victory"], false, "defeat")
	state.take_damage(10.0)
	check_eq(result["count"], 1, "no second finish")
	_free_main(main)

	var main2: Node = _make_main()
	var state2: RunState = main2.get_node("RunState") as RunState
	var result2: Dictionary = {"victory": null}
	state2.finished.connect(func(v: bool) -> void: result2["victory"] = v)
	state2._physics_process(state2.run_duration + 1.0)
	check_eq(result2["victory"], true, "victory after the duration")
	_free_main(main2)


func test_xp_levels_up_and_carries_over() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var levels: Array = []
	state.leveled_up.connect(func(l: int) -> void: levels.append(l))
	state.add_xp(4)
	check_eq(levels.size(), 0, "not yet")
	state.add_xp(1)  # 合計 5 → Lv2
	check_eq(levels, [2], "level 2")
	check_eq(state.xp, 0, "xp reset")
	state.add_xp(100)  # 一度に複数レベル
	check_true(levels.size() >= 3, "several levels at once")
	_free_main(main)


func test_blaster_shoots_the_nearest_enemy() -> void:
	var main: Node = _make_main()
	var a: Character = main.get_node("CharacterA") as Character
	var weapon: Weapon = main.get_node("CharacterA/Weapon") as Weapon
	var near: Enemy = _spawn(main, a.global_position + Vector2(150, 0))
	var far: Enemy = _spawn(main, a.global_position + Vector2(300, 0))
	weapon._physics_process(0.016)
	var projectile: Projectile = null
	for child: Node in main.get_children():
		if child is Projectile:
			projectile = child
	check_true(projectile != null, "a projectile was fired")
	if projectile != null:
		for frame: int in 40:
			projectile._physics_process(1.0 / 60.0)
			if projectile.is_queued_for_deletion():
				break
		check_true(near.hp < near.def.max_hp, "the nearest enemy was hit")
		check_near(far.hp, far.def.max_hp, "the far one was not")
	_free_main(main)


func test_blaster_waits_when_there_is_no_target() -> void:
	var main: Node = _make_main()
	var weapon: Weapon = main.get_node("CharacterA/Weapon") as Weapon
	weapon._physics_process(0.016)
	var fired: bool = false
	for child: Node in main.get_children():
		if child is Projectile:
			fired = true
	check_true(not fired, "no projectile without a target")
	_free_main(main)


func test_shockwave_hits_all_enemies_in_reach() -> void:
	var main: Node = _make_main()
	var b: Character = main.get_node("CharacterB") as Character
	var weapon: Weapon = main.get_node("CharacterB/Weapon") as Weapon
	var e1: Enemy = _spawn(main, b.global_position + Vector2(60, 0))
	var e2: Enemy = _spawn(main, b.global_position + Vector2(0, -90))
	var out: Enemy = _spawn(main, b.global_position + Vector2(600, 0))
	weapon._physics_process(0.016)
	check_true(e1.hp < e1.def.max_hp and e2.hp < e2.def.max_hp, "both inside were hit")
	check_near(out.hp, out.def.max_hp, "the outside one was not")
	_free_main(main)


func test_weapon_cooldown_is_respected() -> void:
	var main: Node = _make_main()
	var b: Character = main.get_node("CharacterB") as Character
	var weapon: Weapon = main.get_node("CharacterB/Weapon") as Weapon
	var e: Enemy = _spawn(main, b.global_position + Vector2(60, 0))
	weapon._physics_process(0.016)
	var after_first: float = e.hp
	weapon._physics_process(0.016)
	check_near(e.hp, after_first, "no second hit within the cooldown")
	weapon._physics_process(weapon.cooldown)
	check_true(e.hp < after_first, "hit again after the cooldown")
	_free_main(main)


func test_rope_attack_hits_enemies_on_a_taut_rope_only() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var attack: RopeAttack = main.get_node("RopeAttack") as RopeAttack
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(600, 0)
	rope.hub = Vector2(300, 0)
	var on_rope: Enemy = _spawn(main, Vector2(150, 0))
	var off_rope: Enemy = _spawn(main, Vector2(150, 200))
	rope.step()
	check_true(rope.stretch_ratios[0] >= rope.config.attack_threshold, "taut")
	attack.step(0.016)
	check_true(on_rope.hp < on_rope.def.max_hp, "enemy on the rope was hit")
	check_near(off_rope.hp, off_rope.def.max_hp, "enemy off the rope was not")
	check_true(rope.attack_active, "attack flag on")
	var after_first: float = on_rope.hp
	attack.step(0.016)
	check_near(on_rope.hp, after_first, "rehit interval respected")
	attack.step(rope.config.attack_rehit_interval)
	check_true(on_rope.hp < after_first, "hit again after the interval")
	_free_main(main)


func test_rope_attack_is_off_when_the_rope_is_slack() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var attack: RopeAttack = main.get_node("RopeAttack") as RopeAttack
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(60, 0)
	rope.hub = Vector2(30, 0)
	var enemy: Enemy = _spawn(main, Vector2(30, 0))
	rope.step()
	attack.step(0.016)
	check_near(enemy.hp, enemy.def.max_hp, "slack rope does not hurt")
	check_true(not rope.attack_active, "attack flag off")
	_free_main(main)


func test_spawner_schedule_helpers() -> void:
	check_near(EnemySpawner.interval_at(0.0, 1.1, 0.3, 240.0), 1.1, "start")
	check_near(EnemySpawner.interval_at(240.0, 1.1, 0.3, 240.0), 0.3, "end")
	check_near(EnemySpawner.interval_at(999.0, 1.1, 0.3, 240.0), 0.3, "clamped")
	check_eq(EnemySpawner.count_at(0.0), 1, "count at 0")
	check_eq(EnemySpawner.count_at(180.0), 3, "count at 180")
	check_eq(EnemySpawner.weights_at(0.0), PackedFloat32Array([1.0, 0.0, 0.0]), "only grunts at first")
	check_true(EnemySpawner.weights_at(100.0)[2] > 0.0, "tanks appear later")
	var w: PackedFloat32Array = PackedFloat32Array([1.0, 0.0, 1.0])
	check_eq(EnemySpawner.pick_index(w, 0.1), 0, "low roll")
	check_eq(EnemySpawner.pick_index(w, 0.9), 2, "high roll skips zero weight")


func test_spawned_enemies_start_outside_the_view() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var camera: FollowCamera = main.get_node("Camera") as FollowCamera
	spawner.seed_value = 7
	spawner.rng.seed = 7
	spawner._spawn_one(0.0)
	var enemies: Array[Node] = tree.get_nodes_in_group("enemies")
	check_eq(enemies.size(), 1, "one enemy spawned")
	if enemies.size() == 1:
		var half: Vector2 = camera.visible_world_size() * 0.5
		var offset: Vector2 = (enemies[0] as Node2D).global_position - camera.global_position
		check_true(absf(offset.x) > half.x or absf(offset.y) > half.y, "outside the visible rectangle")
	_free_main(main)
