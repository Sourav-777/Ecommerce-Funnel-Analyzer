SELECT s.start_time::date AS order_date,
       u.acquisition_channel,
       COUNT(o.order_id) AS orders,
       ROUND(SUM(o.total_amount), 2) AS net_revenue,
       ROUND(AVG(o.total_amount), 2) AS average_order_value
FROM orders o
JOIN sessions s ON s.session_id = o.session_id
JOIN users u ON u.user_id = o.user_id
GROUP BY order_date, u.acquisition_channel
ORDER BY order_date, u.acquisition_channel;