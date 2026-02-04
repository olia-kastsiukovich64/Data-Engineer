CREATE TABLE promocodes (
    promo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    discount_percent INTEGER CHECK(discount_percent BETWEEN 1 AND 100),
    valid_from DATE,
    valid_to DATE,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_by INTEGER,
    FOREIGN KEY (created_by) REFERENCES users(id)
);
INSERT INTO promocodes (code, discount_percent, valid_from, valid_to, max_uses, used_count, is_active, created_by) VALUES
('SPRING5', 5, '2026-01-01', '2026-03-31', 10, 0, 1, 1),
('SUMMER10', 10, '2026-04-01', '2026-06-30', NULL, 0, 1, 1),
('AUTUMN15', 15, '2025-09-01', '2025-11-30', 5, 3, 1, 2),
('WINTER20', 20, '2026-01-01', '2026-02-15', NULL, 1, 1, 3),
('FESTIVE25', 25, '2025-11-01', '2025-12-31', 0, 0, 1, 1),
('NEWYEAR30', 30, '2025-12-01', '2026-01-02', 20, 15, 1, 2),
('VALENTINE35', 35, '2026-02-01', '2026-02-14', NULL, 0, 1, 4),
('SPRING40', 40, '2026-03-01', '2026-03-31', 3, 1, 1, 1),
('SUMMER50', 50, '2026-06-01', '2026-08-31', NULL, 0, 1, 3),
('FALL45', 45, '2026-01-01', '2026-01-15', 5, 2, 0, 2);

SELECT * FROM promocodes

SELECT
    COUNT(*) AS total_promocodes,
    AVG(discount_percent) AS avg_discount,
    COUNT (CASE WHEN is_active = 1 THEN 1 END) AS active_promocodes
FROM promocodes;

SELECT
    CASE 
        WHEN discount_percent BETWEEN 1 AND 10 THEN '1-10%'
        WHEN discount_percent BETWEEN 11 AND 20 THEN '11-20%'
        WHEN discount_percent BETWEEN 21 AND 30 THEN '21-30%'
        WHEN discount_percent BETWEEN 31 AND 40 THEN '31-40%'
        WHEN discount_percent BETWEEN 41 AND 50 THEN '41-50%'
    END AS discount_group,
    COUNT(*) AS promo_count,
    MIN(discount_percent) AS min_discount,
    MAX(discount_percent) AS max_discount,
    COUNT(CASE WHEN max_uses IS NOT NULL THEN 1 END) AS limited_uses
FROM promocodes
GROUP BY discount_group
