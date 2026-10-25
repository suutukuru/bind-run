# データ設計書（初版）

- 版: 0.1 / 2026-10-19
- 原則（ADR-007）: **定義** = 変わらない設定値 → Resource（`.tres`）。**状態** = プレイ中に変わる値 → ノードの変数。

> Resource とは: Godot のデータの入れ物。スクリプトで項目を定義し、`.tres` ファイルとして保存すると、エディタのインスペクタで値を編集できる。Web で言えば「型付きの設定 JSON」に近い。

## 1. 定義データ（Resource）

| Resource | 主な項目 | 使用フェーズ | 状態 |
|---|---|---|---|
| `RopeConfig` | `max_radius`, `natural_radius`, `limit_mode`, `stiffness`, `hub_follow_rate`, `attack_threshold`, `attack_damage`, `attack_rehit_interval`, `attack_half_width` | 1〜3 | **作成済み**（実行時は Rope が複製して持つ）|
| `CharacterDef` | `display_name`, `move_speed`, `color`, `weapon: WeaponDef` | — | **作らないことにした**: キャラは 2 人固定で、`Character` の `@export` と子の `Weapon` で足りる。キャラを増やす段階で再検討 |
| `WeaponDef` | `display_name`, `pattern`（SHOT / PULSE）, `damage`, `cooldown`, `reach`, `projectile_speed` | 3 | **作成済み**（blaster.tres, shockwave.tres。`range` は GDScript の組み込み名なので `reach`）|
| `EnemyDef` | `display_name`, `max_hp`, `move_speed`, `contact_damage`, `xp_value`, `radius`, `color` | 3 | **作成済み**（grunt / runner / tank）|
| `UpgradeDef` | `id`, `title`, `description`, `target_path`, `property_path`, `amount`, `mode`（加算/乗算）, `max_stacks` | 4 | **作成済み**（13 種。ADR-015）|
| `StageDef` | `number`, `note`, `duration`, `spawn_interval_scale`, `enemy_hp_scale` | 2026-10 | **作成済み**（stage_01〜10、一覧は `StagePool`。ADR-016）|
| `WaveTable` | 経過時間ごとの出現間隔・敵の種類 | — | **作らないことにした**: `EnemySpawner` の静的関数（`interval_at / count_at / weights_at`）で足りる。ステージや敵が増えたら Resource 化を検討 |

- `move_speed` は `Character` の `@export` に直接持つ。`CharacterDef` は作らなかった（キャラは 2 人固定で、武器は子ノードの `Weapon` が持つため。中身がほぼ空の抽象化になる）。キャラを増やす段階で再検討する。

## 2. 状態データ（ノードの変数）

| 持ち主 | 状態 | 備考 |
|---|---|---|
| `Character` | `move_intent`, `velocity`, 位置 | |
| `Rope` | `hub`, `stretch_ratios` | 毎フレーム再計算。保存不要 |
| `Enemy` | `hp`, 再ヒット用タイムスタンプ | Phase 3 |
| `SaveData`（user://save.cfg）| 開放済みステージ、クリア済み、エンドレスの最高記録、設定 | 保存する。Web 版はブラウザの保存領域 |
| `RunSetup`（static）| モード（FREE / STAGE / ENDLESS）、ステージ番号 | ホーム → 本編の受け渡し。保存しない |
| `RunState`（1 プレイ分） | `elapsed_time`, `level`, `xp`, `hp`, 取得済み強化リスト | Phase 3〜4。ゲーム終了で破棄 |

- **強化の適用方法（Phase 4 で決定）**: 定義 Resource の値を直接書き換えると、次のプレイにも影響が残る。そのため「定義値 + 取得済み強化からの補正」をその都度計算するか、プレイ開始時に定義をコピー（`duplicate()`）する。後者が単純なため推奨。

## 3. 経験値テーブル（仮）

- 必要経験値 = `5 + (level - 1) * 5`（Lv1→2: 5、Lv2→3: 10 …）。Phase 4 で調整する（仮決定）。

## 4. 保存データ

- 初期版ではなし。設定（音量など）の保存は Phase 7 で `ConfigFile` を検討する。データベースは使わない。
