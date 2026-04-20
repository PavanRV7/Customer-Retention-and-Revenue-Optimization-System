CREATE TABLE customers (
  customer_id INTEGER PRIMARY KEY,
  signup_date DATE,
  age INTEGER,
  gender TEXT,
  region TEXT,
  state TEXT,
  income_band TEXT,
  churn_label INTEGER
);

CREATE TABLE products (
  product_id INTEGER PRIMARY KEY,
  category TEXT,
  subcategory TEXT,
  brand TEXT,
  base_price REAL,
  cost REAL
);

CREATE TABLE transactions (
  transaction_id INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(customer_id),
  product_id INTEGER REFERENCES products(product_id),
  purchase_date DATE,
  quantity INTEGER,
  unit_price REAL,
  discount_pct REAL,
  revenue REAL,
  payment_method TEXT
);

CREATE INDEX idx_tx_customer ON transactions(customer_id);
CREATE INDEX idx_tx_date ON transactions(purchase_date);
CREATE INDEX idx_tx_product ON transactions(product_id);

# Monthly revenue & orders
SELECT
  strftime('%Y-%m', purchase_date) AS month,
  SUM(revenue) AS total_revenue,
  COUNT(*) AS orders
FROM transactions
GROUP BY 1
ORDER BY 1;

# Top 10 customers by revenue
SELECT c.customer_id, c.region, SUM(t.revenue) AS revenue
FROM transactions t
JOIN customers c ON c.customer_id = t.customer_id
GROUP BY 1,2
ORDER BY revenue DESC
LIMIT 10;

# Category revenue share
SELECT p.category, SUM(t.revenue) AS revenue
FROM transactions t
JOIN products p ON p.product_id = t.product_id
GROUP BY 1
ORDER BY revenue DESC;

-- FINAL CUSTOMER BUSINESS VIEW (MySQL compatible)

SELECT 
    c.customer_id,

    -- Recency
    DATEDIFF('2025-08-01', lp.last_date) AS recency_days,

    fm.frequency,
    fm.monetary,

    -- Churn label
    CASE 
        WHEN DATEDIFF('2025-08-01', lp.last_date) > 180 THEN 1
        ELSE 0
    END AS churn_label,

    -- Churn probability
    LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) AS churn_probability,

    -- Revenue at risk
    fm.monetary * LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) AS revenue_at_risk,

    -- Priority score
    fm.monetary * LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) * fm.frequency AS priority_score,

    -- Recommended action
    CASE
        WHEN LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) > 0.8 
             AND fm.monetary > 50000 THEN 'High Value - Personal Offer'
        WHEN LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) > 0.6 THEN 'Discount Campaign'
        WHEN LEAST(1.0, DATEDIFF('2025-08-01', lp.last_date) / 180.0) > 0.3 THEN 'Reminder'
        ELSE 'Cross-sell'
    END AS recommended_action

FROM customers c

LEFT JOIN (
    SELECT customer_id, MAX(purchase_date) AS last_date
    FROM transactions
    GROUP BY customer_id
) lp ON c.customer_id = lp.customer_id

LEFT JOIN (
    SELECT customer_id, COUNT(*) AS frequency, SUM(revenue) AS monetary
    FROM transactions
    GROUP BY customer_id
) fm ON c.customer_id = fm.customer_id;