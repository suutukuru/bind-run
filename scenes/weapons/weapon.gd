class_name Weapon
extends Node
## キャラクターの子として置く自動攻撃の武器。def の pattern で攻撃のしかたが変わる。
## 強化で書き換える値（damage / cooldown / reach）は実行時のコピーに持つ。

@export var def: WeaponDef

var damage: float = 1.0
var cooldown: float = 1.0
var reach: float = 100.0
var projectile_speed: float = 500.0

var _timer: float = 0.0


func _ready() -> void:
	if def == null:
		push_error("Weapon: def が未設定です")
		return
	damage = def.damage
	cooldown = def.cooldown
	reach = def.reach
	projectile_speed = def.projectile_speed


func _physics_process(delta: float) -> void:
	var character: Character = get_parent() as Character
	if character == null or def == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	# 標的がいない間は待機し、現れた瞬間に撃てるよう _timer は 0 以下のままにする
	var fired: bool = false
	if def.pattern == WeaponDef.PULSE:
		fired = _pulse(character)
	else:
		fired = _shoot(character)
	if fired:
		_timer = cooldown


func _shoot(character: Character) -> bool:
	var target: Enemy = _nearest_enemy(character.global_position, reach)
	if target == null:
		return false
	var projectile: Projectile = Projectile.new()
	projectile.position = character.global_position
	projectile.direction = (target.global_position - character.global_position).normalized()
	projectile.speed = projectile_speed
	projectile.damage = damage
	projectile.max_distance = reach * 1.5
	character.get_parent().add_child(projectile)
	return true


func _pulse(character: Character) -> bool:
	var hit_any: bool = false
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.def == null or enemy.is_dead():
			continue
		if character.global_position.distance_to(enemy.global_position) <= reach + enemy.def.radius:
			enemy.take_damage(damage)
			hit_any = true
	if hit_any:
		var effect: PulseEffect = PulseEffect.new()
		effect.position = character.global_position
		effect.max_radius = reach
		character.get_parent().add_child(effect)
	return hit_any


func _nearest_enemy(from: Vector2, max_distance: float) -> Enemy:
	var best: Enemy = null
	var best_dist: float = max_distance
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var d: float = from.distance_to(enemy.global_position)
		if d <= best_dist:
			best_dist = d
			best = enemy
	return best
