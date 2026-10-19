extends SceneTree
## 単体テストの実行役。
##   godot --headless --path . --script res://tests/run_tests.gd [-- --dir=res://tests]
## 指定フォルダの test_*.gd を読み込み、`test_` で始まる関数をすべて実行する。
## 1 件でも失敗（読み込み失敗を含む）があれば終了コード 1、全件成功なら 0。


func _initialize() -> void:
	# _initialize の時点ではルートノードがまだ「準備完了」ではなく、そこへ追加したノードの
	# _ready が呼ばれない。1 フレーム待ってからテストを始める。
	await process_frame

	var dir_path: String = _get_dir_arg()
	var total: int = 0
	var failed: int = 0

	var files: Array = Array(DirAccess.get_files_at(dir_path))
	files.sort()
	for file_name: String in files:
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		# test_case.gd は部品なので除外される（"test_" で始まるが "test_case.gd" は別扱い）
		if file_name == "test_case.gd":
			continue
		var path: String = dir_path.path_join(file_name)
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("FAIL  %s: could not load (script error?)" % path)
			continue

		var suite = script.new()
		suite.tree = self
		var method_names: Array = []
		for method: Dictionary in suite.get_method_list():
			if String(method["name"]).begins_with("test_"):
				method_names.append(String(method["name"]))
		method_names.sort()

		for method_name: String in method_names:
			total += 1
			suite.failures.clear()
			# await: テストが物理フレームを待つ（統合テスト）場合も、終わるまで待つ。待たない関数は即座に戻る
			await suite.call(method_name)
			if suite.failures.is_empty():
				print("PASS  %s::%s" % [file_name, method_name])
			else:
				failed += 1
				for message: String in suite.failures:
					print("FAIL  %s::%s: %s" % [file_name, method_name, message])

	print("Result: %d passed, %d failed (%d total)" % [total - failed, failed, total])
	quit(1 if failed > 0 else 0)


func _get_dir_arg() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			return arg.trim_prefix("--dir=")
	return "res://tests"
