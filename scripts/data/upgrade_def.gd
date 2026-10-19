class_name UpgradeDef
extends Resource
## レベルアップで選ぶ強化の定義。「どのノードの、どのプロパティを、どれだけ変えるか」だけを持つ。
## 新しい強化は .tres を増やして UpgradePool に足すだけで追加できる（コードの変更は不要）。

const ADD: int = 0
## MULTIPLY: 新しい値 = 今の値 × (1 + amount)。減らしたいときは amount を負にする
const MULTIPLY: int = 1

@export var id: StringName = &""
@export var title: String = ""
@export var description: String = ""
## Main から見たノードの場所（例: CharacterA/Weapon）
@export var target_path: NodePath
## 変えるプロパティ。入れ子は : でつなぐ（例: config:attack_damage）
@export var property_path: NodePath
@export var amount: float = 0.1
@export_enum("Add", "Multiply") var mode: int = MULTIPLY
## 同じ強化を選べる回数の上限
@export var max_stacks: int = 5


## root（Main）の下の対象へ適用する。見つからなければ false
func apply_to(root: Node) -> bool:
	var node: Node = root.get_node_or_null(target_path)
	if node == null:
		push_error("UpgradeDef %s: 対象が見つかりません: %s" % [id, target_path])
		return false
	var current: Variant = node.get_indexed(property_path)
	if current == null:
		push_error("UpgradeDef %s: プロパティがありません: %s" % [id, property_path])
		return false
	var value: float = current
	var updated: float = value + amount if mode == ADD else value * (1.0 + amount)
	node.set_indexed(property_path, updated)
	return true
