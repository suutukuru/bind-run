class_name PulseEffect
extends Node2D
## Weapon（PULSE）が出す、広がる輪の見た目だけの演出。ダメージは Weapon 側で与える。

const DURATION: float = 0.25

var max_radius: float = 150.0
var color: Color = Color(1.0, 0.7, 0.3)

var _time: float = 0.0


func _init() -> void:
	z_index = 2


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()


func _draw() -> void:
	var k: float = clampf(_time / DURATION, 0.0, 1.0)
	draw_arc(Vector2.ZERO, max_radius * k, 0.0, TAU, 48, Color(color, 1.0 - k), 6.0)
