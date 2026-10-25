# タスクボード

- 最終更新: 2026-10-19（Phase 5 まで実装、実機確認待ち）
- 状態: Backlog / Ready / In Progress / Blocked / Review / Done
- 優先度: P0 進行を妨げる / P1 現フェーズ必須 / P2 後続でも可 / P3 改善
- 見積もり: XS / S / M / L / XL（XL は分割する）

## サマリー

状態の読み方: **Review（CI 済み・実機確認待ち）** = 自動テストと CI は成功しているが、画面での見た目・指の操作・手触りはオーナーの確認が必要。確認項目は [owner-checklist.md](../testing/owner-checklist.md) にまとめてある。

| ID | タイトル | Phase | 優先度 | 見積 | 状態 | 依存 |
|---|---|---|---|---|---|---|
| TASK-001 | クラウド作業環境の調査 | 0 | P1 | XS | Done | — |
| TASK-002 | ドキュメント初版の作成 | 0 | P1 | M | Review（オーナーのレビュー待ち）| TASK-001 |
| TASK-003 | Windows に Godot 4.7.x を用意し、バージョンを記録する | 0 | P3 | S | Backlog（PC が使えるようになるまで保留。CI と Web 版で代替中）| — |
| TASK-004 | Godot プロジェクトの骨組みを作る | 1 | P1 | S | Done（iPhone の Web 版で灰色の画面を確認）| — |
| TASK-005 | 自作テストランナーを作る | 1 | P1 | S | Done | TASK-004 |
| TASK-006 | RopeModel（純粋計算）と単体テスト | 1 | P1 | S | Done | TASK-005 |
| TASK-007 | 2 人のキャラクターを表示する | 1 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-004 |
| TASK-008 | 入力アクションと KeyboardMoveInput（A の移動）| 1 | P1 | S | Review（CI 済み。キーボード実機は PC がないため未確認）| TASK-007 |
| TASK-009 | B の移動 | 1 | P1 | XS | Review（同上）| TASK-008 |
| TASK-010 | Rope: ハブ計算と最大長の拘束 | 1 | P1 | M | Review（CI 済み・実機確認待ち）| TASK-006, 009 |
| TASK-011 | 紐とハブの描画、ハブ表示切替 | 1 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-010 |
| TASK-012 | カメラ追従（画面の短辺に合わせたズーム補正つき）| 1 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-010 |
| TASK-013 | デバッグ表示（FPS・画面サイズ・位置・敵数）| 1 | P2 | S | Review（CI 済み・実機確認待ち）| TASK-010 |
| TASK-014 | Phase 1 手動プレイテストと記録 | 1 | P1 | S | Ready（オーナー作業。owner-checklist 1〜2 章）| TASK-011〜013, 015, 016 |
| TASK-015 | タッチ入力（フローティング仮想スティック）| 1 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-009 |
| TASK-016 | GitHub Actions で Web 版を書き出し Pages で公開 | 1 | P1 | M | Done（push ごとに自動公開。iPhone でゲームの動作まで確認済み）| TASK-004 |
| TASK-020 | 弾性区間（自然長〜最大長で引き戻す）| 2 | P1 | M | Review（CI 済み・手触りは実機確認待ち）| TASK-014 |
| TASK-021 | 限界時の方式切替（drag / block）| 2 | P1 | S | Review（同上）| TASK-020 |
| TASK-022 | 紐パラメータの実行時調整パネル（TUNE）| 2 | P2 | S | Review（CI 済み・スマホ操作は実機確認待ち）| TASK-020 |
| TASK-023 | 慣性ハブの試作（ADR-002 案 B）| 2 | P2 | M | Review（CI 済み・手触りは実機確認待ち）| TASK-020 |
| TASK-024 | Phase 2 比較プレイテストと方式決定 | 2 | P1 | S | Ready（オーナー作業。owner-checklist 3 章）| TASK-020〜023 |
| TASK-025 | 仮の仮想ツインスティック（Phase 2b）| 2b | P1 | M | Review（TASK-015 で実装済み。実機確認待ち）| TASK-024 |
| TASK-026 | Android 実機での操作スパイク評価 | 2b | P1 | M | Backlog（Android 端末の有無が未確認。iPhone の Web 版で代替）| TASK-025 |
| TASK-030 | 敵・武器の定義データ（EnemyDef / WeaponDef と .tres）| 3 | P1 | S | Review（CI 済み）| TASK-024 |
| TASK-031 | RunState: 共有 HP・経過時間・ゲームオーバー・クリア | 3 | P1 | S | Review（CI 済み）| TASK-030 |
| TASK-032 | Enemy: 追跡・接触ダメージ・被ダメージと撃破 | 3 | P1 | M | Review（CI 済み・実機確認待ち）| TASK-031 |
| TASK-033 | EnemySpawner: 画面外から時間とともに増えて出現 | 3 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-032 |
| TASK-034 | Weapon: Blaster（弾）と Shockwave（範囲）の自動攻撃 | 3 | P1 | M | Review（CI 済み・実機確認待ち）| TASK-032 |
| TASK-035 | RopeAttack: 張った紐に触れた敵へのダメージ | 3 | P1 | M | Review（CI 済み・実機確認待ち）| TASK-032, 021 |
| TASK-040 | XpOrb: 経験値オーブの落下・吸い寄せ・取得 | 4 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-032 |
| TASK-041 | UpgradeDef / UpgradePool（13 種）/ UpgradePicker | 4 | P1 | M | Review（CI 済み）| TASK-040 |
| TASK-042 | MenuPanel とレベルアップの 3 択（ゲーム一時停止）| 4 | P1 | M | Review（CI 済み・実機確認待ち）| TASK-041 |
| TASK-050 | HUD: HP・経験値・残り時間・レベル・撃破数 | 5 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-031 |
| TASK-051 | タイトル画面 | 5 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-042 |
| TASK-052 | ポーズ・結果画面・リトライ | 5 | P1 | S | Review（CI 済み・実機確認待ち）| TASK-042 |
| TASK-053 | 通しプレイの統合テスト（ボットが勝利/敗北まで自動プレイ）| 5 | P1 | M | Done（CI で成功）| TASK-052 |
| TASK-055 | ホーム画面・ツールバー・ステージ 10 個・エンドレス・保存・設定（ADR-016）| 5 | P1 | L | Review（CI の結果待ち・実機確認待ち）| TASK-052 |
| TASK-060 | 縦持ち・横持ちの確定とスマホ操作の仕上げ（Phase 6）| 6 | P1 | M | Backlog（U-01 の決定後）| owner-checklist |
| TASK-070 | 見た目・効果音・BGM・キャラ/武器/敵/強化の追加（Phase 7）| 7 | P2 | XL | Backlog（素材の方針が未決定。分割してから着手）| TASK-060 |
| TASK-080 | Android 向けビルドとテスト（Phase 8）| 8 | P2 | L | Backlog（Android SDK・署名キー。署名キーは公開リポジトリに入れない）| TASK-070 |
| TASK-090 | iOS 向けビルドとテスト（Phase 9）| 9 | P2 | L | Backlog（Mac と Xcode が必要。有無が未確認）| TASK-070 |
| TASK-100 | 公開準備（Phase 10）| 10 | P3 | L | Backlog | TASK-080, 090 |

