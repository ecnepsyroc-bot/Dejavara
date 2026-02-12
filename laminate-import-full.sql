INSERT INTO laminates (id, manufacturer, code, name, finish, sheets_on_hand, min_stock, location, stock_status, notes, is_active, category, dimensions, created_at, updated_at) VALUES
(gen_random_uuid(), 'Unknown', 'LEGNO-122', 'Legno 122', NULL, 1, 0, 'Rack', 'in_stock', NULL, true, 'COLOURED', '5x12', NOW(), NOW()),
(gen_random_uuid(), 'Unknown', 'GREEN-SLATE', 'Green Slate', NULL, 2, 0, 'Rack', 'in_stock', NULL, true, 'COLOURED', '5x12', NOW(), NOW()),
(gen_random_uuid(), 'Unknown', 'EBONY-REZON', 'Ebony Rezon', NULL, 1, 0, 'Rack', 'in_stock', NULL, true, 'METAL', '4x8', NOW(), NOW()),
(gen_random_uuid(), 'Unknown', 'BRONZE-ALUM', 'Bronze Aluminum', NULL, 1, 0, 'Rack', 'in_stock', NULL, true, 'METAL', '4x8', NOW(), NOW()),
(gen_random_uuid(), 'Unknown', 'CHEVRON', 'Chevron', NULL, 7, 0, 'Rack', 'in_stock', NULL, true, 'METAL', '4x8', NOW(), NOW()),
(gen_random_uuid(), 'Formica', 'FORM-BRUSHED-ALUM', 'Formica Brushed Aluminum', NULL, 1, 0, 'Rack', 'in_stock', NULL, true, 'METAL', '4x8', NOW(), NOW());
