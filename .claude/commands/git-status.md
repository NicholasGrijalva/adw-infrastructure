---
description: Check status of open PRs, issues, and ADW agents. Primer on git + ADW operations.
arguments:
  - name: target
    description: Optional issue/PR number to focus on (e.g., "121" or "pr:139")
    required: false
---

# Git + ADW Operations Status

## Quick Reference

### Viewing Issues & PRs
```bash
# List open issues
gh issue list --state open --limit 30

# View specific issue
gh issue view <number>

# View issue with comments (ADW logs)
gh issue view <number> --comments

# List open PRs
gh pr list --state open

# View PR details
gh pr view <number>

# View PR diff
gh pr diff <number>
```

### Triggering ADW SDLC
```bash
# Trigger full SDLC cycle on an issue
gh issue comment <number> --body "adw_sdlc_iso"
```

ADW SDLC phases: `plan_iso` -> `build_iso` -> `test_iso` -> `review_iso` -> `document_iso`

### PRD Locations
- **SAGA Pipeline**: `specs/architecture/PRD_v2.1_event_pipeline.md`
- **SAGA Tests**: `specs/architecture/PRD_v2.1.3_test_infrastructure_addendum.md`
- **LLM Frontend**: `specs/architecture/PRD_LLM_frontend.md`
- **v5 Orchestration**: `specs/architecture/PRD_v5_llm_orchestration_architecture.md`

### Worktree Operations
```bash
# List worktrees
git worktree list

# Check worktree status
git -C trees/<adw_id> status --short

# View worktree commits
git -C trees/<adw_id> log --oneline -5
```

### Merging PRs
Use `/merge_purge_PR <pr_number>` to merge and cleanup worktree.

---

## Task

{{#if target}}
Focus on target: **{{target}}**

1. If target starts with "pr:", view that PR with `gh pr view`
2. Otherwise, view the issue with `gh issue view --comments`
3. Check for ADW status in comments
4. If it's a worktree, check `trees/<adw_id>/` status
{{else}}
Provide a comprehensive status report:

1. **Open PRs**: Run `gh pr list --state open` and summarize
2. **Open Issues**: Run `gh issue list --state open --limit 30` and categorize by:
   - SAGA pipeline issues
   - PRD-v5 / Frontend issues
   - Infrastructure / Other
3. **Active ADW Agents**: Check recent issue comments for `[ADW-AGENTS]` activity
4. **Dependency Analysis**: Note which issues are blocked vs ready to start
{{/if}}

Present findings in a clear, tabular format.
