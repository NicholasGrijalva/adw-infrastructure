# ADW System - AI Developer Workflow

## Overview
ADW (AI Developer Workflow) automates software development by orchestrating Claude Code CLI to process GitHub issues through classification, planning, implementation, and pull request creation. The system uses slash commands as atomic units of work, executed programmatically via subprocess calls to maintain full context and control flow.

## Architecture

### Workflow Orchestration
The system follows a deterministic 7-step workflow orchestrated by `adw_plan_build.py`:
1. Issue fetch → 2. Classification → 3. Branch creation → 4. Planning → 5. Implementation → 6. Commits → 7. PR creation

Each step uses dedicated agents with specific slash commands, tracked by unique ADW IDs for full traceability.

### Agent Execution Model
Agents execute Claude Code CLI through subprocess calls with JSON Lines output capture, parsing structured responses to determine success/failure and extract results. The system uses a template-based request pattern where slash commands and arguments are composed into prompts.

### GitHub Integration
The `github.py` module wraps GitHub CLI (`gh`) commands for issue operations, comment posting, and repository management. Supports both default `gh auth` and custom PAT authentication.

### Data Models
Pydantic models in `data_types.py` enforce type safety across the system, defining structures for GitHub entities, agent requests/responses, and slash command literals.

## Core Components

### Main Orchestrator: adw_plan_build.py
- **Purpose**: Orchestrates complete workflow from issue to PR
- **Key Functions**:
  - `main()`: Entry point, coordinates all workflow steps (lines 358-533)
  - `classify_issue()`: Determines issue type using `/classify_issue` (lines 114-149)
  - `build_plan()`: Creates implementation plan with appropriate command (lines 151-174)
  - `implement_plan()`: Executes plan using `/implement` (lines 207-230)
  - `check_error()`: Uniform error handling across workflow (lines 321-356)
  - `git_branch()`: Creates semantic feature branches (lines 232-259)
  - `git_commit()`: Generates conventional commits (lines 261-292)
  - `pull_request()`: Creates comprehensive PRs (lines 294-319)
- **Workflow Steps**:
  1. Parse args & generate ADW ID
  2. Fetch issue from GitHub
  3. Classify as chore/bug/feature
  4. Create semantic branch
  5. Build implementation plan
  6. Execute implementation
  7. Create commits & PR
- **Error Handling**: `check_error()` pattern posts errors to issue comments and exits gracefully

### Agent Executor: agent.py
- **Purpose**: Programmatic Claude Code CLI execution with output parsing
- **Key Functions**:
  - `execute_template()`: Main entry point for slash command execution (lines 238-262)
  - `prompt_claude_code()`: Executes CLI and captures JSONL output (lines 156-236)
  - `parse_jsonl_output()`: Extracts result message from stream (lines 37-59)
  - `get_claude_env()`: Manages minimal environment for subprocess (lines 84-130)
  - `save_prompt()`: Persists prompts for debugging (lines 132-154)
  - `convert_jsonl_to_json()`: Converts output for analysis (lines 61-82)
- **Execution Model**: Subprocess with stream-json output format, always uses `--dangerously-skip-permissions`
- **Output Capture**: Saves raw JSONL and converts to JSON for analysis

### GitHub Module: github.py
- **Purpose**: GitHub API operations via `gh` CLI wrapper
- **Authentication**: Supports default `gh auth login` or custom GITHUB_PAT
- **Key Functions**:
  - `fetch_issue()`: Get issue details with full JSON structure (lines 76-121)
  - `make_issue_comment()`: Post ADW-prefixed comments (lines 123-155)
  - `fetch_open_issues()`: List all open issues for cron trigger (lines 202-238)
  - `get_repo_url()`: Extract repository from git remote (lines 52-68)
  - `extract_repo_path()`: Parse owner/repo from URL (lines 70-74)
  - `fetch_issue_comments()`: Get comment history for cron (lines 240-281)
  - `mark_issue_in_progress()`: Add labels and assignees (lines 157-201)

### Data Types: data_types.py
- **Models**:
  - `GitHubIssue`: Complete issue representation with comments
  - `GitHubUser`: Author and assignee information
  - `GitHubLabel`: Issue categorization
  - `GitHubComment`: Comment thread tracking
  - `AgentTemplateRequest`: Slash command execution request
  - `AgentPromptResponse`: Execution result with success flag
  - `IssueClassSlashCommand`: Literal type for `/chore`, `/bug`, `/feature`
  - `ClaudeCodeResultMessage`: JSONL result parsing
