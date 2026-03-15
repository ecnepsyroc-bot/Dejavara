@echo off
setlocal enabledelayedexpansion

set LOG=C:\tmp\sync-log.txt
set DUMP=C:\tmp\cambium-backup.dump
set RAILWAY_HOST=trolley.proxy.rlwy.net
set RAILWAY_PORT=44567
set RAILWAY_USER=cambium_sync
set RAILWAY_DB=railway
REM Railway password — set via environment variable or .env file
REM Check Railway dashboard if password has rotated: https://railway.app
if not defined RAILWAY_PASS (
    echo ERROR: RAILWAY_PASS environment variable not set. >> %LOG%
    echo Set it with: set RAILWAY_PASS=your_password_from_railway_dashboard
    exit /b 1
)
set PG_BIN=C:\Program Files\PostgreSQL\18\bin

echo ============================================== >> %LOG%
echo %date% %time% - Starting sync >> %LOG%

REM ============================================
REM PHASE 1: Dump from cambium-server (PG 16)
REM ============================================
set PGPASSWORD=shop_password
echo %date% %time% - Dumping from cambium-server... >> %LOG%
"%PG_BIN%\pg_dump" -U shop_user -p 5432 -d cambium -Fc -f %DUMP% 2>> %LOG%
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - pg_dump FAILED with exit code !ERRORLEVEL! >> %LOG%
    exit /b 1
)
echo %date% %time% - Dump completed successfully >> %LOG%

REM ============================================
REM PHASE 2: Prepare Railway (drop and recreate schema)
REM ============================================
set PGPASSWORD=%RAILWAY_PASS%
echo %date% %time% - Preparing Railway schema... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -c "REVOKE CONNECT ON DATABASE railway FROM PUBLIC; SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'railway' AND pid <> pg_backend_pid(); DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >> %LOG% 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %date% %time% - Schema prep FAILED >> %LOG%
    exit /b 1
)

REM ============================================
REM PHASE 3: Restore in sections (correct ordering)
REM ============================================
echo %date% %time% - Restoring pre-data (tables, types)... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=pre-data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

echo %date% %time% - Restoring data... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

REM ============================================
REM PHASE 3b: Create PKs manually (workaround for FK ordering)
REM All 69 tables referenced by FKs need PKs before post-data
REM ============================================
echo %date% %time% - Creating primary keys for FK-referenced tables... >> %LOG%

