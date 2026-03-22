-- 1. Расчет LTV и порядковый номер покупки
WITH clean_sales AS (
    SELECT 
        o.user_id, o.order_date, (p.price * o.quantity) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY o.user_id ORDER BY o.order_date) AS purchase_seq
    FROM Orders o
    JOIN Products p ON o.product_id = p.product_id
    WHERE o.status = 'Completed'
)
SELECT 
    user_id, 
    SUM(revenue) AS total_ltv,
    MAX(purchase_seq) AS total_orders
FROM clean_sales
GROUP BY user_id
ORDER BY total_ltv DESC;

-- 2. Рейтинг категорий по прибыльности (DENSE_RANK)
SELECT 
    p.category, 
    SUM(p.price * o.quantity) AS total_profit,
    DENSE_RANK() OVER(ORDER BY SUM(p.price * o.quantity) DESC) AS category_rank
FROM Orders o
JOIN Products p ON o.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY p.category;

-- 3. Когортный анализ (Retention Rate)
WITH user_cohorts AS (
    SELECT user_id, order_date,
           MIN(order_date) OVER(PARTITION BY user_id) AS first_buy
    FROM Orders WHERE status = 'Completed'
),
cohort_logic AS (
    SELECT user_id,
           DATE_TRUNC('month', first_buy) AS cohort_month,
           EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', order_date), DATE_TRUNC('month', first_buy))) * 12 
+ EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', order_date), DATE_TRUNC('month', first_buy))) 
AS month_number
    FROM user_cohorts
)
SELECT 
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_number = 0 THEN user_id END) AS m0_acquired,
    COUNT(DISTINCT CASE WHEN month_number = 1 THEN user_id END) AS m1_retention,
    COUNT(DISTINCT CASE WHEN month_number = 2 THEN user_id END) AS m2_retention
FROM cohort_logic
GROUP BY cohort_month
ORDER BY cohort_month;

-- 4. Running Total (Нарастающий итог выручки по дням)
-- Позволяет увидеть динамику роста бизнеса и общую накопленную сумму на любую дату
SELECT 
    order_date,
    SUM(p.price * o.quantity) AS daily_revenue,
    ROUND(SUM(SUM(p.price * o.quantity)) OVER (ORDER BY order_date)::numeric) AS running_total_revenue
FROM Orders o
JOIN Products p ON o.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY order_date
ORDER BY order_date;

-- 5. Price Difference (Анализ ценового позиционирования)
-- Показывает, насколько цена конкретного товара отклоняется от средней в его категории
SELECT 
    product_id,
    category,
    price,
    -- Округляем среднюю цену по категории до 2 знаков
    ROUND(AVG(price) OVER(PARTITION BY category)::numeric, 2) AS avg_category_price,   
    -- Вычисляем разницу и также приводим к чистому виду
    ROUND((price - AVG(price) OVER(PARTITION BY category))::numeric, 2) AS price_diff
FROM Products
ORDER BY category, price_diff DESC;