- **Usage**: Type safety throughout pipeline, JSON serialization for agent communication

### Utilities: utils.py
- **Functions**:
  - `make_adw_id()`: Generate 8-char UUID for workflow tracking
  - `setup_logger()`: Configure dual console/file logging
  - `get_logger()`: Retrieve existing logger by ADW ID
- **Logging Strategy**: DEBUG to file, INFO to console, structured by ADW ID

## Slash Commands

### Issue Classification: /classify_issue
- **Purpose**: Analyzes issue content to determine type
- **Input**: GitHub issue as JSON
- **Output**: `/chore`, `/bug`, `/feature`, or `0` (cannot classify)
- **Classification Rules**:
  - Chore: Documentation, refactoring, infrastructure
  - Bug: Errors, failures, performance issues
  - Feature: New capabilities, enhancements

### Planning Commands: /bug, /feature, /chore
- **Purpose**: Generate detailed implementation plans
- **Workflow**: Creates markdown plan in `specs/` directory with phases, testing strategy
- **Output**: Path to plan file (e.g., `specs/feature-name-plan.md`)
- **Plan Structure**:
  - Overview and requirements
  - Architecture impact analysis
  - Phase-based implementation
  - Testing strategy
  - Success criteria

### Implementation: /implement
- **Purpose**: Executes plan created by planning commands
- **Input**: Plan file path from `specs/`
- **Process**: Reads plan, implements systematically, creates tests
- **Guidelines**:
  - Follow existing code patterns
  - Add comprehensive tests
  - Update documentation
  - Handle edge cases

### Git Operations: /generate_branch_name, /commit
- **Purpose**: Semantic branch creation and commit generation
- **Conventions**:
  - Branch: `{type}-{number}-{adw_id}-{slug}`
  - Commit: `{type}: {description} for #{number}`
- **Examples**:
  - Branch: `feat-42-abc12345-add-video-support`
  - Commit: `feat: add video embedding for #42`

### PR Creation: /pull_request
- **Purpose**: Creates comprehensive pull request
- **Template**: Includes summary, implementation details, test commands, ADW attribution
- **PR Components**:
  - Issue linkage with `Closes #`
  - Implementation summary
  - Test commands
  - ADW attribution

### Helper Commands: /find_plan_file
- **Purpose**: Extract plan file path from planner output
- **Input**: Raw planner command output
- **Output**: Path to plan file or `0` if not found

## Trigger Mechanisms

### Webhook Trigger: trigger_webhook.py
- **Usage**: `uv run adws/trigger_webhook.py`
- **Flow**: FastAPI server receives GitHub webhooks, spawns background `adw_plan_build.py`
- **Endpoints**:
  - `/gh-webhook`: GitHub event receiver
  - `/health`: Comprehensive system health check
- **Event Processing**:
  - Issues opened → Immediate processing
  - Comment "adw" → Trigger workflow
  - Background execution with Popen
- **Response**: Returns immediately with ADW ID for tracking

### Cron Trigger: trigger_cron.py
- **Usage**: `uv run adws/trigger_cron.py`
- **Flow**: Polls GitHub every 20 seconds for new issues or "adw" comments
- **Processing**: Tracks processed issues to avoid duplicates
- **Detection Logic**:
  - New issues without comments
  - Latest comment exactly "adw"
  - Maintains comment ID tracking
- **Graceful Shutdown**: Handles SIGINT/SIGTERM cleanly

### Multi-Repository Webhook: trigger_webhook_multi.py
- **Purpose**: Handle webhooks for multiple repositories
- **Configuration**: `REPOS_BASE_DIR` for repository locations
- **Routing**: Determines repo from webhook payload
- **Execution**: Runs ADW in correct repository context

## Configuration

### Environment Variables
**Required:**
- `ANTHROPIC_API_KEY`: Claude API access
- `CLAUDE_CODE_PATH`: Path to claude CLI (default: "claude")

**Optional:**
- `GITHUB_PAT`: Custom GitHub auth (uses gh auth by default)
- `E2B_API_KEY`: Sandbox execution support
- `PORT`: Webhook server port (default: 8001)
- `REPOS_BASE_DIR`: Multi-repo base directory
- `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR`: Keep cwd (default: "true")

