# Install Worktree

This command sets up an isolated worktree environment with custom port configuration.

> **Note**: Port isolation is temporary - only needed while the worktree is active to avoid conflicts with other running instances. Once the PR is merged and the worktree is removed via `purge_tree.sh`, the isolated ports are no longer relevant.

## Parameters
- Worktree path: {0}
- Backend port: {1}
- Frontend port: {2}

## Read
- .env.sample (from parent repo)
- .mcp.json (from parent repo)
- playwright-mcp-config.json (from parent repo)

## Steps

1. **Setup .env with credentials and port isolation**
   Run the setup script from the parent repo root:
   ```bash
   ./scripts/setup_worktree_env.sh {0} {1} {2}
   ```
   This script:
   - Copies `.env` from parent repo (with all API credentials)
   - Creates `.ports.env` with isolated port configuration
   - Appends port config to `.env`

2. **Navigate to worktree directory**
   ```bash
   cd {0}
   ```

3. **Copy and configure MCP files**
   - Copy `.mcp.json` from parent repo if it exists
   - Copy `playwright-mcp-config.json` from parent repo if it exists
   - These files are needed for Model Context Protocol and Playwright automation
   
   After copying, update paths to use absolute paths:
   - Get the absolute worktree path: `WORKTREE_PATH=$(pwd)`
   - Update `.mcp.json`:
     - Find the line containing `"./playwright-mcp-config.json"`
     - Replace it with `"${WORKTREE_PATH}/playwright-mcp-config.json"`
     - Use a JSON-aware tool or careful string replacement to maintain valid JSON
   - Update `playwright-mcp-config.json`:
     - Find the line containing `"dir": "./videos"`
     - Replace it with `"dir": "${WORKTREE_PATH}/videos"`
     - Create the videos directory: `mkdir -p ${WORKTREE_PATH}/videos`
   - This ensures MCP configuration works correctly regardless of execution context

4. **Install backend dependencies**
   ```bash
   uv sync --all-extras
   uv pip install -e .
   ```

5. **Install frontend dependencies**
   ```bash
   cd frontend && npm install
   ```

6. **Setup database (if applicable)**
   ```bash
   # Run any database setup scripts if needed
   ```

## Error Handling
- If parent .env files don't exist, create minimal versions from .env.sample files
- Ensure all paths are absolute to avoid confusion

## Report
- List all files created/modified (including MCP configuration files)
- Show port assignments
- Confirm dependencies installed
- Note any missing parent .env files that need user attention
- Note any missing MCP configuration files
- Show the updated absolute paths in:
  - `.mcp.json` (should show full path to playwright-mcp-config.json)
  - `playwright-mcp-config.json` (should show full path to videos directory)
- Confirm videos directory was created