# ADW Infrastructure

**AI Developer Workflow** - A portable automation system that transforms GitHub issues into pull requests using Claude Code CLI.

## What is ADW?

ADW orchestrates Claude Code to process GitHub issues through a complete software development lifecycle:

```
GitHub Issue --> Classification --> Planning --> Implementation --> Testing --> Review --> PR
```

Each workflow runs in an **isolated git worktree** with dedicated ports, enabling parallel execution of up to 15 concurrent workflows.

---

## Directory Structure

```
your-project/
├── adws/                              # Core ADW system
│   ├── adw_modules/                   # Reusable Python modules
│   │   ├── agent.py                   # Claude Code CLI execution
│   │   ├── data_types.py              # Pydantic models & types
│   │   ├── git_ops.py                 # Git operations (branch, commit, push)
│   │   ├── github.py                  # GitHub CLI wrapper (issues, PRs, comments)
│   │   ├── label_ops.py               # Issue label operations
│   │   ├── r2_uploader.py             # Cloudflare R2 screenshot uploads
│   │   ├── state.py                   # ADW state persistence
│   │   ├── utils.py                   # Utilities (logging, env, parsing)
│   │   ├── workflow_ops.py            # Core workflow operations
│   │   └── worktree_ops.py            # Git worktree & port management
│   │
│   ├── adw_triggers/                  # Automation triggers
│   │   ├── trigger_webhook.py         # FastAPI webhook server (GitHub events)
│   │   └── trigger_cron.py            # Polling trigger (every 20s)
│   │
│   ├── adw_tests/                     # ADW test suite
│   │   ├── health_check.py            # System validation
│   │   └── test_*.py                  # Unit tests
│   │
│   │── # Entry Point Workflows (create worktrees)
│   ├── adw_plan_iso.py                # Planning only
│   ├── adw_patch_iso.py               # Quick patches
│   │
│   │── # Dependent Workflows (require existing worktree)
│   ├── adw_build_iso.py               # Implementation
│   ├── adw_test_iso.py                # Testing
│   ├── adw_review_iso.py              # Review + screenshots
│   ├── adw_document_iso.py            # Documentation generation
│   ├── adw_ship_iso.py                # PR approval + merge
│   │
│   │── # Orchestrator Workflows (combine phases)
│   ├── adw_plan_build_iso.py          # Plan --> Build
│   ├── adw_plan_build_test_iso.py     # Plan --> Build --> Test
│   ├── adw_plan_build_review_iso.py   # Plan --> Build --> Review
│   ├── adw_plan_build_test_review_iso.py  # Plan --> Build --> Test --> Review
│   ├── adw_plan_build_document_iso.py # Plan --> Build --> Document
│   ├── adw_sdlc_iso.py                # Complete SDLC
│   └── adw_sdlc_zte_iso.py            # Zero Touch Execution (auto-merge)
│
├── .claude/
│   └── commands/                      # Claude Code slash commands
│       ├── classify_issue.md          # Issue type classification
│       ├── classify_adw.md            # ADW workflow extraction
│       ├── generate_branch_name.md    # Semantic branch naming
│       ├── bug.md                     # Bug fix planning
│       ├── feature.md                 # Feature planning
│       ├── chore.md                   # Chore planning
│       ├── patch.md                   # Patch planning
│       ├── implement.md               # Plan execution
│       ├── commit.md                  # Conventional commits
│       ├── pull_request.md            # PR creation
│       ├── review.md                  # Implementation review
│       ├── document.md                # Documentation generation
│       ├── resolve_failed_test.md     # Test failure resolution
│       ├── install_worktree.md        # Worktree setup
│       ├── cleanup_worktrees.md       # Worktree cleanup
│       ├── health_check.md            # System health check
│       ├── track_agentic_kpis.md      # Performance metrics
│       ├── find_plan_file.md          # Plan file extraction
│       └── in_loop_review.md          # In-progress review
│
├── scripts/                           # Utility scripts
│   ├── expose_webhook.sh              # Cloudflare tunnel for webhooks
│   ├── refresh_webhook.sh             # Restart webhook server
│   ├── kill_trigger_webhook.sh        # Stop webhook server
│   ├── setup_worktree_env.sh          # Configure worktree .env
│   ├── purge_tree.sh                  # Clean up worktree + branch
│   ├── check_ports.sh                 # Check port availability
│   ├── clear_issue_comments.sh        # Remove issue comments
│   └── delete_pr.sh                   # Close PR + delete branch
│
├── trees/                             # Git worktrees (runtime, gitignored)
│   └── {adw_id}/                      # Isolated repo copy per workflow
│
├── agents/                            # ADW outputs (runtime, gitignored)
│   └── {adw_id}/
│       ├── adw_state.json             # Workflow state
│       └── */raw_output.jsonl         # Agent outputs
│
├── pyproject.toml                     # Python dependencies
├── .env.example                       # Configuration template
├── .gitignore                         # Ignore runtime directories
├── CLAUDE.md                          # Claude Code instructions
└── README.md                          # This file
```

