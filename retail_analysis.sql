-- === 1. DATA PREPARATION ===

-- Create the raw data table
CREATE TABLE retail_sales_raw (
    invoice_no VARCHAR,
    stock_code VARCHAR,
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC,
    customer_id INTEGER,
    country TEXT
);


-- Create the analytical sales table
CREATE TABLE retail_sales (
    invoice_no VARCHAR,
    stock_code VARCHAR,
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(12,2),
    customer_id INTEGER,
    country TEXT,
    revenue NUMERIC(12,2)
);


INSERT INTO retail_sales (
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    revenue
)
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    quantity * unit_price AS revenue
FROM (
    SELECT DISTINCT
        invoice_no,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country
    FROM retail_sales_raw
) AS unique_sales;


-- === 2. SALES OVERVIEW === 

-- Calculate basic sales KPIs
SELECT
    SUM(revenue) AS gross_revenue,
    SUM(quantity) AS total_quantity_sold,
    COUNT(DISTINCT invoice_no) AS number_of_transactions,
    COUNT(DISTINCT customer_id) AS paying_customers
FROM retail_sales
WHERE quantity > 0
  AND unit_price > 0;


-- Calculate additional sales KPIs
WITH sales_metrics AS (
    SELECT
        SUM(revenue) AS gross_revenue,
        SUM(quantity) AS total_quantity_sold,
        COUNT(DISTINCT invoice_no) AS number_of_transactions,
        COUNT(DISTINCT customer_id) AS paying_customers
    FROM retail_sales
    WHERE quantity > 0
      AND unit_price > 0
)
SELECT
    ROUND(gross_revenue / number_of_transactions, 2) AS aov,
    ROUND(gross_revenue / paying_customers, 2) AS arppu,
    ROUND(number_of_transactions::NUMERIC / paying_customers, 2) AS purchase_frequency,
    ROUND(total_quantity_sold::NUMERIC / number_of_transactions, 2) AS items_per_order
FROM sales_metrics;


-- Calculate gross revenue, returns and net revenue
SELECT
    SUM(CASE
        WHEN quantity > 0 AND unit_price > 0
        THEN revenue
        ELSE 0
    END) AS gross_revenue,

    ABS(SUM(CASE
        WHEN revenue < 0
        THEN revenue
        ELSE 0
    END)) AS returns,

    SUM(revenue) AS net_revenue
FROM retail_sales;


-- === 3. SALES OVER TIME ===

-- Monthly performance
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        COUNT(DISTINCT invoice_no) AS transactions,
        SUM(revenue) AS gross_revenue
    FROM retail_sales
    WHERE quantity > 0
      AND unit_price > 0
      AND invoice_date >= '2010-12-01'
      AND invoice_date < '2011-12-01'
    GROUP BY DATE_TRUNC('month', invoice_date)
),

monthly_returns AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        ABS(SUM(revenue)) AS returns
    FROM retail_sales
    WHERE quantity < 0
      AND invoice_date >= '2010-12-01'
      AND invoice_date < '2011-12-01'
    GROUP BY DATE_TRUNC('month', invoice_date)
)

SELECT
    s.month,
    s.transactions,
    ROUND(s.gross_revenue, 2) AS gross_revenue,
    ROUND(COALESCE(r.returns, 0), 2) AS returns,
    ROUND(
        s.gross_revenue - COALESCE(r.returns, 0),
        2
    ) AS net_revenue
FROM monthly_sales s
LEFT JOIN monthly_returns r
    ON s.month = r.month
ORDER BY s.month;



-- Month-over-month growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(
            CASE
                WHEN quantity > 0 AND unit_price > 0
                THEN revenue
                ELSE 0
            END
        ) AS gross_revenue,
        ABS(
            SUM(
                CASE
                    WHEN quantity < 0
                    THEN revenue
                    ELSE 0
                END
            )
        ) AS returns
    FROM retail_sales
    WHERE invoice_date >= '2010-12-01'
      AND invoice_date < '2011-12-01'
    GROUP BY DATE_TRUNC('month', invoice_date)
),

monthly_metrics AS (
    SELECT
        month,
        gross_revenue,
        returns,
        gross_revenue - returns AS net_revenue
    FROM monthly_revenue
),

monthly_growth AS (
    SELECT
        month,
        net_revenue,
        (
            net_revenue /
            NULLIF(LAG(net_revenue) OVER (ORDER BY month), 0) - 1
        ) * 100 AS mom_growth
    FROM monthly_metrics
)

SELECT
    month,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(mom_growth, 2) AS mom_growth
FROM monthly_growth
WHERE month >= '2011-01-01'
  AND month < '2011-12-01'
ORDER BY month;