REM Build SQL file line by line (Windows batch parentheses are unreliable)
set PKSQL=C:\tmp\create-pks.sql
if exist %PKSQL% del %PKSQL%
echo ALTER TABLE "AreaMaterialListings" ADD CONSTRAINT "PK_AreaMaterialListings" PRIMARY KEY ("Id"); >> %PKSQL%
echo ALTER TABLE "GisCoverPages" ADD CONSTRAINT "PK_GisCoverPages" PRIMARY KEY ("Id"); >> %PKSQL%
echo ALTER TABLE addresses ADD CONSTRAINT "PK_addresses" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE ai_output_drafts ADD CONSTRAINT "PK_ai_output_drafts" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE architect_profiles ADD CONSTRAINT "PK_architect_profiles" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE badge_categories ADD CONSTRAINT "PK_badge_categories" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_areas ADD CONSTRAINT "PK_bom_areas" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_documents ADD CONSTRAINT "PK_bom_documents" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_materials ADD CONSTRAINT "PK_bom_materials" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_projects ADD CONSTRAINT "PK_bom_projects" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_users ADD CONSTRAINT "PK_bom_users" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE bom_vendors ADD CONSTRAINT "PK_bom_vendors" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE clients ADD CONSTRAINT "PK_clients" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE contract_document_types ADD CONSTRAINT "PK_contract_document_types" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE contract_documents ADD CONSTRAINT "PK_contract_documents" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE cross_trade_contacts ADD CONSTRAINT "PK_cross_trade_contacts" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE cutting_materials ADD CONSTRAINT "PK_cutting_materials" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE cutting_projects ADD CONSTRAINT "PK_cutting_projects" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE directory_contacts ADD CONSTRAINT "PK_directory_contacts" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE document_slot_types ADD CONSTRAINT "PK_document_slot_types" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE door_hardware_groups ADD CONSTRAINT "PK_door_hardware_groups" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE drawing_checkouts ADD CONSTRAINT "PK_drawing_checkouts" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE drawing_note_templates ADD CONSTRAINT "PK_drawing_note_templates" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE drawing_series ADD CONSTRAINT "PK_drawing_series" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE drawing_sets ADD CONSTRAINT "PK_drawing_sets" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE drawings ADD CONSTRAINT "PK_drawings" PRIMARY KEY (drawing_id); >> %PKSQL%
echo ALTER TABLE factory_orders ADD CONSTRAINT "PK_factory_orders" PRIMARY KEY (fo_id); >> %PKSQL%
echo ALTER TABLE hardware ADD CONSTRAINT "PK_hardware" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE hardware_categories ADD CONSTRAINT "PK_hardware_categories" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE individual_chats ADD CONSTRAINT "PK_individual_chats" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE installation_schedules ADD CONSTRAINT "PK_installation_schedules" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE item_types ADD CONSTRAINT "PK_item_types" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_areas ADD CONSTRAINT "PK_job_areas" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_badges ADD CONSTRAINT "PK_job_badges" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_ceilings ADD CONSTRAINT "PK_job_ceilings" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_floors ADD CONSTRAINT "PK_job_floors" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_organization_links ADD CONSTRAINT "PK_job_organization_links" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_rooms ADD CONSTRAINT "PK_job_rooms" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_submissions ADD CONSTRAINT "PK_job_submissions" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_walls ADD CONSTRAINT "PK_job_walls" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE job_zones ADD CONSTRAINT "PK_job_zones" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE jobs ADD CONSTRAINT "PK_jobs" PRIMARY KEY (job_id); >> %PKSQL%
echo ALTER TABLE laminate_brands ADD CONSTRAINT "laminate_brands_pkey" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE laminates ADD CONSTRAINT "PK_laminates" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE material_categories ADD CONSTRAINT "PK_material_categories" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE materials ADD CONSTRAINT "PK_materials" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE millwork_finishes ADD CONSTRAINT "PK_millwork_finishes" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE millwork_items ADD CONSTRAINT "PK_millwork_items" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE organizations ADD CONSTRAINT "PK_organizations" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE parts ADD CONSTRAINT "PK_parts" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE product_library ADD CONSTRAINT "PK_product_library" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE products ADD CONSTRAINT "PK_products" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE project_intake_sessions ADD CONSTRAINT "PK_project_intake_sessions" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE project_rooms ADD CONSTRAINT "PK_project_rooms" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE projects ADD CONSTRAINT "PK_projects" PRIMARY KEY (project_id); >> %PKSQL%
echo ALTER TABLE purchase_orders ADD CONSTRAINT "PK_purchase_orders" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE purchasing_materials ADD CONSTRAINT "PK_purchasing_materials" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE quotes ADD CONSTRAINT "PK_quotes" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE room_drawings ADD CONSTRAINT "PK_room_drawings" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE samples ADD CONSTRAINT "PK_samples" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE site_visits ADD CONSTRAINT "PK_site_visits" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE source_documents ADD CONSTRAINT "PK_source_documents" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE staging_files ADD CONSTRAINT "PK_staging_files" PRIMARY KEY ("Id"); >> %PKSQL%
echo ALTER TABLE subassemblies ADD CONSTRAINT "PK_subassemblies" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE subcategories ADD CONSTRAINT "PK_subcategories" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE trade_types ADD CONSTRAINT "PK_trade_types" PRIMARY KEY (id); >> %PKSQL%
echo ALTER TABLE users ADD CONSTRAINT "PK_users" PRIMARY KEY (user_id); >> %PKSQL%
echo ALTER TABLE vendors ADD CONSTRAINT "PK_vendors" PRIMARY KEY (vendor_id); >> %PKSQL%
echo ALTER TABLE work_orders ADD CONSTRAINT "PK_work_orders" PRIMARY KEY (id); >> %PKSQL%

"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -f %PKSQL% >> %LOG% 2>&1
echo %date% %time% - Primary keys created (69 tables) >> %LOG%

echo %date% %time% - Restoring post-data (indexes, constraints)... >> %LOG%
"%PG_BIN%\pg_restore" --no-owner --no-privileges --section=post-data -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% %DUMP% 2>> %LOG%

REM Note: pg_restore returns non-zero for warnings, so we dont fail on it

REM ============================================
REM PHASE 4: Re-enable connections
REM ============================================
echo %date% %time% - Re-enabling connections... >> %LOG%
"%PG_BIN%\psql" -h %RAILWAY_HOST% -p %RAILWAY_PORT% -U %RAILWAY_USER% -d %RAILWAY_DB% -c "GRANT CONNECT ON DATABASE railway TO PUBLIC;" >> %LOG% 2>&1

echo %date% %time% - Sync completed >> %LOG%
exit /b 0
