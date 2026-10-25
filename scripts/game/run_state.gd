class_name RunState
extends Node
## 1 回のプレイ（ラン）の状態: 共有 HP・経過時間・レベル・経験値。ゲームオーバー/クリアもここで決まる。
## ゲームのルールだけを持ち、画面や入力は知らない（UI は signal を受け取って表示する）。

signal hp_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal finished(victory: bool)

## 生き残ればクリアになる時間（秒）。FR-052 の初期値は 5 分。0 以下なら時間切れなし（エンドレス）
@export var run_duration: float = 300.0
@export var max_hp: float = 100.0:
	set(value):
		# 最大 HP が増えた分だけ HP も回復する（強化の「最大 HP +」を得に感じさせるため）
		var gained: float = value - max_hp
		max_hp = value
		if _ready_done:
			hp = minf(hp + maxf(gained, 0.0), max_hp)
			hp_changed.emit(hp, max_hp)

var hp: float = 100.0:
	set(value):
		hp = clampf(value, 0.0, max_hp)
var elapsed: float = 0.0
var level: int = 1
var xp: int = 0
var kills: int = 0
var running: bool = true

var _ready_done: bool = false


## レベル level から次のレベルに上がるのに必要な経験値（data-design.md の仮決定）
static func xp_needed(for_level: int) -> int:
	return 5 + (for_level - 1) * 5


## 秒を「分:秒」の文字にする（HUD・結果・ホームで同じ書き方にする）
static func format_time(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	return "%02d:%02d" % [total / 60, total % 60]


func _ready() -> void:
	add_to_group("run_state")
	hp = max_hp
	_ready_done = true
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_needed(level), level)


func _physics_process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if run_duration > 0.0 and elapsed >= run_duration:
		_finish(true)


func take_damage(amount: float) -> void:
	if not running or amount <= 0.0:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_finish(false)


func heal(amount: float) -> void:
	hp += amount
	hp_changed.emit(hp, max_hp)


func add_xp(amount: int) -> void:
	if not running:
		return
	xp += amount
	# 一度に複数レベル上がる場合もあるので、必要量を満たす間くりかえす
	while xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed(level), level)


func _finish(victory: bool) -> void:
	running = false
	finished.emit(victory)
