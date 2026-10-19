class_name UpgradePicker
extends RefCounted
## レベルアップ時に出す強化候補を選ぶ（純粋な関数。乱数は呼び出し側から渡すのでテストできる）。


## pool から、選択回数が上限に達していないものを重複なしで n 個ランダムに選ぶ。
## counts は {強化の id: すでに選んだ回数}
static func pick(pool: Array, counts: Dictionary, n: int, rng: RandomNumberGenerator) -> Array:
	var candidates: Array = []
	for item: Variant in pool:
		var def: UpgradeDef = item as UpgradeDef
		if def != null and int(counts.get(def.id, 0)) < def.max_stacks:
			candidates.append(def)
	# Fisher-Yates シャッフル
	for i: int in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	return candidates.slice(0, mini(n, candidates.size()))
