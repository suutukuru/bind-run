class_name RopeConfig
extends Resource
## ゴム紐のパラメータ（定義データ）。値は default_rope_config.tres で調整する。

## 各キャラとハブの最大距離。2 人のとき、A〜B の最大距離はこの 2 倍
@export var max_radius: float = 160.0
## これより短い間は「たるみ」（伸び率 0）。Phase 1 では見た目の伸び率にだけ使う
@export var natural_radius: float = 100.0
