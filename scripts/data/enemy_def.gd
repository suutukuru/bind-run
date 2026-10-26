class_name EnemyDef
extends Resource
## 敵の定義データ（変わらない値）。プレイ中に変わる HP などは Enemy が持つ。

@export var display_name: String = "Grunt"
@export var max_hp: float = 24.0
@export var move_speed: float = 75.0
## 触れたときに共有 HP へ与えるダメージ
@export var contact_damage: float = 6.0
@export var xp_value: int = 1
@export var radius: float = 18.0
@export var color: Color = Color(0.85, 0.3, 0.3)
## 紐攻撃のダメージに掛ける倍率（ボスは紐でよく削れるようにして、紐の出番を作る）
@export var rope_damage_multiplier: float = 1.0
