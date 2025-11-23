#!/bin/bash
# nginxアクセスログをクリアするスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPMENT_DIR="$(dirname "$SCRIPT_DIR")"
ACCESS_LOG="${DEVELOPMENT_DIR}/logs/nginx/access.log"

# アクセスログをクリア
echo "アクセスログをクリアしています..."
echo "" > "${ACCESS_LOG}"

# nginxにログのリロードを通知（必要に応じて）
docker exec nginx nginx -s reopen 2>/dev/null || true

echo "アクセスログをクリアしました: ${ACCESS_LOG}"
echo "ベンチマークを実行してください。"
