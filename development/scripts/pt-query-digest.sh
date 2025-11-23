#!/bin/bash
# pt-query-digestをDocker内で実行するスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPMENT_DIR="$(dirname "$SCRIPT_DIR")"

# スロークエリログを有効化（設定ファイルが読み込まれていない場合に備えて）
echo "スロークエリログを有効化しています..."
docker exec mysql mysql -uroot -proot -e "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 0;" 2>&1 | grep -v "Using a password" || true

# スロークエリログファイルのパスを取得
SLOW_LOG_FILE=$(docker exec mysql mysql -uroot -proot -Nse "SHOW VARIABLES LIKE 'slow_query_log_file';" 2>&1 | grep -v "Using a password" | awk '{print $2}' || echo "/var/lib/mysql/slow.log")
LOCAL_SLOW_LOG="${DEVELOPMENT_DIR}/slow.log"

# 引数の解析
# 最初の引数がファイルとして存在する場合はそのファイルを解析
# それ以外の場合は、MySQLコンテナからログを取得してオプションを適用

if [ $# -gt 0 ] && [ -f "$1" ]; then
    # ファイルが指定されている場合
    LOG_FILE="$1"
    ABS_LOG_FILE="$(cd "$(dirname "$LOG_FILE")" && pwd)/$(basename "$LOG_FILE")"
    echo "pt-query-digestで解析中: $LOG_FILE"
    docker run --rm \
        -v "${ABS_LOG_FILE}:/slow.log:ro" \
        percona/percona-toolkit:latest \
        pt-query-digest /slow.log "${@:2}"
else
    # MySQLコンテナからログを取得
    echo "スロークエリログをMySQLコンテナから取得しています..."
    docker cp mysql:${SLOW_LOG_FILE} "${LOCAL_SLOW_LOG}" 2>/dev/null || {
        echo "エラー: スロークエリログが見つかりません。"
        echo "スロークエリログファイルのパス: ${SLOW_LOG_FILE}"
        echo "MySQLコンテナが起動しているか、スロークエリログが有効になっているか確認してください。"
        exit 1
    }
    
    if [ ! -s "${LOCAL_SLOW_LOG}" ]; then
        echo "警告: スロークエリログが空です。"
        echo "ベンチマークを実行してから再度試してください。"
        exit 1
    fi
    
    echo "pt-query-digestで解析中..."
    docker run --rm \
        -v "${LOCAL_SLOW_LOG}:/slow.log:ro" \
        percona/percona-toolkit:latest \
        pt-query-digest /slow.log "$@"
fi

