extends "res://tests/test_case.gd"
## ボス（TC-170〜）: 出現の時間、ふつうの出現の停止、技（突進・全方位・扇・呼び出し）、弾、怒り、紐の倍率。
## 避けやすさ・強さの感触はスマホで確認する。

const TEST_SAVE: String = "user://test_save.cfg"


func _make_main() -> Node:
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


func _count(group: String) -> int:
	return tree.get_nodes_in_group(group).size()


# ボスをキャラから離れた所に出す（勝手に動いて結果が変わらないよう、技はテストから始める）
func _boss_far_away(main: Node) -> Boss:
	var boss: Boss = (main.get_node("EnemySpawner") as EnemySpawner).spawn_boss()
	boss.global_position = Vector2(3000, 0)
	return boss


func test_the_move_order_uses_every_move() -> void:
	var moves: Array = []
	for i: int in Boss.MOVE_ORDER.size():
		moves.append(Boss.next_move(i))
	for move: int in [Boss.CHARGE_WINDUP, Boss.RING, Boss.FAN, Boss.SUMMON]:
		check_true(moves.has(move), "move %d is used" % move)
	check_eq(Boss.next_move(Boss.MOVE_ORDER.size()), Boss.next_move(0), "the order repeats")


func test_the_boss_appears_at_five_minutes_and_stops_normal_spawns() -> void:
	SaveData.path = TEST_SAVE
	RunSetup.start_stage(1)
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	state.elapsed = 299.0
	spawner._physics_process(0.016)
	check_true(spawner.boss == null, "no boss before five minutes")
	state.elapsed = 300.0
	spawner._physics_process(0.016)
	check_true(spawner.boss != null, "the boss appears")
	check_near(state.boss_at, 0.0, "only one boss")
	check_true((main.get_node("Hud") as Hud)._boss == spawner.boss, "the hud shows the boss bar")
	var before: int = _count("enemies")
	spawner._timer = 0.0
	spawner._physics_process(0.016)
	check_eq(_count("enemies"), before, "no normal spawns during the boss")
	_free_main(main)


func test_the_boss_is_tougher_in_later_stages() -> void:
	SaveData.path = TEST_SAVE
	RunSetup.start_stage(10)
	var main: Node = _make_main()
	var boss: Boss = _boss_far_away(main)
	check_near(boss.max_hp(), boss.def.max_hp * StagePool.get_stage(10).enemy_hp_scale, "scaled hp")
	check_near(boss.hp, boss.max_hp(), "full hp")
	_free_main(main)


func test_the_charge_is_telegraphed_then_fast() -> void:
	var main: Node = _make_main()
	var boss: Boss = _boss_far_away(main)
	var def: BossDef = boss.boss_def()
	boss.begin_move(Boss.CHARGE_WINDUP)
	var start: Vector2 = boss.global_position
	boss._physics_process(def.charge_windup * 0.5)
	check_vec_near(boss.global_position, start, "stands still while winding up")
	boss._physics_process(def.charge_windup * 0.6)
	check_eq(boss.state, Boss.CHARGE, "charges after the windup")
	var before: Vector2 = boss.global_position
	boss._physics_process(0.1)
	check_near(boss.global_position.distance_to(before), def.charge_speed * 0.1, "charge speed", 0.5)
	check_true(boss.global_position.x < before.x, "charges toward the characters")
	_free_main(main)


func test_ring_and_fan_fire_bullets() -> void:
	var main: Node = _make_main()
	var boss: Boss = _boss_far_away(main)
	var def: BossDef = boss.boss_def()
	boss.begin_move(Boss.RING)
	boss._physics_process(0.016)
	check_eq(_count("enemy_bullets"), def.ring_bullets, "a ring of bullets")
	boss.begin_move(Boss.FAN)
	boss._physics_process(0.016)
	check_eq(_count("enemy_bullets"), def.ring_bullets + def.fan_bullets, "a fan of bullets")
	_free_main(main)


func test_summon_calls_minions() -> void:
	var main: Node = _make_main()
	var boss: Boss = _boss_far_away(main)
	var before: int = _count("enemies")
	boss.begin_move(Boss.SUMMON)
	check_eq(_count("enemies"), before + boss.boss_def().summon_count, "minions appear")
	_free_main(main)


func test_a_bullet_hurts_the_shared_hp() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var a: Character = main.get_node("CharacterA") as Character
	var bullet: EnemyBullet = EnemyBullet.new()
	bullet.damage = 8.0
	bullet.position = a.global_position
	main.get_node("EnemySpawner").add_child(bullet)
	bullet._physics_process(0.016)
	check_near(state.hp, state.max_hp - 8.0, "bullet damage")
	_free_main(main)


func test_the_boss_enrages_below_half_hp() -> void:
	var main: Node = _make_main()
	var boss: Boss = _boss_far_away(main)
	check_true(not boss.is_enraged(), "calm at full hp")
	boss.take_damage(boss.max_hp() * 0.6)
	check_true(boss.is_enraged(), "enraged below half")
	boss.begin_move(Boss.CHARGE_WINDUP)
	check_eq(boss._charges_left, 2, "double charge when enraged")
	_free_main(main)


func test_the_rope_hurts_the_boss_more() -> void:
	var main: Node = _make_main()
	var rope: Rope = main.get_node("Rope") as Rope
	var attack: RopeAttack = main.get_node("RopeAttack") as RopeAttack
	var a: Character = main.get_node("CharacterA") as Character
	var b: Character = main.get_node("CharacterB") as Character
	rope.config.stiffness = 0.0
	a.global_position = Vector2(0, 0)
	b.global_position = Vector2(1200, 0)
	rope.hub = Vector2(600, 0)
	var boss: Boss = _boss_far_away(main)
	boss.global_position = Vector2(300, 0)
	rope.step()
	attack.step(0.016)
	check_near(boss.max_hp() - boss.hp, rope.config.attack_damage * boss.def.rope_damage_multiplier, "rope damage x multiplier")
	check_true(boss.def.rope_damage_multiplier > 1.0, "the rope is the boss killer")
	_free_main(main)


func test_endless_schedules_the_next_boss_after_a_win() -> void:
	SaveData.path = TEST_SAVE
	RunSetup.start_endless()
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	check_near(state.boss_at, 300.0, "first boss at five minutes")
	var boss: Boss = _boss_far_away(main)
	state.elapsed = 400.0
	boss.take_damage(boss.max_hp())
	check_true(state.running, "endless goes on")
	check_near(state.boss_at, 700.0, "next boss five minutes later")
	_free_main(main)