---

## Porting ADW to Your Project

### Option 1: Clone Template (New Project)

```bash
# Clone the ADW template
git clone https://github.com/NicholasGrijalva/adw-infrastructure.git my-project
cd my-project

# Install dependencies
uv sync

# Configure
cp .env.example .env
claude login  # Authenticate Claude Code
gh auth login # Authenticate GitHub CLI
```

### Option 2: Add to Existing Project

```bash
# Add ADW as a remote
git remote add adw-template https://github.com/NicholasGrijalva/adw-infrastructure.git
git fetch adw-template main

# Merge ADW files (creates adws/, .claude/, scripts/)
git merge adw-template/main --allow-unrelated-histories

# Or cherry-pick specific commits
git cherry-pick <commit-hash>

# Install ADW dependencies (merge into your pyproject.toml)
uv add pydantic python-dotenv boto3 schedule fastapi uvicorn
```

### Option 3: Manual Copy

```bash
# Copy from template repo
cp -r adw-template/adws your-project/
cp -r adw-template/.claude your-project/
cp -r adw-template/scripts your-project/
cp adw-template/.env.example your-project/

# Add to your pyproject.toml:
# pydantic>=2.0.0
# python-dotenv>=1.0.0
# boto3>=1.34.0 (optional, for R2 uploads)
# schedule>=1.2.0 (optional, for cron trigger)
# fastapi>=0.109.0 (optional, for webhook server)
# uvicorn>=0.27.0 (optional, for webhook server)
```

---

## Configuration

### 1. Environment Setup

```bash
cp .env.example .env
```

### 2. Claude Authentication

```bash
claude login
# Uses OAuth tokens from ~/.claude/.credentials.json
# Works with Claude Max subscription - no API key needed
```

### 3. GitHub CLI

```bash
gh auth login
# Or set GITHUB_PAT in .env for different account
```

### 4. Verify Setup

```bash
uv run adws/health_check.py
```

---

## Webhook Setup (GitHub Integration)

This section walks you through setting up automatic ADW triggering via GitHub webhooks. When complete, creating an issue or commenting `adw_plan_build_iso` will automatically start workflows.

### Architecture Overview

```
GitHub Issue Created
        |
        v
GitHub Webhook POST --> Cloudflare Tunnel --> Local Webhook Server (port 8001)
                                                      |
                                                      v
                                              ADW Workflow Spawned
```

### Step 1: Install Cloudflared

Cloudflared creates a secure tunnel from Cloudflare's edge to your local server without opening firewall ports.

**macOS (Homebrew):**
```bash
brew install cloudflared
```

**Linux (Debian/Ubuntu):**
```bash
# Download latest release
curl -L -o cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
```

**Windows:**
```powershell
# Download from: https://github.com/cloudflare/cloudflared/releases
# Or use winget:
winget install Cloudflare.cloudflared
```

Verify installation:
```bash
cloudflared --version
```

### Step 2: Create a Cloudflare Tunnel

1. **Log in to Cloudflare Zero Trust Dashboard**
   - Go to: https://one.dash.cloudflare.com
   - Sign up for free if you don't have an account

2. **Create a Tunnel**
   - Navigate to: **Networks** > **Tunnels**
   - Click **Create a tunnel**
   - Select **Cloudflared** as connector type
   - Name your tunnel (e.g., `adw-webhook`)
   - Click **Save tunnel**

3. **Copy the Tunnel Token**
   - After creating, you'll see an install command like:
     ```
     cloudflared service install eyJhIjoiNjM...
     ```
   - Copy the token (the long string after `install`)
   - Add to your `.env` file:
     ```bash
     CLOUDFLARED_TUNNEL_TOKEN=eyJhIjoiNjM...
     ```

4. **Configure Public Hostname**
   - In the tunnel config, click **Public Hostname**
   - Add a hostname:
     - **Subdomain**: `adw-webhook` (or your choice)
     - **Domain**: Select your Cloudflare domain
     - **Service Type**: `HTTP`
     - **URL**: `localhost:8001`
   - Save the configuration
   - Note your full URL: `https://adw-webhook.yourdomain.com`

### Step 3: Configure GitHub Webhook

1. **Go to Repository Settings**
   - Navigate to your GitHub repo
   - Click **Settings** > **Webhooks** > **Add webhook**

2. **Configure Webhook**
   - **Payload URL**: `https://adw-webhook.yourdomain.com/gh-webhook`
   - **Content type**: `application/json`
   - **Secret**: Leave empty (or add for production security)
   - **SSL verification**: Enable

