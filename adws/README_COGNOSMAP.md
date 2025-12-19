# ADW System for Cognosmap

AI Developer Workflow (ADW) embedded in cognosmap for automated issue processing.

## Quick Start

### Process an Issue Manually

```bash
cd /Users/nick/Downloads/cognosmap
uv run adws/adw_plan_build.py {issue_number}
```

Example:
```bash
# Process issue #6
uv run adws/adw_plan_build.py 6
```

This will:
1. Classify the issue (chore/bug/feature)
2. Create a feature branch
3. Generate an implementation plan in `specs/`
4. Implement the solution
5. Create commits
6. Open a pull request

### Monitor Progress

ADW creates detailed logs in the `agents/` directory:

```bash
# Find the ADW ID from the issue comments (e.g., abc12345)
# Then view logs:
tail -f agents/abc12345/sdlc_planner/execution.log
tail -f agents/abc12345/sdlc_implementor/execution.log
```

View all agent output:
```bash
cat agents/abc12345/sdlc_planner/raw_output.json | jq .
```

## Webhook Server (Optional)

### Start the Webhook Server

```bash
cd /Users/nick/Downloads/cognosmap
uv run adws/trigger_webhook.py
```

The server will listen on `http://localhost:8001` by default.

### Expose via Cloudflare Tunnel

In a separate terminal:
```bash
cloudflared tunnel run adw-webhook-multi
```

This exposes the webhook at: `https://adw.cognos-adw.com/gh-webhook`

### Configure GitHub Webhook

1. Go to: https://github.com/NicholasGrijalva/cognosmap/settings/hooks
2. Click "Add webhook"
3. Configure:
   - **Payload URL**: `https://adw.cognos-adw.com/gh-webhook`
   - **Content type**: `application/json`
   - **Events**: Select "Issues" and "Issue comments"
   - **Active**: ✓
4. Save

Now ADW will automatically process:
- New issues when they're opened
- Existing issues when someone comments "adw"

## How It Works

### Workflow Steps

1. **Classification** (`/classify_issue`)
   - Analyzes issue content
   - Returns `/chore`, `/bug`, or `/feature`

2. **Branch Creation** (`/generate_branch_name`)
   - Creates semantic branch: `feat-{number}-{adw_id}-{description}`
   - Example: `feat-6-abc12345-test-adw-system`

3. **Planning** (uses `/chore`, `/bug`, or `/feature`)
   - Generates implementation plan in `specs/`
   - Plan includes architecture analysis and step-by-step implementation

4. **Implementation** (`/implement`)
   - Executes the plan
   - Modifies code, creates tests
   - Follows cognosmap architecture patterns

5. **Commit & PR** (`/commit`, `/pull_request`)
   - Creates semantic commits with ADW attribution
   - Opens PR linking back to original issue

### Slash Commands

All commands are in `.claude/commands/`:
- `/classify_issue.md` - Issue classifier
- `/chore.md` - Maintenance task planner
- `/bug.md` - Bug fix planner
- `/feature.md` - Feature implementation planner
- `/implement.md` - Plan executor
- `/find_plan_file.md` - Plan path extractor
- `/generate_branch_name.md` - Branch name generator
- `/commit.md` - Commit creator
- `/pull_request.md` - PR creator

You can customize these commands to change how ADW behaves for cognosmap.

## Environment Variables

Required variables (already configured in `.env`):
- `ANTHROPIC_API_KEY` - For Claude Code execution
- `GITHUB_PAT` - For GitHub API access
- `CLAUDE_CODE_PATH` - Path to claude CLI
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` - Keep working directory

Optional:
- `CLOUDFLARED_TUNNEL_TOKEN` - For webhook exposure
- `E2B_API_KEY` - For sandboxed execution

## Testing ADW

### Manual Test

```bash
# Create test issue
gh issue create --title "Test ADW" --body "Testing automated workflow"

# Note the issue number (e.g., #6)

# Process it
cd /Users/nick/Downloads/cognosmap
uv run adws/adw_plan_build.py 6

