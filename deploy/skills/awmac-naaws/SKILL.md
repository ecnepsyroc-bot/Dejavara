---
name: awmac-naaws
description: "AWMAC/NAAWS architectural woodwork standards reference for Canadian millwork. Use when: (1) Specifying grades (Custom/Premium), (2) Creating shop drawings or material listings, (3) Veneer matching specifications, (4) GIS inspection requirements, (5) Understanding tolerances, (6) Wall paneling documentation, (7) Casework standards, (8) Any reference to AWMAC, NAAWS, AWI, or architectural woodwork quality grades."
---

# AWMAC/NAAWS Architectural Woodwork Standards

Reference for the North American Architectural Woodwork Standards (NAAWS 4.0), maintained by AWMAC (Canada) and the Woodwork Institute. The definitive standard for Canadian architectural woodwork projects.

## Quick Reference

| Topic | Section |
|-------|---------|
| Lumber | NAAWS Section 03 |
| Sheet Products/Veneer | NAAWS Section 04 |
| Finishing | NAAWS Section 05 |
| Millwork | NAAWS Section 06 |
| Stairwork & Rails | NAAWS Section 07 |
| Wall/Ceiling Surfacing | NAAWS Section 08 |
| Wood Doors | NAAWS Section 09 |
| Casework | NAAWS Section 10 |
| Countertops | NAAWS Section 11 |
| Historic Restoration | NAAWS Section 12 |
| Care & Storage | NAAWS Section 13 |
| Installation | NAAWS Section 14 |
| Tolerances | NAAWS Section 15 |

---

## Grades

