# 詳細設計書

- 版: 0.1（Phase 0）/ 2026-10-19
- 範囲: Phase 1〜5（2026-10-19 時点で実装済み）。章 1〜6 は Phase 1、章 7 以降は Phase 2〜5。
- 状態: CI（Godot 4.7.2）で単体テスト・通しプレイが成功。実機での見た目・操作の確認は [owner-checklist.md](../testing/owner-checklist.md)。実装との食い違いは本書を更新し、changelog に理由を書く。

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
| `@export target_path: NodePath` | 動かすキャラの場所。`_ready` で `target: Character` に解決する（型付きノード参照はシーンから解決されなかったため） |
| `@export action_prefix: String` | `"a"` なら `a_left/a_right/a_up/a_down` を読む |

- `_physics_process`: `target.move_intent = Input.get_vector(prefix+"_left", prefix+"_right", prefix+"_up", prefix+"_down")`
- `process_priority = -10`（キャラより先）
- InputMap は project.godot ではなく `InputActions.register()`（`scripts/input/input_actions.gd`）で実行時に登録する。理由: テストで検証でき、手書きの書式ミスで起動できなくなる事故を避けられるため（Main の `_ready` で呼ぶ）

InputMap（`project.godot` に定義）:

| アクション | キー | 将来のパッド |
|---|---|---|
| `a_left/right/up/down` | A / D / W / S | 左スティック |
| `b_left/right/up/down` | ← / → / ↑ / ↓ | 右スティック |
| `debug_toggle_hub` | F1 | — |
| `debug_toggle_overlay` | F3 | — |

### 2.2b TouchMoveInput（`scripts/input/touch_move_input.gd`、TASK-015）

- `Node2D`。`CanvasLayer`（TouchLayer）の下に A 用（LEFT）・B 用（RIGHT）の 2 つを置く。1 インスタンスが 1 本の指・1 キャラを担当
- 画面の左半分で触れ始めた指 → LEFT、右半分 → RIGHT。触れた位置がスティックの中心（フローティング方式）
- `intent = (指の位置 - 中心).limit_length(stick_radius) / stick_radius`（`static intent_from_drag`、テスト対象）
- `process_priority = -9`。指が触れている間だけ `move_intent` を書く。離れている間はキーボード側（-10）が決める
- 描画: 指の位置にキャラ色の半透明の円とつまみ。座標は CanvasLayer の画面座標（カメラの影響なし）
- 未確認: `canvas_items` / `expand` のストレッチ下で、指の座標が表示と一致するか（実機で確認）。マウスでの擬似タッチ（`emulate_touch_from_mouse`）は、実機で二重入力にならない確証がないため入れていない

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
    3. 伸び率を計算 → `queue_redraw()`（描画は TASK-011）
- `_draw()`: 各メンバー〜ハブに線。色は伸び率で 白 → 黄 → 赤、線の太さは張るほど細く。`show_hub` のときハブに小さな点。
- Rope 自身は原点に置き、描画座標は `to_local()` で変換する。
- members が 2 未満、または config 未設定なら `push_error` して処理しない。

### 2.6 main.gd

- `Camera2D` の位置を毎フレーム `rope.hub` に合わせる（2 人が常に収まる）。ズームは固定。
- 初期配置: A=(560, 360)、B=(720, 360)（カメラ追従を入れる TASK-012 までは画面中央付近。カメラを入れたら見直す）。

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


---

# 以降: Phase 2〜5 の実装（2026-10-19）

## 7. シーン構成（main.tscn の現状）

