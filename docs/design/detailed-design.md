# 詳細設計書

- 版: 0.1（Phase 0）/ 2026-10-19
- 範囲: **Phase 1（最小プロトタイプ）のみ**。Phase 2 以降は着手前に追記する。
- 状態: 未実装。実装時に食い違いがあれば本書を更新し、changelog に理由を書く。

## 1. ディレクトリとスクリプト一覧（Phase 1）

```
project.godot
scenes/
  main/main.tscn              + main.gd
  characters/character.tscn   + character.gd
  rope/rope.tscn              + rope.gd
scripts/
  input/keyboard_move_input.gd
  rope/rope_model.gd
  rope/rope_config.gd
  debug/debug_overlay.gd
data/
  rope/default_rope_config.tres
tests/
  run_tests.gd
  test_rope_model.gd
```

| ファイル | クラス名 | 基底 | 責務 |
|---|---|---|---|
| `character.gd` | `Character` | CharacterBody2D | intent と速度から移動するだけ |
| `keyboard_move_input.gd` | `KeyboardMoveInput` | Node | 指定アクションからベクトルを読み、対象キャラに intent を書く |
| `rope_model.gd` | `RopeModel` | RefCounted | 紐の純粋な計算（静的関数のみ） |
| `rope_config.gd` | `RopeConfig` | Resource | 紐のパラメータ定義 |
| `rope.gd` | `Rope` | Node2D | 毎フレームのハブ計算・拘束・描画 |
| `main.gd` | — | Node2D | 起動時の配線、カメラ追従 |
| `debug_overlay.gd` | `DebugOverlay` | CanvasLayer | FPS、距離、伸び率、ハブ表示切替 |
| `run_tests.gd` | — | SceneTree | テストの実行と集計 |

## 2. 各クラスの詳細

### 2.1 Character（`scenes/characters/character.gd`）

| 変数 | 型 | 説明 |
|---|---|---|
| `@export move_speed` | float = 220.0 | 最大移動速度（px/秒） |
| `@export body_color` | Color | A/B の見分け用 |
| `move_intent` | Vector2 | 入力側が書く。長さ 0〜1 |

- `_physics_process(_delta)`: `velocity = move_intent.limit_length(1.0) * move_speed` → `move_and_slide()`
- `_draw()`: 半径 16px の円（見た目は仮）
- コリジョン: 自身を layer 1「character」に置き、mask から 1 を外して A と B が互いに当たらないようにする（ADR-004）。
- `process_priority = 0`

### 2.2 KeyboardMoveInput（`scripts/input/keyboard_move_input.gd`）

| 変数 | 説明 |
|---|---|
| `@export target_path: NodePath` | 動かすキャラ |
| `@export action_prefix: String` | `"a"` なら `a_left/a_right/a_up/a_down` を読む |

- `_physics_process`: `target.move_intent = Input.get_vector(prefix+"_left", prefix+"_right", prefix+"_up", prefix+"_down")`
- `process_priority = -10`（キャラより先）

InputMap（`project.godot` に定義）:

| アクション | キー | 将来のパッド |
|---|---|---|
| `a_left/right/up/down` | A / D / W / S | 左スティック |
| `b_left/right/up/down` | ← / → / ↑ / ↓ | 右スティック |
| `debug_toggle_hub` | F1 | — |
| `debug_toggle_overlay` | F3 | — |

### 2.3 RopeConfig（`scripts/rope/rope_config.gd`）

```gdscript
class_name RopeConfig
extends Resource

@export var max_radius: float = 160.0     # 各キャラ〜ハブの最大距離
@export var natural_radius: float = 100.0 # Phase 1 は描画の伸び率のみに使用
```

### 2.4 RopeModel（`scripts/rope/rope_model.gd`）— テストの主対象

