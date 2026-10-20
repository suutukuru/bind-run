class_name RopeConfig
extends Resource
## ゴム紐のパラメータ（定義データ）。値は default_rope_config.tres で調整する。
## 実行中は Rope が複製して持つので、調整パネルで変えても元のファイルは変わらない。

## 最大長に達したときの動き（ADR-003 の U-02、実機で比較する）。
## クラス自身の enum を型にすると読み込み順で失敗することがあるため、定数 + int で持つ
## DRAG: 押した側は最大長で止まり、相方が引きずられる
const DRAG: int = 0
## BLOCK: 押した側が止まるだけで、相方は引きずられない
const BLOCK: int = 1

## 各キャラとハブの最大距離。2 人のとき、A〜B の最大距離はこの 2 倍
@export var max_radius: float = 480.0
## これより短い間は「たるみ」（引き戻しなし・伸び率 0）
@export var natural_radius: float = 380.0
@export_enum("Drag", "Block") var limit_mode: int = DRAG
## 自然長を超えた分を引き戻す強さ（1/秒）。0 で引き戻しなし
@export var stiffness: float = 3.0
## ハブが目標位置に追いつく速さ（1/秒）。0 でハブは常に 2 人の中点（慣性なし）
@export var hub_follow_rate: float = 0.0

@export_group("Rope Attack")
## 伸び率がこの値以上のとき、紐に触れた敵にダメージを与える
@export var attack_threshold: float = 0.7
@export var attack_damage: float = 10.0
## 同じ敵に再びダメージを与えるまでの間隔（秒）
@export var attack_rehit_interval: float = 0.4
## 紐の太さの半分（当たり判定に足す）
@export var attack_half_width: float = 30.0