```
Main (Node2D, main.gd)                進行役: メニュー・強化の適用
├─ RunState                           共有HP・時間・レベル・経験値
├─ CharacterA (Character) └ Weapon    Blaster（弾）
├─ CharacterB (Character) └ Weapon    Shockwave（範囲）
├─ InputA / InputB (KeyboardMoveInput)
├─ Rope (rope.tscn) / RopeAttack      紐の拘束・描画／紐攻撃
├─ EnemySpawner                       敵とオーブがこの子になる
├─ Camera (FollowCamera)
├─ TouchLayer (CanvasLayer) ├ TouchA └ TouchB   タッチ入力（画面座標）
├─ DebugOverlay / TuningPanel         開発用の状態表示・調整パネル
├─ Hud                                HP・経験値・時間・ポーズボタン
└─ MenuPanel                          レベルアップ・ポーズ・結果
```

起動シーンは `scenes/title/title.tscn`（START で main.tscn へ）。処理順（`process_priority`）: KeyboardMoveInput -10 → TouchMoveInput -9 → キャラ・敵・武器 0 → Rope 10 → RopeAttack 11。

## 8. 紐の拡張（Rope / RopeModel / RopeConfig）

- `RopeModel` に純粋関数を追加: `elastic_pull`（自然長を超えた分に比例して引き戻す。1 フレームで自然長より内側へ行き過ぎない）、`follow_hub`（慣性ハブ: 目標へ `rate × delta` の割合で近づく）、`distance_to_segment`（紐攻撃の判定）。
- `RopeConfig` に追加: `limit_mode`（DRAG=0 / BLOCK=1）、`stiffness`、`hub_follow_rate`、紐攻撃の `attack_threshold / attack_damage / attack_rehit_interval / attack_half_width`。
- `Rope.step(delta)` の流れ: ① DRAG ならここでハブを更新（移動後の位置から）② 各メンバーに `elastic_pull` → `constrain`（最大長）③ 伸び率を計算 ④ BLOCK ならここでハブを更新（前フレームのハブを基準に拘束するので、押した側が止まるだけで相方は引きずられない）。
- `Rope` は `_ready` で `config` を複製する。調整パネルで値を変えても共有の `.tres` は変わらない。
- 紐攻撃が有効な間（`attack_active`）は紐に白い太い光を重ねて描く。
- enum の型指定を使わない: クラス自身の `enum` を変数の型にすると、ゲーム起動時の読み込み順で「Cannot assign a value of type …Side as Side」になり、スクリプトが読み込めなかった（CI のスモーク実行で発見、ADR-011）。`TouchMoveInput.LEFT/RIGHT` と `RopeConfig.DRAG/BLOCK` は int の定数で持つ。

## 9. カメラとUIの大きさ（ADR-012）

- `FollowCamera`: 位置は `Rope.hub`。ズームは `短辺 / view_short_side(600)` で、**画面の短辺にワールドの 600px が映る**よう毎フレーム補正する。縦持ちの `expand` で表示範囲が縦に広がってキャラが点になる問題への対処。
- `UiScale.unit(viewport)` = 画面の短辺の 1%。HUD・メニュー・調整パネル・デバッグ文字・スティックの半径（`stick_radius_ratio` = 0.15）はこの単位で決める。画面サイズが変わる（`size_changed`）たびに再配置する。

## 10. タッチ入力（TouchMoveInput）

- `_unhandled_input` で受ける（ボタンなど UI が処理した指はスティックにしない）。ポーズ（`NOTIFICATION_PAUSED/UNPAUSED`）で状態をリセットし、止まっている間に離した指が残らないようにする。
- 半径は `stick_radius_px()` = 短辺 × 0.15。描画は指の位置に半透明の円とつまみ（キャラの色）。

## 11. 戦闘（Phase 3）