### ADW ID System
8-character UUIDs track workflow execution across all agents and artifacts:
- Issue comments: `{adw_id}_ops: ✅ Starting ADW workflow`
- Agent logs: `agents/{adw_id}/{agent_name}/`
- Git commits: `Generated with ADW ID: {adw_id}`
- Branch names: `feat-42-{adw_id}-description`

### Agent Logs
**Structure:**
```
agents/
└── {adw_id}/
    ├── adw_plan_build/
    │   └── execution.log
    ├── issue_classifier/
    │   ├── raw_output.jsonl
    │   ├── raw_output.json
    │   └── prompts/classify_issue.txt
    ├── sdlc_planner/
    │   ├── raw_output.jsonl
    │   ├── raw_output.json
    │   └── prompts/{command}.txt
    └── sdlc_implementor/
        ├── raw_output.jsonl
        ├── raw_output.json
        └── prompts/implement.txt
```

## Usage Patterns

### Running ADW for an Issue
```bash
cd /Users/nick/Downloads/cognosmap
uv run adws/adw_plan_build.py 123          # Process issue #123
uv run adws/adw_plan_build.py 123 custom1  # With custom ADW ID
```

### Health Check
```bash
uv run adws/health_check.py
# Verifies: env vars, git config, Claude CLI, GitHub auth
```

### Webhook Setup
1. Start server: `uv run adws/trigger_webhook.py`
2. Configure GitHub webhook to `http://server:8001/gh-webhook`
3. Select events: Issues, Issue comments
4. Optional: Use Cloudflare tunnel for public exposure

### Monitoring Active Workflows
```bash
# Find ADW ID from issue comments
tail -f agents/{adw_id}/adw_plan_build/execution.log

# View agent outputs
cat agents/{adw_id}/sdlc_planner/raw_output.json | jq .

# Check saved prompts
cat agents/{adw_id}/sdlc_planner/prompts/feature.txt
```

## Key Design Decisions

### Why Slash Commands?
Slash commands provide atomic, testable units of work with clear inputs/outputs. They enable modular workflow composition and easy customization without modifying core orchestration logic. Each command is self-contained with explicit success/failure criteria.

### Why Subprocess Execution?
Direct subprocess calls to Claude Code CLI preserve full context, enable output streaming, and maintain compatibility with CLI-specific features like permissions handling. This approach avoids API limitations and maintains consistency with manual CLI usage.

### Agent Output Parsing
JSONL stream format allows real-time monitoring while structured result messages provide clear success/failure signals with session tracking. The dual JSONL/JSON storage enables both streaming and post-processing analysis.

### Error Handling Strategy
The `check_error()` pattern ensures consistent error reporting to GitHub issues, maintaining visibility even when workflows fail mid-execution. Errors are always posted as issue comments with ADW ID prefixes for traceability.

## Common Patterns

### Agent Template Request
```python
request = AgentTemplateRequest(
    agent_name="sdlc_planner",
    slash_command="/feature",
    args=[issue.title, issue.body],
    adw_id=adw_id,
    model="sonnet"  # or "opus" for complex tasks
)
response = execute_template(request)
if not response.success:
    check_error(response, issue_number, adw_id, agent_name, "Planning failed", logger)
```

### Issue Comment Formatting
```python
# Status update
message = f"{adw_id}_ops: ✅ Starting ADW workflow"
make_issue_comment(issue_number, message)

# Error reporting
message = f"{adw_id}_{agent_name}: ❌ Error: {error_details}"
make_issue_comment(issue_number, message)
```

### Commit Message Format
```
feat: add video support for #42

Implemented video embedding with Twelve Labs integration
for multimodal content processing in knowledge graph.

Generated with ADW ID: abc12345
🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Error Checking Pattern
```python
# For functions returning (result, error) tuples
result, error = some_operation()
check_error(error, issue_number, adw_id, agent_name, "Operation failed", logger)

