---
description: Create a parallel development branch with worktree and ADW target label
argument-hint: [source-branch] [target-name]
allowed-tools: Bash(git fetch:*), Bash(git branch:*), Bash(git worktree:*), Bash(git push:*), Bash(gh label create:*), Bash(gh label list:*), Bash(ls:*), Bash(cat:*), Bash(grep:*), Read, Write, Skill
---

# Create Parallel Branch

Create a Tier 2 long-lived parallel branch with worktree and ADW targeting infrastructure.

## Arguments
- **Source branch**: $1 (e.g., `main`, `prd-6`)
- **Target name**: $2 (e.g., `prd-12`, `payments-system`)

The target name will be used for:
- Branch name: `$2`
- Worktree path: `/Users/nick/Downloads/$2`
- ADW label: `target:$2`

---

## Step 1: Validate Inputs

First, validate that both arguments are provided:

```
Arguments received:
- Source branch: $1
- Target name: $2
```

**Validation checks:**
1. Both arguments must be non-empty
2. Source branch must exist on origin
3. Target branch must NOT already exist
4. Target worktree path must NOT already exist
5. Label may exist (warn but continue)

Run these checks:
```bash
git fetch origin
git branch -a | grep "remotes/origin/$1" || echo "ERROR: Source branch '$1' not found on origin"
git branch -a | grep "remotes/origin/$2" && echo "ERROR: Target branch '$2' already exists"
ls -d /Users/nick/Downloads/$2 2>/dev/null && echo "ERROR: Worktree already exists at /Users/nick/Downloads/$2"
gh label list | grep "target:$2" && echo "WARNING: Label target:$2 already exists (will skip creation)"
```

If any ERROR is found, STOP and report the issue to the user.

---

## Step 2: Create Branch

Create the new branch from the source:

```bash
git branch $2 origin/$1
```

---

## Step 3: Create Worktree

Create the worktree adjacent to the main cognosmap repo:

```bash
git worktree add /Users/nick/Downloads/$2 $2
```

---

## Step 4: Push Branch to Origin

Push the new branch to remote with upstream tracking:

```bash
git push -u origin $2
```

---

## Step 5: Create ADW Target Label

Create the GitHub label for ADW targeting (skip if already exists):

```bash
gh label create "target:$2" --description "ADW target: $2 parallel branch" --color "0E8A16" 2>/dev/null || echo "Label already exists"
```

---

## Step 6: Calculate Available Ports

Scan existing parallel worktrees for port assignments and calculate next available ports.

**Base ports:**
- Backend: 9100 (main uses 9110)
- Frontend: 9200

**Scan these locations for .ports.env files:**
- `/Users/nick/Downloads/prd-*/.ports.env`
- `/Users/nick/Downloads/content-system/.ports.env`
- `/Users/nick/Downloads/cognosmap-*/.ports.env`

```bash
# Find highest backend port
cat /Users/nick/Downloads/*/.ports.env 2>/dev/null | grep BACKEND_PORT | sort -t= -k2 -n | tail -1

# Find highest frontend port
cat /Users/nick/Downloads/*/.ports.env 2>/dev/null | grep FRONTEND_PORT | sort -t= -k2 -n | tail -1
```

Calculate next ports by incrementing the highest found (or use 9111/9211 if none found).

---

## Step 7: Run /install_worktree

Invoke the install_worktree skill with calculated ports:

```
/install_worktree /Users/nick/Downloads/$2 <backend_port> <frontend_port>
```

Replace `<backend_port>` and `<frontend_port>` with the calculated values from Step 6.

---

## Step 8: Add CORS Configuration

After install_worktree completes, append CORS_ORIGINS to the worktree's .env:

```bash
cat >> /Users/nick/Downloads/$2/.env << 'EOF'

# CORS Configuration (allow this worktree's frontend)
CORS_ORIGINS=["http://localhost:5173","http://localhost:3000","http://localhost:<frontend_port>"]
EOF
```

Replace `<frontend_port>` with the actual port assigned.

---

## Step 9: Output Summary

After all steps complete, output a summary:

```
## Parallel Branch Created Successfully

| Component | Value |
|-----------|-------|
| Branch | $2 |
| Worktree | /Users/nick/Downloads/$2 |
| Label | target:$2 |
| Backend Port | <backend_port> |
| Frontend Port | <frontend_port> |
| CORS | Configured for localhost:<frontend_port> |

### Next Steps
1. `cd /Users/nick/Downloads/$2`
2. Start backend: `make backend` (uses port <backend_port>)
3. Start frontend: `make frontend` (uses port <frontend_port>)

### ADW Usage
Issues with label `target:$2` will branch from and merge to this parallel branch.
```

---

## Verification

Run these commands to verify:

```bash
git branch -a | grep $2
git worktree list | grep $2
gh label list | grep "target:$2"
grep CORS_ORIGINS /Users/nick/Downloads/$2/.env
```
