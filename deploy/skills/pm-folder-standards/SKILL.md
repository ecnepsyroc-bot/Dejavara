---
name: pm-folder-standards
description: "Reference for legacy folder structures used by Feature Millwork PMs (Steve, Sean, Patrick, John). Use when navigating non-Cambium projects, migrating files to Cambium structure, or looking up where a specific document type lives in a legacy project. Triggers include: legacy project, Steve's project, Sean's project, Patrick's project, find file in old structure, migration, folder mapping, old server, pre-cambium, translate folder."
---

# PM Folder Standards

Legacy folder conventions used by Feature Millwork project managers. Use this to navigate, search, and migrate non-Cambium projects.

## PM Project Ownership

| PM | Projects |
|----|----------|
| **Cory** (Cambium) | Dentons, ESDC, Netflix, Oakridge-b6, Oakridge-b7, Smith-and-farrow, Sunlife (data on old server) |
| **Sean** | 3410 Marpole Avenue, Cactus Club Houston, Cactus Club Miami, Cactus Club Miami Beach, King Taps Lonsdale, Kings Tap - Park Place, Bellano, RBC GAM, Hue, WC Fishing Lodge |
| **Steve** | Canaccord 1133, WCFC, YVR 21N, Raymond James |
| **Patrick** | Disney, EVR, Cirnac, Harbourside-Lot D, PWC-5th Floor, PWC-7th Floor |
| **John** | Shape Properties (with Sean, Cory, Ardis contributing) |

## Steve's Pattern

**Projects:** Canaccord 1133, WCFC, YVR 21N, Raymond James

Most consistent of the legacy PMs. Same template across all projects.

```
{project}/
├── FO/                       ← Factory orders
├── PO/                       ← Purchase orders
├── TRANSMITTAL/              ← Transmittals
├── SPEC/                     ← Specifications
├── PDF SHOP DWG/             ← Production drawings (PDFs)
├── REVIEWED SHOP DWG/        ← Approved/reviewed drawings
├── SI/                       ← Site instructions
├── SITE MEASURE/             ← Field measurements
├── SITE PICTURE/             ← Site photos
├── IFC/                      ← Issued for construction
├── CONTRACT DUCUMENT/        ← Contract docs (note: typo)
├── SAMPLES/                  ← Physical samples
├── RFIs/                     ← Requests for information
├── CCNs/                     ← Contractor change notices
└── *.dwg, *.bak (at root)   ← Working CAD files kept loose
```

**Identifying markers:**
- Singular nouns (FO, PO, TRANSMITTAL, SPEC)
- `PDF SHOP DWG` / `REVIEWED SHOP DWG` (spaces in folder names)
- `CONTRACT DUCUMENT` typo (carried across projects)
- DWG/BAK files loose at project root for quick access
- Person-named subfolders when collaborating: `STEVE DWG`, `GARRY`

## Sean's Pattern

**Projects:** 3410 Marpole, CC Houston, CC Miami, CC Miami Beach, King Taps (both), Bellano, RBC GAM, Hue, WC Fishing Lodge

Most projects (10) but least consistency. Style evolved across three eras:

### Early Sean (Marpole, King Taps)
Identical to Steve's template, including the `CONTRACT DUCUMENT` typo.

```
FO/, PO/, TRANSMITTAL/, SPEC/, PDF SHOP DWG/,
REVIEWED SHOP DWG/, SI/, SITE MEASURE/, CONTRACT DUCUMENT/
```

### Mid Sean (Cactus Club Houston)
Shifted to plural FOs/POs but kept some singular. New typo introduced.

```
FOs/, POs/, SPEC/, TRANSMITTAL/, PDF SHOP DWG/,
REVIWED SHOP DWG/ (note: typo), CONTRACT DOCUMENT/ (fixed)
```

### Late Sean (Cactus Club Miami)
Adopted Patrick's plural trailing-'s' convention.

```
FOs/, POs/, PDFs/, SHOPs/, SPECs/, TRANSMITTALs/,
REVIEWED/, SITE MEASURES/, architecturals/
```

### Bellano (outlier)
Uses SCREAMING_SNAKE convention — possibly the original Feature Millwork standard.

```
FACTORY_ORDER/, PURCHASE_ORDER/, SITE_MEASURE/,
REQUEST_FOR_INFORMATION/, CONTRACTOR_DOCS_RECEIVED/
```

**Identifying markers:**
- Check which era by looking for plural/singular mix
- Scope-specific subfolders inside FOs on large projects (e.g., `BAFFLES OPTIMIZING/`, `VESTIBULE OPTIMIZING/`)

## Patrick's Pattern

**Projects:** Disney, EVR, Cirnac, Harbourside-Lot D, PWC-5th Floor, PWC-7th Floor

Second most consistent after Steve.

```
{project}/
├── ARCHITECTURALs/           ← Architectural drawings received
├── FOs/                      ← Factory orders
├── POs/                      ← Purchase orders
├── PDFs/                     ← Production drawing PDFs
├── SHOPs/                    ← Shop drawings
├── SPECs/                    ← Specifications
├── TRANSMITTALs/             ← Transmittals
├── REVIEWED/                 ← Approved/reviewed drawings
├── RFIs/                     ← Requests for information
├── FILE/                     ← Miscellaneous reference docs
├── SITE MEASURES/            ← Field measurements
└── PCN/ or PCNs/             ← Proposed Change Notices (not CCN)
```