-- April vs September 2011
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,

        COUNT(DISTINCT invoice_no) FILTER (
            WHERE quantity > 0
              AND unit_price > 0
        ) AS transactions,

        COUNT(DISTINCT customer_id) FILTER (
            WHERE quantity > 0
              AND unit_price > 0
        ) AS customers,

        SUM(revenue) FILTER (
            WHERE quantity > 0
              AND unit_price > 0
        ) AS gross_revenue,

        ABS(
            SUM(revenue) FILTER (
                WHERE quantity < 0
            )
        ) AS returns,

        SUM(quantity) FILTER (
            WHERE quantity > 0
              AND unit_price > 0
        ) AS quantity_sold

    FROM retail_sales
    WHERE invoice_date >= '2011-04-01'
      AND invoice_date < '2011-10-01'
    GROUP BY DATE_TRUNC('month', invoice_date)
)

SELECT
    month,
    transactions,
    customers,
    ROUND(gross_revenue, 2) AS gross_revenue,
    ROUND(COALESCE(returns, 0), 2) AS returns,
    ROUND(
        gross_revenue - COALESCE(returns, 0),
        2
    ) AS net_revenue,
    quantity_sold,

    ROUND(
        gross_revenue / NULLIF(transactions, 0),
        2
    ) AS aov,

    ROUND(
        gross_revenue / NULLIF(customers, 0),
        2
    ) AS arppu,

    ROUND(
        transactions::NUMERIC / NULLIF(customers, 0),
        2
    ) AS purchase_frequency,

    ROUND(
        quantity_sold::NUMERIC / NULLIF(transactions, 0),
        2
    ) AS items_per_order

FROM monthly_metrics
WHERE month IN (
    '2011-04-01',
    '2011-09-01'
)
ORDER BY month;


-- === 3. СUSTOMER ANALYSIS === 

-- Calculate overall customer metrics
SELECT
    COUNT(DISTINCT customer_id) AS paying_customers,
    ROUND(SUM(revenue), 2) AS gross_revenue,
    COUNT(DISTINCT invoice_no) AS number_of_transactions,
    ROUND(
        SUM(revenue) / COUNT(DISTINCT customer_id),
        2
    ) AS arppu
FROM retail_sales
WHERE quantity > 0
  AND unit_price > 0;


-- Calculate the share of customer-attributed gross revenue generated by the top 10% of customers
WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(revenue) AS customer_revenue
    FROM retail_sales
    WHERE quantity > 0
      AND unit_price > 0
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        customer_revenue,
        ROW_NUMBER() OVER (
            ORDER BY customer_revenue DESC
        ) AS customer_rank,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
)

SELECT
    ROUND(
        SUM(
            CASE
                WHEN customer_rank <= CEIL(total_customers * 0.10)
                THEN customer_revenue
                ELSE 0
            END
        )
        / SUM(customer_revenue) * 100,
        2
    ) AS top_10_customers_revenue_share
FROM ranked_customers;


-- Rank customers by gross revenue and return the top 10
SELECT
    customer_id,
    ROUND(SUM(revenue), 2) AS gross_revenue
FROM retail_sales
WHERE quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY gross_revenue DESC
LIMIT 10;


-- === 4. PRODUCT ANALYSIS ===

-- Identify the products with the highest sales volume
SELECT
    stock_code,
    description,
    SUM(quantity) AS quantity_sold
FROM retail_sales
WHERE quantity > 0
  AND unit_price > 0
GROUP BY
    stock_code,
    description
ORDER BY quantity_sold DESC
LIMIT 10;


-- Identify products with the highest return value excluding non-product transactions
SELECT
    stock_code,
    description,
    ROUND(ABS(SUM(revenue)), 2) AS returns_value,
    ABS(SUM(quantity)) AS returned_quantity
FROM retail_sales
WHERE quantity < 0
  AND stock_code NOT IN (
      'AMAZONFEE',
      'M',
      'POST',
      'CRUK',
      'BANK CHARGES'
  )
GROUP BY
    stock_code,
    description
ORDER BY returns_value DESC
LIMIT 10;


-- Identify the products generating the highest net revenue after returns
SELECT
    stock_code,
    description,
    ROUND(SUM(revenue), 2) AS net_revenue
FROM retail_sales
WHERE stock_code NOT IN (
    'AMAZONFEE',
    'M',
    'POST',
    'CRUK',
    'BANK CHARGES',
    'DOT'
)
GROUP BY
    stock_code,
    description
HAVING SUM(revenue) > 0
ORDER BY net_revenue DESC
LIMIT 10;


-- == 5. GEOGRAPHY ANALYSIS == 

-- Identify the countries generating the highest net revenue after returns
SELECT
    country,
    ROUND(SUM(revenue), 2) AS net_revenue
FROM retail_sales
GROUP BY country
HAVING SUM(revenue) > 0
ORDER BY net_revenue DESC
LIMIT 10;


-- Identify the countries with the highest number of paying customers
SELECT
    country,
    COUNT(DISTINCT customer_id) AS paying_customers
FROM retail_sales
WHERE quantity > 0
  AND unit_price > 0
  AND customer_id IS NOT NULL
GROUP BY country
ORDER BY paying_customers DESC
LIMIT 10;