Phase 3〜5 は、オーナーの指示（「計画済みの範囲を一通り実装して、あとから確認すべき点をまとめる」）で、Phase 2 の手触り検証の結果を待たずに先行して実装した。紐の方式（drag/block・弾性・慣性）は仮の既定値で動いており、TASK-024 の結果で変わる可能性がある。変わっても紐の計算は `RopeModel` / `Rope` / `RopeConfig` に閉じているため、戦闘側への影響は小さい。

---

## 詳細

### TASK-001 クラウド作業環境の調査 — Done
- 目的: 実装前に作業環境を把握する
- 実施内容: リポジトリ内容、Git 状態、Godot の有無、外部ダウンロード可否を確認
- 完了条件: 結果を README と test-results に記録
- 結果: リポジトリは空（コミットなし、ブランチ `master`）。Godot 未インストール。github.com 等へのダウンロードはネットワーク制限で不可 → **クラウド側では Godot を実行できない**
- 関連: NFR-006 / テスト: なし（調査）

### TASK-002 ドキュメント初版の作成 — Review
- 目的: 要件・設計・計画の共通認識を作る
- 完了条件: README / CLAUDE.md / docs 一式が存在し、オーナーがレビューする
- テスト: オーナーのレビュー（**オーナー確認待ち**）