**Identifying markers:**
- Plural with trailing lowercase 's': `FOs/`, `POs/`, `TRANSMITTALs/`
- `REVIEWED` (not `REVIEWED SHOP DWG`)
- `FILE` folder for misc reference
- `PCN`/`PCNs` instead of `CCN` ("Proposed Change Notice")
- Scope-based subfolders on large projects (Harbourside: D1-D4, CEILING SLATS, ENTRY SURROUNDS)

## Multi-PM Projects

| Project | Lead | Contributors | Person Folders |
|---------|------|-------------|----------------|
| Canaccord 1133 | Steve | Cory, Garry | `STEVE DWG`, `CORY - NUMBERED DRW`, `GARRY` |
| Shape Properties | John | Sean, Cory, Ardis | `SEAN`, `Cory`, `Ardis` |
| Cactus Club Miami | Sean | — | `SEAN` |
| Harbourside-Lot D | Patrick | Steve | `Steve` |

**Rule:** Person-named folders are personal workspaces, NOT document categories. Contents map to the PM's own folder convention.

## Known Typo Registry

| Typo | Correct Cambium Folder | Found In |
|------|----------------------|----------|
| `CONTRACT DUCUMENT` | `00-contract/` | Steve (Canaccord, WCFC), Sean (Marpole) |
| `REVIWED SHOP DWG` | `04-drawings/approved/` | Sean (CC Houston) |
| `APPROVEDF DWG & SAMPLES` | `04-drawings/approved/` | Patrick (PWC-5th) |
| `SITE MEASUER` | `10-site/measure/` | Patrick (PWC-5th) |
| `SITE MEASUERMENT` | `10-site/measure/` | Patrick (Harbourside) |

## Translation Table: Legacy to Cambium

### Factory Orders / Production

| Legacy Folder Name | Cambium Equivalent | Notes |
|---|---|---|
| `FO/`, `FOs/`, `FACTORY_ORDER/` | `07-production/` | Production docs, cut lists |
| `PDF SHOP DWG/`, `PDFs/`, `SHOPs/` | `04-drawings/production/` | Final issued shop drawings |
| `REVIEWED SHOP DWG/`, `REVIWED SHOP DWG/`, `REVIEWED/`, `APPROVEDF DWG & SAMPLES` | `04-drawings/approved/` | Returned with approval stamp |
| `IFC/`, `IFT/` | `04-drawings/ifc/` | Architect's issued sets |

### Administration

| Legacy Folder Name | Cambium Equivalent | Notes |
|---|---|---|
| `PO/`, `POs/`, `PURCHASE_ORDER/` | `08-buyout/` | Vendor POs and coordination |
| `TRANSMITTAL/`, `TRANSMITTALs/`, `Transmittals/` | `01-admin/transmittal/` | |
| `RFI/`, `RFIs/`, `REQUEST_FOR_INFORMATION/` | `01-admin/rfi/` | |
| `SI/` | `01-admin/site-instruction/` | |
| `CCN/`, `CCNs/`, `PCN/`, `PCNs/` | `01-admin/change-order/` | Patrick uses PCN for same concept |
| `SAMPLES/` | `06-samples/` | |

### Contract / Specs

| Legacy Folder Name | Cambium Equivalent | Notes |
|---|---|---|
| `SPEC/`, `SPECs/`, `Specs/` | `00-contract/specifications/` | Or root `00-contract/` |
| `CONTRACT DUCUMENT/`, `CONTRACT DOCUMENT/`, `CONTRACTOR_DOCS_RECEIVED/` | `00-contract/` | |
| `ARCHITECTURALs/` | `00-contract/drawings/` | Architect's drawings received |

### Site

| Legacy Folder Name | Cambium Equivalent | Notes |
|---|---|---|
| `SITE MEASURE/`, `SITE MEASURES/`, `SITE_MEASURE/`, `SITE MEASUER/`, `SITE MEASUERMENT/` | `10-site/measure/` | |
| `SITE PICTURE/` | `10-site/photo/` | |

### Misc

| Legacy Folder Name | Cambium Equivalent | Notes |
|---|---|---|
| `FILE/` | Triage needed | Patrick's catch-all. Contents vary — inspect individually |
| Root DWGs/BAKs | `03-cad/working/` | Steve keeps these at root intentionally |
| Person-named folders | Triage needed | Map contents by document type, not by person |
| Scope-based folders (D1, D2, BAFFLES, etc.) | `07-production/{fo-scope}/` | Production scope splits |

## Migration Notes

- **Dry-run first** — always preview before copying
- **Copy, never move** — preserve original structure until migration is verified
- **`_received/` rule applies** — external docs keep original filenames
- **Root DWGs** — route to `03-cad/working/` (Steve's habit)
- **Person folders** — contents must be individually categorized, not bulk-moved
- **`FILE/` folder** — Patrick's misc folder requires manual inspection
- **Scope folders** — map to `07-production/` subfolders based on FO context
