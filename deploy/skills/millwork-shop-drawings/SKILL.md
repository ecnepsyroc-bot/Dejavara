---
name: millwork-shop-drawings
description: "Architectural millwork shop drawing conventions for cabinet construction details, section views, and orthographic projections. Use when creating cabinet/casework drawings, construction details, joinery diagrams, or any technical illustration showing how millwork components fit together. Triggers include: shop drawings, cabinet sections, dado joints, rabbet joints, construction details, orthographic views, plan/elevation/section views, or casework documentation."
---

# Millwork Shop Drawing Conventions

Technical drawing standards for architectural millwork and cabinet construction documentation.

## Line Types and Their Meanings

| Line Type | Appearance | Use |
|-----------|------------|-----|
| **Solid (white/black)** | Continuous | Visible edges, cut surfaces, outlines |
| **Dashed (hidden)** | Short dashes (1/8" with 1/16" gaps) | Hidden edges, elements behind/below visible surfaces |
| **Center line** | Long-short-long dash pattern | Symmetry axes, hole centers |
| **Dimension** | Thin solid with oblique ticks (45° slashes) | Measurements |

### Critical Rule: Dashed Lines
Dashed lines show what EXISTS but is NOT VISIBLE in the current view:
- In PLAN view: Elements below the cut plane (cabinets under countertop)
- In SECTION view: Grooves cut INTO material (dados), elements behind the visible piece
- In ELEVATION view: Hidden internal structure

## Orthographic Projection (Third Angle)

Standard view arrangement for North American shop drawings:

```
┌─────────────┐
│    PLAN     │  (looking down)
│  (top view) │
└─────────────┘
┌─────────────┬─────────────┐
│  ELEVATION  │   SECTION   │
│ (front view)│ (cut-through)│
└─────────────┴─────────────┘
```

### View Alignment Rules
- Plan and elevation align VERTICALLY (same width)
- Elevation and section align HORIZONTALLY (same height)
- Construction lines project between views

## Section View Conventions

A section view is a CUT-THROUGH showing internal structure.

### What to Show in Section Views
1. **Cut material** — Solid lines for the piece being sectioned
2. **Joinery cuts** — Dashed lines for dados/rabbets (grooves cut INTO material)
3. **Mating pieces** — Solid outlines for pieces that sit IN the grooves
4. **Hidden elements** — Dashed lines for pieces behind the section plane

### Cabinet Section Example (HTV-HBD Construction)

Looking at a gable (side panel) from inside the cabinet:

```
Section View Structure:
├── White solid rectangle = gable outline (the piece being viewed)
├── Dashed horizontal lines INSIDE gable = dado grooves (cuts into gable)
├── Small white rectangles at top/bottom = horizontal panels in dados
│   (these extend PAST the gable on both sides)
└── Dashed vertical at back = back panel (behind gable)
```

Key insight: The dado is a GROOVE - it's recessed into the material, so it appears as dashed lines. The panel that SITS IN the dado is solid because it's a physical piece.

## Joinery Representation

### Dado Joint (groove across grain)
- The dado itself: Dashed parallel lines (it's a cut INTO the material)
- The piece sitting in dado: Solid rectangle

### Rabbet Joint (L-shaped notch on edge)
- The rabbet cut: Shown as step in the outline
- Back panel in rabbet: Dashed (behind the gable)

### Half-Blind Dado
- Stops before front edge (hidden from front view)
- Still shown as dashed lines in section

## Plan View Conventions

Plan view = looking DOWN at the cabinet.

### What Appears Solid vs Dashed
- **Top/bottom panels**: Solid (you see them directly)
- **Gables sitting in dados**: Dashed (hidden under the top panel)
- **Fasteners (brads)**: Solid lines indicating direction of penetration

## Color Conventions (AutoCAD Model Space)

| Color | Use |
|-------|-----|
| White | Visible edges, primary geometry |
| Magenta/Purple | Hidden lines (dashed) |
| Green | Fasteners, brad nails, hardware |
| Cyan | Dimensions, annotations |
| Yellow | Center lines |

## Common Mistakes to Avoid

1. **Drawing dados as solid lines** — Dados are grooves, show as dashed
2. **Not extending horizontal panels past gables** — In HTV construction, horizontals wrap OVER gables
3. **Misaligning views** — Plan width = elevation width
4. **Forgetting back panel** — Always show as dashed in section (it's behind the gable)
5. **Wrong line weights** — Cut edges heavier than projection lines

## Reference Standards

- AWI (Architectural Woodwork Institute) Standards
- ASME Y14.2 Line Conventions
- Third Angle Projection (North American standard)

For detailed joinery specifications, see `references/joinery-types.md`.
For cabinet construction nomenclature, see `references/construction-codes.md`.
