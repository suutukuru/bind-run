# bind-run（仮称）

ゴム紐でつながった 2 人のキャラクターを同時に操作し、敵の群れを生き延びる 2D サバイバルアクション型ローグライト。スマートフォン（iOS / Android）向けで、Godot 4 で開発する。

## 開発の目的

- 遊べるゲームを完成させる。
- 開発を通してゲーム開発の考え方（ゲームループ、物理、設計、テスト）を学ぶ。判断の理由は `docs/` に残す。

## 使用技術

| 項目 | 内容 |
|---|---|
| エンジン | Godot 4.7.x（2026-10-19 時点の最新安定版は 4.7.2） |
| 言語 | GDScript |
| 開発 OS | Windows（PC 版は開発・検証用） |
| 対象 | Android / iOS（iOS のビルドには macOS + Xcode が必要） |
| バージョン管理 | Git |
| 外部アドオン | なし |

## 開発環境の準備

1. Godot 4.7.x（標準版。.NET 版ではない）を [公式サイト](https://godotengine.org/download/windows/) から入手する。
2. このリポジトリを clone する。
3. Godot のプロジェクトマネージャーで「インポート」し、`project.godot` を選ぶ（TASK-004 で作成済み。**Godot での起動は未確認**）。

## 実行方法

- Godot エディタで F5（Phase 1 以降）。
- 操作（予定）: A = WASD、B = 矢印キー、F1 = 接続点の表示切替、F3 = デバッグ表示切替。

## テスト方法

```
godot --headless --path . --script res://tests/run_tests.gd
```

終了コード 0 で全件成功（Phase 1 の TASK-005 で作成予定）。詳細は [テスト戦略](docs/testing/test-strategy.md)。

## ドキュメント

最初に読むもの: **要件定義 → 基本設計 → タスクボード**

| 分類 | ファイル | 内容 |
|---|---|---|
| 要件 | [requirements.md](docs/requirements/requirements.md) | 何を作るか、機能要件 ID、受け入れ条件、面白さの仮説 |
| 設計 | [basic-design.md](docs/design/basic-design.md) | 全体構造、ゲームループ、シーン構成 |
| 設計 | [detailed-design.md](docs/design/detailed-design.md) | スクリプトとメソッドの仕様（Phase 1） |
| 設計 | [architecture-decisions.md](docs/design/architecture-decisions.md) | 重要な判断とその理由（ADR） |
| 設計 | [data-design.md](docs/design/data-design.md) | 定義データと状態データ |
| 計画 | [roadmap.md](docs/planning/roadmap.md) | フェーズ計画 |
| 計画 | [task-board.md](docs/planning/task-board.md) | タスク一覧と状態 |
| 計画 | [risks.md](docs/planning/risks.md) | リスク |
| 計画 | [changelog.md](docs/planning/changelog.md) | 仕様・設計の変更履歴 |
| テスト | [test-strategy.md](docs/testing/test-strategy.md) / [test-cases.md](docs/testing/test-cases.md) / [test-results.md](docs/testing/test-results.md) | 方針・ケース・結果 |
| 学習 | [learning-log.md](docs/learning/learning-log.md) / [glossary.md](docs/learning/glossary.md) | 学んだ概念、用語集 |

## 現在の状況

- **フェーズ**: Phase 0（環境調査・企画整理）完了、オーナーのレビュー待ち
- **動作状況**: 空のシーンのみ。CI（Godot 4.7.2）で import と Web 書き出しが成功。画面を出しての起動はまだ未確認。ゲームのコードはまだない
- **直近のタスク**: TASK-005〜006（テストランナーと紐の計算）→ TASK-007〜009（2 人の表示と移動）