# Watch it work (new terminal)
# Find ADW ID from issue comments
tail -f agents/{adw_id}/*/execution.log
```

### Health Check

```bash
cd /Users/nick/Downloads/cognosmap
uv run adws/health_check.py
```

This verifies:
- Environment variables are set
- Git repository is configured
- Claude Code CLI is working
- GitHub CLI is authenticated

## Customization

### Modify Planning Behavior

Edit `.claude/commands/feature.md` (or bug.md/chore.md) to change:
- Plan structure
- Implementation approach
- Testing requirements
- Documentation standards

### Modify Implementation Behavior

Edit `.claude/commands/implement.md` to change:
- Code style enforcement
- Testing strategy
- Documentation requirements

### Change Model

In `adws/data_types.py`, line 109:
```python
model: Literal["sonnet", "opus"] = "opus"  # Change default here
```

Or in `adws/adw_plan_build.py`, modify specific agent model usage.

## Troubleshooting

### "Claude Code CLI is not installed"
```bash
# Verify claude is accessible
which claude

# Update .env if needed
CLAUDE_CODE_PATH=/path/to/claude
```

### "Missing ANTHROPIC_API_KEY"
Check `.env` file has valid API key.

### "GitHub CLI not authenticated"
```bash
gh auth login
# Or set GITHUB_PAT in .env
```

### Workflow Fails Mid-Execution

Check agent logs:
```bash
cd agents/{adw_id}
cat sdlc_planner/raw_output.json | jq .
cat sdlc_implementor/raw_output.json | jq .
```

Look for error messages in the last entries.

### Branch Already Exists

If you re-run ADW on the same issue:
```bash
git branch -D {old_branch_name}
git push origin --delete {old_branch_name}
```

Then run ADW again with a new ADW ID:
```bash
uv run adws/adw_plan_build.py {issue_number} {custom_adw_id}
```

## Directory Structure

```
cognosmap/
├── adws/                          # ADW system (embedded)
│   ├── adw_plan_build.py         # Main workflow orchestrator
│   ├── agent.py                  # Claude Code integration
│   ├── github.py                 # GitHub operations
│   ├── data_types.py             # Type definitions
│   └── trigger_webhook.py        # Webhook server
├── .claude/
│   └── commands/                 # Slash commands (customizable)
│       ├── classify_issue.md
│       ├── chore.md
│       ├── bug.md
│       ├── feature.md
│       ├── implement.md
│       ├── find_plan_file.md
│       ├── generate_branch_name.md
│       ├── commit.md
│       └── pull_request.md
├── agents/                       # Execution logs per ADW run
│   └── {adw_id}/
│       ├── issue_classifier/
│       ├── sdlc_planner/
│       └── sdlc_implementor/
└── specs/                        # Implementation plans (generated)
    └── {plan-name}-plan.md
```

## Advanced Usage

### Run Specific Agents Only

```python
from adws.agent import execute_template
from adws.data_types import AgentTemplateRequest

# Just classify an issue
request = AgentTemplateRequest(
    agent_name="issue_classifier",
    slash_command="/classify_issue",
    args=[issue_json],
    adw_id="test123",
    model="sonnet"
)
response = execute_template(request)
print(response.output)  # /feature, /bug, or /chore
```

### Continuous Monitoring (Cron)

```bash
# Polls GitHub every 20 seconds for new issues
cd /Users/nick/Downloads/cognosmap
uv run adws/trigger_cron.py
```

Processes issues when:
- New issue has no comments
- Latest comment is exactly "adw"

## Best Practices

1. **Review plans before implementation**: ADW creates plans in `specs/` - review them before letting it implement
2. **Test incrementally**: Start with small chores/bugs to validate behavior
3. **Customize commands**: Tailor slash commands to cognosmap's specific needs
4. **Monitor logs**: Keep an eye on agent logs during execution
5. **Manual review**: Always review PRs before merging, even from ADW

## Next Steps

1. ✅ ADW is now embedded in cognosmap
2. ✅ All slash commands created and customized
3. ✅ Environment configured
4. ⏭️ Test with issue #6: `uv run adws/adw_plan_build.py 6`
5. ⏭️ Review generated plan and PR
6. ⏭️ Set up webhook (optional)
7. ⏭️ Process real issues as needed
