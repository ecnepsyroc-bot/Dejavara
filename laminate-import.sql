-- Laminate Inventory Import - From handwritten scan dated July 24, 2025
-- Run against Railway PostgreSQL (cambium-production)

-- WHITE Category
INSERT INTO laminates (id, manufacturer, code, name, finish, sheets_on_hand, min_stock, location, stock_status, notes, is_active, category, dimensions, created_at, updated_at)
VALUES
-- Page 1 - WHITE (Left column)
(gen_random_uuid(), ''Unknown'', ''CRYSTAL-WHITE'', ''Crystal White'', NULL, 1, 0, ''Rack'', ''in_stock'', ''Imported from July 2025 scan'', true, ''WHITE'', ''4x8'', NOW(), NOW()),
(gen_random_uuid(), ''Unknown'', ''WINTER-WHITE-5x12'', ''Winter White'', NULL, 1, 0, ''Rack'', ''in_stock'', NULL, true, ''WHITE'', ''5x12'', NOW(), NOW());
