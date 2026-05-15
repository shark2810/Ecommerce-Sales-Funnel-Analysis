
-- =====================================================
-- 1. DEFINING SALES FUNNEL STAGES AND COUNTING USERS
-- =====================================================

-- Bước 1: Với mỗi user, đánh dấu họ đã đạt bước nào (0 hoặc 1)
WITH funnel_stages AS (
  SELECT
    user_id,
    MAX(CASE WHEN event_type = 'page_view'      THEN 1 ELSE 0 END) AS reached_page_view,
    MAX(CASE WHEN event_type = 'add_to_cart'    THEN 1 ELSE 0 END) AS reached_add_to_cart,
    MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS reached_checkout,
    MAX(CASE WHEN event_type = 'payment_info'   THEN 1 ELSE 0 END) AS reached_payment,
    MAX(CASE WHEN event_type = 'purchase'       THEN 1 ELSE 0 END) AS reached_purchase
  FROM user_events
  GROUP BY user_id
),



-- Bước 2: Đếm tổng số user đạt mỗi bước
funnel_counts AS (
  SELECT
    SUM(reached_page_view)   AS cnt_page_view,
    SUM(reached_add_to_cart) AS cnt_add_to_cart,
    SUM(reached_checkout)    AS cnt_checkout,
    SUM(reached_payment)     AS cnt_payment,
    SUM(reached_purchase)    AS cnt_purchase
  FROM funnel_stages
)

-- Bước 3: Trình bày kết quả dạng bảng dọc + tỷ lệ
SELECT
  1                                                            AS stage_order,
  'page_view'                                                  AS stage,
  cnt_page_view                                                AS user_count,
  100.0                                                        AS pct_of_top,
  0                                                            AS users_dropped
FROM funnel_counts

UNION ALL SELECT
  2, 'add_to_cart',
  cnt_add_to_cart,
  ROUND(100.0 * cnt_add_to_cart    / cnt_page_view, 1),
  cnt_page_view   - cnt_add_to_cart
FROM funnel_counts

UNION ALL SELECT
  3, 'checkout_start',
  cnt_checkout,
  ROUND(100.0 * cnt_checkout       / cnt_page_view, 1),
  cnt_add_to_cart - cnt_checkout
FROM funnel_counts

UNION ALL SELECT
  4, 'payment_info',
  cnt_payment,
  ROUND(100.0 * cnt_payment        / cnt_page_view, 1),
  cnt_checkout    - cnt_payment
FROM funnel_counts

UNION ALL SELECT
  5, 'purchase',
  cnt_purchase,
  ROUND(100.0 * cnt_purchase       / cnt_page_view, 1),
  cnt_payment     - cnt_purchase
FROM funnel_counts

ORDER BY stage_order;

-- =====================================================
-- 2. DEFINING SALES FUNNEL STAGES AND COUNTING USERS
-- +
-- CALCULATING CONVERSION RATES IN SALES FUNNEL
-- =====================================================

WITH funnel_stages AS (
  SELECT
    user_id,
    MAX(CASE WHEN event_type = 'page_view'      THEN 1 ELSE 0 END) AS reached_page_view,
    MAX(CASE WHEN event_type = 'add_to_cart'    THEN 1 ELSE 0 END) AS reached_add_to_cart,
    MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS reached_checkout,
    MAX(CASE WHEN event_type = 'payment_info'   THEN 1 ELSE 0 END) AS reached_payment,
    MAX(CASE WHEN event_type = 'purchase'       THEN 1 ELSE 0 END) AS reached_purchase
  FROM user_events
  GROUP BY user_id
),

funnel_counts AS (
  SELECT
    SUM(reached_page_view)   AS cnt_page_view,
    SUM(reached_add_to_cart) AS cnt_add_to_cart,
    SUM(reached_checkout)    AS cnt_checkout,
    SUM(reached_payment)     AS cnt_payment,
    SUM(reached_purchase)    AS cnt_purchase
  FROM funnel_stages
)

SELECT
  stage_order,
  stage,
  user_count,
  pct_of_top,
  users_dropped,
  step_conversion_rate,
  overall_conversion_rate

  -- Chỉ thêm 2 cột mới này
  --step_conversion_rate
  --overall_conversion_rate

FROM (

  SELECT 1 AS stage_order, 'page_view' AS stage,
    cnt_page_view AS user_count,
    100.0 AS pct_of_top,
    0 AS users_dropped,
    NULL AS step_conversion_rate,
    100.0 AS overall_conversion_rate
  FROM funnel_counts

  UNION ALL SELECT 2, 'add_to_cart',
    cnt_add_to_cart,
    ROUND(100.0 * cnt_add_to_cart / cnt_page_view, 1),
    cnt_page_view - cnt_add_to_cart,
    ROUND(100.0 * cnt_add_to_cart / cnt_page_view, 1),   -- step = overall (bước đầu)
    ROUND(100.0 * cnt_add_to_cart / cnt_page_view, 1)
  FROM funnel_counts

  UNION ALL SELECT 3, 'checkout_start',
    cnt_checkout,
    ROUND(100.0 * cnt_checkout / cnt_page_view, 1),
    cnt_add_to_cart - cnt_checkout,
    ROUND(100.0 * cnt_checkout / cnt_add_to_cart, 1),    -- step: so với bước trước
    ROUND(100.0 * cnt_checkout / cnt_page_view, 1)       -- overall: so với đầu phễu
  FROM funnel_counts

  UNION ALL SELECT 4, 'payment_info',
    cnt_payment,
    ROUND(100.0 * cnt_payment / cnt_page_view, 1),
    cnt_checkout - cnt_payment,
    ROUND(100.0 * cnt_payment / cnt_checkout, 1),
    ROUND(100.0 * cnt_payment / cnt_page_view, 1)
  FROM funnel_counts

  UNION ALL SELECT 5, 'purchase',
    cnt_purchase,
    ROUND(100.0 * cnt_purchase / cnt_page_view, 1),
    cnt_payment - cnt_purchase,
    ROUND(100.0 * cnt_purchase / cnt_payment, 1),
    ROUND(100.0 * cnt_purchase / cnt_page_view, 1)
  FROM funnel_counts

) AS funnel_report 
ORDER BY stage_order;

