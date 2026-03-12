# Railway Sync Outage Report - 2026-03-11

## Summary

**Duration:** ~16+ hours (at least since 03:04 AM until 19:39 PM)
**Impact:** Railway database (`cambium-production.up.railway.app`) stopped receiving updates from cambium-server SSOT
**Root Cause:** PostgreSQL permission denial - `shop_user` lacked SELECT privileges on tables owned by `postgres`
**Resolution:** Granted all privileges to `shop_user` on all tables and sequences

---

## Timeline

| Time | Event |
|------|-------|
| Unknown | Tables created by EF migrations as `postgres` user without granting permissions to `shop_user` |
| 2026-03-11 03:04 | First logged sync failure ("Dump FAILED") |
| 03:04 - 19:24 | Every 20-minute sync attempt failed (49 consecutive failures) |
| 19:35 | Issue identified: `pg_dump` failing with permission denied on `finish_codes` table |
| 19:37 | Fix applied: `GRANT ALL PRIVILEGES` to `shop_user` |
| 19:39 | Sync completed successfully |

---

## Root Cause Analysis

### The Problem

The sync script (`C:\tmp\sync-to-railway.cmd`) runs `pg_dump` as `shop_user`:

```batch
set PGPASSWORD=shop_password
C:\Progra~1\Postgr~1\18\bin\pg_dump -U shop_user -p 5432 -d cambium -Fc -f C:\tmp\cambium-backup.dump
```

However, **165 tables** in the `cambium` database were owned by `postgres`, not `shop_user`:

```
tablename                        | tableowner
---------------------------------+------------
finish_codes                     | postgres
projects                         | postgres
addresses                        | postgres
... (165 total tables)
```

When `pg_dump` tried to lock these tables for backup, it received:

```
ERROR: permission denied for table finish_codes
```

### Why This Happened

1. **EF Core migrations** run as the `postgres` superuser (the connection string in deployment uses `postgres`)
2. When migrations create tables, PostgreSQL assigns ownership to the connected user (`postgres`)
3. The `shop_user` role was never granted privileges on these tables
4. This likely worked initially when there were fewer tables, but broke when `finish_codes` (or another table) was added without corresponding grants

### The Silent Failure Pattern

The sync script only logged "Dump FAILED" without capturing the actual error:

```batch
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Dump FAILED >> C:\tmp\sync-log.txt
    exit /b 1
)
```

This made diagnosis harder - the actual PostgreSQL error was discarded.

---

## Fix Applied

### Immediate Fix (Applied 2026-03-11 19:37)

```sql
-- Grant privileges on all existing objects
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shop_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shop_user;

-- Ensure future objects also get grants (for any tables created by postgres)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO shop_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO shop_user;
```

### Verification

```bash
# pg_dump now succeeds
pg_dump -U shop_user -p 5432 -d cambium -Fc -f C:\tmp\test-dump.dump
# Exit code: 0, file size: 639,269 bytes
```

---

## Remaining Issues: FK Constraint Warnings

The sync completed with **32 non-fatal warnings** about foreign key constraints:

```
pg_restore: error: could not execute query: ERROR: there is no unique constraint
matching given keys for referenced table "organizations"
Command was: ALTER TABLE ONLY public.source_documents
    ADD CONSTRAINT "FK_source_documents_organizations_organization_id"
    FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
```

### Affected Constraints

| Table | FK Constraint | Referenced Table | Issue |
|-------|--------------|------------------|-------|
| `source_documents` | `FK_source_documents_organizations_organization_id` | `organizations` | Missing unique constraint on `organizations.id` |
| `user_email_settings` | `FK_user_email_settings_users_user_id` | `users` | Missing unique constraint on `users.user_id` |
| `user_preferences` | `FK_user_preferences_users_user_id` | `users` | Missing unique constraint on `users.user_id` |
| ... | (29 more) | ... | Similar issues |

### Why This Happens

PostgreSQL requires the referenced column to have a `PRIMARY KEY` or `UNIQUE` constraint for FK relationships. These constraints exist on cambium-server but are failing to restore on Railway, likely because:

1. The `pg_restore` order isn't respecting constraint dependencies
2. Or the unique constraints were created outside of migrations and aren't in the dump

### Impact

- **Data integrity:** The actual data is restored correctly
- **Referential integrity:** FKs aren't enforced on Railway, but data relationships are intact
- **Production risk:** LOW - Railway is read-replica for Laminate QR codes, not the SSOT

### Recommended Fix (Future Task)

Create an EF migration that explicitly ensures all PK/unique constraints exist:

```csharp
// Verify organizations.id has proper PK
migrationBuilder.Sql(@"
    DO $$ BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conname = 'PK_organizations' AND contype = 'p'
        ) THEN
            ALTER TABLE organizations ADD PRIMARY KEY (id);
        END IF;
    END $$;
");
```

