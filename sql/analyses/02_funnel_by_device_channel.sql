SELECT device, acquisition_channel, COUNT(*) AS sessions,
       COUNT(*) FILTER (WHERE added_to_cart) AS carts,
       COUNT(*) FILTER (WHERE began_checkout) AS checkouts,
       COUNT(*) FILTER (WHERE purchased) AS purchases,
       ROUND(100.0*COUNT(*) FILTER (WHERE purchased)/NULLIF(COUNT(*),0),2) AS session_conversion_pct,
       ROUND(100.0*COUNT(*) FILTER (WHERE purchased)::numeric/NULLIF(COUNT(*) FILTER (WHERE began_checkout),0),2) AS checkout_to_purchase_pct
FROM v_session_funnel GROUP BY device,acquisition_channel ORDER BY device,acquisition_channel;
