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

```
基本コマンド
# ベンチマーク実行
make bench

# スロークエリログをクリア
make clear-slow-log

# MySQL設定（long_query_time=10秒に設定）
make mysql-config

# スロークエリ解析
make analyze

# フルワークフロー（推奨）
make full-bench
```