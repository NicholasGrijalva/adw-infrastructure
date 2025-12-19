#!/bin/bash
# Setup .env for a worktree by copying from parent repo and appending port config
# Usage: ./scripts/setup_worktree_env.sh <worktree_path> [backend_port] [frontend_port]
#
# Example:
#   ./scripts/setup_worktree_env.sh trees/87c721c0 9109 9209

set -e

WORKTREE_PATH="${1:?Usage: $0 <worktree_path> [backend_port] [frontend_port]}"
BACKEND_PORT="${2:-9100}"
FRONTEND_PORT="${3:-9200}"

# Get the script's directory to find the parent repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_REPO="$(dirname "$SCRIPT_DIR")"

# Resolve worktree path (handle both absolute and relative)
if [[ "$WORKTREE_PATH" = /* ]]; then
    WORKTREE_ABS="$WORKTREE_PATH"
else
    WORKTREE_ABS="$PARENT_REPO/$WORKTREE_PATH"
fi

# Validate paths
if [[ ! -d "$WORKTREE_ABS" ]]; then
    echo "Error: Worktree directory does not exist: $WORKTREE_ABS"
    exit 1
fi

if [[ ! -f "$PARENT_REPO/.env" ]]; then
    echo "Error: Parent .env does not exist: $PARENT_REPO/.env"
    exit 1
fi

echo "Setting up .env for worktree: $WORKTREE_ABS"
echo "  Backend port:  $BACKEND_PORT"
echo "  Frontend port: $FRONTEND_PORT"

# Step 1: Copy parent .env to worktree
cp "$PARENT_REPO/.env" "$WORKTREE_ABS/.env"
echo "  Copied .env from parent repo"

# Step 2: Create .ports.env
cat > "$WORKTREE_ABS/.ports.env" << EOF
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
VITE_BACKEND_URL=http://localhost:$BACKEND_PORT
EOF
echo "  Created .ports.env"

# Step 3: Append port config to .env (with section header)
cat >> "$WORKTREE_ABS/.env" << EOF

# ========================================
# WORKTREE PORT CONFIGURATION
# ========================================
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
VITE_BACKEND_URL=http://localhost:$BACKEND_PORT
EOF
echo "  Appended port configuration to .env"

echo ""
echo "Done! Worktree .env is ready with:"
echo "  - All credentials from parent repo"
echo "  - Isolated port configuration"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_ABS"
echo "  uv sync --all-extras && uv pip install -e ."