- **RunState**（`scripts/game/run_state.gd`）: 共有 HP、`elapsed`、`level`、`xp`、`kills`、`running`。信号: `hp_changed / xp_changed / leveled_up / finished(victory)`。`max_hp` を増やすと増えた分だけ HP も回復。`xp_needed(level) = 5 + (level−1) × 5`。
- **Enemy**（`scenes/enemies/enemy.gd`、`class_name Enemy`）: 物理エンジンを使わない `Node2D`。最も近いキャラへ直進し、`radius + Character.RADIUS` 以内で `RunState.take_damage`（同じ敵は 0.7 秒の間隔）。`take_damage` で被弾、HP 0 で `died` を出して消える。グループ `enemies`。`rope_hit_ready_at` は紐攻撃の再ヒット管理用。
- **EnemySpawner**: 画面外（見えている範囲の対角線の半分 + 80px）の円周に出現。静的関数 `interval_at / count_at / weights_at / pick_index` で出現を決める（0.7 秒 → 0.2 秒に 240 秒かけて短縮、60 秒ごとに 1 回の出現数が +1、Runner は 30 秒後・Tank は 90 秒後から混ざる、最大 180 体）。
- **Weapon**（`scenes/weapons/weapon.gd`）: キャラの子。`def: WeaponDef` を実行時のコピー（`damage / cooldown / reach / projectile_speed`）にして持つので、強化しても `.tres` は変わらない。`SHOT` は最も近い敵へ `Projectile` を撃つ（敵がいない間は待機し、現れた瞬間に撃つ）。`PULSE` は半径内の全敵に一度にダメージを与え `PulseEffect`（輪）を出す。
- **RopeAttack**: Rope の後（優先度 11）に判定。伸び率が `attack_threshold` 以上のメンバーの紐（ハブ→メンバー）と各敵の距離が `敵の半径 + attack_half_width` 以内なら、再ヒット間隔つきでダメージ。武器とは別ノードで、互いを参照しない（FR-033）。

## 12. 成長（Phase 4）

- **XpOrb**: 敵の撃破位置に落ちる。キャラが `EnemySpawner.orb_pickup_radius` 以内に来ると 420px/秒で吸い寄せられ、触れると `RunState.add_xp`（2 人で共有）。
- **UpgradeDef**: 「Main から見たノードのパス」と「プロパティのパス（`config:attack_damage` のような入れ子も可）」と増減量だけを持つ。`apply_to(Main)` で適用。ADD は加算、MULTIPLY は `× (1 + amount)`。
- **UpgradePool**: `preload` で 13 種を列挙（`DirAccess` で走査しない: 書き出し後は `.tres` が `.remap` に変わるため）。**UpgradePicker**: 上限に達していないものから重複なしで 3 つ、乱数は呼び出し側から渡す（再現できる）。
- **Main**: `leveled_up` で選択メニューを開く。一度に複数レベル上がったら、選ぶたびに次を出す。

## 13. UI（Phase 5）

- **MenuPanel**: `process_mode = ALWAYS` の CanvasLayer。`open(title, body, options, pause_game)`、選ぶとメニューを閉じてから callback。タイトル・ポーズ・レベルアップ・結果で共用。
- **Hud**: HP バー（赤）、経験値バー（青）、`LV / 残り時間 / KILLS`、ポーズボタン（II）。
- **Title**: 遊び方と START。結果画面は RETRY（シーンを読み直す）と TITLE。
- **すべて英語**: Web 版の標準フォントに日本語の文字が入っていないため（ADR-013）。

## 14. 開発用（DebugOverlay / TuningPanel）

- `DebugOverlay`: 0.2 秒ごとに FPS・表示サイズ・ウィンドウサイズ・A/B の位置・距離・伸び率・敵数を表示。F3 で切替。
- `TuningPanel`: 右上の TUNE で開閉。`Rope.config` の複製の `max_radius / natural_radius / stiffness / hub_follow_rate / attack_damage / attack_threshold / attack_half_width` をスライダーで、`limit_mode` を選択で、ハブの点とデバッグ文字をチェックで変える。

## 15. テスト（現状）

