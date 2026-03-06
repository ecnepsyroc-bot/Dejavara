---
name: millwork-file-management
description: "File management system for millwork project managers (v8.0.0). Covers folder structure creation, naming conventions, revision control, drawing organization, DXF production geometry, transmittals, README deployment, pre-FO staging, and inbox-to-archive workflows. Use when: creating project folders, naming files, organizing drawings, managing revisions, handling trade coordination documents, tracking samples/submittals, AWMAC documentation, specification pipeline, DXF files, transmittal packages, global FO index, pre-FO cutlists, README deployment, or discussing folder structure decisions. Triggers include: project template, folder structure, naming convention, revision, drawing organization, document management, AWMAC, GIS, MSE, specification pipeline, sample tracking, DXF, transmittal, global FO, pre-FO staging, ifc-working, README, deploy-readmes, agreement_scope, powdercoating finish."
---

# Millwork File Management

File organization system for Feature Millwork project managers (v8.0.0), based on Feature Millwork Documentation Standards V8.0.0.

## Core Principles

| Principle | Description |
|-----------|-------------|
| Document-type organization | Files organized by *what they are*, not who created them |
| Machine-parseable naming | Filenames follow patterns that regex can extract |
| Dual-location architecture | Projects at `C:\Projects\`, FOs at `C:\FO\` |
| Drawing-to-fabrication linkage | FO# links the production chain |
| Folder as source of truth | Database indexes filesystem, never overrides it |
| Every folder earns its place | Empty folders waste attention; `_README.txt` answers "What goes here?" |

## Dual-Location Architecture

| Root | Path | Purpose |
|------|------|---------|
| **Projects** | `C:\Projects\` | Full project documentation (15 folders) |
| **Factory Orders** | `C:\FO\` | ARDIS, CNC, DXF, machine files |

**Why two locations?** ARDIS has strict path-length limits (<70 characters). `C:\FO\` keeps paths short.

### Pre-FO Staging Workflow

```
_fo/staging/{jobname}-cutlist.xlsx    <- Before FO number assigned
        | (FO number assigned)
