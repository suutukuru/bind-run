extends "res://tests/test_case.gd"
## ランナー自身の検証用。わざと失敗し、run_tests.gd が終了コード 1 を返すことを CI で確かめる。


func test_always_fails() -> void:
	check_true(false, "intentional failure")
