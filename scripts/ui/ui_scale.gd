class_name UiScale
extends RefCounted
## UI の大きさの基準。画面の短辺の 1% を 1 単位とする。
## 縦持ち・横持ち・端末の違いに関わらず、文字やボタンが同じ見た目の大きさになる。


static func unit(viewport: Viewport) -> float:
	var size: Vector2 = viewport.get_visible_rect().size
	return minf(size.x, size.y) / 100.0
