class_name RunSetup
extends RefCounted
## ホームから本編へ「何を遊ぶか」を渡す。シーンを切り替えても値が残るよう static 変数で持つ
## （これだけのために autoload を増やさない。ADR-016）。
## 本編を直接起動したとき（テスト・エディタの F6）は FREE で、従来どおり 5 分のランになる。

const FREE: int = 0
const STAGE: int = 1
const ENDLESS: int = 2

static var mode: int = FREE
static var stage_number: int = 1


static func start_stage(number: int) -> void:
	mode = STAGE
	stage_number = number


static func start_endless() -> void:
	mode = ENDLESS


static func reset() -> void:
	mode = FREE
	stage_number = 1
