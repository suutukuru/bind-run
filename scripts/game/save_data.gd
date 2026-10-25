class_name SaveData
extends RefCounted
## 進み具合（開放済みのステージ・クリア・エンドレスの最高記録）と設定の保存。
## Web 版では user:// はブラウザの保存領域（IndexedDB）に入るので、同じブラウザなら次回も残る。
## ファイルは小さいため、読むたびに開き、書くたびに保存する（状態をメモリに持たず、食い違いを避ける）。

## テストでは別のファイルに差し替える
static var path: String = "user://save.cfg"


static func unlocked_stage() -> int:
	return int(_load().get_value("progress", "unlocked_stage", 1))


static func is_unlocked(number: int) -> bool:
	return number <= unlocked_stage()


static func is_cleared(number: int) -> bool:
	return bool(_load().get_value("progress", "cleared_%d" % number, false))


## クリアを記録し、次のステージを開放する
static func record_stage_clear(number: int) -> void:
	var file: ConfigFile = _load()
	file.set_value("progress", "cleared_%d" % number, true)
	var unlocked: int = int(file.get_value("progress", "unlocked_stage", 1))
	file.set_value("progress", "unlocked_stage", maxi(unlocked, number + 1))
	_save(file)


## エンドレスで生き残った最長の時間（秒）。記録がなければ 0
static func endless_best() -> float:
	return float(_load().get_value("endless", "best_seconds", 0.0))


## 最高記録を更新したら true
static func record_endless(seconds: float) -> bool:
	var file: ConfigFile = _load()
	if seconds <= float(file.get_value("endless", "best_seconds", 0.0)):
		return false
	file.set_value("endless", "best_seconds", seconds)
	_save(file)
	return true


static func get_setting(key: String, default_value: Variant) -> Variant:
	return _load().get_value("settings", key, default_value)


static func set_setting(key: String, value: Variant) -> void:
	var file: ConfigFile = _load()
	file.set_value("settings", key, value)
	_save(file)


## 進み具合と記録を消す（設定は残す）
static func reset_progress() -> void:
	var file: ConfigFile = _load()
	for section: String in ["progress", "endless"]:
		if file.has_section(section):
			file.erase_section(section)
	_save(file)


## ファイルごと消す（テストの後片付け用）
static func delete_file() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func _load() -> ConfigFile:
	var file: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(path):
		file.load(path)
	return file


static func _save(file: ConfigFile) -> void:
	var err: Error = file.save(path)
	if err != OK:
		push_warning("SaveData: 保存できませんでした (%d): %s" % [err, path])