# For AgentPromptResponse objects
response = execute_template(request)
check_error(response, issue_number, adw_id, agent_name, "Agent failed", logger)
```

## Extension Points

### Adding New Slash Commands
1. Create `.claude/commands/new_command.md` with clear input/output spec
2. Add to `SlashCommand` literal in `data_types.py`
3. Integrate into workflow in `adw_plan_build.py`
4. Add agent name constant if needed
5. Update logging structure in `agent.py`

### Adding New Triggers
1. Create `trigger_new.py` following webhook/cron patterns
2. Call `adw_plan_build.py` with issue number and ADW ID
3. Add logging to `agents/{adw_id}/trigger_new/`
4. Handle graceful shutdown and error cases
5. Document trigger-specific configuration

### Customizing Workflow Steps
Modify `main()` in `adw_plan_build.py` to add/remove/reorder steps. Each step should:
1. Call agent with `execute_template()`
2. Check errors with `check_error()`
3. Post status to issue comments
4. Log progress with logger
5. Update workflow state as needed

### Custom Agent Names
Define agent constants at module level:
```python
AGENT_REVIEWER = "code_reviewer"
AGENT_TESTER = "test_generator"
```

## Troubleshooting

### Common Issues
- **"Claude Code CLI not installed"**: Set `CLAUDE_CODE_PATH` correctly
- **"Missing ANTHROPIC_API_KEY"**: Add to `.env` file
- **"gh not authenticated"**: Run `gh auth login` or set `GITHUB_PAT`
- **"Agent execution failed"**: Check `agents/{adw_id}/*/raw_output.json`
- **"Branch already exists"**: Delete with `git branch -D {branch}`
- **"No plan file found"**: Check planner output in logs

### Log Locations
- Execution logs: `agents/{adw_id}/adw_plan_build/execution.log`
- Agent outputs: `agents/{adw_id}/{agent_name}/raw_output.json`
- Saved prompts: `agents/{adw_id}/{agent_name}/prompts/`
- JSONL streams: `agents/{adw_id}/{agent_name}/raw_output.jsonl`

### Debug Mode
View detailed execution:
```bash
# Real-time monitoring
tail -f agents/{adw_id}/*/execution.log

# Parse agent output
cat agents/{adw_id}/*/raw_output.json | jq '.[-1].result'

# Check prompts sent
cat agents/{adw_id}/*/prompts/*.txt

# View JSONL stream
cat agents/{adw_id}/*/raw_output.jsonl | while read line; do echo $line | jq .; done
```

### Recovery Procedures
**Stuck workflow:**
1. Find ADW ID from issue comments
2. Check last successful step in logs
3. Manually run remaining steps with same ADW ID
4. Update issue with completion status

**Failed implementation:**
1. Review plan in `specs/`
2. Check implementation output
3. Fix issues manually
4. Commit with ADW attribution
5. Create PR referencing issue

## API Integration Examples

### Direct Agent Execution
```python
from adws.agent import execute_template
from adws.data_types import AgentTemplateRequest

# Classify an issue programmatically
request = AgentTemplateRequest(
    agent_name="issue_classifier",
    slash_command="/classify_issue",
    args=[issue_json],
    adw_id="test123",
    model="sonnet"
)
response = execute_template(request)
issue_type = response.output.strip()  # "/feature", "/bug", or "/chore"
```

### Custom Workflow Integration
```python
from adws.github import fetch_issue, make_issue_comment
from adws.utils import make_adw_id

# Custom workflow step
adw_id = make_adw_id()
issue = fetch_issue("42", "owner/repo")
make_issue_comment("42", f"{adw_id}_custom: Starting custom workflow")
# ... custom logic ...
```

### Webhook Integration
```python
from fastapi import FastAPI, Request
import subprocess

app = FastAPI()

@app.post("/custom-webhook")
async def custom_handler(request: Request):
    payload = await request.json()
    issue_number = payload["issue"]["number"]

    # Trigger ADW in background
    subprocess.Popen([
        "uv", "run", "adws/adw_plan_build.py",
        str(issue_number)
    ])

    return {"status": "accepted"}
