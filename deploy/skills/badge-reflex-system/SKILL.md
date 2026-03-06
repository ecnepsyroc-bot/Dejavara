---
name: badge-reflex-system
description: "Smart badge system for millwork drawings in AutoCAD, managed via the Luxify Toolbar. Badges identify finishes, fixtures, equipment, and procurement items. Use when working on badge creation, badge palettes, badge attributes, or badge detection. Triggers include badge shapes (ellipse/diamond/rectangle/star), finish codes (PL/PT/WV), fixture codes (SS/ST/GL), equipment codes (APPL/EQ), or discussions of the 100-clicks-to-3 workflow."
---

# Smart Badge System

AutoCAD automation for smart badges in millwork drawings, managed via the Luxify Toolbar. Goal: reduce 100+ clicks to 3.

> **Note:** "Badge Reflex" is the conceptual name for the detection/response behavior. The user-facing tool is the Luxify Toolbar.

## Badge Taxonomy

| Shape | Category | Examples | Purpose |
|-------|----------|----------|---------|
| Ellipse | FINISH | PL (Plastic Laminate), PT (Paint), WV (Wood Veneer), GL (Glass Laminate) | Surface materials, treatments |
| Diamond | FIXTURE | SS (Solid Surface), ST (Stone), GL (Glass) | Built items, hardware, architectural profiles |
| Rectangle | EQUIPMENT | APPL (Appliances), EQ (Equipment) | Appliances, machinery, electrical |
| 8-Point Star | BUYOUT | — | Procurement items, fabricated by other trades |
| Triangle | PROVENANCE | — | Authorization tracking, change source |

## Badge Code Structure

```
[PREFIX][SUFFIX]
   │       │
   │       └── Number (1, 2, 3...)
   └── Category code (PL, PT, SS, APPL...)

Examples: PL1, PT2, SS1, APPL1, WV3
```

## Excel Data Structure

```
| Category  | Prefix | Suffix | Description          | Manufacturer | Material |
|-----------|--------|--------|----------------------|--------------|----------|
| FINISH    | PL     | 1      | Plastic Laminate     | Formica      | P-123    |
| FINISH    | PT     | 2      | Paint - Satin White  | Benjamin M   | OC-17    |
| FIXTURE   | SS     | 1      | Solid Surface        | Corian       | Glacier  |
| EQUIPMENT | APPL   | 1      | Refrigerator         | Sub-Zero     | 648PRO   |
```

## Placement Workflow

```
1. Arrow placed (points to item)
      ↓
2. Line extends (specific length)
      ↓
3. Badge attaches (at end of line)

Sequence: Arrow → Line → Badge
```

## Tool Palette Organization

- **Job-based palettes** (one per job, not per project)
- Multiple projects exist within a job
- Load via command line or select from library by job name
- Contains all badges for that specific job

## Smart Block Requirements

- Text displays as `PREFIX + SUFFIX` (e.g., "PL1")
- Shape wraps text, auto-sizing
- Leader line with arrow at specific length
- Attributes store full specification data

## Block Attributes

```
BADGE_CODE      → "PL1"
CATEGORY        → "FINISH"
DESCRIPTION     → "Plastic Laminate"
MANUFACTURER    → "Formica"
MATERIAL        → "P-123"
PROVENANCE_FLAG → "ORIGINAL" | "MODIFIED"
AVAILABILITY    → "IN_STOCK" | "LEAD_TIME"
```

## C# Badge Manager Pattern

```csharp
// Domain: Badge logic only
public class BadgeManager
{
    private readonly BadgeDbContext _db;

    public async Task<Badge> CreateBadge(string category, string prefix, int suffix)
    {
        var shape = category switch
        {
            "FINISH" => BadgeShape.Ellipse,
            "FIXTURE" => BadgeShape.Diamond,
            "EQUIPMENT" => BadgeShape.Rectangle,
            "BUYOUT" => BadgeShape.Star,
            _ => throw new ArgumentException($"Unknown category: {category}")
        };

        return new Badge
        {
            Code = $"{prefix}{suffix}",
            Category = category,
            Shape = shape
        };
    }

    public async Task RefreshBadgesInDrawing()
    {
        // Loop through all block references
        // Identify badges by block name
        // Read BADGE_CODE attribute
        // Fetch current spec from API
        // Update attributes
    }
}

// Adapter: Orchestrates badge creation within a job context
public class BadgeJobAdapter
{
    private readonly BadgeManager _badges;
    private readonly JobManager _jobs;

    public async Task<Badge> CreateBadgeForJob(string jobNumber, BadgeCreateDto dto)
    {
        var job = await _jobs.GetJob(jobNumber);
        if (job == null) throw new InvalidOperationException();

        dto.JobId = job.Id;
        return await _badges.CreateBadge(dto.Category, dto.Prefix, dto.Suffix);
    }
}
```

## Cambium API Integration

```
GET /api/jobs/{jobNumber}/badges/{code}

Response:
{
    "code": "PL1",
    "category": "FINISH",
    "description": "Plastic Laminate",
    "manufacturer": "Formica",
    "material": "P-123",
    "specification": { ... }
}
```

## Viewport Badge Detection

Separate system that runs BEFORE plotting:
1. Find all viewports on PLOT_FRAME_PS layer
2. Detect badges within each viewport boundary
3. Compile legend data
4. Validate all badges accounted for

## Legend Generation

After viewport detection:
1. Deduplicate badges by code
2. Look up full spec (shorthand) from badge-data
3. Sort by category, then code
4. Generate legend block

## Architecture Mapping

```
domain/badge-core/        → Badge types, shapes, validation
domain/excel-sync/        → Excel read/write
adapters/badge-to-job/    → Links badges to job data
adapters/badge-to-api/    → Cambium API sync
ports/events/             → badge-created, badge-updated
ui/palette/               → WPF tool palette
```

## Commands

| Command | Purpose |
|---------|---------|
| `BADGEPALETTE` | Open job-specific badge palette |
| `REFRESHBADGES` | Sync all badges with Cambium |
| `DETECTBADGES` | Find badges in viewports |
| `CREATELEGEND` | Generate badge legend |
