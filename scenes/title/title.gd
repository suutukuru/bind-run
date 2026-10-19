extends Node
## タイトル画面。遊び方を出して、START でゲーム本編へ進む。

const GAME_SCENE: String = "res://scenes/main/main.tscn"


func _ready() -> void:
	var menu: MenuPanel = MenuPanel.new()
	add_child(menu)
	var body: String = "Drag the LEFT half of the screen to move A (blue)\nDrag the RIGHT half to move B (orange)\nStretch the rope tight and sweep it through enemies!"
	menu.open("BIND RUN", body, [{"text": "START", "callback": _start}], false)


func _start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
