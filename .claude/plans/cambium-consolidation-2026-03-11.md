# Plan: Consolidate Cambium to Single Location

**Date:** 2026-03-11
**Author:** Claude Code
**Status:** PENDING EXTERNAL REVIEW

---

## Problem Statement

Cambium exists in two locations that have drifted apart:

| Location | Type | Commit | Status |
|----------|------|--------|--------|
| `C:\Users\cory\repos\Cambium` | Standalone clone | 75bb245 | Active, current |
| `C:\Dev\Dejavara\Cambium` | Submodule | 8b51065 | 14 commits behind |

This violates the established rule: "NO standalone clones of submodules."

The user keeps encountering this drift problem because work happens in the standalone clone, but the canonical structure expects all work in the submodule.

## Root Cause

At some point, `C:\Users\cory\repos\Cambium` was cloned independently (likely before the 2026-02-14 consolidation or as a workaround for a submodule issue). Work continued there instead of in the Dejavara submodule.

## Proposed Solution

### Phase 1: Verify standalone has everything

**Actions:**
1. Check both remotes point to the same GitHub repo
2. Verify standalone has no unpushed commits
3. Verify standalone has no uncommitted changes

```powershell
# In standalone
cd C:\Users\cory\repos\Cambium
git remote -v
git status
git log --oneline -5
git log origin/main..HEAD  # unpushed commits
```

**Success criteria:** Standalone is clean and fully pushed to origin

### Phase 2: Update submodule to match

**Actions:**
```powershell
cd C:\Dev\Dejavara
git submodule update --remote Cambium
cd Cambium
git checkout main
git pull
git log --oneline -3  # Should show 75bb245 at HEAD
```

**Rollback:**
```powershell
cd C:\Dev\Dejavara
git submodule update --init Cambium  # Restores to recorded ref
```

**Success criteria:** `C:\Dev\Dejavara\Cambium` is at commit 75bb245

### Phase 3: Commit submodule ref update in Dejavara

**Actions:**
```powershell
cd C:\Dev\Dejavara
git add Cambium
git commit -m "chore: sync Cambium submodule to HEAD (consolidation)"
git push
```

**Rollback:** `git reset --hard HEAD~1` (before push)

**Success criteria:** Dejavara repo tracks current Cambium HEAD

### Phase 4: Delete standalone clone

**Actions:**
```powershell
# Rename first (safer than delete)
Rename-Item "C:\Users\cory\repos\Cambium" "C:\Users\cory\repos\Cambium-TODELETE-$(Get-Date -Format 'yyyyMMdd')"

# After 1 week with no issues, delete:
# Remove-Item -Recurse -Force "C:\Users\cory\repos\Cambium-TODELETE-*"
```

**Rollback:** Rename back to `Cambium`

**Success criteria:** Only one Cambium location exists

### Phase 5: Update any IDE/tool references

**Actions:**
1. Check VSCode recent workspaces for `C:\Users\cory\repos\Cambium`
2. Update any Terminal shortcuts/aliases
3. Check git config for worktrees or other refs

```powershell
# Find VSCode references
Select-String -Path "$env:APPDATA\Code\User\*.json" -Pattern "repos\\Cambium" -SimpleMatch
```

**Success criteria:** No tools point to the old location

---

## Files Modified

| File | Change |
|------|--------|
| `C:\Dev\Dejavara\Cambium` (submodule) | Updated to HEAD |
| Dejavara repo | Submodule ref commit |
| `C:\Users\cory\repos\Cambium` | Renamed/deleted |

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Standalone has unpushed work | Medium | High | Phase 1 explicitly checks |
| IDE breaks when path changes | Medium | Low | Phase 5 updates references |
| User muscle memory opens wrong path | High | Low | Rename (not delete) gives recovery window |
| Submodule update fails | Low | Medium | Rollback via `git submodule update --init` |

## Prevention: Why This Won't Happen Again

The MEMORY.md already has the rule. The failure mode is:
1. Submodule gets into weird state (detached HEAD, merge conflict)
2. User clones fresh to "work around" the issue
3. Forgets to delete the workaround clone
4. Work accumulates in wrong location

**Proposed guardrail:** Add a pre-commit hook to Dejavara that warns if common standalone paths exist:

```bash
# .git/hooks/pre-commit (or in CLAUDE.md as reminder)
if [ -d "$HOME/repos/Cambium/.git" ]; then
  echo "WARNING: Standalone Cambium clone exists at ~/repos/Cambium"
  echo "Work should happen in C:\Dev\Dejavara\Cambium"
fi
```

---

## Questions for Reviewer

1. Is the rename-before-delete approach (1 week buffer) appropriate, or should we just delete immediately?
2. Should we add the pre-commit hook guardrail?
3. Are there other locations to check for stale clones (e.g., `C:\Users\cory\Dev\`)?

---

## Review Checklist (for Claude.ai)

- [ ] Does Phase 1 adequately verify no work will be lost?
- [ ] Is the submodule update approach correct?
- [ ] Any edge cases with the rename/delete approach?
- [ ] Is the guardrail hook worth implementing?
- [ ] Should MEMORY.md be updated to note this consolidation was completed?

---

**This plan is ready for external review before execution. Copy to Claude.ai for adversarial review.**