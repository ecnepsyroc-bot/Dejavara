---
name: millwork-file-management
description: "File management system for millwork project managers. Covers folder structure creation, naming conventions, revision control, drawing organization, and inbox-to-archive workflows. Use when: creating project folders, naming files, organizing drawings, managing revisions, handling trade coordination documents, tracking samples/submittals, or discussing folder structure decisions. Triggers include: project template, folder structure, naming convention, revision, drawing organization, document management, AWMAC, AIA standard, inbox workflow, factory order, FO."
---

# Millwork File Management

File organization system for Feature Millwork project managers (v5.7.0), based on AIA/AWMAC standards.

## Core Principles

| Principle | Description |
|-----------|-------------|
| Document-type organization | Files organized by *what they are*, not who created them |
| Machine-parseable naming | Filenames follow patterns that regex can extract |
| Dual-location architecture | Projects in full paths, FOs in short paths |
| Drawing-to-fabrication linkage | FO# links the production chain |
| Folder as source of truth | Database indexes filesystem, never overrides it |

## Dual-Location Architecture

| Root | Path | Purpose | Char Budget |
|------|------|---------|-------------|
| **Projects** | `C:\Projects\` | Full project documentation | ~200 chars |
| **Factory Orders** | `C:\FO\` | ARDIS, CNC, machine files | ~240 chars |

**Why two locations?** ARDIS and legacy CNC software have path length limitations. A shallow `C:\FO\` root prevents path overflow.

## Project Template (12 Folders + 2 System)

**Location:** `C:\Projects\{jobnumber}-{jobname}\`

**Root = inbox.** Any file sitting directly at project root is unsorted and must be dealt with immediately.

```
{jobnumber}-{jobname}/                      ← INBOX: unsorted = action needed NOW
│
├── 00-contract/
│   ├── addenda/
│   ├── agreement/
│   ├── drawings/                           ← Architect drawings (IFT, reference — NOT IFC)
│   ├── insurance/
│   └── specifications/
│
├── 01-admin/
│   ├── ccn/
│   │   └── _received/
│   ├── certs/                              ← AWMAC-MSE-Cert.pdf
│   ├── change-order/
│   │   └── _received/
│   ├── close-out/
│   ├── deficiencies/
│   ├── email-disputes/
│   ├── field-notice/
│   ├── install/
│   ├── meeting-minutes/
│   ├── rfi/
│   │   ├── _received/
│   │   └── _template/
│   ├── rfp/
│   ├── schedule/
│   ├── shipping/
│   ├── site-instruction/
│   └── submittal/
│       ├── _source/
│       │   └── sub-001/
│       ├── _received/
│       └── _template/
│
├── 02-financial/
│   ├── budget/
│   ├── invoices/
│   ├── po-log/
│   └── progress-claims/
│
├── 03-cad/
│   ├── archive/
│   ├── as-built/
│   ├── coordination/
│   ├── library/
│   └── working/                            ← Active .dwg files (always current)
│
├── 04-drawings/
│   ├── approved/
│   ├── as-built/
│   ├── buyout/
│   ├── ifc/                                ← IFC sets from architects (DON'T rename)
│   ├── install/
│   ├── production/
│   └── revision/
│       └── {drawing-id}/
│
├── 05-materials/
│   ├── countertops/
│   │   ├── custom/
│   │   ├── laminate/
│   │   ├── porcelain/
│   │   ├── quartz/
│   │   ├── solid-surface/
│   │   └── stone/
│   ├── custom/
│   ├── doors/
│   ├── finish/
│   │   ├── paint/
│   │   └── stain/
│   ├── glass/
│   ├── hardware/
│   ├── laminate/
│   ├── metals/
│   ├── powdercoating/
│   ├── sheet-goods/
│   ├── solid/
│   ├── takeoff/
│   ├── upholstery/
│   └── veneer/
│
├── 06-samples/                             ← Mirrors 05-materials structure
│   ├── countertops/
│   ├── custom/
│   ├── doors/
│   ├── finish/
│   ├── glass/
│   ├── hardware/
│   ├── laminate/
│   ├── metals/
│   ├── mockup/
│   ├── powdercoating/
│   ├── sheet-goods/
│   ├── solid/
│   ├── upholstery/
│   └── veneer/
│
├── 07-production/
│   ├── _fo-index.md                        ← Links FO numbers → C:\FO\ paths
│   ├── {jobname}-cutlist.xlsx              ← Working cutlist (pre-FO#)
│   └── {fo-number}/
│       ├── cut-lists/
│       ├── parts-list/
│       ├── preglue/
│       ├── revision/
│       └── work-orders/
│
├── 08-buyout/
│   ├── quotes/                             ← Pre-decision vendor comparison
│   └── {vendor-name}/                      ← One folder per vendor
│       ├── correspondence/
│       ├── drawings/
│       ├── po/
│       ├── quotes/
│       ├── wo/
│       └── _received/
│
├── 09-coordination/
│   ├── custom/
│   ├── doors/                              ← Multi-party coordination (use transmittal with disclaimer)
│   │   ├── _received/
│   │   ├── _source/
│   │   └── _template/
│   ├── drywall/
│   ├── electrical/
│   ├── glazing/
│   ├── hvac/
│   ├── mechanical/
│   └── plumbing/
│
├── 10-site/
│   ├── measure/
│   └── photo/
│
├── 11-awmac/
│   ├── submissions/
│   ├── qc/
│   ├── _source/
│   │   └── gis-001/
│   ├── _received/
│   └── _template/                          ← INSI, INSF, HUM forms (unsigned)
│
├── _archive/
│
└── _cambium/
    ├── cache/
    ├── index.json
    └── qr/
```

## Job Number Format

**Pattern:** `YY##` (4-digit numeric)
- `YY` = 2-digit year
- `##` = 2-digit sequence

**Examples:**
- `2501-chambers` (first job of 2025)
- `2601-netflix-burbank` (first job of 2026)
- `2615-dentons-vancouver` (15th job of 2026)

No letters. No hyphens in the code. The full project name is secondary.

## File Naming Convention

### Universal Pattern

```
[Job]-[DocType]-[Sequence]-[Revision]-[Date].[ext]
```

**Example:** `2419-SD-1.0-R2-20260128.pdf`

| Segment | Format | Example |
|---------|--------|---------|
| **Job** | 4-digit code | `2419` |
| **DocType** | 2-4 letter code | `SD`, `RFI`, `SUB` |
| **Sequence** | X.0 for drawings, 3-digit for docs | `1.0`, `001` |
| **Revision** | R0=first issue, R1=first revision | `R0`, `R1` |
| **Date** | YYYYMMDD (no hyphens) | `20260128` |

### Universal Rules

| Rule | Standard | Example |
|------|----------|---------|
| No spaces | Dashes between segments | `2419-SD-1.0-R0-20260128.pdf` |
| Date format | YYYYMMDD (ISO 8601 compact) | `20260128` |
| Drawing sequences | X.0 format | `1.0`, `1.1`, `2.0` |
| Document sequences | 3-digit zero-padded | `RFI-001`, `SUB-003` |
| Descriptions | Lowercase, hyphenated | `coffee-point-905` |
| Status | NOT in filename — tracked separately | — |

### Document Type Codes

**Shop Production:**
| Code | Meaning | Folder Home |
|------|---------|-------------|
| `SD` | Shop Drawing | `04-drawings/production/` |
| `CUT` | Cut List | `C:\FO\{FO#}\` |
| `MAT` | Material List | `05-materials/` |
| `HW` | Hardware Schedule | `05-materials/hardware/` |
| `FIN` | Finish Schedule | `05-materials/finish/` |

**Project Correspondence:**
| Code | Meaning | Folder Home |
|------|---------|-------------|
| `RFI` | Request for Information | `01-admin/rfi/` |
| `SUB` | Submittal | `01-admin/submittal/` |
| `CO` | Change Order | `01-admin/change-order/` |
| `SI` | Site Instruction | `01-admin/site-instruction/` |
| `CCN` | Contemplated Change Notice | `01-admin/ccn/` |
| `COORD` | Coordination Drawing | `09-coordination/{trade}/` |

**Reference Documents:**
| Code | Meaning | Folder Home |
|------|---------|-------------|
| `IFC` | Issued For Construction | `04-drawings/ifc/` |
| `DWG` | Architectural Drawing | `00-contract/drawings/` |
| `SPEC` | Specification | `00-contract/specifications/` |
| `REF` | Reference Drawing | `00-contract/drawings/` |

**AWMAC:**
| Code | Meaning | Folder Home |
|------|---------|-------------|
| `INSI` | Initial Inspection Request | `11-awmac/submissions/` |
| `INSF` | Final Inspection Request | `11-awmac/submissions/` |
| `HUM` | Humidity Report | `11-awmac/submissions/` |
| `GIS` | GIS Report | `11-awmac/_received/` |

### By Document Type

| Type | Pattern | Example |
|------|---------|---------|
| **RFIs** | `{job}-RFI-{###}-R{#}-{date}` | `2419-RFI-007-R0-20260128.pdf` |
| **Submittals** | `{job}-SUB-{###}-feature-millwork-R{#}-{date}` | `2419-SUB-001-feature-millwork-R0-20260128.pdf` |
| **Change Orders** | `{job}-CO-{###}-R{#}-{date}` | `2419-CO-003-R0-20260301.pdf` |
| **Site Photos** | `{date}-{location}-{desc}` | `20260211-reception-backing-verification.jpg` |
| **Working CAD** | `{jobname}` or `{jobname}-{descriptor}` | `netflix-cabinets.dwg` |
| **Production PDF** | `FO{#}-{sheet}-{desc}-R{#}-{date}` | `FO15961-1.0-office-cabinets-R1-20260128.pdf` |

## Factory Order Structure

**Location:** `C:\FO\{fo-number}\` (FO number only, no description)

- ✅ `C:\FO\15961\`
- ❌ `C:\FO\15961_Reception-Desk\`

```
C:\FO\{fo-number}\
├── Shops/                          ← G-code output
├── {fo-number}.pdf                 ← FO document
├── {fo-number}.R41                 ← ARDIS program
├── {fo-number}.xls                 ← Parts list (working)
├── {fo-number}.csv                 ← Cut list (clean)
├── {fo-number}_dirty.csv           ← Cut list (raw export)
├── {fo-number}_plywoods.pdf        ← Plywood cutlist
├── {fo-number}_solids.pdf          ← Solids cutlist
├── {fo-number}_preglue.pdf         ← Preglue cutlist
├── {fo-number}_layouts.pdf         ← Panel optimization
├── Imperial_template.MCH
├── Imperial_template.STD
├── Imperial_template.STK
└── Default.EDG
```

**FO file naming:** Use bare FO number, NO `FO` prefix inside `C:\FO\`:
- ✅ `15961.R41`, `15961.csv`, `15961_plywoods.pdf`
- ❌ `FO15961.R41`, `fo_15961.csv`

The `FO` prefix is reserved for production PDFs (e.g., `FO15961-1.0-cabinets-R1-20260128.pdf`).

## PDF Output Modes

| Mode | Pattern | Example | Audience |
|------|---------|---------|----------|
| **Submittal** | `{Job}-SUB-{###}-feature-millwork-R{#}-{date}` | `2419-SUB-001-feature-millwork-R0-20260128.pdf` | GC/architect |
| **Production** | `FO{#}-{sheet}-{desc}-R{#}-{date}` | `FO15961-1.0-office-cabinets-R1-20260128.pdf` | Shop floor |
| **Internal** | `{sheet}-{desc}` | `1.0-office-cabinets.pdf` | Working reference |

## The Three Underscore Patterns

### `_source/` — Working Pieces
When you assemble an issued document by combining multiple files, keep source pieces here.

```
01-admin/submittal/
├── 2419-SUB-001-feature-millwork-R0-20260210.pdf    ← Issued document
└── _source/
    └── sub-001/
        ├── transmittal.pdf
        ├── floorplan-highlighted.pdf
        └── sd-1.0-reception-desk.pdf
```

**Rules:**
- Underscore prefix sorts to top, signals "not for distribution"
- Subfolder named `{type-seq}/` to match issued document
- Contents use descriptive names — no formal naming needed
- Create when needed, don't pre-create empty

**Used in:** `01-admin/submittal/`, `11-awmac/`, `09-coordination/doors/`

### `_received/` — External Documents As-Is
When external parties send documents, file them with their original naming.

```
01-admin/submittal/
├── 2419-SUB-001-feature-millwork-R0-20260210.pdf    ← What you sent
└── _received/
    └── FM-SD-Package-1-Reviewed-AAN.pdf              ← Their approval, their name
```

**Rules:**
- Keep original filenames — do NOT rename into Feature convention
- Create when needed, don't pre-create empty

**Used in:** `11-awmac/_received/`, `08-buyout/{vendor}/_received/`, `01-admin/rfi/_received/`

### `_template/` — Blank, Unsigned Forms
Reusable form templates ready for use.

```
Pattern:   [Trade]-[Type]-[###]-R[#]-template.[ext]
Example:   feature-RFI-001-R0-template.docx

On use:    [Job]-[Type]-[###]-R[#]-[Date].[ext]
Example:   2419-RFI-001-R0-20260210.docx
```

**Rules:**
- Templates are NEVER signed — signatures only on dated, issued documents
- On use: Save-As, swap trade→job code and template→date, then sign

**Used in:** `01-admin/rfi/`, `01-admin/submittal/`, `11-awmac/`

## Revision Control

### Revision Notation

| Notation | Meaning |
|----------|---------|
| R0 | Original issue (first release — NOT "no revision") |
| R1 | First revision |
| R2+ | Subsequent revisions |
| RA, RB | Letter notation if GC requires it |

**When to increment:** Any time a drawing is REISSUED to an external party or shop floor after a previous issue.

### CAD File Organization

**Working files** — No rev/date in filename. OneDrive version history tracks versions.

```
03-cad/
├── working/
│   └── netflix-cabinets.dwg              ← Always current, no date
└── archive/
    ├── netflix-cabinets-20260126.dwg     ← Dated when archived
    └── netflix-cabinets-20260123.dwg
```

**Issued snapshots** — When publishing, snapshot with rev+date:

```
04-drawings/revision/{drawing-id}/
├── r0_2025-02-05.dwg
├── r0_2025-02-05.pdf
├── r1_2025-11-15.dwg
├── r1_2025-11-15.pdf
└── revision-log.json
```

### Revision Log Schema

```json
{
  "drawing": "DEN-1832",
  "current_revision": 2,
  "history": [
    { "rev": 0, "date": "2025-02-05", "note": "IFC", "by": "cory" },
    { "rev": 1, "date": "2025-11-15", "note": "Moved to 1731", "by": "cory" },
    { "rev": 2, "date": "2025-11-27", "note": "Finished end added", "by": "cory" }
  ]
}
```

### Superseded File Handling

**NEVER delete superseded files.** Move to `04-drawings/revision/{drawing-id}/` or rename with `_SUPD` suffix. You will need the history for disputes.

## AWMAC Folder (11-awmac/)

**Four-Subfolder Structure:**

```
11-awmac/
├── submissions/       ← What you send to AWMAC/GIS
├── qc/                ← Internal quality checks, photos
├── _source/           ← Assembly pieces for submissions
│   └── gis-001/
├── _received/         ← Everything back from AWMAC/GIS (keep original names)
└── _template/         ← AWMAC forms: INSI, INSF, HUM (unsigned)
```

**AWMAC workflow sequence:**

```
0. You → AWMAC    2419-GIS-001-R0-20251029.pdf        GIS submission
1. You → AWMAC    2419-INSI-001-R0-20251024.pdf       Initial inspection request
2. AWMAC → You    (filed as-is in _received/)          GIS report / inspection results
3. You → AWMAC    2419-HUM-001-R0-20260305.pdf        Humidity report
4. You → AWMAC    2419-INSF-001-R0-20260305.pdf       Final inspection request
```

**Certificate location:** `01-admin/certs/AWMAC-MSE-Cert.pdf`

## Anti-Patterns to Avoid

| Bad | Why | Good |
|-----|-----|------|
| `PDFs/` folder | File type is redundant | `04-drawings/production/` |
| `APPROVED` in filename | Status tracked separately | `2419-SUB-001-R0-20260210.pdf` |
| Spaces in filenames | Breaks automated parsing | Use dashes |
| Renaming `_received/` files | Breaks traceability | Keep original names |
| `C:\FO\15961_Reception-Desk\` | Description in FO path | `C:\FO\15961\` |
| `FO15961.R41` inside C:\FO\ | FO prefix redundant | `15961.R41` |
| Files at project root | No organization | Process immediately |
| `2026-01-28` in filenames | Hyphenated dates | `20260128` |

## Quick Reference

### When You Receive a Document

1. What type is it? (RFI, submittal, SI, coordination...)
2. That's the folder.
3. Name it with the convention.
4. External docs → `_received/` (keep original name)

### When You Create a Drawing

1. Save working DWG to `03-cad/working/` (no date in name)
2. When ready: plot to `04-drawings/production/` with rev+date
3. Archive DWG snapshot to `04-drawings/revision/{id}/`
4. Update revision-log.json

### When You Don't Know Where Something Goes

Ask: *"If I needed to find this in 6 months, what would I search for?"*

The answer is the folder name.

## Philosophy

> **Folder structure is infrastructure, not a task.**

Once established, you don't think about it. Structure serves you — you don't serve structure.
