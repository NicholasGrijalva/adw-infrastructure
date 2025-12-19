# ADW Workflow Extraction

Extract ADW workflow information from the text below and return a JSON response.

## Instructions

- Look for ADW workflow commands in the text (e.g., `/adw_plan_iso`, `/adw_build_iso`, `/adw_test_iso`, `/adw_review_iso`, `/adw_document_iso`, `/adw_patch_iso`, `/adw_plan_build_iso`, `/adw_plan_build_test_iso`, `/adw_plan_build_test_review_iso`, `/adw_sdlc_iso`, `/adw_sdlc_ZTE_iso`)
- Also recognize commands without the `_iso` suffix and automatically add it (e.g., `/adw_plan` → `/adw_plan_iso`)
- Also recognize variations like `adw_plan_build`, `adw plan build`, `/adw plan then build`, etc. and map to the correct command
- Look for ADW IDs (8-character alphanumeric strings, often after "adw_id:" or "ADW ID:" or similar)
- Look for model set specification: "model_set base" or "model_set heavy" (case insensitive)
  - Default to "base" if no model_set is specified
  - Also recognize variations like "model set: heavy", "modelset heavy", etc.
- Return a JSON object with the extracted information
- If no ADW workflow is found, return empty JSON: `{}`
- IMPORTANT: DO NOT RUN the `adw_sdlc_ZTE_iso` workflows unless `ZTE` is EXPLICITLY uppercased. This is a dangerous workflow and it needs to be absolutely clear when we're running it. If zte is not capitalized, then run the non zte version `/adw_sdlc_iso`.

## Valid ADW Commands

### Non-Isolated Workflows (runs in main repo)
- `/adw_plan_build` - Simple Plan + Build in main repository (faster, no isolation)

### Isolated Workflows (runs in separate git worktrees with full isolation)
- `/adw_plan_iso` - Planning only
- `/adw_build_iso` - Building only (requires adw_id)
- `/adw_test_iso` - Testing only (requires adw_id)
- `/adw_review_iso` - Review only (requires adw_id)
- `/adw_document_iso` - Documentation only (requires adw_id)
- `/adw_ship_iso` - Ship/approve and merge PR (requires adw_id)
- `/adw_patch_iso` - Direct patch from issue
- `/adw_plan_build_iso` - Plan + Build (isolated)
- `/adw_plan_build_test_iso` - Plan + Build + Test
- `/adw_plan_build_review_iso` - Plan + Build + Review (skips test)
- `/adw_plan_build_document_iso` - Plan + Build + Document (skips test and review)
- `/adw_plan_build_test_review_iso` - Plan + Build + Test + Review
- `/adw_sdlc_iso` - Complete SDLC: Plan + Build + Test + Review + Document
- `/adw_sdlc_ZTE_iso` - Zero Touch Execution: Complete SDLC + auto-merge to production. DANGEROUS: Only runs if 'ZTE' is EXPLICITLY uppercased in the request.

### Default Behavior
- If a user specifies an exact workflow name (e.g., `/adw_plan_build`), use that exact workflow
- If a user provides a natural language description without `_iso` suffix (e.g., "adw plan build"), default to the isolated version (`/adw_plan_build_iso`)
- Isolated versions are preferred by default as they provide more features and safety

## Response Format

Respond ONLY with a JSON object in this format:
```json
{
  "adw_slash_command": "/adw_plan",
  "adw_id": "abc12345",
  "model_set": "base"
}
```

Fields:
- `adw_slash_command`: The ADW command found (include the slash)
- `adw_id`: The 8-character ADW ID if found
- `model_set`: The model set to use ("base" or "heavy"), defaults to "base" if not specified

If only some fields are found, include only those fields.
If nothing is found, return: `{}`
IMPORTANT: Always include `model_set` with value "base" if no model_set is explicitly mentioned in the text.

## Text to Analyze

$ARGUMENTS