AWMAC uses two grades (NAAWS adds Economy for completeness but it's rarely specified):

### Custom Grade (Default)
- Specified for high-quality architectural woodwork
- Provides well-defined control over materials, workmanship, and installation
- Default grade if none specified
- Covers most commercial millwork projects

### Premium Grade
- Highest level of quality, materials, workmanship, and installation
- Reserved for high-profile areas: reception, boardrooms, executive areas
- Requires explicit specification of all veneer matching
- Viewing distance: 39" (1000mm) vs 48" (1220mm) for Custom

### Grade Selection by Area

| Area Type | Typical Grade |
|-----------|---------------|
| Mechanical rooms, utility | Economy (rarely specified) |
| General office, corridors | Custom |
| Reception, boardrooms, executive | Premium |

---

## Surface Categories

Understanding surface visibility determines material requirements:

### Exposed Exterior
Surfaces visible from outside the building (rare in millwork)

### Exposed Interior
Surfaces visible during normal building use:
- Door/drawer fronts
- Cabinet sides in open view
- Visible shelving
- Wall paneling faces

### Semi-Exposed
Surfaces visible only when doors/drawers open:
- Interior cabinet sides
- Shelf undersides
- Drawer sides
- Interior backs (behind doors)

### Concealed
Never visible during normal use:
- Cabinet backs against walls
- Bottoms of base cabinets
- Structural components

---

## Veneer Specifications

For Premium grade, all veneer specifications must be explicitly stated. See `references/VENEER.md` for complete details.

### Slicing Methods (Materials Cut)
- **Plain/Flat sliced** - Cathedral grain, most common
- **Quarter sliced** - Straight grain, stripes
- **Rift cut** - Comb grain, minimal fleck (oak)
- **Rotary** - Full sheet, plywood appearance

### Leaf Matching (Between Adjacent Leaves)
- **Book match** - Mirrored at joint (default for plain sliced)
- **Slip match** - Repeated pattern (default for quarter/rift)
- **Random** - No matching

### Panel Matching (Layout Within Panel)
- **Running match** - Economical, asymmetric (Economy default)
- **Balance match** - Equal width leaves, may trim outer
- **Center balance match** - Symmetrical with center joint

### Assembly Matching (Between Panels in Room)
- **Blueprint match** - Panels assigned to specific locations
- **Sequence match** - Numbered panels, install in order
- **Warehouse match** - Random from batch

### Standard Note Block for Premium Veneer

```
VENEER SPECIFICATIONS
Species: [White Oak / Walnut / etc.]
Materials Cut: [Plain sliced / Quarter sliced / Rift / Rotary]
Leaf Match: [Book / Slip / Random]
Panel Match: [Running / Balance / Center balance]
Assembly Match: [Blueprint / Sequence / Warehouse]
```

---

## Shop Drawing Requirements

### Required Information (All Grades)

1. **Project identification** - Name, number, location
2. **Grade** - Custom or Premium per area
3. **Species** - All wood species specified
4. **Construction type** - Frameless, face frame, etc.
5. **Door/drawer interface** - Overlay, inset, reveal
6. **Hardware** - Hinges, slides, pulls (with manufacturer)
7. **Finish** - Type, sheen, color codes

### Premium Grade Additional Requirements

1. **Veneer specifications** - All four matching types
2. **Flitch/bundle numbers** - Track material source
3. **Panel sequence** - Numbering for assembly match
4. **Grain direction** - Arrows on all panels

### Wall Panel Elevation Labeling

For wall paneling at Premium grade:

```
Each panel shows:
├── Panel ID (WP-01, WP-02, etc.) in bubble
├── Grain direction arrow
├── Flitch/bundle reference (FLT-2/B-3)
└── Sequence number (filled circle)
```

Include panel schedule with:
- Panel ID
- Dimensions (W x H)
- Flitch/bundle
- Install sequence

---

## GIS (Guarantee and Inspection Service)

AWMAC's quality assurance program with three-step inspection:

### Step 1: Shop Drawing Review
- Inspector verifies compliance with NAAWS
- Checks materials, joinery, finishing specifications
- Notes deviations from architectural drawings

### Step 2: Sample Unit Inspection (if specified)
- Physical inspection at shop or site
- Verifies construction matches approved drawings

### Step 3: Final Inspection
- On-site verification of installed work
- Tolerances per Section 15
- Two-year guarantee issued upon compliance

### GIS Specification Language

```
Architectural woodwork shall comply with NAAWS 4.0 
[Custom/Premium] grade. AWMAC Guarantee and Inspection 
Service (GIS) is required. Shop drawings shall be 
submitted to AWMAC Chapter office for review prior 
to fabrication.
```

---

## Installation Tolerances (Section 15)

### Casework Installation
- Level: ±1/8" (3mm) in 96" (2440mm)
- Plumb: ±1/8" (3mm) in 96" (2440mm)
- Adjacent units flush: ±1/16" (1.5mm)

### Wall Surfacing
- Panel joints: ±1/32" (0.8mm) gap
- Panel alignment: ±1/16" (1.5mm) in 96"
- Reveal consistency: ±1/32" (0.8mm)

### Site Conditions Required
- Temperature: 65-75°F (18-24°C)
- Humidity: 25-55% RH
- HVAC operational 7+ days before install

### Viewing Distance for Defects
- Premium: 39" (1000mm)
- Custom: 48" (1220mm)

---

## Material Listings / Cover Sheet Data

Standard AWMAC project cover sheet includes:

### Section Checkboxes (NAAWS 03-14)
Mark which sections apply to project scope

### Contact Information
- Design Professional
- General Contractor
- Millwork Manufacturer
- Installer (if different)
- Finisher (if different)

### Specifications by Room/Area
For each room, specify:
- **Exposed surfaces** - Species, grade, cut
- **Semi-exposed** - Material (melamine, HPL, veneer)
- **Concealed** - Material
- **Core** - Particleboard, MDF, plywood
- **Edge banding** - PVC, wood, HPL
- **Hardware** - Manufacturer, series, finish
- **Finish** - Type, sheen, color

---

## Common Specification Codes

### Finish Types
- **WD** - Wood (transparent finish)
- **PL** - Plastic Laminate
- **PT** - Paint
- **SS** - Solid Surface
- **GL** - Glass

### Hardware References
- **Manufacturer-Series-Finish** format
- Example: BLUM-CLIP-NI (Blum Clip Top, Nickel)

### Typical Badge Format
```
[TYPE]-[NUMBER]
WD-1    Wood finish specification 1
PL-2    Plastic laminate spec 2
MT-103  Hardware/fixture item 103
```

---

## Key Differences: AWMAC vs AWI

| Aspect | AWMAC/NAAWS | AWI |
|--------|-------------|-----|
| Region | Canada, California | US (primarily) |
| Grades | Custom, Premium | Economy, Custom, Premium |
| Format | Numeric sections | ANSI standards |
| Testing | Specification-based | Performance-based (lab tested) |
| Certification | GIS program | QCP program |
| Units | Metric/Imperial dual | Metric first |

**In Canada, always reference NAAWS unless project specifically requires AWI.**

---

## References

For detailed information:
- `references/VENEER.md` - Complete veneer matching specifications
- `references/CASEWORK.md` - Section 10 casework details
- `references/TOLERANCES.md` - Section 15 tolerance tables

## External Resources

- NAAWS 4.0 Manual: https://naaws.com (free PDF download)
- AWMAC GIS: https://awmac.com/gis/
- Guide Specifications: https://awmac.com/gis/guide-specifications/
