class_name StageDef
extends Resource
## ステージ 1 つの定義。ステージは番号順に開放する（前のステージをクリアすると次が遊べる）。
## どのステージも 5 分でボスが出る。難しさは「出現の多さ」「敵（ボスを含む）の硬さ」で付ける（サバイバー系: 敵の速さではなく量で調整する）。

@export var number: int = 1
## ホームに出す一言（何が起きるステージか）
@export var note: String = ""
## ボスが出るまでの時間（秒）。ボスを倒すとクリア
@export var boss_time: float = 300.0
## 出現間隔に掛ける倍率。小さいほど敵が多い
@export var spawn_interval_scale: float = 1.0
## 敵の HP に掛ける倍率
@export var enemy_hp_scale: float = 1.0