3. **Select Events**
   - Choose **Let me select individual events**
   - Check:
     - **Issues** (for new issue triggers)
     - **Issue comments** (for `adw_*` comment triggers)
     - **Pull requests** (for auto-closing linked issues on merge)
   - Click **Add webhook**

### Step 4: Start the Services

**Terminal 1 - Start Webhook Server:**
```bash
uv run adws/adw_triggers/trigger_webhook.py
```

You should see:
```
Starting ADW Webhook Trigger on port 8001
Starting server on http://0.0.0.0:8001
Webhook endpoint: POST /gh-webhook
Health check: GET /health
```

**Terminal 2 - Start Cloudflare Tunnel:**
```bash
./scripts/expose_webhook.sh
```

Or manually:
```bash
cloudflared tunnel run --token $CLOUDFLARED_TUNNEL_TOKEN
```

### Step 5: Test the Integration

1. **Verify Health Check:**
   ```bash
   curl https://adw-webhook.yourdomain.com/health
   ```
   Should return: `{"status": "healthy", ...}`

2. **Test with a GitHub Issue:**
   - Create a new issue with body containing: `adw_plan_build_iso`
   - Or comment `adw_plan_build_iso` on any issue
   - ADW should post a comment confirming workflow started

### Webhook Events Reference

| GitHub Event | Action | ADW Behavior |
|--------------|--------|--------------|
| `issues` | `opened` | Triggers workflow if body contains `adw_*` |
| `issue_comment` | `created` | Triggers workflow if comment contains `adw_*` |
| `pull_request` | `closed` (merged) | Auto-closes linked issues (`Closes #123`) |

### Triggering Workflows via Comments

Comment on any issue to trigger a specific workflow:

```
adw_plan_build_iso          # Plan + Build
adw_plan_build_test_iso     # Plan + Build + Test
adw_sdlc_iso                # Full SDLC pipeline
adw_sdlc_zte_iso            # Zero Touch Execution (auto-merge)
```

With existing ADW ID (for dependent workflows):
```
adw_build_iso abc12345      # Continue build in existing worktree
adw_test_iso abc12345       # Run tests in existing worktree
adw_review_iso abc12345     # Review in existing worktree
```

### Running as a Background Service (Optional)

**Using systemd (Linux):**

Create `/etc/systemd/system/adw-webhook.service`:
```ini
[Unit]
Description=ADW Webhook Server
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/your/project
ExecStart=/usr/local/bin/uv run adws/adw_triggers/trigger_webhook.py
Restart=always
Environment=PATH=/usr/local/bin:/usr/bin

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable adw-webhook
sudo systemctl start adw-webhook
```

**Using launchd (macOS):**

Create `~/Library/LaunchAgents/com.adw.webhook.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.adw.webhook</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/uv</string>
        <string>run</string>
        <string>adws/adw_triggers/trigger_webhook.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/your/project</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.adw.webhook.plist
```

### Alternative: Cron Polling (No Webhook Required)

If you can't set up webhooks, use the polling trigger instead:

```bash
uv run adws/adw_triggers/trigger_cron.py
```

This polls GitHub every 20 seconds for:
- New issues without ADW comments
- Comments containing `adw_*` triggers

---

## Usage

### Process a GitHub Issue

```bash
# Basic: Plan + Build
uv run adws/adw_plan_build_iso.py 123

# With testing
uv run adws/adw_plan_build_test_iso.py 123

# Full SDLC (plan, build, test, review, document)
uv run adws/adw_sdlc_iso.py 123

# Zero Touch Execution (auto-merge on success)
uv run adws/adw_sdlc_zte_iso.py 123
```

### Run Individual Phases

```bash
# Planning (creates worktree)
uv run adws/adw_plan_iso.py 123

# Build in existing worktree
uv run adws/adw_build_iso.py 123 abc12345

# Test
uv run adws/adw_test_iso.py 123 abc12345

# Ship (approve + merge PR)
uv run adws/adw_ship_iso.py 123 abc12345
```

### Automation

```bash
# Webhook server (instant GitHub events)
uv run adws/adw_triggers/trigger_webhook.py

# Cron polling (every 20 seconds)
uv run adws/adw_triggers/trigger_cron.py

# Expose webhook via Cloudflare tunnel
./scripts/expose_webhook.sh
```

### Cleanup

```bash
# Remove worktree and optionally delete branch
./scripts/purge_tree.sh abc12345

# List all worktrees
git worktree list

# Check port usage
./scripts/check_ports.sh
```

---

## How It Works

### 1. Issue Classification

ADW analyzes the GitHub issue and determines type:
- `/feature` - New functionality
- `/bug` - Bug fixes
- `/chore` - Maintenance, docs, refactoring

