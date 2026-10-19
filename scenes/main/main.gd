extends Node2D
## ゲーム全体の組み立て役。


@onready var _rope: Rope = $Rope


func _ready() -> void:
	InputActions.register()


func _unhandled_input(event: InputEvent) -> void:
	# F1: ハブの点の表示切替。見た目だけで、ロジックは変わらない
	if event.is_action_pressed("debug_toggle_hub"):
		_rope.show_hub = not _rope.show_hub
