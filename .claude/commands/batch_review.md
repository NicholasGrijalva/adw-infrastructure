---
description: Review multiple PRs in batch
argument-hint: pr_number1 pr_number2 ...
allowed-tools: Bash(uv run adws/adw_batch_review_iso.py:*)
model: sonnet
---

# /batch_review - Batch PR Review Orchestrator

Review multiple ADW-generated pull requests in parallel and display aggregated results.

This command wraps the `adw_batch_review_iso.py` orchestrator script, providing a user-friendly interface for triggering batch reviews directly from Claude Code sessions.

## Variables

- **PR Numbers**: $ARGUMENTS (space-separated list of PR numbers to review)

## Step 1: Parse and Validate Arguments

Extract PR numbers from $ARGUMENTS:

1. Split $ARGUMENTS by whitespace to get individual PR numbers
2. Validate each argument is a positive integer
3. Remove duplicates if any
4. If no arguments provided or all invalid, display usage help and exit

**Validation Rules**:
- Each argument must be a valid integer
- PR numbers must be positive (> 0)
- At least one valid PR number required

**Error Handling**:
```
Invalid input: /batch_review abc 123
Error: Invalid PR number 'abc'. All arguments must be positive integers.

Usage: /batch_review <pr_number1> [pr_number2] [pr_number3] ...
Example: /batch_review 385 386 387
```

## Step 2: Execute Batch Review Orchestrator

Run the orchestrator script with validated PR numbers:

```bash
uv run adws/adw_batch_review_iso.py <pr_numbers> --concurrent 3 --mode lightweight --no-auto-merge
```

**Command Components**:
- `<pr_numbers>`: Space-separated list of validated PR numbers
- `--concurrent 3`: Process up to 3 PRs in parallel (balances throughput and resource usage)
- `--mode lightweight`: Skip screenshot generation for faster reviews
- `--no-auto-merge`: Do NOT auto-merge ACCEPT results (user must manually merge)

**Example**:
```bash
uv run adws/adw_batch_review_iso.py 385 386 387 --concurrent 3 --mode lightweight --no-auto-merge
```

**Timeout**: Set subprocess timeout to 10 minutes (600 seconds) to allow for multiple PR reviews

## Step 3: Parse Orchestrator Output

The orchestrator prints a summary table to stdout in this format:

```
============================================================
Batch Review Complete
============================================================
Total PRs:      3
Completed:      3
Auto-merged:    2 - [385, 387]
Needs review:   1 - [386]
Failed:         0 - []
============================================================
```

Extract the following fields from the output:
- **Total PRs**: Total number of PRs in the batch
- **Completed**: Number of successfully reviewed PRs
- **Auto-merged**: List of PR numbers with ACCEPT decision
- **Needs review**: List of PR numbers with DENY decision
- **Failed**: List of PR numbers where review crashed or errored

**Note**: Even with `--no-auto-merge` flag, PRs that pass all gates will appear in "Auto-merged" category (this is the orchestrator's terminology for ACCEPT decisions, not actual merge status).

## Step 4: Format and Display Results

Present results in a clear, actionable format:

### Success Output Format

```markdown
## Batch Review Results

**Summary**
- Total PRs: 3
- Completed: 3
- Ready to merge (ACCEPT): 2
- Needs attention (DENY): 1
- Failed: 0

**Ready to Merge** ✓
PRs that passed all review gates:
- #385
- #387

**Needs Attention** ✗
PRs that failed one or more gates:
- #386

**Next Steps**
- Review DENY details: Run `/review_for_merge <pr_number>` for specific gate failures
- Merge approved PRs: Use `gh pr merge <pr_number> --squash` or merge via GitHub UI
- Fix failures: Address gate failures and re-run `/batch_review` after fixes
```

### Failure Output Format

If orchestrator fails or returns non-zero exit code:

```markdown
## Batch Review Failed

**Error**: <error_message_from_stderr>

**Troubleshooting**:
1. Verify PR numbers exist: `gh pr view <pr_number>`
2. Check orchestrator logs in worktree directories
3. Ensure dependencies are installed: `uv sync`
4. Manually run: `uv run adws/adw_batch_review_iso.py <pr_numbers>`
```

## Step 5: Provide Actionable Guidance

Based on results, provide context-specific next steps:

**If all PRs ACCEPT**:
```
All PRs passed review! Ready to merge:
- gh pr merge 385 --squash
- gh pr merge 387 --squash
```

**If some PRs DENY**:
```
Some PRs need fixes. Review gate failures:
- /review_for_merge 386

Common gate failures:
- tests_resolved: Run tests and fix failures
- blockers_resolved: Remove TODO/FIXME comments
- acceptance_criteria_met: Complete missing requirements
- no_security_concerns: Fix security anti-patterns
```

**If PRs failed to review**:
```
Review process crashed for some PRs. Check:
- Worktree isolation errors (ensure ADW ID is valid)
- Test infrastructure failures (pytest, npm)
- Missing dependencies or configuration
```

## Usage Examples

**Example 1: Review single PR**
```bash
/batch_review 385
```

**Example 2: Review multiple PRs**
```bash
/batch_review 385 386 387 390 395
```

**Example 3: Review after fixes**
```bash
# After addressing gate failures on PR 386
/batch_review 386
```

## Error Scenarios

### Invalid Arguments
```
Input: /batch_review
Output: Error - No PR numbers provided. Usage: /batch_review <pr_number1> [pr_number2] ...

Input: /batch_review abc xyz
Output: Error - Invalid PR numbers: 'abc', 'xyz'. All arguments must be positive integers.

Input: /batch_review 123 abc 456
Output: Error - Invalid PR number 'abc'. Valid PRs: 123, 456
```

### Orchestrator Not Found
```
Error: Orchestrator script not found at adws/adw_batch_review_iso.py
Check: Ensure you're in the project root directory
```

### Non-existent PRs
```
PRs that don't exist will appear in the "Failed" category:
- Failed: 1 - [999]

This is expected behavior - orchestrator handles missing PRs gracefully.
```

## Integration Notes

This command is designed for:
- **Interactive use**: Quick batch reviews during development
- **Pre-merge validation**: Check multiple ADW PRs before merging
- **Workflow automation**: Can be called programmatically if needed

**Important**:
- This command does NOT auto-merge PRs (uses `--no-auto-merge` flag)
- Users must manually merge ACCEPT results via GitHub UI or `gh pr merge`
- For auto-merge behavior, use the orchestrator script directly without the flag
- All review logic lives in `adw_batch_review_iso.py` - this is just a UI wrapper

## Related Commands

- `/review_for_merge <pr> <issue> <test_status>` - Detailed single PR review with gate breakdown
- `/ship <pr>` - Merge and cleanup PR after review (future)
- `/test` - Run validation test suite before review

## Technical Details

**Subprocess Execution**:
- Uses `uv run` to ensure correct Python environment
- Captures stdout for parsing results
- Captures stderr for error diagnostics
- Returns orchestrator exit code (0 = success, 1 = failures present)

**Concurrency**:
- Default 3 concurrent reviews balances speed and resource usage
- Orchestrator handles isolation via worktrees
- Each review runs in its own isolated environment

**Review Mode**:
- Lightweight mode skips screenshot generation (faster)
- Full mode includes visual validation (slower, use for UI changes)
- This command defaults to lightweight for speed
