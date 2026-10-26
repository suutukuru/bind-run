class_name BossDef
extends EnemyDef
## ボスの定義。ふつうの敵の値（HP・大きさ・接触ダメージ）に、行動パターンの値を足したもの。
## 行動は「追う → 技 → 追う → 技 …」のくり返し。HP が減ると怒り状態になり、間隔が短くなる。

@export_group("Chase")
## 技と技の間に追いかける時間（秒）
@export var chase_time: float = 2.4

@export_group("Charge")
## 突進の前の溜め（予告の線を出す）時間（秒）
@export var charge_windup: float = 0.8
@export var charge_time: float = 0.6
@export var charge_speed: float = 680.0

@export_group("Shots")
## 全方位に撃つ弾の数と回数
@export var ring_bullets: int = 14
@export var ring_waves: int = 3
## 狙い撃ち（扇形）の弾の数と広がり（度）
@export var fan_bullets: int = 5
@export var fan_spread_degrees: float = 50.0
@export var fan_waves: int = 3
## 弾を撃つ間隔（秒）
@export var shot_interval: float = 0.45
@export var bullet_speed: float = 260.0
@export var bullet_damage: float = 8.0

@export_group("Summon")
@export var summon_def: EnemyDef
@export var summon_count: int = 6

@export_group("Enrage")
## HP がこの割合を切ると怒り状態（行動の間隔が短くなり、突進が 2 連続になる）
@export var enrage_hp_ratio: float = 0.5
## 怒り状態のときに時間に掛ける倍率（小さいほど速い）
@export var enrage_time_scale: float = 0.65
