# ADW Infrastructure - Claude Code Configuration

This project contains the ADW (AI Developer Workflow) infrastructure for automating GitHub issue-to-PR pipelines.

## ADW Overview

ADW transforms GitHub issues into pull requests through automated orchestration:
1. **Issue Classification**: Analyzes issue content to determine type (bug/feature/chore)
2. **Planning**: Generates implementation plans in `specs/` directory
3. **Implementation**: Executes plans using Claude Code CLI
4. **Git Operations**: Creates branches, commits, and pull requests

## Running ADW

### Process an Issue
```bash
# Process issue #123
uv run adws/adw_plan_build.py 123

# With custom ADW ID for tracking
uv run adws/adw_plan_build.py 123 custom-id
```

### Health Check
```bash
uv run adws/health_check.py
```

### Webhook Server
```bash
uv run adws/adw_triggers/trigger_webhook.py
```

## Slash Commands

ADW uses these slash commands (in `.claude/commands/`):

| Command | Purpose |
|---------|---------|
| `/classify_issue` | Determine issue type |
| `/bug`, `/feature`, `/chore` | Generate plans |
| `/implement` | Execute plans |
| `/commit` | Create commits |
| `/pull_request` | Create PRs |
| `/review` | Review against spec |

## ADW ID Tracking

Every workflow is tracked by an 8-character ADW ID:
- Issue comments: `{adw_id}_ops: message`
- Branch names: `feat-42-{adw_id}-description`
- Logs: `agents/{adw_id}/`

## Customization

### Add New Slash Commands
1. Create `.claude/commands/new_command.md`
2. Add to `SlashCommand` literal in `adws/adw_modules/data_types.py`
3. Integrate into `adws/adw_plan_build.py`

### Modify Workflow
Edit `adws/adw_plan_build.py` to customize:
- Classification logic
- Planning steps
- PR templates

## Directory Structure

```
adws/                          # Core ADW modules
├── adw_plan_build.py          # Main orchestrator
├── adw_modules/               # Reusable utilities
│   ├── agent.py               # Claude Code execution
│   ├── github.py              # GitHub CLI wrapper
│   └── ...
└── adw_triggers/              # Trigger mechanisms
    ├── trigger_webhook.py     # GitHub webhooks
    └── trigger_cron.py        # Polling trigger

.claude/commands/              # Slash commands
specs/                         # Generated plans go here
agents/                        # Execution logs
```

## Requirements

- Python 3.11+
- Claude Code CLI (`claude`)
- GitHub CLI (`gh`)
- uv package manager