- `tests/test_*.gd` を `godot --headless --fixed-fps 60 --script res://tests/run_tests.gd` で実行（CI）。ランナーは 1 フレーム待ってから始め、`await` するテスト（物理フレームを進める統合テスト）にも対応する。
- 統合テスト（`test_gameplay.gd`）: ボットが ①紐だけで敵を倒す ②武器で全滅させ経験値を拾う ③25 秒のランを勝利まで（途中でレベルアップを選ぶ）④囲まれて敗北、を通す。
- CI はさらに、ゲームシーンとタイトルを 300 フレーム起動して `SCRIPT ERROR` が出ないこと、Web 書き出しがスレッドなしであることを確認する。

## 16. ホーム画面とモード（ADR-016）

- 起動シーンは `scenes/home/home.tscn`（タイトル画面は廃止）。`Home` は UI をコードで組み立て、大きさは `UiScale` に合わせる。
- 下のツールバー（高さ 12u）: 左から「？？？・装備・ホーム・ガチャ・設定」。中央のホームが初期表示。
- ホーム: ステージのカード（番号・時間と一言・状態、`<` `出撃` `>`、「ステージを選ぶ」）とエンドレスのカード（最高記録、「挑戦」）。横持ちでは 2 枚を横に並べる。
- ステージ選択: 10 個のボタン（横持ち 5 列、縦持ち 2 列）。未開放は押せない。クリア済みは ★。
- 設定: 「調整ボタンを表示」「デバッグ文字を表示」「紐の中心（ハブ）を表示」（`SaveData` の settings。本編の `Main._apply_settings` が読む）、「記録を消す」（2 回押すと消える。設定は残る）。
- 装備・ガチャ・？？？: 枠だけ（現在の武器の表示、無効な「引く」ボタン、候補の一覧）。
- 本編: `Main._apply_run_setup` が `RunSetup` を読み、ステージなら `RunState.run_duration = 0`（時間切れのクリアなし）・`RunState.boss_at = StageDef.boss_time`（5 分）と `EnemySpawner.interval_scale / hp_scale`、エンドレスなら `run_duration = 0`・`boss_at = 300`（倒すと 5 分後に次）と `hp_growth_per_minute` を設定。HUD の先頭に「ステージ N」「エンドレス」、エンドレスは経過時間を表示。
- 結果: ステージをクリアすると記録して次を開放し「次のステージへ / もう一度 / ホームへ」。失敗とエンドレスは「もう一度 / ホームへ」。エンドレスは最高記録を更新したら知らせる。ポーズの「タイトルへ」は「ホームへ」に変更。

## 17. ボス（2026-10-26）

- 出現: `EnemySpawner` が `RunState.boss_at` の時間に `spawn_boss()`（画面外から）。出たら `boss_at = 0`。ボスがいる間はふつうの出現を止める。HUD は「ボスまで mm:ss」→「ボス戦」、ボスの HP バー、「ボス出現！」の告知。
- クリア: ステージはボスを倒すとクリア（`RunState.win()`）。生き残るだけではクリアにならない。エンドレスは倒すと「ボス撃破！」と出て続き、5 分後に次のボス。
- `Boss`（`Enemy` を継承、`BossDef` は `EnemyDef` を継承）: 「追う → 技」をくり返す。技の順番は `MOVE_ORDER` = 突進 → 全方位弾 → 突進 → 扇形の狙い撃ち → 手下の呼び出し。突進は溜め（0.8 秒）の間に赤い線で予告。弾を撃つ間は中心がピンクに光る。
- 怒り: HP 50% 未満で外側に赤い輪。技の間隔 ×0.65、突進が 2 連続。
- 弾 `EnemyBullet`: まっすぐ飛び、キャラに触れると共有 HP にダメージ（8）。武器・紐では消せない。5 秒で消える。
- 紐: `EnemyDef.rope_damage_multiplier`（ボスは 3 倍）。紐でボスを削るのが速い。
- HP: 基本 2500 × ステージの敵 HP 倍率（0.7〜2.0）。数値はすべて仮。
