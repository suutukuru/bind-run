# データ設計書（初版）

- 版: 0.1 / 2026-10-19
- 原則（ADR-007）: **定義** = 変わらない設定値 → Resource（`.tres`）。**状態** = プレイ中に変わる値 → ノードの変数。

> Resource とは: Godot のデータの入れ物。スクリプトで項目を定義し、`.tres` ファイルとして保存すると、エディタのインスペクタで値を編集できる。Web で言えば「型付きの設定 JSON」に近い。

## 1. 定義データ（Resource）

| Resource | 主な項目 | 使用フェーズ | 状態 |
|---|---|---|---|
| `RopeConfig` | `max_radius`, `natural_radius`,（P2）`stiffness`, `pull_mode`,（P3）`tension_threshold`, `damage`, `rehit_interval` | 1〜3 | Phase 1 で作成 |
| `CharacterDef` | `display_name`, `move_speed`, `color`, `weapon: WeaponDef` | 3 | 未作成 |
| `WeaponDef` | `damage`, `cooldown`, `range`, `projectile_speed`, `pattern`（最寄り射撃 / 周囲範囲 など） | 3 | 未作成 |
| `EnemyDef` | `max_hp`, `move_speed`, `contact_damage`, `xp_value`, `radius` | 3 | 未作成 |
| `UpgradeDef` | `id`, `title`, `description`, `target`（A/B/共通/紐）, `stat`, `amount`, `max_stacks` | 4 | 未作成 |
| `WaveTable` | 経過時間ごとの出現間隔・敵の種類 | 3〜5 | 未作成 |

- Phase 1 では `move_speed` は `Character` の `@export` に直接持つ。`CharacterDef` は武器が入る Phase 3 で導入する（今作ると中身がほぼ空の抽象化になるため）。

## 2. 状態データ（ノードの変数）

| 持ち主 | 状態 | 備考 |
|---|---|---|
| `Character` | `move_intent`, `velocity`, 位置 | |
| `Rope` | `hub`, `stretch_ratios` | 毎フレーム再計算。保存不要 |
| `Enemy` | `hp`, 再ヒット用タイムスタンプ | Phase 3 |
| `RunState`（1 プレイ分） | `elapsed_time`, `level`, `xp`, `hp`, 取得済み強化リスト | Phase 3〜4。ゲーム終了で破棄 |

- **強化の適用方法（Phase 4 で決定）**: 定義 Resource の値を直接書き換えると、次のプレイにも影響が残る。そのため「定義値 + 取得済み強化からの補正」をその都度計算するか、プレイ開始時に定義をコピー（`duplicate()`）する。後者が単純なため推奨。

## 3. 経験値テーブル（仮）

- 必要経験値 = `5 + (level - 1) * 5`（Lv1→2: 5、Lv2→3: 10 …）。Phase 4 で調整する（仮決定）。

## 4. 保存データ

- 初期版ではなし。設定（音量など）の保存は Phase 7 で `ConfigFile` を検討する。データベースは使わない。
