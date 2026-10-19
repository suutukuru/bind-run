# テスト結果

実施したテストだけを記録する。未実施のものは書かない。

## 2026-10-19 Phase 0 環境調査（TASK-001）

- 対象バージョン: なし（リポジトリにコミットなし）
- 実施内容と結果:

| 確認内容 | コマンド | 結果 |
|---|---|---|
| リポジトリの内容 | `ls -la`, `git status`, `git log` | `.git` のみ。コミットなし、ブランチ `master` |
| Godot の有無 | `which godot godot4` | 見つからない |
| Godot 配布元への接続 | `curl` で github.com / downloads.tuxfamily.org | 接続拒否（ネットワーク制限） |
| 最新の安定版 | Web 検索（godotengine.org のダウンロードページ） | 4.7.2-stable（2026-08-18）。4.8-beta1（2026-10-15）はベータ |

- 結論: クラウド作業環境では Godot の自動テスト・構文チェックを実行できない（R-08）。
- 自動テスト: **未実施**（実行環境なし）。代替: オーナーの Windows 環境で実行する。

## 2026-10-19 CI 初回実行（TASK-004 / TASK-016a）

- 対象: コミット `9ee883e`（GitHub Actions run 39194079402、ubuntu-latest）
- 実行内容（`.github/workflows/ci.yml`）と結果:

| ステップ | コマンド | 結果 |
|---|---|---|
| Godot / テンプレート取得 | curl + `sha512sum -c` | 成功（チェックサム OK）。`godot --version` = `4.7.2.stable.official.ed1daf0bf` |
| プロジェクト import | `godot --headless --path . --import` | 成功。エラー出力なし |
| 単体テスト | `tests/run_tests.gd` | **スキップ**（まだ存在しない） |
| Web 書き出し | `godot --headless --path . --export-release "Web" build/web/index.html` | 成功。`main.tscn` がパックされ、`index.html / .js / .wasm(約 39.5MB) / .pck` などが生成された |
| 成果物アップロード | actions/upload-artifact | 成功（約 10MB に圧縮） |

- 分かったこと: `project.godot` と `main.tscn` は Godot 4.7.2 で読み込め、Web 書き出しまで通る。
- **まだ確認できていないこと**: 実際に起動して画面が出るか（TC-101）、`variant/thread_support=false` が効いているか（どのテンプレートが使われたか）、ブラウザでの動作。
- 自動テスト（単体）: 未実施（テスト未作成）。

## 2026-10-19 CI: スレッドなし確認と Pages 公開（TASK-016a / 016b）

- 対象: コミット `648ba07`（run 39195100702）、`bf2200c`（run 39195148416）
- 結果:

| 確認 | 結果 |
|---|---|
| Web 書き出しがスレッドなしか | **確認済み**。生成された `index.html` に `const GODOT_THREADS_ENABLED = false;`（`variant/thread_support=false` が有効） |
| 当初のチェック（`ensureCrossOriginIsolationHeaders`） | 誤った指標（PWA 用の別項目で既定値 true）。私のチェックの誤りで、書き出し設定は正しかった。チェックを修正済み |
| GitHub Pages へのデプロイ | 成功。URL: https://suutukuru.github.io/bind-run/ |
| 公開 URL へのアクセス | **未確認**（この環境から github.io に接続できない）。スマホでの表示確認はオーナー待ち（TASK-016c） |

## 不具合一覧

| BUG-ID | 現象 | 再現手順 | 期待結果 | 環境 | 重要度 | 状態 |
|---|---|---|---|---|---|---|
| （なし） | | | | | | |
