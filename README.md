# ISUCON13 Docker Nodejs

### docker compose での構築方法

```bash
$ cd development
$ make down/node
$ make up/node
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

### アクセスログ解析（alp）

alpを使用してnginxのアクセスログを解析し、ボトルネックを特定できます。

#### alpのインストール

```bash
mkdir -p ~/tools
cd ~/tools
# macOS (arm64)の場合
curl -L https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_darwin_arm64.zip -o alp_darwin_arm64.zip
unzip alp_darwin_arm64.zip
chmod +x alp

# Linux (amd64)の場合
# wget https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.tar.gz
# tar zxvf alp_linux_amd64.tar.gz
```

#### 簡単な使い方

```bash
cd development

# アクセスログをクリア（ベンチマーク実行前）
./scripts/clear-access-log.sh

# ベンチマーク実行
# (cd ../bench && ./bin/bench_darwin_arm64 run --dns-port=1053)

# ベンチマーク実行後、解析
./scripts/alp-analyze.sh
```

#### 解析結果の読み方

- **COUNT**: リクエスト数
- **SUM**: 合計処理時間（この値が大きいURIがボトルネック候補）
- **AVG**: 平均処理時間
- **MAX**: 最大処理時間
- **P90/P95/P99**: パーセンタイル値（90%, 95%, 99%の処理時間）

ボトルネックの優先順位は、基本的に **SUM（合計処理時間）** が大きいURIから対応していくと効果的です。