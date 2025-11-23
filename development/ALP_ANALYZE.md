# alpによるアクセスログ解析

このドキュメントでは、alpを使用したnginxアクセスログの解析方法について説明します。

## 概要

alpは、nginxやApacheのアクセスログを解析して、リクエストごとの統計情報を表示するツールです。
ISUCON等のパフォーマンスチューニングにおいて、ボトルネックとなっているエンドポイントを特定するのに非常に有用です。

## セットアップ

### 1. alpのインストール

alpは既に `~/tools/alp` にインストール済みです。

もし再インストールが必要な場合は以下を実行してください:

```bash
mkdir -p ~/tools
cd ~/tools

# macOS (arm64)の場合
curl -L https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_darwin_arm64.zip -o alp_darwin_arm64.zip
unzip alp_darwin_arm64.zip
chmod +x alp

# Linux (amd64)の場合
wget https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.tar.gz
tar zxvf alp_linux_amd64.tar.gz
chmod +x alp
```

### 2. nginxの設定

nginx設定ファイルは既にLTSV形式でログを出力するように設定されています。

設定ファイル: `development/etc/nginx/conf.d/nginx.conf`

ログファイルの場所: `development/logs/nginx/access.log`

## 使い方

### 基本的なワークフロー

1. アクセスログをクリア
2. ベンチマークを実行
3. alpで解析

```bash
cd development

# 1. アクセスログをクリア
./scripts/clear-access-log.sh

# 2. ベンチマークを実行
cd ../bench
./bin/bench_darwin_arm64 run --dns-port=1053
cd ../development

# 3. alpで解析
./scripts/alp-analyze.sh
```

### スクリプトの詳細

#### alp-analyze.sh

アクセスログを解析し、合計処理時間でソートして表示します。

```bash
./scripts/alp-analyze.sh
```

オプションを追加することも可能です:

```bash
# 上位10件のみ表示
./scripts/alp-analyze.sh --limit 10

# JSONフォーマットで出力
./scripts/alp-analyze.sh --output json
```

#### clear-access-log.sh

アクセスログをクリアします。

```bash
./scripts/clear-access-log.sh
```

## 解析結果の読み方

alpの出力例:

```
+-------+-----+-----+-----+-----+-----+--------+------------------------+-------+--------+--------+-------+--------+
| COUNT | 1XX | 2XX | 3XX | 4XX | 5XX | METHOD | URI                    |  MIN  |  MAX   |  SUM   |  AVG  |  P90   |
+-------+-----+-----+-----+-----+-----+--------+------------------------+-------+--------+--------+-------+--------+
| 1000  | 0   | 950 | 0   | 50  | 0   | GET    | /api/livestream/[0-9]+ | 0.001 | 2.500  | 1500.0 | 1.500 | 2.000  |
| 500   | 0   | 500 | 0   | 0   | 0   | POST   | /api/user/[^/]+/icon   | 0.010 | 1.000  | 250.0  | 0.500 | 0.800  |
+-------+-----+-----+-----+-----+-----+--------+------------------------+-------+--------+--------+-------+--------+
```

### 各列の意味

- **COUNT**: リクエスト数
- **1XX, 2XX, 3XX, 4XX, 5XX**: ステータスコード別のリクエスト数
- **METHOD**: HTTPメソッド
- **URI**: リクエストURI（正規表現でグループ化されている）
- **MIN**: 最小処理時間（秒）
- **MAX**: 最大処理時間（秒）
- **SUM**: 合計処理時間（秒）- **重要！**
- **AVG**: 平均処理時間（秒）
- **P90, P95, P99**: パーセンタイル値（90%, 95%, 99%の処理時間）
- **STDDEV**: 標準偏差
- **MIN(BODY), MAX(BODY), SUM(BODY), AVG(BODY)**: レスポンスボディサイズ

### ボトルネックの特定方法

ボトルネックを特定する際は、以下の優先順位で確認します:

1. **SUM（合計処理時間）が大きいURI**
   - 全体のパフォーマンスに最も影響を与えているエンドポイント
   - 最優先で改善すべき対象

2. **COUNT（リクエスト数）が多く、AVG（平均処理時間）も大きいURI**
   - 頻繁に呼ばれて、かつ処理に時間がかかっている
   - 改善効果が高い

3. **AVGは低いがCOUNTが極端に多いURI**
   - N+1問題などの可能性
   - クエリの最適化やキャッシュで改善できる可能性

4. **MAXやP99が極端に大きいURI**
   - 特定の条件下でのみ遅い
   - エッジケースの処理に問題がある可能性

### 改善例

例えば、上記の例では:

1. `/api/livestream/[0-9]+` が SUM=1500.0 で最も影響が大きい
   - COUNT=1000、AVG=1.500なので、1リクエストあたり1.5秒かかっている
   - データベースクエリの最適化、N+1の解消、キャッシュの導入などを検討

2. `/api/user/[^/]+/icon` が SUM=250.0 で2番目
   - AVG=0.500と比較的早いが、COUNT=500と頻繁に呼ばれている
   - 静的ファイル化やCDN配信を検討

## URI統合パターンのカスタマイズ

`alp-analyze.sh` では、以下のパターンでURIを統合しています:

```bash
MATCH_PATTERNS=(
    "/api/livestream/[0-9]+"
    "/api/user/[^/]+/livestream"
    "/api/user/[^/]+/statistics"
    "/api/user/[^/]+/icon"
    "/api/user/[^/]+/theme"
    "/api/livestream/[0-9]+/livecomment"
    "/api/livestream/[0-9]+/reaction"
    "/api/livestream/[0-9]+/report"
    "/api/livestream/[0-9]+/ngwords"
    "/api/livestream/[0-9]+/moderate"
    "/api/livestream/[0-9]+/enter"
    "/api/livestream/[0-9]+/exit"
    "/api/livestream/[0-9]+/statistics"
)
```

アプリケーションの仕様に合わせて、このパターンを追加・修正してください。

## 高度な使い方

### 特定のステータスコードのみ抽出

```bash
~/tools/alp ltsv --file logs/nginx/access.log --status 5xx
```

### 特定の時間帯のみ解析

```bash
~/tools/alp ltsv --file logs/nginx/access.log \
    --filter 'Time >= "2023-11-23T10:00:00" && Time <= "2023-11-23T11:00:00"'
```

### カスタムソート

```bash
# 平均処理時間でソート
~/tools/alp ltsv --file logs/nginx/access.log --sort avg -r

# リクエスト数でソート
~/tools/alp ltsv --file logs/nginx/access.log --sort count -r
```

### JSON出力

```bash
~/tools/alp ltsv --file logs/nginx/access.log --output json | jq .
```

## トラブルシューティング

### アクセスログが空の場合

```bash
# nginxコンテナが起動しているか確認
docker ps | grep nginx

# アクセスログが正しくマウントされているか確認
docker inspect nginx | grep -A 5 Mounts
```

### LTSV形式でない場合

nginx設定ファイルを確認し、`log_format ltsv` が定義されているか確認してください。

```bash
cat development/etc/nginx/conf.d/nginx.conf | grep -A 15 "log_format ltsv"
```

## 参考資料

- [alp GitHub](https://github.com/tkuchiki/alp)
- [ISUCON Workshop - アクセスログ解析](https://isucon-workshop.trap.show/text/chapter-3/2-AccessLog.html)