-- =====================================================
-- 3. ANALYZING MARKETING CHANNELS AND TRAFFIC SOURCES
-- =====================================================

WITH channel_stats AS (
  SELECT
    traffic_source,

    -- Lượng: số user và số sự kiện
    COUNT(DISTINCT user_id)                                         AS total_users,
    COUNT(*)                                                        AS total_events,

    -- Đếm user đạt từng bước trong phễu
    COUNT(DISTINCT CASE WHEN event_type = 'page_view'
                        THEN user_id END)                          AS users_page_view,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'
                        THEN user_id END)                          AS users_add_to_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start'
                        THEN user_id END)                          AS users_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase'
                        THEN user_id END)                          AS users_purchased,

    -- Doanh thu
    ROUND(SUM(CASE WHEN event_type = 'purchase'
                   THEN amount ELSE 0 END), 2)                     AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)            AS total_orders,
    ROUND(AVG(CASE WHEN event_type = 'purchase'
                   THEN amount END), 2)                            AS avg_order_value

  FROM user_events
  GROUP BY traffic_source
)

SELECT
  traffic_source,

  -- Lượng
  total_users,
  total_events,

  -- Phễu theo kênh
  users_page_view,
  users_add_to_cart,
  users_purchased,

  -- Chất: conversion rate (view → purchase)
  ROUND(100.0 * users_purchased / NULLIF(users_page_view, 0), 1)  AS conversion_rate,

  -- Doanh thu
  total_revenue,
  total_orders,
  avg_order_value,

  -- Hiệu quả: doanh thu trung bình trên mỗi user (kể cả người không mua)
  ROUND(total_revenue / NULLIF(total_users, 0), 2)                AS revenue_per_user

FROM channel_stats
ORDER BY total_revenue DESC;

-- =====================================================
-- 4.TIME TO CONVERSION ANALYSIS
-- =====================================================

-- Bước 1: Lấy thời điểm từng bước của mỗi user, convert sang phút
WITH user_timestamps AS (

    SELECT
        user_id,

        MIN(CASE WHEN event_type = 'page_view'
                 THEN event_date END) AS time_page_view,

        MIN(CASE WHEN event_type = 'add_to_cart'
                 THEN event_date END) AS time_add_to_cart,

        MIN(CASE WHEN event_type = 'checkout_start'
                 THEN event_date END) AS time_checkout,

        MIN(CASE WHEN event_type = 'payment_info'
                 THEN event_date END) AS time_payment,

        MIN(CASE WHEN event_type = 'purchase'
                 THEN event_date END) AS time_purchase

    FROM user_events
    GROUP BY user_id
),

-- Bước 2: Tính thời gian giữa các bước (chỉ user đã đi đủ các bước)
conversion_times AS (

    SELECT
        user_id,

        -- phút từ view → cart
        DATEDIFF(
            MINUTE,
            time_page_view,
            time_add_to_cart
        ) AS mins_view_to_cart,

        -- phút từ cart → checkout
        DATEDIFF(
            MINUTE,
            time_add_to_cart,
            time_checkout
        ) AS mins_cart_to_checkout,

        -- phút từ checkout → payment
        DATEDIFF(
            MINUTE,
            time_checkout,
            time_payment
        ) AS mins_checkout_to_payment,

        -- phút từ payment → purchase
        DATEDIFF(
            MINUTE,
            time_payment,
            time_purchase
        ) AS mins_payment_to_purchase,

        -- tổng phút từ view → purchase
        DATEDIFF(
            MINUTE,
            time_page_view,
            time_purchase
        ) AS total_mins_to_purchase

    FROM user_timestamps

    WHERE time_purchase IS NOT NULL
),

-- Bước 3: Thống kê trung bình toàn hệ thống
summary AS (
  SELECT
    COUNT(*)                               AS total_buyers,
    ROUND(AVG(mins_view_to_cart),          2) AS avg_view_to_cart,
    ROUND(AVG(mins_cart_to_checkout),      2) AS avg_cart_to_checkout,
    ROUND(AVG(mins_checkout_to_payment),   2) AS avg_checkout_to_payment,
    ROUND(AVG(mins_payment_to_purchase),   2) AS avg_payment_to_purchase,
    ROUND(AVG(total_mins_to_purchase),     2) AS avg_total_mins,
    ROUND(MIN(total_mins_to_purchase),     2) AS fastest_purchase,
    ROUND(MAX(total_mins_to_purchase),     2) AS slowest_purchase
  FROM conversion_times
)

-- Kết quả 1: Chi tiết từng user đã mua
SELECT
  'detail'                    AS result_type,
  user_id,
  mins_view_to_cart,
  mins_cart_to_checkout,
  mins_checkout_to_payment,
  mins_payment_to_purchase,
  total_mins_to_purchase
FROM conversion_times

UNION ALL

-- Kết quả 2: Tổng hợp trung bình
SELECT
  'average',
  NULL,
  avg_view_to_cart,
  avg_cart_to_checkout,
  avg_checkout_to_payment,
  avg_payment_to_purchase,
  avg_total_mins
FROM summary

ORDER BY result_type DESC, total_mins_to_purchase;