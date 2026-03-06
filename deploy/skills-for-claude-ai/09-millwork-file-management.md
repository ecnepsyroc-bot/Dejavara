---
name: millwork-file-management
description: "File management system for millwork project managers. Covers folder structure creation, naming conventions, revision control, drawing organization, and inbox-to-archive workflows. Use when: creating project folders, naming files, organizing drawings, managing revisions, handling trade coordination documents, tracking samples/submittals, or discussing folder structure decisions. Triggers include: project template, folder structure, naming convention, revision, drawing organization, document management, AWMAC, AIA standard, inbox workflow, factory order, FO."
---

<!-- STATUS: PENDING UPDATE — This skill references v5.7.0. Current standard is V7.1.1.
     Missing V7.1.1 changes:
     - Two-digit view numbers (X.01 instead of X.0)
     - Fabrication suffix 'f' for shop-only drawings (e.g., X.00f)
     - 16 folders (12 numbered + 4 system: _fo, _cad_working, _archive, _cambium)
     - Underscores for numbered folders (00_contract, not 00-contract)
     - 05_samples/ extracted to root level (was 05-materials/00_samples/)
     - _cad_working junction → 03_cad/working
     - _fo/ folder for Factory Order index
     - DXF naming conventions ({FO#}-{qualifier}.dxf)
     - Global FO index at P:\Projects\_fo\
     - Transmittal type (Pattern #12)
     DO NOT use this skill for V7.1.1 decisions until updated. -->

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
{jobnumber}-{jobname}/                      <- INBOX: unsorted = action needed NOW
|
+-- 00-contract/
|   +-- addenda/
|   +-- agreement/
|   +-- drawings/                           <- Architect drawings (IFT, reference -- NOT IFC)
|   +-- insurance/
|   +-- specifications/
|
+-- 01-admin/
|   +-- ccn/
|   |   +-- _received/
|   +-- certs/                              <- AWMAC-MSE-Cert.pdf
|   +-- change-order/
|   |   +-- _received/
|   +-- close-out/
|   +-- deficiencies/
|   +-- email-disputes/
|   +-- field-notice/
|   +-- install/
|   +-- meeting-minutes/
|   +-- rfi/
|   |   +-- _received/
|   |   +-- _template/
|   +-- rfp/
|   +-- schedule/
|   +-- shipping/
|   +-- site-instruction/
|   +-- submittal/
|       +-- _source/
|       |   +-- sub-001/
|       +-- _received/
|       +-- _template/
|
+-- 02-financial/
|   +-- budget/
|   +-- invoices/
|   +-- po-log/
|   +-- progress-claims/
|
+-- 03-cad/
|   +-- archive/
|   +-- as-built/
|   +-- coordination/
|   +-- library/
|   +-- working/                            <- Active .dwg files (always current)
|
+-- 04-drawings/
|   +-- approved/
|   +-- as-built/
|   +-- buyout/
|   +-- ifc/                                <- IFC sets from architects (DON'T rename)
|   +-- install/
|   +-- production/
|   +-- revision/
|       +-- {drawing-id}/
|
+-- 05-materials/
|   +-- countertops/
|   +-- custom/
|   +-- doors/
|   +-- finish/
|   +-- glass/
|   +-- hardware/
|   +-- laminate/
|   +-- metals/
|   +-- powdercoating/
|   +-- sheet-goods/
|   +-- solid/
|   +-- takeoff/
|   +-- upholstery/
|   +-- veneer/
|
+-- 06-samples/                             <- Mirrors 05-materials structure
|
+-- 07-production/
|   +-- _fo-index.md                        <- Links FO numbers to C:\FO\ paths
|   +-- {jobname}-cutlist.xlsx              <- Working cutlist (pre-FO#)
|   +-- {fo-number}/
|
+-- 08-buyout/
|   +-- quotes/                             <- Pre-decision vendor comparison
|   +-- {vendor-name}/
|
+-- 09-coordination/
|   +-- custom/
|   +-- doors/
|   +-- drywall/
|   +-- electrical/
|   +-- glazing/
|   +-- hvac/
|   +-- mechanical/
|   +-- plumbing/
|
+-- 10-site/
|   +-- measure/
|   +-- photo/
|
+-- 11-awmac/
|   +-- submissions/
|   +-- qc/
|   +-- _source/
|   +-- _received/
|   +-- _template/
|
+-- _archive/
+-- _cambium/
```

## Job Number Format

**Pattern:** `YY##` (4-digit numeric)
- `YY` = 2-digit year
- `##` = 2-digit sequence

**Examples:**
- `2501-chambers` (first job of 2025)
- `2601-netflix-burbank` (first job of 2026)

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

## Document Type Codes

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

**AWMAC:**
| Code | Meaning | Folder Home |
|------|---------|-------------|
| `INSI` | Initial Inspection Request | `11-awmac/submissions/` |
| `INSF` | Final Inspection Request | `11-awmac/submissions/` |
| `HUM` | Humidity Report | `11-awmac/submissions/` |
| `GIS` | GIS Report | `11-awmac/_received/` |

## Factory Order Structure

**Location:** `C:\FO\{fo-number}\` (FO number only, no description)

```
C:\FO\{fo-number}\
+-- Shops/                          <- G-code output
+-- {fo-number}.pdf                 <- FO document
+-- {fo-number}.R41                 <- ARDIS program
+-- {fo-number}.xls                 <- Parts list (working)
+-- {fo-number}.csv                 <- Cut list (clean)
+-- {fo-number}_dirty.csv           <- Cut list (raw export)
+-- {fo-number}_plywoods.pdf        <- Plywood cutlist
+-- {fo-number}_solids.pdf          <- Solids cutlist
+-- {fo-number}_preglue.pdf         <- Preglue cutlist
+-- {fo-number}_layouts.pdf         <- Panel optimization
```

**FO file naming:** Use bare FO number, NO `FO` prefix inside `C:\FO\`.

## Revision Control

| Notation | Meaning |
|----------|---------|
| R0 | Original issue (first release) |
| R1 | First revision |
| R2+ | Subsequent revisions |

**When to increment:** Any time a drawing is REISSUED to an external party or shop floor after a previous issue.

**NEVER delete superseded files.** Move to revision folder or rename with `_SUPD` suffix.

## The Three Underscore Patterns

- **`_source/`** — Working pieces assembled into issued documents
- **`_received/`** — External documents filed as-is (keep original names)
- **`_template/`** — Blank, unsigned forms ready for use

## Philosophy

> **Folder structure is infrastructure, not a task.**

Once established, you don't think about it. Structure serves you -- you don't serve structure.
