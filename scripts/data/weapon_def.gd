class_name WeaponDef
extends Resource
## 武器の定義データ。実行中の値は Weapon が複製して持つので、強化しても元の .tres は変わらない。

## SHOT: 最も近い敵へ弾を撃つ / PULSE: 自分の周囲にいる敵を一度にまとめて攻撃する
const SHOT: int = 0
const PULSE: int = 1

@export var display_name: String = "Blaster"
@export_enum("Shot", "Pulse") var pattern: int = SHOT
@export var damage: float = 14.0
## 攻撃の間隔（秒）
@export var cooldown: float = 0.5
## SHOT: 狙う敵を探す距離 / PULSE: 攻撃が届く半径
@export var reach: float = 360.0
@export var projectile_speed: float = 560.0