### TASK-003 Windows に Godot 4.7.x を用意する — Ready（オーナー作業）
- 目的: 実行確認の環境を作る（Claude のクラウド環境では Godot を実行できないため）
- 実施内容: 公式サイトから Godot 4.7.x（標準版、.NET 版ではない）を入手。コマンドから使えるようにする
- 完了条件: `godot --version` の出力（例: `4.7.2.stable.official...`）を共有してもらい、test-results に記録
- 関連: ADR-001

### TASK-004 Godot プロジェクトの骨組み — Ready
- 目的: Godot で開ける最小のプロジェクトを作る
- 実施内容: `project.godot`（名前、ウィンドウ 1280×720、レンダラー = Compatibility）、`.gitignore`/`.gitattributes` 確認、`docs/.gdignore`、空の `main.tscn`
- 変更点: InputMap は TASK-008 へ移した（Godot を実行できず、手書きの入力設定を検証できないため。必要になる TASK-008 で、動作確認とセットで追加する）
- 実施結果（2026-10-19）: 上記ファイルを作成。CI（Godot 4.7.2）で import と Web 書き出しが成功（test-results 参照）。**画面表示を伴う起動は未確認**のため Review のまま
- 完了条件: Windows の Godot でプロジェクトを開いてエラーなく実行でき、灰色の画面が出る
- テスト: TC-101（手動、**オーナー確認**）
- 関連: ADR-009

### TASK-005 自作テストランナー
- 目的: ロジックを自動で確認できるようにする（ADR-006）
- 実施内容: `tests/run_tests.gd`（SceneTree 継承、`tests/test_*.gd` を読み込み `test_` 始まりの関数を実行し、失敗数で終了コードを返す）
- 完了条件: 意図的に失敗するテストで終了コード 1、全成功で 0
- テスト: TC-001

### TASK-006 RopeModel と単体テスト
- 目的: 紐の計算を、シーンと切り離して正しさを保証する
- 実施内容: detailed-design 2.4 の 3 関数と、TC-002〜006 のテスト
- 完了条件: headless 実行で全テスト成功
- 関連: FR-004, 005, 008 / AC-003, 005

### TASK-007 2 人のキャラクターを表示する
- 実施内容: `character.tscn`（CharacterBody2D + CollisionShape2D 円 + 仮の円描画）。main に A（青）・B（橙）を配置
- 完了条件: 実行すると 2 つの円が左右に並ぶ / テスト: TC-102（手動）

### TASK-008 A の移動
- 実施内容: InputMap `a_*`、`KeyboardMoveInput`、`Character.move_intent`
- 完了条件: WASD で A だけが動き、斜めでも速くならない / テスト: TC-103 / 関連: FR-001, 061, 064

### TASK-009 B の移動
- 実施内容: InputMap `b_*`、2 つ目の KeyboardMoveInput（prefix = "b"）。**コードの追加なし**で動くこと（ADR-005 の確認）
- 完了条件: 矢印キーで B だけが動き、A と同時に操作できる / テスト: TC-103 / 関連: FR-002

### TASK-010 Rope: ハブ計算と最大長の拘束
- 実施内容: `rope.gd`、`RopeConfig`、`default_rope_config.tres`、process_priority の設定
- 完了条件: 2 人をどう動かしても A〜B 距離が 2R + 1px 以下（デバッグ表示で確認）
- テスト: TC-104（手動）/ 関連: FR-003〜005, AC-002

### TASK-011 紐とハブの描画
- 完了条件: 紐が伸び率に応じて色が変わり、F1 でハブ表示が切り替わる。切り替えても動きが変わらない
- テスト: TC-105 / 関連: FR-007, 008

### TASK-012 カメラ追従
- 完了条件: 2 人が一緒に移動しても、常に両方が画面内にいる / 関連: FR-009

### TASK-013 デバッグ表示
- 完了条件: FPS、A〜B 距離、伸び率が表示され、F3 で切替 / 関連: FR-072

