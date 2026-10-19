extends RefCounted
## テストファイルの共通部品。各テストは `extends "res://tests/test_case.gd"` で継承し、
## `test_` で始まる関数を書く。検証に失敗するとメッセージが failures に溜まり、
## run_tests.gd が集計する（外部アドオンを使わない最小構成、ADR-006）。

var failures: Array[String] = []
## シーンを組み立てるテスト用。ランナーが実行前に渡す（tree.root にノードを追加できる）
var tree: SceneTree


func check_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append(message if message != "" else "expected true")


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [message, str(expected), str(actual)])


# 浮動小数点は誤差が出るため、== ではなく許容誤差つきで比べる
func check_near(actual: float, expected: float, message: String = "", epsilon: float = 0.0001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s expected %s but got %s" % [message, str(expected), str(actual)])


func check_vec_near(actual: Vector2, expected: Vector2, message: String = "", epsilon: float = 0.0001) -> void:
	if actual.distance_to(expected) > epsilon:
		failures.append("%s expected %s but got %s" % [message, str(expected), str(actual)])
