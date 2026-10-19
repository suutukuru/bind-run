extends Node
## タイトル画面。遊び方を出して、START でゲーム本編へ進む。

const GAME_SCENE: String = "res://scenes/main/main.tscn"


func _ready() -> void:
	var menu: MenuPanel = MenuPanel.new()
	add_child(menu)
	var body: String = "画面の左半分をドラッグで A（青）、右半分で B（橙）を動かす\n紐をピンと張って、敵をなぎ払おう！"
	menu.open("BIND RUN", body, [{"text": "スタート", "callback": _start}], false)


func _start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