### TASK-015 最小のタッチ入力
- 目的: スマホのブラウザでも Phase 1 を操作できるようにする（本格的な仮想スティックは Phase 2b / 6）
- 実施内容: `TouchMoveInput`（KeyboardMoveInput と同じく `move_intent` を書くだけ）。画面左半分でタッチした位置を基準にドラッグ方向へ A、右半分で B。PC ではマウスでも試せる
- 完了条件: スマホで A・B を同時に動かせる / テスト: TC-107（手動） / 関連: FR-063, 064

### TASK-016 Web 版の自動ビルドと公開
- 目的: PC なしでもスマホで最新版を確認できるようにする
- 実施内容: GitHub Actions のワークフロー（Godot の Web 書き出し → Pages へ公開）。書き出し設定 `export_presets.cfg` はコミットしない方針（CLAUDE.md）なので、CI 内で生成する方法を検討する
- 調査結果（2026-10-19、公式ドキュメント 4.2 版と検索結果。4.7 版は未確認）: Web 版は SharedArrayBuffer を使い、サーバーが COOP/COEP ヘッダーを返さないと動かない。GitHub Pages ではヘッダーを設定できないため `coi-serviceworker` で回避する案がある。iOS では Godot 4 の Web 版が動かないという報告がある（古い可能性あり）
- 分割: **016a** CI で Godot を取得し、テスト実行と Web 書き出しを行う（公開なし。ログは私が読める）（**016a は 2026-10-19 に成功**）→ **016b** Pages で公開（**2026-10-19 に成功**。https://suutukuru.github.io/bind-run/ ）→ **016c** iPhone で空シーン（灰色）の表示を確認（**2026-10-19 完了**）。操作の確認はタッチ入力（TASK-015）の後（オーナーのリポジトリ公開と Pages 有効化が必要）→ **016c** スマホ実機で起動確認（オーナー）
- 完了条件: push 後に URL が更新され、スマホのブラウザで起動する / テスト: PL-001（手動） / **オーナー作業: リポジトリの公開と Pages の有効化**

### TASK-014 Phase 1 プレイテスト
- 実施内容: TC-101〜106 をオーナーが実施。H-03, H-04 について一言感想を記録
- 完了条件: test-results に結果、learning-log に学び、Phase 2 の調整方針を決定
- **オーナーのプレイ確認が必要**


### TASK-030〜053（Phase 3〜5）の完了条件と確認方法

詳細な設計は [detailed-design.md](../design/detailed-design.md)、確認項目は [owner-checklist.md](../testing/owner-checklist.md)。

| ID | 完了条件 | 自動テスト（CI）| 実機で確認すること |
|---|---|---|---|
| TASK-030 | `.tres` を `load` でき、敵 3 種・武器 2 種を定義できる | test_combat | — |
| TASK-031 | 共有 HP が 0 で敗北、制限時間でクリア、`finished` が 1 回だけ出る | test_combat | HUD の表示 |
| TASK-032 | 敵が近いキャラへ進み、接触で間隔つきにダメージ、撃破で `died` | test_combat | 見た目、重なり |
| TASK-033 | 画面の外に出現し、時間で間隔が縮み種類が増える | test_combat, test_gameplay | 難易度（5 章）|
| TASK-034 | 最近い敵に撃つ／範囲攻撃、クールダウンを守る、標的がいないと待つ | test_combat | 気持ちよさ |
| TASK-035 | 張った紐の上の敵だけに、再ヒット間隔つきでダメージ。たるんだ紐では無効 | test_combat, test_gameplay | H-02（4 章）|
| TASK-040 | 撃破でオーブが落ち、近づくと吸い寄せ、触れると経験値 | test_progression, test_gameplay | 見た目 |
| TASK-041 | 13 種すべてが Main に適用でき、重複なし、上限を守る、乱数を固定すれば再現する | test_progression | 選びたくなるか（H-06）|
| TASK-042 | レベルアップでゲームが止まり 3 択、選ぶと効果、複数レベルは続けて選ぶ | test_progression, test_gameplay | 押しやすさ |
| TASK-050 | HP・経験値・時間・レベルが更新される | （起動の確認のみ）| 見やすさ（6 章）|
| TASK-051 | タイトルが出て START でゲームへ | test_progression | 見た目 |
| TASK-052 | ポーズ／結果（RETRY / TITLE） | test_progression, test_gameplay | 動作 |
| TASK-053 | ボットが 25 秒のランを勝利まで、囲まれて敗北まで通せる | test_gameplay | — |