| 関数 | 入力 | 出力 | 仕様 |
|---|---|---|---|
| `static hub_position(points: PackedVector2Array) -> Vector2` | 全メンバーの位置 | ハブ位置 | 平均。空配列なら `Vector2.ZERO` |
| `static constrain(pos: Vector2, hub: Vector2, max_radius: float) -> Vector2` | 位置・ハブ・半径 | 補正後の位置 | 距離 ≤ 半径ならそのまま。超えたらハブ方向へ戻して円周上に置く。`pos == hub` でも安全 |
| `static stretch_ratio(dist: float, natural: float, max_r: float) -> float` | 距離・自然長・最大長 | 0.0〜1.0 | `(dist-natural)/(max_r-natural)` を 0〜1 に制限。`max_r <= natural` なら距離 ≥ max_r で 1、それ以外 0 |

拘束の流れ（2 人の場合の数値例）:

```
A=(0,0), B=(400,0), R=160
hub = (200,0)
A: 距離200 > 160 → (40,0) に補正
B: 距離200 > 160 → (360,0) に補正
→ A〜B = 320 = 2R。ハブ位置は変わらない
```

3 人以上では補正後に重心がずれるため、1 回の補正で完全には収まらない。将来は数回繰り返す（Phase 1 の範囲外。コメントで明記する）。

### 2.5 Rope（`scenes/rope/rope.gd`）

| 変数 | 説明 |
|---|---|
| `@export member_paths: Array[NodePath]` | つなぐキャラ（Phase 1 は A, B） |
| `@export config: RopeConfig` | パラメータ |
| `@export show_hub: bool = true` | ハブ表示（ロジックには不使用） |
| `hub: Vector2` | 最新のハブ位置（読み取り専用として扱う） |
| `stretch_ratios: PackedFloat32Array` | メンバーごとの伸び率 |

- `process_priority = 10`（キャラ移動の後）
- `_physics_process`:
  1. members の `global_position` を集めて `hub_position()`
  2. 各メンバーに `constrain()` を適用し、補正があればそのキャラの `global_position` を更新
  3. 補正したキャラの `velocity` から外向き成分を取り除く（次フレームでの押し付けを防ぐ）
  4. 伸び率を計算 → `queue_redraw()`
- `_draw()`: 各メンバー〜ハブに線。色は伸び率で 白 → 黄 → 赤、線の太さは張るほど細く。`show_hub` のときハブに小さな点。
- Rope 自身は原点に置き、描画座標は `to_local()` で変換する。
- members が 2 未満、または config 未設定なら `push_error` して処理しない。

### 2.6 main.gd

- `Camera2D` の位置を毎フレーム `rope.hub` に合わせる（2 人が常に収まる）。ズームは固定。
- 初期配置: A=(-80, 0)、B=(80, 0)。

### 2.7 DebugOverlay

- 表示: FPS（`Engine.get_frames_per_second()`）、A〜B 距離、各伸び率、ハブ表示 ON/OFF。
- F1: `rope.show_hub` を切替。F3: オーバーレイ自体を切替。

## 3. 状態管理

Phase 1 では状態遷移（タイトル/プレイ/リザルト）なし。常に「プレイ中」。

## 4. 衝突判定

Phase 1 ではキャラ同士は当たらず、壁もない（フィールドは無限、カメラが追従）。敵との衝突は Phase 3 で設計する。

## 5. 例外的な状況への対応

| 状況 | 対応 |
|---|---|
| キャラとハブが同じ位置（距離 0） | `constrain` は補正不要として元の位置を返す（ゼロ除算しない） |
| 2 人が正反対へ全力で移動 | 毎フレーム両者が戻されるため、ハブ付近で釣り合って止まる（期待挙動） |
| 片方だけ移動 | 相方が半分の速さで引きずられる（Phase 2 で「止める方式」と比較） |
| 低フレームレート | 拘束は毎物理フレーム必ず行うため、最大長は超えない |

## 6. テスト方法

- 自動: `godot --headless --path . --script res://tests/run_tests.gd`。終了コード 0 で成功（TC-001〜TC-006）。
- 手動: test-cases.md の TC-101〜TC-106。
