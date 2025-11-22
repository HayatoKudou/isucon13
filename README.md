# ISUCON13 Docker Nodejs

### docker compose での構築方法

```bash
$ cd development
$ make down/go
$ make up/go
```

### ベンチマーカーの実行

```bash
$ cd bench
$ make
$ ./bin/bench_darwin_arm64 run --dns-port=1053
```

### メインのデータベース（isupipe）

```
ホスト: 127.0.0.1 または localhost
ポート: 3306
ユーザー名: isucon
パスワード: isucon
データベース名: isupipe
```

### スロークエリ解析（pt-query-digest）

pt-query-digestを使用してスロークエリを解析できます。詳細は [PT_QUERY_DIGEST.md](./development/PT_QUERY_DIGEST.md) を参照してください。

簡単な使い方:

```bash
cd development

# スロークエリログをクリア（ベンチマーク実行前）
SLOW_LOG=$(docker exec mysql mysql -uroot -proot -Nse "SHOW VARIABLES LIKE 'slow_query_log_file';" 2>&1 | grep -v "Using a password" | awk '{print $2}')
docker exec mysql bash -c "echo '' > ${SLOW_LOG}"

# ベンチマーク実行後、解析
./scripts/pt-query-digest.sh
```

**注意**: 初回実行時は、Dockerイメージ（percona-toolkit）のダウンロードに時間がかかる場合があります。