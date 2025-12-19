#!/bin/bash

# Refresh ADW Webhook Server
# Kills existing webhook process and starts a fresh one

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/webhook.log"

echo "Stopping existing webhook server..."

# Kill existing webhook processes
pkill -f "trigger_webhook" 2>/dev/null || true
sleep 1

# Force kill if still running
if pgrep -f "trigger_webhook" > /dev/null; then
    echo "Process still running, force killing..."
    pkill -9 -f "trigger_webhook"
    sleep 1
fi

# Also clear port 8001 if occupied
if lsof -i :8001 > /dev/null 2>&1; then
    echo "Clearing port 8001..."
    lsof -ti :8001 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

echo "Starting webhook server..."

# Start webhook server in background
cd "$PROJECT_ROOT"
nohup uv run adws/adw_triggers/trigger_webhook.py > "$LOG_FILE" 2>&1 &
sleep 2

# Verify running
if pgrep -f "trigger_webhook" > /dev/null; then
    echo "Webhook started successfully"
    echo ""
    curl -s http://localhost:8001/health | python3 -m json.tool
else
    echo "ERROR: Webhook failed to start"
    echo "--- Log output ---"
    cat "$LOG_FILE"
    exit 1
fi
