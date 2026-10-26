class_name Boss
extends Enemy
## ボス。追いかけながら、突進・全方位弾・狙い撃ち・手下の呼び出しを順番に使う。
## 技の前には予告（突進の線・色の変化）を出して、見てから避けられるようにする。
## HP が半分を切ると怒り状態になり、技の間隔が短く、突進が 2 連続になる。

## 行動（クラス自身の enum を型にしない: ADR-011）
const CHASE: int = 0
const CHARGE_WINDUP: int = 1
const CHARGE: int = 2
const RING: int = 3
const FAN: int = 4
const SUMMON: int = 5
## 追いかけた後に使う技の順番（くり返す）
const MOVE_ORDER: Array = [CHARGE_WINDUP, RING, CHARGE_WINDUP, FAN, SUMMON]
## 突進の予告の線の長さ（px）
const TELEGRAPH_LENGTH: float = 700.0

## 手下を呼ぶ・弾を置く先
var spawner: EnemySpawner
var state: int = CHASE

var _state_time: float = 0.0
var _order_index: int = 0
var _charge_dir: Vector2 = Vector2.RIGHT
var _charges_left: int = 0
var _shots_left: int = 0
var _shot_timer: float = 0.0


## index 回目に使う技
static func next_move(index: int) -> int:
	return MOVE_ORDER[index % MOVE_ORDER.size()]


func boss_def() -> BossDef:
	return def as BossDef


func is_enraged() -> bool:
	return hp <= max_hp() * boss_def().enrage_hp_ratio


## 技を始める（テストからも呼べる）
func begin_move(move: int) -> void:
	var b: BossDef = boss_def()
	if move == CHARGE_WINDUP:
		_charges_left = 2 if is_enraged() else 1
		_set_state(CHARGE_WINDUP)
	elif move == RING:
		_shots_left = b.ring_waves
		_shot_timer = 0.0
		_set_state(RING)
	elif move == FAN:
		_shots_left = b.fan_waves
		_shot_timer = 0.0
		_set_state(FAN)
	elif move == SUMMON:
		_summon()
		_set_state(CHASE)
	else:
		_set_state(CHASE)


func _move(delta: float, target: Character) -> void:
	var b: BossDef = boss_def()
	_state_time += delta
	if state == CHASE:
		super._move(delta, target)
		if _state_time >= b.chase_time * _time_scale():
			begin_move(next_move(_order_index))
			_order_index += 1
	elif state == CHARGE_WINDUP:
		# 溜めの間は相手の方を向き続け、溜め終わった瞬間の向きで突っ込む
		var to_target: Vector2 = target.global_position - global_position
		if to_target.length() > 0.001:
			_charge_dir = to_target.normalized()
		queue_redraw()
		if _state_time >= b.charge_windup * _time_scale():
			_set_state(CHARGE)
	elif state == CHARGE:
		global_position += _charge_dir * b.charge_speed * delta
		if _state_time >= b.charge_time:
			_charges_left -= 1
			_set_state(CHARGE_WINDUP if _charges_left > 0 else CHASE)
	elif state == RING or state == FAN:
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			if state == RING:
				_shoot_ring(b.ring_waves - _shots_left)
			else:
				_shoot_fan(target)
			_shots_left -= 1
			_shot_timer = b.shot_interval * _time_scale()
			if _shots_left <= 0:
				_set_state(CHASE)


func _time_scale() -> float:
	return boss_def().enrage_time_scale if is_enraged() else 1.0


func _set_state(value: int) -> void:
	state = value
	_state_time = 0.0
	queue_redraw()


# 全方位。回ごとに角度を半分ずらし、弾の隙間を変える
func _shoot_ring(wave: int) -> void:
	var b: BossDef = boss_def()
	var offset: float = PI / maxf(1.0, b.ring_bullets) * (wave % 2)
	for i: int in b.ring_bullets:
		_fire(Vector2.from_angle(offset + TAU * i / b.ring_bullets))


# 一番近いキャラを狙って扇形に撃つ
func _shoot_fan(target: Character) -> void:
	var b: BossDef = boss_def()
	var base: float = (target.global_position - global_position).angle()
	var spread: float = deg_to_rad(b.fan_spread_degrees)
	for i: int in b.fan_bullets:
		var t: float = 0.5 if b.fan_bullets <= 1 else float(i) / (b.fan_bullets - 1)
		_fire(Vector2.from_angle(base - spread * 0.5 + spread * t))


func _fire(direction: Vector2) -> void:
	var bullet: EnemyBullet = EnemyBullet.new()
	bullet.velocity = direction * boss_def().bullet_speed
	bullet.damage = boss_def().bullet_damage
	bullet.position = global_position
	get_parent().add_child(bullet)


func _summon() -> void:
	var b: BossDef = boss_def()
	if spawner == null or b.summon_def == null:
		return
	for i: int in b.summon_count:
		var offset: Vector2 = Vector2.from_angle(TAU * i / b.summon_count) * (b.radius + 50.0)
		spawner.spawn_enemy(b.summon_def, global_position + offset)


func _draw() -> void:
	super._draw()
	if def == null:
		return
	# 怒り状態は外側の赤い輪で知らせる
	if is_enraged():
		draw_arc(Vector2.ZERO, def.radius + 10.0, 0.0, TAU, 48, Color(1, 0.2, 0.2, 0.8), 5.0)
	if state == CHARGE_WINDUP:
		draw_line(Vector2.ZERO, _charge_dir * TELEGRAPH_LENGTH, Color(1, 0.25, 0.25, 0.45), def.radius * 0.8)
	elif state == RING or state == FAN:
		draw_arc(Vector2.ZERO, def.radius * 0.6, 0.0, TAU, 32, Color(1, 0.35, 0.8, 0.9), 6.0)
