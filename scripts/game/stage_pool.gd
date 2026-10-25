class_name StagePool
extends RefCounted
## ステージの一覧（1 から順番）。UpgradePool と同じく、フォルダを走査せず preload で列挙する
## （書き出し後のビルドでは .tres のファイル名が変わり、走査では見つからなくなるため）。

const ALL: Array = [
	preload("res://data/stages/stage_01.tres"),
	preload("res://data/stages/stage_02.tres"),
	preload("res://data/stages/stage_03.tres"),
	preload("res://data/stages/stage_04.tres"),
	preload("res://data/stages/stage_05.tres"),
	preload("res://data/stages/stage_06.tres"),
	preload("res://data/stages/stage_07.tres"),
	preload("res://data/stages/stage_08.tres"),
	preload("res://data/stages/stage_09.tres"),
	preload("res://data/stages/stage_10.tres"),
]


static func count() -> int:
	return ALL.size()


## 番号（1 始まり）のステージ。範囲外なら null
static func get_stage(number: int) -> StageDef:
	if number < 1 or number > ALL.size():
		return null
	return ALL[number - 1] as StageDef
