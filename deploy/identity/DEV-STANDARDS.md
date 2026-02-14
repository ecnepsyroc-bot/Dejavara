# Development Standards

## No Quick Fixes

**Rule:** No quick fixes, workarounds, or band-aids unless explicitly part of a phased development plan marked in a spec file as "TODO later".

Every change must be:
1. **Properly diagnosed** - Understand the root cause before coding
2. **Properly designed** - Think through the solution architecture
3. **Properly implemented** - Write clean, maintainable code
4. **Properly tested** - Verify it works before declaring done

If a problem is complex, say so. Take the time to do it right.

### What This Means

❌ **Don't do:**
- "Try this workaround for now"
- "Use incognito mode as a quick fix"
- "We'll fix it properly later"
- Suggesting users change their behavior to avoid bugs

✅ **Do:**
- Diagnose the actual problem
- Propose a proper solution
- Implement it correctly
- Verify it works

### Exceptions

Quick fixes are acceptable ONLY when:
- Explicitly documented in a spec file as a planned phase
- Marked with a TODO and tracked for follow-up
- The user explicitly requests a temporary solution

---

*Added: 2026-02-08 by Cory's directive*
