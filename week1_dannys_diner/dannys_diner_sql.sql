/* --------------------
 Case Study Questions
 --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- 1.
with customer_product_price as (
    SELECT
        customer_id,
        sales.product_id,
        price
    FROM
        sales
        INNER JOIN menu ON sales.product_id = menu.product_id
)
SELECT
    customer_id,
    SUM(price) as total
FROM
    customer_product_price
GROUP BY
    customer_id;

-- 2.
SELECT
    customer_id,
    COUNT(DISTINCT(order_date)) as total_day
FROM
    sales
GROUP BY
    customer_id;

-- 3.
with customer_firstProduct as (
    SELECT
        DISTINCT customer_id,
        FIRST_VALUE(product_id) OVER (PARTITION BY customer_id) as first_product_id
    FROM
        sales
)
SELECT
    customer_id,
    product_name as first_product_name
FROM
    customer_firstProduct
    INNER JOIN menu ON customer_firstProduct.first_product_id = menu.product_id;

-- 4.
SELECT
    product_id,
    COUNT(1) as total_buy
FROM
    sales
GROUP BY
    product_id
ORDER BY
    total_buy DESC
LIMIT
    1;

-- 5.
with times_product_purchased_by_customer as (
    SELECT
        customer_id,
        product_id,
        COUNT(product_id) as total_buy
    FROM
        sales
    GROUP BY
        customer_id,
        product_id
),
ranking_times_purchased as (
    SELECT
        customer_id,
        product_id,
        total_buy,
        RANK() OVER(
            PARTITION BY customer_id
            ORDER BY
                total_buy DESC
        ) total_buy_rank
    FROM
        times_product_purchased_by_customer
)
SELECT
    customer_id,
    product_name as most_popular_product
FROM
    ranking_times_purchased
    INNER JOIN menu ON ranking_times_purchased.product_id = menu.product_id
WHERE
    ranking_times_purchased.total_buy_rank = 1
ORDER BY
    customer_id;

-- 6.
SELECT
    DISTINCT sales.customer_id,
    FIRST_VALUE(product_id) OVER (PARTITION BY sales.customer_id) as first_product_as_member
FROM
    sales
    INNER JOIN members ON sales.customer_id = members.customer_id
WHERE
    order_date >= join_date;

-- 7.
SELECT
    DISTINCT sales.customer_id,
    LAST_VALUE(product_id) OVER (PARTITION BY sales.customer_id) as first_product_as_member
FROM
    sales
    INNER JOIN members ON sales.customer_id = members.customer_id
WHERE
    order_date < join_date;

-- 8.
SELECT
    sales.customer_id,
    COUNT(price) as total_items,
    SUM(price) as amount_spent
FROM
    sales
    INNER JOIN members ON sales.customer_id = members.customer_id
    INNER JOIN menu ON sales.product_id = menu.product_id
WHERE
    order_date < join_date
GROUP BY
    sales.customer_id;

-- 9.
with product_with_time_buy as (
    SELECT
        customer_id,
        product_name,
        price,
        COUNT(product_name) as time_buy
    FROM
        sales
        INNER JOIN menu ON sales.product_id = menu.product_id
    GROUP BY
        customer_id,
        product_name,
        price
    ORDER BY
        customer_id
)
SELECT
    customer_id,
    SUM (
        CASE
            product_name
            WHEN 'sushi' THEN price * time_buy * 2
            ELSE price * time_buy
        END
    ) as points
FROM
    product_with_time_buy
GROUP BY
    customer_id;

-- 10.
with product_with_time_buy_and_order_date as (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        COUNT(product_name) as time_buy
    FROM
        sales
        INNER JOIN menu ON sales.product_id = menu.product_id
    GROUP BY
        customer_id,
        order_date,
        product_name,
        price
    ORDER BY
        customer_id
),
point_on_each_order as (
    SELECT
        product_with_time_buy_and_order_date.customer_id,
        order_date,
        join_date,
        product_name,
        price,
        CASE
            WHEN order_date >= join_date
            AND order_date <= join_date + 7 THEN (price * time_buy * 2)
            ELSE (
                CASE
                    product_name
                    WHEN 'sushi' THEN price * time_buy * 2
                    ELSE price * time_buy
                END
            )
        END as points
    FROM
        product_with_time_buy_and_order_date
        INNER JOIN members ON product_with_time_buy_and_order_date.customer_id = members.customer_id
    WHERE
        order_date <= '2021-01-31' :: date
)
SELECT
    customer_id,
    SUM(points) as total_points
FROM
    point_on_each_order
GROUP BY
    customer_id;