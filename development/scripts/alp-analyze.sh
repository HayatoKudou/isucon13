#!/bin/bash
# alpでnginxアクセスログを解析するスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPMENT_DIR="$(dirname "$SCRIPT_DIR")"
ACCESS_LOG="${DEVELOPMENT_DIR}/logs/nginx/access.log"
ALP_BIN="${HOME}/tools/alp"

# alpがインストールされているか確認
if [ ! -f "${ALP_BIN}" ]; then
    echo "エラー: alpが見つかりません (${ALP_BIN})"
    echo "alpをインストールしてください。"
    exit 1
fi

# アクセスログが存在するか確認
if [ ! -f "${ACCESS_LOG}" ]; then
    echo "エラー: アクセスログが見つかりません (${ACCESS_LOG})"
    echo "nginxコンテナが起動しているか確認してください。"
    exit 1
fi

# アクセスログが空でないか確認
if [ ! -s "${ACCESS_LOG}" ]; then
    echo "警告: アクセスログが空です。"
    echo "ベンチマークを実行してから再度試してください。"
    exit 1
fi

echo "alpでアクセスログを解析中..."
echo "ログファイル: ${ACCESS_LOG}"
echo ""

# URI統合パターン（ISUCONでよく使うパターン）
# 必要に応じて調整してください
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

# -mオプション用のパターン文字列を作成
MATCH_ARGS=""
for pattern in "${MATCH_PATTERNS[@]}"; do
    MATCH_ARGS="${MATCH_ARGS} -m ${pattern}"
done

# alpを実行（合計処理時間でソート）
${ALP_BIN} ltsv \
    --file "${ACCESS_LOG}" \
    --sort sum \
    -r \
    ${MATCH_ARGS} \
    "$@"

echo ""
echo "解析完了。"
echo ""
echo "Tips:"
echo "  - SUM列が大きいURIがボトルネックの候補です"
echo "  - COUNT列でリクエスト数を確認できます"
echo "  - AVG列で平均処理時間を確認できます"
