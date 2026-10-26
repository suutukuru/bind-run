class_name EnemySpawner
extends Node2D
## 時間とともに増える敵を、画面の外から出現させる。出現した敵はこのノードの子になる。
## RunState.boss_at の時間になったらボスを出し、ボスがいる間はふつうの出現を止める。

signal boss_spawned(boss: Boss)
signal boss_defeated(boss: Boss)

## 敵の定義（[0] Grunt, [1] Runner, [2] Tank の順）
@export var defs: Array = []
@export var camera_path: NodePath
@export var run_state_path: NodePath
@export var base_interval: float = 0.7
@export var min_interval: float = 0.2
## 出現間隔が min_interval に達するまでの時間（秒）
@export var ramp_seconds: float = 240.0
@export var max_alive: int = 180
## 経験値オーブを拾える距離（強化「Magnet」の対象）
@export var orb_pickup_radius: float = 70.0
## ステージごとの難しさ（Main がラン開始時に設定する）。出現間隔に掛ける倍率。小さいほど多い
@export var interval_scale: float = 1.0
## 敵の HP に掛ける倍率
@export var hp_scale: float = 1.0
## 1 分ごとに敵の HP の倍率に足す量（エンドレスで時間とともに硬くするため）
@export var hp_growth_per_minute: float = 0.0
## ボスの定義（ステージ・エンドレスで出る）
@export var boss_def: BossDef
## 0 以外なら乱数を固定する（テスト用）
@export var seed_value: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _camera: FollowCamera
var _run_state: RunState
var _timer: float = 1.0
var _alive: int = 0
## 戦っているボス（いなければ null）
var boss: Boss = null


## 経過時間 t での出現間隔（秒）。時間とともに短くなる
static func interval_at(t: float, base: float, min_value: float, ramp: float) -> float:
	if ramp <= 0.0:
		return min_value
	return lerpf(base, min_value, clampf(t / ramp, 0.0, 1.0))


## 1 回の出現で出す数。1 分ごとに 1 体増える
static func count_at(t: float) -> int:
	return 1 + int(t / 60.0)


## 敵の種類の重み [Grunt, Runner, Tank]。Runner は 30 秒後、Tank は 90 秒後から混ざる
static func weights_at(t: float) -> PackedFloat32Array:
	return PackedFloat32Array([1.0, 0.0 if t < 30.0 else 0.5, 0.0 if t < 90.0 else 0.25])


## 重みに従って種類を選ぶ。roll は 0.0 以上 1.0 未満の乱数
static func pick_index(weights: PackedFloat32Array, roll: float) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var target: float = roll * total
	var acc: float = 0.0
	for i: int in weights.size():
		acc += weights[i]
		if target < acc:
			return i
	return 0


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as FollowCamera
	_run_state = get_node_or_null(run_state_path) as RunState
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func _physics_process(delta: float) -> void:
	if _run_state != null and not _run_state.running:
		return
	var t: float = _run_state.elapsed if _run_state != null else 0.0
	if _run_state != null and _run_state.boss_at > 0.0 and boss == null and t >= _run_state.boss_at:
		spawn_boss()
	# ボス戦の間はふつうの出現を止める（ボスの技と手下に集中させる）
	if boss != null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	for i: int in count_at(t):
		_spawn_one(t)
	_timer = interval_at(t, base_interval, min_interval, ramp_seconds) * interval_scale


func spawn_enemy(def: EnemyDef, pos: Vector2) -> Enemy:
	var enemy: Enemy = Enemy.new()
	enemy.def = def
	enemy.hp_scale = current_hp_scale()
	enemy.position = pos
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	_alive += 1
	return enemy


## 今出す敵の HP の倍率（ステージの倍率 + エンドレスの時間による増加）
func current_hp_scale() -> float:
	var t: float = _run_state.elapsed if _run_state != null else 0.0
	return hp_scale + hp_growth_per_minute * t / 60.0


func spawn_boss() -> Boss:
	if boss_def == null:
		push_error("EnemySpawner: boss_def が未設定です")
		return null
	var new_boss: Boss = Boss.new()
	new_boss.def = boss_def
	new_boss.spawner = self
	new_boss.hp_scale = current_hp_scale()
	new_boss.position = _offscreen_position()
	new_boss.died.connect(_on_enemy_died)
	new_boss.died.connect(_on_boss_died)
	add_child(new_boss)
	_alive += 1
	boss = new_boss
	if _run_state != null:
		_run_state.boss_at = 0.0
	boss_spawned.emit(new_boss)
	return new_boss


func _spawn_one(t: float) -> void:
	if _alive >= max_alive or defs.is_empty():
		return
	var index: int = pick_index(weights_at(t), rng.randf())
	var def: EnemyDef = defs[mini(index, defs.size() - 1)] as EnemyDef
	spawn_enemy(def, _offscreen_position())


func _offscreen_position() -> Vector2:
	var center: Vector2 = Vector2.ZERO
	var radius: float = 700.0
	if _camera != null:
		center = _camera.global_position
		# 画面の外に出すため、見えている範囲の対角線の半分より少し遠くを使う
		radius = _camera.visible_world_size().length() * 0.5 + 80.0
	return center + Vector2.from_angle(rng.randf() * TAU) * radius


func _on_boss_died(enemy: Enemy) -> void:
	boss = null
	boss_defeated.emit(enemy as Boss)


func _on_enemy_died(enemy: Enemy) -> void:
	_alive = maxi(0, _alive - 1)
	if _run_state != null:
		_run_state.kills += 1
	_drop_reward(enemy)


# 倒した敵の位置に経験値オーブを落とす
func _drop_reward(enemy: Enemy) -> void:
	var orb: XpOrb = XpOrb.new()
	orb.value = enemy.def.xp_value
	orb.position = enemy.position
	orb.spawner = self
	add_child(orb)