```

## Critical Code Sections

### CRITICAL PARTIAL READS (Essential Implementation Sections)

1. **Main Workflow Orchestration** - [`adws/adw_plan_build.py:358-533`](/Users/nick/Downloads/cognosmap/adws/adw_plan_build.py)
   - **Critical for**: Understanding complete ADW workflow from issue → PR
   - **Read**: Lines 358-533 (main() function with all 7 workflow steps)

2. **Agent Template Execution** - [`adws/agent.py:238-262`](/Users/nick/Downloads/cognosmap/adws/agent.py)
   - **Critical for**: How slash commands are composed and executed
   - **Read**: Lines 238-262 (execute_template function)

3. **Claude Code Subprocess Call** - [`adws/agent.py:156-236`](/Users/nick/Downloads/cognosmap/adws/agent.py)
   - **Critical for**: Understanding CLI invocation and output capture
   - **Read**: Lines 156-236 (prompt_claude_code function with env setup)

4. **Error Handling Pattern** - [`adws/adw_plan_build.py:321-356`](/Users/nick/Downloads/cognosmap/adws/adw_plan_build.py)
   - **Critical for**: Consistent error reporting across workflow
   - **Read**: Lines 321-356 (check_error function with type handling)

5. **Issue Classification Logic** - [`adws/adw_plan_build.py:114-149`](/Users/nick/Downloads/cognosmap/adws/adw_plan_build.py)
   - **Critical for**: How issues are routed to planning commands
   - **Read**: Lines 114-149 (classify_issue with validation)

6. **GitHub Issue Fetching** - [`adws/github.py:76-121`](/Users/nick/Downloads/cognosmap/adws/github.py)
   - **Critical for**: GitHub CLI integration for issue data
   - **Read**: Lines 76-121 (fetch_issue with JSON parsing)

7. **Webhook Event Processing** - [`adws/trigger_webhook.py:40-123`](/Users/nick/Downloads/cognosmap/adws/trigger_webhook.py)
   - **Critical for**: How GitHub events trigger ADW workflows
   - **Read**: Lines 40-123 (github_webhook endpoint with Popen)

8. **Cron Issue Detection** - [`adws/trigger_cron.py:64-92`](/Users/nick/Downloads/cognosmap/adws/trigger_cron.py)
   - **Critical for**: Logic for detecting processable issues
   - **Read**: Lines 64-92 (should_process_issue with comment tracking)

9. **JSONL Output Parsing** - [`adws/agent.py:37-59`](/Users/nick/Downloads/cognosmap/adws/agent.py)
   - **Critical for**: Extracting results from Claude Code output
   - **Read**: Lines 37-59 (parse_jsonl_output with result extraction)

10. **Environment Configuration** - [`adws/agent.py:84-130`](/Users/nick/Downloads/cognosmap/adws/agent.py)
    - **Critical for**: Subprocess environment setup for auth
    - **Read**: Lines 84-130 (get_claude_env with token handling)

11. **Health Check System** - [`adws/health_check.py:256-309`](/Users/nick/Downloads/cognosmap/adws/health_check.py)
    - **Critical for**: System validation and diagnostics
    - **Read**: Lines 256-309 (run_health_check comprehensive checks)

12. **Logger Setup** - [`adws/utils.py:15-68`](/Users/nick/Downloads/cognosmap/adws/utils.py)
    - **Critical for**: Dual logging strategy implementation
    - **Read**: Lines 15-68 (setup_logger with file/console handlers)

## Performance Considerations

### Subprocess Overhead
Each agent call spawns a new Claude Code process, adding ~2-3 seconds overhead. For complex workflows, consider batching operations within single slash commands.

### API Rate Limits
- GitHub API: 5000 requests/hour authenticated
- Anthropic: Tier-based limits
- Mitigation: Implement exponential backoff, cache issue data

### Log Management
Agent logs accumulate quickly. Implement rotation or cleanup:
```bash
# Clean logs older than 7 days
find agents/ -name "*.log" -mtime +7 -delete
```

## Security Considerations

### Token Management
- Store tokens in `.env`, never commit
- Use GitHub fine-grained PATs with minimal scope
- Rotate tokens regularly
- Monitor token usage in GitHub settings

### Command Injection
All user input is passed through Pydantic models and slash command templates, preventing direct shell execution. The system never uses `shell=True` in subprocess calls.

### Webhook Validation
Production deployments should validate GitHub webhook signatures to prevent unauthorized triggers.

## Summary

ADW transforms GitHub issues into pull requests through a sophisticated orchestration layer built on Claude Code CLI. The system's strength lies in its modular slash command architecture, allowing easy customization of planning and implementation strategies while maintaining a robust, traceable workflow. By using subprocess execution with structured output parsing, ADW maintains full control over the development process while leveraging Claude's capabilities for code generation and problem-solving.

The key innovation is treating slash commands as composable units of work that can be chained together programmatically, with each command having clear contracts for input and output. This enables ADW to adapt to different development workflows by simply modifying the slash command implementations without touching the core orchestration logic. The comprehensive logging and ADW ID system ensures every action is traceable from issue to PR, providing transparency and debuggability throughout the automated development process.

For AI agents working with ADW, the most critical understanding is the flow from `AgentTemplateRequest` → `execute_template()` → subprocess → JSONL parsing → `AgentPromptResponse`, combined with the error handling pattern that ensures failures are visible and debuggable. The slash command abstraction allows infinite extensibility while the orchestrator provides the robust execution framework.