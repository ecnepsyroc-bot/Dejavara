---
name: quickbooks-contractor-invoicing
description: QuickBooks Online setup and invoicing workflow for Canadian contractors billing clients for labor and reimbursable expenses. Use when setting up QBO for contractor work, creating invoice templates, configuring products/services, managing GST/PST tax codes in BC, handling tax-inclusive pricing, or establishing a two-invoice system (labor vs expenses). Covers custom invoice numbering, billable expenses, and Canadian sales tax compliance.
---

# QuickBooks Online Contractor Invoicing (Canada/BC)

Setup and workflow guide for contractors billing clients with separate labor and expense invoices.

## Two-Invoice System Overview

Split billing into two invoice types for cleaner accounting:

| Invoice Type | Contents | Tax Handling |
|--------------|----------|--------------|
| **Labor (L)** | Install Hours, Office Hours | GST only (services exempt from PST in BC) |
| **Expenses (E)** | Mileage, Parking, Materials | Mixed: some GST-only, some tax-inclusive pass-through |

Benefits: Cleaner GL mapping for client, easier receipt attachment, clearer tax handling.

## Initial Setup Checklist

### 1. Enable Required Settings

**Settings → Account and Settings → Sales:**
- Turn ON: Custom transaction numbers
- Turn ON: Service date (for date column on invoices)

**Settings → Account and Settings → Expenses:**
- Turn ON: Track expenses and items by customer
- Turn ON: Make expenses and items billable (if Plus/Advanced)

**Settings → Account and Settings → Advanced → Tax:**
- Verify GST/PST is configured for BC

### 2. Configure Tax Codes

Navigate to: **Taxes → Sales Tax → Manage sales tax**

Required tax codes for BC contractors:

| Code | Rate | Use For |
|------|------|---------|
| GST | 5% | Services (labor), mileage |
| GST/PST (BC) | 12% | Taxable goods if applicable |
| Zero-rated | 0% | Pass-through materials (tax already paid) |
| Exempt | 0% | Non-taxable items |

**Tax-Inclusive Pricing:**
- Set at the product/service level when creating items
- QBO back-calculates: $25 inclusive = $23.81 + $1.19 GST
- The invoice TAX column shows the tax *code*, not inclusive/exclusive status

### 3. Create Products & Services

Navigate to: **Settings → Products and Services → New**

#### Labor Items (Invoice L)

| Name | Rate | Tax | Notes |
|------|------|-----|-------|
| Install Hours | $45.00/hr | GST | On-site work |
| Office Hours | $38.00/hr | GST | PM, drafting, coordination |

#### Expense Items (Invoice E)

| Name | Rate | Tax | Inclusive? | Notes |
|------|------|-----|------------|-------|
| Travel Mileage | $0.69/km | GST | No | CRA rate for BC |
| Parking | — | GST | **YES** | Receipts are tax-inclusive |
| Materials Purchased | — | Zero-rated | N/A | Pass-through, tax already paid |
| Material (PST Inclusive) | — | GST | **YES** | When you paid GST+PST, bill GST only |

**Creating a Tax-Inclusive Item:**
1. New → Service (or Non-inventory)
2. Enter name and description
3. Check "Inclusive of tax" checkbox
4. Select appropriate tax code
5. Save

### 4. Create Invoice Templates

Navigate to: **Settings → Custom form styles → New style → Invoice**

#### Template A: Labor Invoice
- Name: "Labor Invoice"
- Columns: Date, Service, Description, Qty, Rate, Amount
- Optional: Hide Tax column (all items are GST anyway)
- Clean, minimal layout

#### Template B: Expenses Invoice
- Name: "Expenses Invoice"  
- Columns: Date, Service, Description, Tax, Qty, Rate, Amount
- Keep Tax column visible
- Consider wider Description for receipt references

**Set Default:** Click dropdown next to template → Make default

### 5. Invoice Numbering Convention

Format options:
- `YYYY-MM-DD-L1` / `YYYY-MM-DD-E1` (Labor/Expenses)
- `2026-01-07-L1` / `2026-01-07-E1`

Or simpler:
- `INV-001-L` / `INV-001-E`

**To set sequence:**
1. Settings → Account and Settings → Sales
2. Enable Custom transaction numbers
3. Create first invoice with desired number
4. QBO continues sequence automatically

## Daily Invoicing Workflow

### Creating a Labor Invoice

1. **+ New → Invoice**
2. Select customer (Feature Millwork)
3. Set Invoice # with L suffix: `2026-01-07-L1`
4. Select "Labor Invoice" template
5. Add line items:
   - Date | Install Hours | "Work completed onsite [location]" | Qty | Rate
   - Date | Office Hours | "Site visit to [project]" | Qty | Rate
6. Review GST calculation at bottom
7. Save and send

### Creating an Expenses Invoice

1. **+ New → Invoice**
2. Same customer
3. Set Invoice # with E suffix: `2026-01-07-E1`
4. Select "Expenses Invoice" template
5. Add line items with clear descriptions:
   - Parking: "Parking [location] - receipt attached"
   - Mileage: "Billable km traveled [origin to destination]"
   - Materials: "Total cost GST/PST inclusive [vendor] invoice"
6. Verify tax calculations
7. Save and send

### Tax-Inclusive Line Items

When entering parking or materials where you paid tax-inclusive:

1. Select the tax-inclusive product/service item
2. Enter the **total amount you paid** (e.g., $25.00)
3. QBO automatically calculates: Base $23.81 + GST $1.19 = $25.00
4. Your client pays $25.00, you collected correct GST

**Verify:** Check tax summary before saving—GST should match expected amount.

## Common Tax Scenarios

### Scenario 1: Parking Receipt ($25 tax-inclusive)
- Item: Parking (GST, inclusive)
- Amount: $25.00
- Result: $23.81 + $1.19 GST = $25.00

### Scenario 2: Materials from Supplier (You paid GST+PST)
- Item: Materials Purchased (Zero-rated)
- Amount: $130.07 (exact invoice total)
- Result: Pass-through, no additional tax
- Description: "Total cost GST/PST inclusive [vendor] invoice"

### Scenario 3: Materials - Reimburse GST Only
When you paid GST+PST but client only reimburses GST:
- Item: Material (PST Inclusive) - GST, inclusive
- Amount: $202.45
- Result: QBO calculates GST portion, you absorb PST
- Note: Clarify with accountant if this is correct approach

### Scenario 4: Travel Mileage
- Item: Travel Mileage (GST, not inclusive)
- Qty: 100 km
- Rate: $0.69
- Result: $69.00 + $3.45 GST = $72.45

## Troubleshooting

**Tax column shows "GST" for everything:**
Normal behavior. The column shows tax *code assigned*, not inclusive/exclusive status. Verify calculations in tax summary.

**Invoice numbers not incrementing:**
1. Clear browser cache
2. Verify Custom transaction numbers is ON
3. Create a test invoice with desired number, save, then continue

**Template not applying:**
QBO uses "sticky" mode—last template used applies to next invoice. Manually select template, save, and it remembers.

**Tax-inclusive not calculating correctly:**
1. Edit the product/service item
2. Verify "Inclusive of tax" is checked
3. Verify correct tax code is selected
4. Re-add item to invoice

## Reference Files

- [TAX-CODES.md](references/TAX-CODES.md) - Complete BC tax code reference
- [INVOICE-CHECKLIST.md](references/INVOICE-CHECKLIST.md) - Quick reference for invoicing