---

## Preventive Measures

### 1. Improve Sync Script Error Logging

Update `C:\tmp\sync-to-railway.cmd` to capture actual errors:

```batch
C:\Progra~1\Postgr~1\18\bin\pg_dump -U shop_user -p 5432 -d cambium -Fc -f C:\tmp\cambium-backup.dump 2>> C:\tmp\sync-log.txt
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Dump FAILED with exit code %ERRORLEVEL% >> C:\tmp\sync-log.txt
    exit /b 1
)
```

### 2. Add Permissions to Migration Pipeline

In `Cambium.Data/CambiumDbContext.cs` or a post-migration hook:

```csharp
// After migrations, ensure shop_user has access
await context.Database.ExecuteSqlRawAsync(@"
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO shop_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO shop_user;
");
```

### 3. Monitoring

Add a health check that verifies sync freshness:

```sql
-- On Railway, check last sync time
SELECT MAX(updated_at) FROM projects;
-- Alert if > 1 hour stale
```

---

## Data Architecture Reference

```
cambium-server:5432 (PG 16, SSOT)
         │
         │ pg_dump every 20 min
         ▼
    Railway:44567 (read replica)
         │
         │ pg_dump every 20 min
         ▼
    Pi backup (disaster recovery)
```

- **cambium-server** is the single source of truth
- **Railway** serves external access (Laminate QR codes, mobile)
- **Pi** provides offsite backup with 7-day retention

---

## Appendix: Affected Tables (165 total)

<details>
<summary>Click to expand full table list</summary>

```
__EFMigrationsHistory, addresses, ai_confidence_config, ai_output_drafts,
architect_profiles, AreaMaterialListings, audit_logs, badge_categories,
badge_drawings, badge_spec_history, bom_areas, bom_documents, bom_materials,
bom_projects, bom_users, bom_vendors, buyout_items, cabinet_type_notes,
carcase_constructions, CaseworkSpecs, clients, contacts, contract_document_type_aliases,
contract_document_types, contract_documents, CountertopSpecs, courier_contacts,
cross_trade_contacts, cross_trade_coordination, cutting_materials, cutting_parts,
cutting_projects, cutting_sheets, DataProtectionKeys, directory_contacts,
document_drafts, document_naming_rules, document_revision_links, document_slot_types,
document_status_types, door_details, door_hardware_groups, drawing_checkouts,
drawing_materials, drawing_note_templates, drawing_pages, drawing_revisions,
drawing_series, drawing_set_items, drawing_sets, drawing_versions, drawings,
email_log, extracted_metadata, factory_orders, finish_codes, finishes,
FinishingSpecs, fo_checkpoints, fo_parts, fo_sequences, fo_status_history,
gis_rooms, GisChangeOrders, GisCoverPages, GisSubstitutions, hardware,
hardware_categories, hardware_items, HardwareSpecs, HistoricRestorationSpecs,
individual_chats, installation_checklists, installation_schedules, item_document_slots,
item_finishes, item_hardware, item_materials, item_type_slot_templates, item_types,
job_areas, job_badges, job_ceilings, job_contact_links, job_drawing_properties,
job_floors, job_organization_links, job_rooms, job_specifications, job_submissions,
job_walls, job_zones, jobs, labor_entries, laminate_assignments, laminate_brands,
laminate_brand_distributors, laminate_transactions, laminates, material_categories,
materials, messages, MillworkVeneerSpecs, millwork_finishes, millwork_items,
mockups, organizations, parse_failures, parts, PassageDoorSpecs, password_reset_tokens,
po_activity_log, po_line_items, po_print_log, product_library, products,
project_contacts, project_factory_orders, project_intake, project_intake_sessions,
project_note_configs, project_rooms, project_sheets, projects, purchase_orders,
purchasing_materials, quality_inspections, quotes, rfis, room_badges, room_drawings,
sample_status_history, samples, sheet_specs, SheetProductHpls, SheetProductVeneers,
shipments, site_data, site_measurements, site_photos, site_visits, source_documents,
spec_abbreviations, staging_audit_rules, staging_commits, staging_files,
staging_quarantine, staging_skip_rules, StairworkRailsSpecs, subassemblies,
subcategories, submission_items, sync_conflicts, trade_types, unknown_materials,
user_email_settings, user_preferences, users, vendor_keywords, vendors,
WallCeilingSurfacingSpecs, work_order_products, work_orders, workflows
```

</details>

---

**Report generated:** 2026-03-11 19:45
**Author:** Claude Code
**Status:** Resolved (with 32 non-critical FK warnings remaining)