# /find_plan_file - Extract Plan File Path

## Purpose
Parse the output from a planning command (/chore, /bug, or /feature) and extract the path to the generated plan file.

## Input
You will receive the raw output text from a planning command, which should contain a file path to the plan that was created.

## Your Task
1. **Parse the output text** to find the plan file path
2. **Validate the path** looks correct (should be in specs/ directory)
3. **Return ONLY the file path**, nothing else

## Expected Path Patterns
Plans should be in the `specs/` directory with these patterns:
- `specs/{descriptive-name}-plan.md` (for chores)
- `specs/fix-{descriptive-name}-plan.md` (for bugs)
- `specs/{feature-name}-plan.md` (for features)

## Output Format

**If a valid plan file path is found:**
Return ONLY the path:
```
specs/{plan-name}-plan.md
```

**If no plan file path is found:**
Return:
```
0
```

## Examples

**Input text contains:**
"Created implementation plan at specs/video-embedding-support-plan.md"

**Output:**
```
specs/video-embedding-support-plan.md
```

**Input text contains:**
"I created a plan in the specs directory called fix-neo4j-query-failure-plan.md"

**Output:**
```
specs/fix-neo4j-query-failure-plan.md
```

**Input text doesn't contain a clear path:**

**Output:**
```
0
```

## Important Notes
- Return ONLY the file path, no other text
- Do not add quotes, backticks, or formatting
- Do not include any explanation
- The path should be relative to the repository root
- If multiple paths are found, return the one in specs/ directory
- If no path is found, return exactly: 0
