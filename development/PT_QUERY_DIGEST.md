# pt-query-digest でスロークエリ解析

このプロジェクトでは、pt-query-digestをDocker内で実行できるようになっています。ローカルにインストールする必要はありません。

## 使用方法

### 1. スロークエリログのクリア

slow.log　を消す

### 2. ベンチマークの実行

```bash
cd bench
./bin/bench_darwin_arm64 run --dns-port=1053
```

### 3. pt-query-digestで解析

ベンチマーク実行後、以下のコマンドでスロークエリを解析できます:

```bash
# developmentディレクトリから実行
cd development

# 基本の解析（MySQLコンテナから自動的にログを取得）
./scripts/pt-query-digest.sh

# より詳細な解析（実行時間順）
./scripts/pt-query-digest.sh --order-by Query_time:sum

# レポートをファイルに出力
./scripts/pt-query-digest.sh > slow_report.txt

# 特定のデータベースのみを解析
./scripts/pt-query-digest.sh --filter '$event->{db} =~ m/^isupipe/'

# ローカルのログファイルを直接指定する場合
./scripts/pt-query-digest.sh ./slow.log
```

## よく使うオプション

- `--limit N`: 上位N件のみ表示（デフォルト: 10）
- `--order-by`: ソート順を指定（例: `Query_time:sum`, `Lock_time:sum`）
- `--filter`: フィルタ条件を指定
- `--since`: 特定の時刻以降のログのみ解析（例: `--since '2024-01-01 00:00:00'`）
- `--until`: 特定の時刻までのログのみ解析

## 解析結果の見方

pt-query-digestの出力は以下のような構造になっています:

1. **Overall**: 全体の統計情報
2. **Profile**: クエリごとの詳細情報
   - Rank: ランク
   - Response time: レスポンス時間
   - Calls: 実行回数
   - R/Call: 1回あたりの平均時間
   - Query: クエリのパターン

## 注意点

- `long_query_time = 0` に設定しているため、全てのクエリが記録されます
- 本番環境では適切な閾値を設定してください（例: `long_query_time = 0.1`）
- ログファイルが大きくなりすぎる場合は、定期的にローテーションしてください