### 2. Worktree Isolation

Each workflow creates an isolated git worktree:
```
trees/abc12345/           # Complete repo copy
├── .env                  # Copied from parent
├── .ports.env            # Port configuration
└── ...                   # Full project files
```

### 3. Port Allocation

Deterministic port assignment based on ADW ID:
- Backend: 9100-9114 (15 ports)
- Frontend: 9200-9214 (15 ports)
- Enables 15 concurrent workflows

### 4. State Persistence

Workflow state tracked in `agents/{adw_id}/adw_state.json`:
```json
{
  "adw_id": "abc12345",
  "issue_number": 123,
  "branch_name": "feat-123-abc12345-add-feature",
  "plan_file": "specs/feature-plan.md",
  "issue_class": "/feature",
  "worktree_path": "/path/to/trees/abc12345",
  "backend_port": 9107,
  "frontend_port": 9207
}
```

### 5. ADW ID Tracking

8-character identifier appears everywhere:
- Issue comments: `abc12345_ops: Starting workflow`
- Branch names: `feat-123-abc12345-description`
- Commit messages: `Generated with ADW ID: abc12345`
- Log files: `agents/abc12345/`

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/classify_issue` | Determine issue type (bug/feature/chore) |
| `/classify_adw` | Extract ADW workflow from text |
| `/generate_branch_name` | Create semantic branch name |
| `/bug`, `/feature`, `/chore` | Generate implementation plans |
| `/patch` | Create targeted patch plan |
| `/implement` | Execute implementation plan |
| `/commit` | Create conventional commit |
| `/pull_request` | Create GitHub PR |
| `/review` | Review against spec + screenshots |
| `/document` | Generate feature documentation |
| `/resolve_failed_test` | Fix failing tests |
| `/install_worktree` | Setup worktree environment |
| `/cleanup_worktrees` | Remove stale worktrees |
| `/health_check` | Validate system setup |
| `/track_agentic_kpis` | Update performance metrics |

---

## Customization

### Add New Slash Commands

1. Create `.claude/commands/new_command.md`:
```markdown
# My Command

Description of what this command does.

## Variables
- $ARGUMENTS: Input from user

## Instructions
1. Step one
2. Step two

## Output
Return the result as specified.
```

2. Add to `adws/adw_modules/data_types.py`:
```python
SlashCommand = Literal[
    "/classify_issue",
    "/my_command",  # Add here
    ...
]
```

3. Add model mapping in `adws/adw_modules/agent.py`:
```python
SLASH_COMMAND_MODEL_MAP = {
    "/my_command": {"base": "sonnet", "heavy": "opus"},
    ...
}
```

### Modify Workflows

Edit the orchestrator scripts to customize phases:

```python
# adws/adw_plan_build_iso.py
def main():
    # Add custom steps
    plan_phase()
    my_custom_validation()  # Add here
    build_phase()
```

### Custom Triggers

Create new trigger in `adws/adw_triggers/`:

```python
# trigger_custom.py
from adw_modules.workflow_ops import run_workflow

def on_event(issue_number):
    run_workflow("adw_plan_build_iso", issue_number)
```

---

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `expose_webhook.sh` | Run Cloudflare tunnel for public webhook |
| `refresh_webhook.sh` | Kill + restart webhook server with health check |
| `kill_trigger_webhook.sh` | Stop webhook server process |
| `setup_worktree_env.sh` | Copy .env and set ports for worktree |
| `purge_tree.sh` | Remove worktree, kill ports, delete branch |
| `check_ports.sh` | Show ADW port usage and worktree status |
| `clear_issue_comments.sh` | Delete all comments from an issue |
| `delete_pr.sh` | Close PR and optionally delete branch |

---

## Troubleshooting

### Health Check

```bash
uv run adws/health_check.py
```

### Common Issues

**"Claude Code not found"**
```bash
which claude  # Get path
# Add to .env: CLAUDE_CODE_PATH=/path/to/claude
```

**"No worktree found"**
```bash
# Run entry point workflow first
uv run adws/adw_plan_iso.py <issue>
```

**"Port in use"**
```bash
./scripts/check_ports.sh
lsof -i :9107  # Find process
```

**"GitHub auth failed"**
```bash
gh auth status
gh auth login
```

### Debug Mode

```bash
# View agent outputs
cat agents/<adw_id>/sdlc_planner/raw_output.jsonl | tail -1 | jq .

# View state
cat agents/<adw_id>/adw_state.json | jq .

# Check worktree
git -C trees/<adw_id> status
```

---

## Requirements

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager
- [Claude Code CLI](https://claude.ai/code) - `claude login` or API key
- [GitHub CLI](https://cli.github.com/) - `gh auth login`
- Git 2.30+ (worktree support)

---

## License

MIT
