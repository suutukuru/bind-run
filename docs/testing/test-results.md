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

## 2026-10-19 iPhone 実機での Web 版表示（TASK-016c）

- 実施者: オーナー（iPhone の Safari。機種・iOS バージョンは未記録）
- 対象: Pages に公開された、空のシーンだけの版（コミット `bf2200c` 時点）。URL: https://suutukuru.github.io/bind-run/
- 結果: **濃いめの灰色の画面が表示された**（`project.godot` の背景色 `Color(0.2, 0.2, 0.22)` と一致）。読み込みも完了した
- 分かったこと: スレッドなし書き出しの Web 版は、iPhone の Safari で起動して描画できる
- まだ確認できていないこと: 操作（タッチ）、キャラ表示後の挙動、フレームレート、横持ち/縦持ち、機種差

## 2026-10-19 単体テストの CI 実行（TASK-005〜010）

- 対象: コミット `6f511a7`（run 39196374846）。25 件のテスト（`tests/test_*.gd`）を `godot --headless --script res://tests/run_tests.gd` で実行
- 結果: **全件成功**（テストステップが終了コード 0）。ランナー自己確認（わざと失敗するテスト → 終了コード 1）も成功。Web 書き出しとスレッドなし確認も成功
- 内訳: RopeModel 13 件（TC-002〜006 と詳細設計の数値例）／Character 3 件／入力 5 件／Rope 4 件
- 注意: `Result: N passed` の行そのものはログの取得範囲外で未読。件数 25 は、前回の失敗実行（23 成功 + 2 失敗）と同じテスト構成からの推定
- 実行していないもの: 画面を出しての表示確認（TC-101〜106 の手動部分）、実機でのキー/タッチ操作

### 途中で起きた不具合（すべて修正済み・同日）

| BUG-ID | 現象 | 原因 | 修正 |
|---|---|---|---|
| BUG-001 | テストが読み込めず失敗（`root` が未定義） | テスト基底が RefCounted で SceneTree の `root` を持たない | ランナーが `tree` を渡す |
| BUG-002 | 追加したノードの `_ready()` が呼ばれず、Rope のメンバーが空 | `SceneTree._initialize()` の時点ではルートが未準備 | ランナーが 1 フレーム待つ |
| BUG-003 | `KeyboardMoveInput.target` が null のまま | 型付きノード参照（`@export var target: Character`）がシーンから解決されなかった | `target_path`（NodePath）を `_ready()` で解決 |

## 2026-10-19 CI: 紐の描画とタッチ入力（TASK-011 / TASK-015）

- 対象: コミット `3c76a0b`（run 39196716026）、`138c2ab`（run 39196810092）
- 結果: 単体テストのステップ・ランナー自己確認・Web 書き出し・スレッドなし確認・Pages 公開、すべて成功
- 追加した自動テスト: 紐の色（白→黄→赤）、ハブ表示の切替で位置が変わらないこと（AC-003）、タッチ入力（方向と強さ、左右の担当、2 本指の同時操作、指を離したあとの挙動）
- 実行していないもの: 見た目の確認、スマホ実機での指の操作（TC-107）。**オーナーの確認待ち**

## 2026-10-19 Phase 2〜5 の CI 実行（コミット `9b00bb0`、run 39201843537）

- 単体テスト + 統合テスト: **76 件すべて成功**（`Result: 76 passed, 0 failed (76 total)`）。`godot --headless --fixed-fps 60 --script res://tests/run_tests.gd`
- 内訳: RopeModel 20／Rope・カメラ 14／Character 3／入力 5／タッチ 7／調整パネル 3／戦闘 14／成長・メニュー 10／**通しプレイ（統合）5**
- 通しプレイ（`test_gameplay.gd`）で確認できたこと: ①張った紐だけで敵を倒せる ②武器で敵を全滅させ、経験値オーブを拾える ③ボットが 25 秒のランを勝利まで通し、途中のレベルアップで選択肢を押して進められる ④動かずに囲まれると敗北してゲームオーバー画面が出る ⑤敵 150 体 × 120 フレームの処理が **40 ms**（描画なしの計測）
- ランナー自己確認（わざと失敗するテスト → 終了コード 1）: 成功
- スモーク実行（タイトル・ゲームシーンを各 300 フレーム起動）: `SCRIPT ERROR` なし
- Web 書き出し: 成功。スレッドなし（`GODOT_THREADS_ENABLED = false`）。`index.pck` 約 78KB、`index.wasm` 約 39.5MB
- Pages への公開: 成功
- **実行していないもの（オーナー確認待ち → owner-checklist.md）**: 画面での見た目、縦持ち/横持ちの表示、指の操作、紐の手触り、紐攻撃の気持ちよさ、難易度、実機の FPS、キーボード操作（PC がないため）

### 追加で見つかった不具合（すべて修正済み・同日）

| BUG-ID | 現象 | 原因 | 修正 | 見つけた方法 |
|---|---|---|---|---|
| BUG-004 | **公開中の版でタッチ入力が機能していなかった可能性が高い**。ゲームを直接起動すると `TouchMoveInput` が構文エラーで読み込めない | クラス自身の enum を型にした書き方（`@export var side: Side = Side.LEFT`）が読み込み順で失敗 | int の定数 + `@export_enum` に変更（ADR-011） | CI に追加した**スモーク実行**（単体テストは読み込み順が違うため通っていた） |
| BUG-005 | 縦持ちのスマホでキャラが数 px の点になり「画面が出ていない」ように見えた | `expand` のストレッチで縦方向の表示範囲が広がる | カメラのズームを画面の短辺に合わせる（ADR-012） | オーナー報告から推定。**修正後の見え方は未確認** |

## 不具合一覧

| BUG-ID | 現象 | 再現手順 | 期待結果 | 環境 | 重要度 | 状態 |
|---|---|---|---|---|---|---|
| BUG-001〜005 | 上記「途中で起きた不具合」「追加で見つかった不具合」を参照（すべて修正済み）| | | | | Fixed |