C:\FO\{FO#}\{jobname}-cutlist.xlsx    <- After FO number assigned
```

## Project Template (11 Numbered + 4 System = 15 Folders)

**Location:** `C:\Projects\{jobnumber}_{jobname}\`

```
C:\Projects\{jobnumber}_{jobname}\
|-- _fo/                           <- Factory Orders index and status
|   |-- _fo-index.md
|   +-- staging/                   <- Pre-FO cutlists and planning docs
|-- _cad_working/                  -> junction to 03_cad/working
|-- _archive/                      <- Superseded/obsolete documents
|-- _cambium/                      <- Cambium platform metadata
|   |-- index.json
|   |-- cache/
|   +-- qr/
|-- 00_contract/                   <- Contract documents (immutable baseline)
|   |-- addenda/
|   |-- agreement_scope/           <- Signed contracts, LOIs, scope letters
|   |-- drawings/                  <- Original IFC/IFT as received (immutable)
|   |-- insurance/
|   +-- specifications/            <- Division specs as received (immutable)
|-- 01_admin/                      <- Contract administration (workspace)
|   |-- ccn/
|   |   +-- _received/
|   |-- certs/
|   |-- change-order/
|   |   +-- _received/
|   |-- close-out/
|   |-- deficiencies/
|   |-- email-disputes/
|   |-- field-notice/
|   |-- install/
|   |-- meeting-minutes/
|   |-- rfi/
|   |   |-- _received/
|   |   +-- _template/
|   |-- rfp/
|   |-- samples/                   -> junction to 05_samples/
|   |-- schedule/
|   |-- shipping/
|   |-- site-instruction/
|   |-- specifications/            <- Negotiation workspace (stage 2)
|   |   +-- _received/
|   |-- submittal/
|   |   |-- _source/
|   |   |-- _received/
|   |   +-- _template/
|   +-- transmittal/
|       +-- _template/
|-- 02_financial/                  <- Financial tracking
|   |-- budget/
|   |-- invoices/
|   |-- po-log/
|   +-- progress-claims/
|-- 03_cad/                        <- CAD working files (DWG only)
|   |-- archive/
|   |-- as-built/
|   |-- coordination/
|   |-- library/
|   +-- working/
|-- 04_drawings/                   <- Issued PDF drawings
|   |-- approved/
|   |-- as-built/
|   |-- buyout/
|   |-- ifc-working/               <- Working IFC copies for CAD underlay
|   |-- install/
|   |-- production/
|   +-- revision/
|-- 05_samples/                    <- Production-facing sample records
|   |-- countertops/
|   |   |-- custom/ laminate/ porcelain/ quartz/ solid-surface/ stone/
|   |-- custom/
|   |-- doors/
|   |-- finish/
|   |   |-- paint/
|   |   |-- powdercoating/         <- Under finish/ (it's a finish, not a material type)
|   |   +-- stain/
|   |-- glass/
|   |-- hardware/
|   |-- laminate/
|   |-- metals/
|   |-- mockup/
|   |-- sheet-goods/
|   |-- solid/
|   |-- upholstery/
|   +-- veneer/
|-- 06_materials/                  <- Resolved material documentation
|   |-- countertops/
|   |   |-- custom/ laminate/ porcelain/ quartz/ solid-surface/ stone/
|   |-- custom/
|   |-- doors/
|   |-- finish/
|   |   |-- paint/
|   |   |-- powdercoating/
|   |   +-- stain/
|   |-- glass/
|   |-- hardware/
|   |-- laminate/
|   |-- metals/
|   |-- sheet-goods/
|   |-- solid/
|   |-- takeoff/
|   |-- upholstery/
|   +-- veneer/
|-- 07_buyout/                     <- Vendor relationships
|   |-- quotes/
|   +-- {vendor-name}/
|       |-- po/
|       |-- quotes/
|       |-- wo/
|       +-- _received/
|-- 08_coordination/               <- Trade coordination
|   |-- custom/
|   |-- doors/
|   |   |-- _received/
|   |   |-- _source/
|   |   +-- _template/
|   |-- drywall/
|   |-- electrical/
|   |-- glazing/
|   |-- hvac/
|   |-- mechanical/
|   +-- plumbing/
|-- 09_site/                       <- Field documentation
|   |-- measure/
|   +-- photo/
+-- 10_awmac/                      <- AWMAC quality program
    |-- submissions/
    |-- qc/
    |-- _source/
    |-- _received/
    +-- _template/
```

## System Folders

### _fo/ -- Factory Orders

- `_fo-index.md` -- Markdown table linking FO numbers to status and `C:\FO\` locations
- `staging/` -- Pre-FO cutlists and planning docs (before FO number assigned)

When an FO number is assigned, move files from `_fo/staging/` to `C:\FO\{FO#}\`.

**_fo-index.md format:**
```markdown
| FO# | Description | Status | Sheet Range | Location |
|-----|-------------|--------|-------------|----------|
| 16001 | Reception Desk | In Progress | 1.00-3.00 | C:\FO\16001 |
|  |  |  |  |  |
```

### _cad_working/ -- CAD Junction

Junction (`mklink /J`) to `03_cad/working/` for quick drafter access from project root.

### _archive/ -- Superseded Documents

Superseded or obsolete documents retained for audit trail. NOT for revision history (use `04_drawings/revision/`).

### _cambium/ -- Platform Metadata

Managed by Cambium platform. Do not edit manually. Contains `index.json` (version, project metadata), `cache/`, `qr/`.

## Numbered Folder Reference

| # | Folder | Scope |
|---|--------|-------|
| 00 | `contract/` | Immutable baseline: agreement + scope, drawings, specs, addenda, insurance |
| 01 | `admin/` | Workspace: RFIs, submittals, COs, CCNs, transmittals, spec negotiations, email disputes |
| 02 | `financial/` | Budget, invoices, PO log, progress claims |
| 03 | `cad/` | Working DWGs, archive, as-built, coordination, library |
| 04 | `drawings/` | Issued PDFs: production, ifc-working, approved, buyout, install, as-built, revision |
| 05 | `samples/` | Production-facing sample records by material type |
| 06 | `materials/` | Resolved material documentation by type + takeoffs |
| 07 | `buyout/` | Vendor folders: quotes, POs, WOs, `_received/` |
| 08 | `coordination/` | Trade coordination: doors, drywall, electrical, glazing, hvac, mechanical, plumbing |
| 09 | `site/` | Site measurements and photos |
| 10 | `awmac/` | AWMAC quality: submissions, QC, `_source/`, `_received/`, `_template/` (5 subfolders only) |

### Key Distinctions

**IFC Filing:**
| Folder | Contents |
|--------|----------|
| `00_contract/drawings/` | Original IFC as received from architect (immutable) |
| `04_drawings/ifc-working/` | Working copies used as CAD underlays/references |

**Contract vs Admin:**
- `00_contract/` = Immutable baseline. Do not edit.
- `01_admin/` = The workspace. Submittals, RFIs, COs, negotiations.
- A stamped submittal return is NOT a contract document.

**Money:**
- Money coming IN -> `02_financial/`
- Money going OUT -> `07_buyout/{vendor}/`

**Coordination vs Buyout:**
- `08_coordination/` = subtrades (drywall, electrical, etc.)
- `07_buyout/` = vendors (one folder per vendor)

## Junctions

| Junction | Target | Purpose |
|----------|--------|---------|
| `_cad_working/` | `03_cad/working/` | Quick drafter access |
| `01_admin/samples/` | `05_samples/` | Admin workspace bridge to sample records |

Junctions use absolute paths. Created via `mklink /J`.

## Specification Pipeline

Three-stage model for specification handling:

```
RECEIVED                    NEGOTIATED                 RESOLVED
00_contract/specifications/ -> 01_admin/specifications/ -> 06_materials/{type}/
(immutable baseline)          (active workspace)         (production-facing)
```

- **Stage 1 (Received):** Contract specs as received. Immutable. Dispute baseline.
- **Stage 2 (Negotiated):** RFI clarifications, substitution requests, annotated specs. Active workspace.
- **Stage 3 (Resolved):** Confirmed manufacturer cut sheets and data sheets, filed by material type.

**Why three stages?** In a dispute you need to show: what was specified (Stage 1), how it was negotiated (Stage 2), and what was actually used (Stage 3).

## Naming Conventions

### Universal Rules

1. No loose files at project root -- everything goes in a folder
2. Date format: YYYY-MM-DD or YYYYMMDD -- sorts chronologically
3. Status tracked in database -- NOT in filenames (exception: samples retain `_STATUS` suffix)
4. Underscores between elements -- no spaces
5. Numbered folders use underscores: `00_contract`, `01_admin`
6. Subfolder names use lowercase-hyphen: `change-order/`, `email-disputes/`
7. DXF files use FO number as primary identifier: `{FO#}-{qualifier}.dxf`

### Document Type Patterns

| # | Type | Pattern | Example | Folder |
|---|------|---------|---------|--------|
| 1 | RFI | `RFI-###_desc` | `RFI-007_panel-reveal.pdf` | `01_admin/rfi/` |
| 2 | Submittal | `SUB-###_desc` | `SUB-012_reception-desk.pdf` | `01_admin/submittal/` |
| 3 | Sample | `date_desc_supplier_STATUS` | `2026-01-28_walnut_windsor_PENDING.pdf` | `05_samples/{type}/` |
| 4 | Shop Drawing | `JobCode-SD-###-R#-date` | `2419-SD-001-R2-20260128.pdf` | `04_drawings/production/` |
| 5 | Change Order | `CO-###_desc` | `CO-003_added-millwork.pdf` | `01_admin/change-order/` |
| 6 | CCN | `CCN-###_desc` | `CCN-005_revised-panel.pdf` | `01_admin/ccn/` |
| 7 | Meeting Minutes | `MM_date_desc` | `MM_2026-01-28_kickoff.pdf` | `01_admin/meeting-minutes/` |
| 8 | Working Cutlist | `jobname-cutlist.xlsx` | `chambers-cutlist.xlsx` | `_fo/staging/` |
| 9 | Template | `trade-TYPE-###-R#-template` | `feature-SUB-001-R0-template.pdf` | (per type) |
| 10 | Site Photo | `YYYYMMDD-location-desc` | `20260211-reception-backing.jpg` | `09_site/photo/` |
| 11 | Specification | `SPEC-###_desc` | `SPEC-001_laminate-substitution.pdf` | `01_admin/specifications/` |
| 12 | Transmittal | `TR-###_desc_date` | `TR-005_architect_20260215.pdf` | `01_admin/transmittal/` |

### AWMAC Document Types

| Code | Full Name | Pattern | Folder |
|------|-----------|---------|--------|
| GIS | Grade Inspection Summary | `{Job}-GIS-###-date` | `10_awmac/submissions/` |
| INSI | Initial Inspection | `{Job}-INSI-###-date` | `10_awmac/submissions/` |
| INSF | Final Inspection | `{Job}-INSF-###-date` | `10_awmac/submissions/` |
| HUM | Humidity Test | `{Job}-HUM-###-date` | `10_awmac/submissions/` |
| MSE | Manufacturer's Statement of Exclusions | `{Job}-MSE-date` | `01_admin/certs/` |

MSE files to `01_admin/certs/`, not `10_awmac/` -- it's a contractual certification, not an internal quality record.

### Status Values (Database Metadata)

- `PENDING` -- Awaiting response
- `APPROVED` -- Accepted
- `REJECTED` -- Not accepted, needs revision
- `REVISED` -- Resubmitted after rejection

Status is tracked in Cambium database, NOT in filenames. Exception: samples retain `_STATUS` suffix for shop floor visibility.

## DXF Production Geometry

**Location:** `C:\FO\{FO#}\`

**Cardinal Rule:** No FO, no production. DXF files MUST be tied to a Factory Order.

**Pattern:** `{FO#}-{qualifier}.dxf`

| Qualifier | Purpose | Example |
|-----------|---------|---------|
| `1.00`, `2.00` | Sheet number (panel face) | `15961-1.00.dxf` |
| `1.00f` | Fabrication view | `15961-1.00f.dxf` |
| `nest` | Nesting layout | `15961-nest.dxf` |
| `ctop` | Countertop profile | `15961-ctop.dxf` |
| `hcut` | Hand-cut template | `15961-hcut.dxf` |
| `edge` | Edge profile | `15961-edge.dxf` |
| `panel` | Panel layout | `15961-panel.dxf` |
| `custom` | Non-standard geometry | `15961-custom.dxf` |

## Global Factory Order Index

`P:\Projects\_fo\` provides a single-pane view of ALL active Factory Orders across all projects.

```
P:\Projects\_fo\
|-- 15961 -> C:\FO\15961\    (junction)
|-- 15962 -> C:\FO\15962\    (junction)
+-- _sync.log
```

**Source of truth:** `C:\FO\` -- the sync script scans this directory for active FO folders (skipping `_archive/` and `_templates/`).

**Sync script:** `folder_organizer/scripts/sync-global-fo.ps1` -- runs every 5 minutes via Task Scheduler.

| Flag | Purpose |
|------|---------|
| `-Install` | Register Task Scheduler job |
| `-Uninstall` | Remove Task Scheduler job |
| `-WhatIf` | Dry-run |

## Filing Decision Guide

### Quick Decision Rules

| Question | Answer |
|----------|--------|
| **ARDIS / CNC / CSV / DXF?** | Always `C:\FO\{FO#}\` |
| **Pre-FO cutlist (no FO# yet)?** | `_fo/staging/` |
| **IFC set (contract original)?** | `00_contract/drawings/` |
| **IFC set (working copy for CAD)?** | `04_drawings/ifc-working/` |
| **Specification question?** | See Specification Pipeline |
| **Sample work?** | `05_samples/{type}/` (admin access via `01_admin/samples/` junction) |
| **Powdercoating?** | `05_samples/finish/powdercoating/` or `06_materials/finish/powdercoating/` |
| **Money coming IN?** | `02_financial/` |
| **Money going OUT?** | `07_buyout/{vendor}/` |
| **From the field?** | `09_site/` |
| **AWMAC related?** | `10_awmac/` |
| **Email for disputes/legal record?** | `01_admin/email-disputes/` |
| **Not sure?** | Check `_README.txt` inside the folder |

### Filing Steps

**Step 1: Who created it?**
- I created it -> Match document type to folder (see Document Type Patterns)
- They sent it -> Is it a contract document?

**Step 2: Contract document?**
- YES -> `00_contract/{type}/` (file as received, don't rename)
- NO -> Is it a response to your submission?

**Step 3: Response to your submission?**
- YES -> `{folder}/_received/` (e.g., `01_admin/submittal/_received/`)
- NO -> Determine document type and file accordingly

### Quick Path Reference

| I have a... | Put it in... |
|-------------|-------------|
| RFI I'm issuing | `01_admin/rfi/` |
| RFI response from architect | `01_admin/rfi/_received/` |
| Submittal package | `01_admin/submittal/` |
| Approved submittal return | `01_admin/submittal/_received/` |
| Transmittal | `01_admin/transmittal/` |
| IFC set (contract original) | `00_contract/drawings/` |
| IFC copy for CAD underlay | `04_drawings/ifc-working/` |
| Shop drawing PDF | `04_drawings/production/` |
| Install drawing | `04_drawings/install/` |
| Pre-FO cutlist | `_fo/staging/` |
| Cutlist with FO# | `C:\FO\{FO#}\` |
| ARDIS / DXF / G-code | `C:\FO\{FO#}\` |
| Sample record | `05_samples/{type}/` |
| Powdercoating sample | `05_samples/finish/powdercoating/` |
| Material data sheet | `06_materials/{type}/` |
| Vendor quote | `07_buyout/{vendor}/quotes/` |
| PO to vendor | `07_buyout/{vendor}/po/` |
| Site photo | `09_site/photo/` |
| AWMAC report | `10_awmac/submissions/` |
| MSE certificate | `01_admin/certs/` |

## The Three Underscore Patterns

### `_source/` -- Working Pieces

Source pieces assembled into an issued document. Not for distribution.

```
01_admin/submittal/
|-- SUB-001_reception-desk.pdf        <- Issued document
+-- _source/
    +-- sub-001/
        |-- transmittal.pdf
        +-- sd-1.0-reception-desk.pdf
```

**Used in:** `01_admin/submittal/`, `10_awmac/`, `08_coordination/doors/`

### `_received/` -- External Documents As-Is

Documents from external parties, filed with their original naming. Do NOT rename.

```
01_admin/submittal/
|-- SUB-001_reception-desk.pdf        <- What you sent
+-- _received/
    +-- FM-SD-Package-1-Reviewed.pdf   <- Their approval, their name
```

**Used in:** `01_admin/rfi/`, `01_admin/submittal/`, `01_admin/ccn/`, `01_admin/change-order/`, `01_admin/specifications/`, `07_buyout/{vendor}/`, `08_coordination/doors/`, `10_awmac/`

### `_template/` -- Blank, Unsigned Forms

Reusable form templates. Never signed. On use: Save-As, swap trade->job code and template->date.

**Used in:** `01_admin/rfi/`, `01_admin/submittal/`, `01_admin/transmittal/`, `10_awmac/`

## Revision Control

### Revision Notation

| Notation | Meaning |
|----------|---------|
| R0 | Original issue (first release) |
| R1 | First revision |
| R2+ | Subsequent revisions |
| RA, RB | Letter notation if GC requires it |

Increment revision any time a drawing is reissued to an external party or shop floor.

### CAD File Organization

Working files in `03_cad/working/` -- no rev/date in filename. OneDrive version history tracks versions.

Archived files in `03_cad/archive/` -- dated when archived (e.g., `netflix-cabinets-20260126.dwg`).

### Revision History

```
04_drawings/revision/{drawing-id}/
|-- r0_2025-02-05.dwg
|-- r0_2025-02-05.pdf
|-- r1_2025-11-15.dwg
|-- r1_2025-11-15.pdf
+-- revision-log.json
```

**Never delete superseded files.** Move to `04_drawings/revision/{drawing-id}/`.

## README System

V8.0 deploys `_README.txt` files to folders that benefit from filing guidance. Each answers: "What goes here? What doesn't? Example filenames."

- Plain text, deployed by CLI during `create-project`, `fix`, or `deploy-readmes`
- Content defined in `ProjectTemplate.cs` (single source of truth)
- Not every folder gets one -- only where filing decisions aren't obvious
- 29 folders have descriptions out of ~129 total
- Idempotent: safe to run multiple times, existing READMEs skipped unless `--force`

## Anti-Patterns

| Bad | Why | Correct |
|-----|-----|---------|
| `PDFs/` folder | File type is redundant | `04_drawings/production/` |
| Vendor names as top-level folders | Use buyout structure | `07_buyout/{vendor}/` |
| `MISC/` or `OTHER/` | File properly | Use correct folder |
| Person names as folders | Not document-type | Use correct category |
| Loose files at project root | Root is inbox | File immediately |
| Status in filename | Status is metadata | Track in Cambium |
| Skip specification pipeline | Loses negotiation trail | Received -> Negotiated -> Resolved |
| Working IFC in `00_contract/drawings/` | Contract originals are immutable | `04_drawings/ifc-working/` |
| Extra subfolders under `10_awmac/` | Only 5 allowed | Use existing structure |
| Pre-FO cutlists in `03_cad/working/` | Cutlists are production, not CAD | `_fo/staging/` |
| Renaming received documents | Breaks traceability | Keep original names |
| Powdercoating at root of samples/materials | It's a finish | `finish/powdercoating/` |

## CLI Tool Commands

**Tool Location:** `C:\Dev\Dejavara\Cambium\folder_organizer\Cambium.FolderOrganizer.Cli\`

All migration/fix/deploy commands default to **dry-run**. Use `--execute` to apply.

| Command | Purpose | Flags |
|---------|---------|-------|
| `create-project <name>` | Create new V8.0 project | `--base`, `--job-number`, `--name-only` |
| `migrate <path>` | Migrate to latest version (auto-detects source) | `--execute` |
| `deploy-readmes <path>` | Deploy `_README.txt` files | `--execute`, `--force` |
| `create-fo <number>` | Create Factory Order folder at `C:\FO\` | `--base`, `--copy-templates` |
| `validate <path>` | Check structure compliance | -- |
| `fix <path>` | Create missing folders + READMEs | `--execute` |
| `info` | Show configuration and paths | -- |

### Common Workflows

**New project:**
```bash
cd C:\Dev\Dejavara\Cambium\folder_organizer\Cambium.FolderOrganizer.Cli
dotnet run -- create-project "2501_Harbourside-D5"
dotnet run -- validate "C:\Projects\2501_Harbourside-D5"
dotnet run -- create-fo 16001 --copy-templates
```

**Retrofit READMEs:**
```bash
dotnet run -- deploy-readmes "C:\Projects\{project}" --execute
```

**Fix broken structure:**
```bash
dotnet run -- validate "C:\Projects\{project}"
dotnet run -- fix "C:\Projects\{project}" --execute
```

### Migration Paths

- V6.0 -> V6.1 (direct)
- V6.1 -> V7.0 (16 steps)
- V7.x -> V8.0 (17 steps)

V8 migration removes `07_production/` (contents to `_fo/staging/`, `04_drawings/install/`, `C:\FO\{FO#}\`), moves powdercoating under `finish/`, renames `ifc/` to `ifc-working/`, renames `agreement/` to `agreement_scope/`, renumbers 08-11 to 07-10, deploys READMEs.

If `07_production/` is non-empty after automated moves, migration pauses and generates `_cambium/migration-v8-audit.txt` for manual resolution.

## Factory Order Structure

**Location:** `C:\FO\{fo-number}\` (FO number only, no description)

```
C:\FO\{fo-number}\
|-- Shops/                          <- G-code output
|-- {fo-number}.R41                 <- ARDIS program
|-- {fo-number}.xls                 <- Parts list
|-- {fo-number}.csv                 <- Cut list
+-- (template files: .MCH, .STD, .STK, .EDG)
```

FO file naming: bare FO number, NO `FO` prefix inside `C:\FO\`:
- CORRECT: `15961.R41`, `15961.csv`
- WRONG: `FO15961.R41`

## Version History

V8.0.0 supersedes V7.1.1 (2026-02-28). Key changes:
- `07_production/` removed (contents redistributed)
- `_fo/staging/` added for pre-FO cutlists
- `powdercoating/` moved under `finish/` in both samples and materials
- `ifc/` renamed to `ifc-working/`
- `agreement/` renamed to `agreement_scope/`
- Folders renumbered: 08->07, 09->08, 10->09, 11->10
- `_README.txt` system introduced
- Total: 11 numbered (00-10) + 4 system = 15 folders

**Source:** Feature Millwork Documentation Standards v8.0.0
