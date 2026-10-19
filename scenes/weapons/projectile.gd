class_name Projectile
extends Node2D
## Weapon（SHOT）が撃つ弾。最初に当たった敵 1 体にダメージを与えて消える。

const RADIUS: float = 7.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 560.0
var damage: float = 10.0
var max_distance: float = 540.0

var _travelled: float = 0.0


func _init() -> void:
	z_index = 2


func _physics_process(delta: float) -> void:
	var step: Vector2 = direction * speed * delta
	global_position += step
	_travelled += step.length()
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.def == null or enemy.is_dead():
			continue
		if global_position.distance_to(enemy.global_position) <= enemy.def.radius + RADIUS:
			enemy.take_damage(damage)
			queue_free()
			return
	if _travelled >= max_distance:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.65, 0.88, 1.0))
