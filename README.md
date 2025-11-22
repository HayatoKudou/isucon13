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