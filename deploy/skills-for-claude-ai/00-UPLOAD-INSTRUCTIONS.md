# Claude.ai Skill Upload Instructions

Output location: `C:/Dev/Dejavara/deploy/skills-for-claude-ai/`

## Files Produced

| # | File | Status | Changes |
|---|------|--------|---------|
| 01 | `01-cambium-platform.md` | **UPDATED** | Removed "22 MSB3277 warnings" → "0 warnings"; removed EF Core version conflict section; AutoCAD version 2022-2026 |
| 02 | `02-aspnet-api-development.md` | **READY** | Deploy version is correct — has dual auth, column-drift, no Rami |
| 03 | `03-agentic-coding-workflow.md` | **UPDATED** | Fixed "22 pre-existing MSB3277 warnings are acceptable" → "0 warnings" |
| 04 | `04-autocad-plugin-development.md` | **UPDATED** | "AutoCAD 2022-2025" → "2022-2026" in 4 locations; "2025+" → "2027+" in version table |
| 09 | `09-millwork-file-management.md` | **PENDING UPDATE** | v5.7.0 content unchanged; HTML comment documents all V7.1.1 gaps |

## Skills NOT Packaged (Claude.ai-only — no local source)

These 6 skills exist only on Claude.ai. Export them manually from Claude.ai if refresh needed:

- `awmac-naaws`
- `badge-reflex-system`
- `context-engineering`
- `mcp-server-development`
- `millwork-shop-drawings`
- `quickbooks-contractor-invoicing`

## Upload Procedure

### For EXISTING skills (update):
1. claude.ai → Settings → Skills → find skill → "..." → Edit
2. Replace entire content with file content (everything between and including the `---` frontmatter)
3. Save and verify name/description match the frontmatter

### Upload order for existing skills:
1. **cambium-platform** (update — anchor skill, fixes warning count)
2. **aspnet-api-development** (update — dual auth, column-drift, no Rami)
3. **agentic-coding-workflow** (update — AUDIT.log protocol, pre-push gate, fixes warning count)
4. **autocad-plugin-development** (minor update — AutoCAD 2026)

### millwork-file-management: PENDING UPDATE
The skill references v5.7.0 standards. Current is V7.1.1 which has significant structural changes:
- Two-digit view numbers (X.01 instead of X.0)
- Fabrication suffix `f` for shop-only drawings
- 16 folders (12 numbered + 4 system) vs current 14
- Underscores for numbered folders (00_contract not 00-contract)
- `05_samples/` extracted to root level
- `_fo/` and `_cad_working/` system folders
- DXF naming conventions
- Global FO index

**Recommendation:** Do NOT upload the current v5.7.0 version as-is. Schedule a dedicated session to rewrite this skill against V7.1.1 standards with domain expertise review.

### For NEW skills (from parallel session):
These are handled separately:
- `cambium-auth-credentials`
- `cambium-railway-ops`
- `cambium-database-migrations`
- `cambium-permissions-log`
- `feature-millwork-infrastructure`
