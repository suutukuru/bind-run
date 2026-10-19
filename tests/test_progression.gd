extends "res://tests/test_case.gd"
## 経験値・レベルアップ・強化・メニューの流れ（TC-3xx）。


func _make_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _free_main(main: Node) -> void:
	tree.paused = false
	tree.root.remove_child(main)
	main.free()


func test_every_upgrade_in_the_pool_applies_to_the_main_scene() -> void:
	var main: Node = _make_main()
	var seen: Dictionary = {}
	for item: Variant in UpgradePool.all():
		var def: UpgradeDef = item as UpgradeDef
		check_true(def != null, "pool entry is an UpgradeDef")
		if def == null:
			continue
		check_true(not seen.has(def.id), "unique id: %s" % def.id)
		seen[def.id] = true
		check_true(def.apply_to(main), "applies: %s" % def.id)
	check_true(seen.size() >= 10, "at least 10 upgrades")
	_free_main(main)


func test_multiply_and_add_upgrades_change_the_right_values() -> void:
	var main: Node = _make_main()
	var weapon: Weapon = main.get_node("CharacterA/Weapon") as Weapon
	var rope: Rope = main.get_node("Rope") as Rope
	var state: RunState = main.get_node("RunState") as RunState
	var before_damage: float = weapon.damage
	var before_radius: float = rope.config.max_radius
	(load("res://data/upgrades/blaster_damage.tres") as UpgradeDef).apply_to(main)
	check_near(weapon.damage, before_damage * 1.3, "blaster damage x1.3")
	(load("res://data/upgrades/rope_length.tres") as UpgradeDef).apply_to(main)
	check_near(rope.config.max_radius, before_radius + 40.0, "rope +40")
	(load("res://data/upgrades/max_hp.tres") as UpgradeDef).apply_to(main)
	check_near(state.max_hp, 120.0, "max hp")
	check_near(state.hp, 120.0, "healed by the gained amount")
	var shared: RopeConfig = load("res://data/rope/default_rope_config.tres") as RopeConfig
	check_near(shared.max_radius, 480.0, "the shared .tres is untouched")
	_free_main(main)


func test_picker_returns_distinct_choices_and_honours_max_stacks() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	var picks: Array = UpgradePicker.pick(UpgradePool.all(), {}, 3, rng)
	check_eq(picks.size(), 3, "three choices")
	var ids: Dictionary = {}
	for item: Variant in picks:
		ids[(item as UpgradeDef).id] = true
	check_eq(ids.size(), 3, "distinct")

	# 上限に達した強化は出ない
	var counts: Dictionary = {}
	for item: Variant in UpgradePool.all():
		var def: UpgradeDef = item as UpgradeDef
		counts[def.id] = def.max_stacks
	counts[&"magnet"] = 0
	var only: Array = UpgradePicker.pick(UpgradePool.all(), counts, 3, rng)
	check_eq(only.size(), 1, "only the non-maxed one remains")
	check_eq((only[0] as UpgradeDef).id, &"magnet", "it is the magnet")
	check_eq(UpgradePicker.pick([], {}, 3, rng).size(), 0, "empty pool")


func test_picker_is_reproducible_with_a_seed() -> void:
	var a: RandomNumberGenerator = RandomNumberGenerator.new()
	var b: RandomNumberGenerator = RandomNumberGenerator.new()
	a.seed = 7
	b.seed = 7
	var first: Array = UpgradePicker.pick(UpgradePool.all(), {}, 3, a)
	var second: Array = UpgradePicker.pick(UpgradePool.all(), {}, 3, b)
	for i: int in 3:
		check_eq((first[i] as UpgradeDef).id, (second[i] as UpgradeDef).id, "same pick %d" % i)


func test_killed_enemy_drops_an_orb_that_gives_xp() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var state: RunState = main.get_node("RunState") as RunState
	var a: Character = main.get_node("CharacterA") as Character
	var enemy: Enemy = spawner.spawn_enemy(load("res://data/enemies/tank.tres") as EnemyDef, a.global_position + Vector2(5, 0))
	enemy.take_damage(1000.0)
	check_eq(state.kills, 1, "kill counted")
	var orbs: Array[Node] = tree.get_nodes_in_group("orbs")
	check_eq(orbs.size(), 1, "one orb dropped")
	if orbs.size() == 1:
		var orb: XpOrb = orbs[0] as XpOrb
		check_eq(orb.value, 3, "tank orb is worth 3")
		orb._physics_process(0.016)
		check_eq(state.xp, 3, "xp gained when touched")
	_free_main(main)


func test_orb_is_pulled_in_from_the_pickup_range() -> void:
	var main: Node = _make_main()
	var spawner: EnemySpawner = main.get_node("EnemySpawner") as EnemySpawner
	var a: Character = main.get_node("CharacterA") as Character
	var orb: XpOrb = XpOrb.new()
	orb.spawner = spawner
	orb.position = a.global_position + Vector2(spawner.orb_pickup_radius - 5.0, 0)
	spawner.add_child(orb)
	var before: float = orb.global_position.distance_to(a.global_position)
	orb._physics_process(0.05)
	check_true(orb.global_position.distance_to(a.global_position) < before, "pulled toward the character")
	var far: XpOrb = XpOrb.new()
	far.spawner = spawner
	far.position = a.global_position + Vector2(spawner.orb_pickup_radius + 200.0, 0)
	spawner.add_child(far)
	var far_before: Vector2 = far.global_position
	far._physics_process(0.05)
	check_vec_near(far.global_position, far_before, "an orb out of range stays")
	_free_main(main)


func test_level_up_opens_a_paused_menu_and_choosing_applies_the_upgrade() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	state.add_xp(RunState.xp_needed(1))
	check_true(menu.is_open(), "menu opened on level up")
	check_true(tree.paused, "game paused while choosing")
	check_eq(menu.option_count(), 3, "three choices")
	menu.press(0)
	check_true(not menu.is_open(), "menu closed after choosing")
	check_true(not tree.paused, "game resumed")
	var total: int = 0
	for item: Variant in UpgradePool.all():
		total += main.upgrade_count((item as UpgradeDef).id)
	check_eq(total, 1, "exactly one upgrade recorded")
	_free_main(main)


func test_several_level_ups_ask_for_several_choices() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	state.add_xp(RunState.xp_needed(1) + RunState.xp_needed(2))  # 2 レベル分
	check_true(menu.is_open(), "first choice")
	menu.press(0)
	check_true(menu.is_open(), "second choice follows")
	menu.press(0)
	check_true(not menu.is_open(), "done after two choices")
	_free_main(main)


func test_game_over_shows_the_result_menu() -> void:
	var main: Node = _make_main()
	var state: RunState = main.get_node("RunState") as RunState
	var menu: MenuPanel = main.get_node("MenuPanel") as MenuPanel
	state.take_damage(state.max_hp)
	check_true(menu.is_open(), "result menu")
	check_eq(menu.option_count(), 2, "RETRY and TITLE")
	check_true(tree.paused, "game stopped")
	_free_main(main)


func test_title_scene_builds_its_menu() -> void:
	var title: Node = (load("res://scenes/title/title.tscn") as PackedScene).instantiate()
	tree.root.add_child(title)
	var menu: MenuPanel = null
	for child: Node in title.get_children():
		if child is MenuPanel:
			menu = child
	check_true(menu != null and menu.is_open(), "title menu is open")
	check_true(not tree.paused, "the title does not pause the tree")
	tree.root.remove_child(title)
	title.free()
