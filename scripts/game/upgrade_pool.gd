class_name UpgradePool
extends RefCounted
## 選べる強化の一覧。DirAccess でフォルダを走査せず preload で列挙する:
## 書き出し後のビルドでは .tres が変換されてファイル名が変わり、走査では見つからなくなるため。

const ALL: Array = [
	preload("res://data/upgrades/blaster_damage.tres"),
	preload("res://data/upgrades/blaster_rate.tres"),
	preload("res://data/upgrades/blaster_range.tres"),
	preload("res://data/upgrades/shock_damage.tres"),
	preload("res://data/upgrades/shock_radius.tres"),
	preload("res://data/upgrades/shock_rate.tres"),
	preload("res://data/upgrades/speed_a.tres"),
	preload("res://data/upgrades/speed_b.tres"),
	preload("res://data/upgrades/rope_damage.tres"),
	preload("res://data/upgrades/rope_length.tres"),
	preload("res://data/upgrades/rope_frenzy.tres"),
	preload("res://data/upgrades/max_hp.tres"),
	preload("res://data/upgrades/magnet.tres"),
]


static func all() -> Array:
	return ALL
