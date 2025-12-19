# ADW Infrastructure

**AI Developer Workflow** - Automated GitHub issue to pull request pipeline using Claude Code CLI.

ADW transforms GitHub issues into pull requests through an orchestrated workflow:
1. Issue classification (bug/feature/chore)
2. Planning (generates implementation plan in `specs/`)
3. Implementation (executes plan using Claude Code)
4. Git operations (branch, commit, PR creation)

## Quick Start

### Prerequisites

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager
- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated

### Installation

```bash
# Clone this template into your project
git clone https://github.com/your-org/adw-infrastructure.git adws-template

# Copy ADW files to your project
cp -r adws-template/adws your-project/
cp -r adws-template/.claude your-project/
cp adws-template/pyproject.toml your-project/  # or merge dependencies

# Install dependencies
cd your-project
uv sync
```

### Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Authenticate Claude Code (choose one):
   ```bash
   # Option A: Claude Max subscription (recommended - no API key needed)
   claude login

   # Option B: Direct API key (set in .env)
   # ANTHROPIC_API_KEY=your_key_here
   ```

3. Ensure `gh` is authenticated:
   ```bash
   gh auth login
   ```

### Usage

#### Process a GitHub Issue

```bash
# Process issue #123
uv run adws/adw_plan_build.py 123

# Process with custom ADW ID
uv run adws/adw_plan_build.py 123 my-adw-id
```

#### Health Check

```bash
uv run adws/health_check.py
```

#### Webhook Server (for GitHub webhooks)

```bash
uv run adws/adw_triggers/trigger_webhook.py
```

#### Cron Trigger (polls for new issues)

```bash
uv run adws/adw_triggers/trigger_cron.py
```

## Architecture

```
adws/
├── adw_plan_build.py          # Main orchestrator (issue -> PR)
├── adw_modules/
│   ├── agent.py               # Claude Code CLI execution
│   ├── data_types.py          # Pydantic models
│   ├── git_ops.py             # Git operations
│   ├── github.py              # GitHub CLI wrapper
│   ├── worktree_ops.py        # Git worktree management
│   └── ...
├── adw_triggers/
│   ├── trigger_webhook.py     # FastAPI webhook server
│   └── trigger_cron.py        # Polling trigger
└── adw_tests/                 # Test suite

.claude/commands/              # Slash commands for Claude Code
├── classify_issue.md          # Issue type classification
├── bug.md, feature.md, chore.md  # Planning commands
├── implement.md               # Implementation execution
├── commit.md, pull_request.md # Git operations
└── ...
```

## Slash Commands

ADW uses Claude Code slash commands as atomic workflow units:

| Command | Purpose |
|---------|---------|
| `/classify_issue` | Determine issue type (bug/feature/chore) |
| `/bug`, `/feature`, `/chore` | Generate implementation plans |
| `/implement` | Execute implementation plan |
| `/commit` | Create conventional commit |
| `/pull_request` | Create GitHub PR |
| `/review` | Review implementation against spec |

## Customization

### Adding New Slash Commands

1. Create `.claude/commands/new_command.md` with input/output spec
2. Add to `SlashCommand` literal in `adws/adw_modules/data_types.py`
3. Integrate into workflow in `adws/adw_plan_build.py`

### Custom Workflows

Modify `adws/adw_plan_build.py` to customize the workflow:
- Add/remove steps
- Change classification logic
- Customize PR templates

## ADW ID System

Each workflow execution is tracked by an 8-character ADW ID:
- Issue comments: `{adw_id}_ops: Starting workflow`
- Branch names: `feat-42-{adw_id}-description`
- Agent logs: `agents/{adw_id}/`

## Logs

Execution artifacts are stored in `agents/{adw_id}/`:
```
agents/
└── abc12345/
    ├── adw_plan_build/execution.log
    ├── sdlc_planner/
    │   ├── raw_output.jsonl
    │   └── prompts/feature.txt
    └── sdlc_implementor/
        └── raw_output.json
```

## License

MIT
