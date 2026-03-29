-- 用户忠诚度分析，RFM模型分层
WITH w1 AS (    
    SELECT    
        customer_id,    
        DATEDIFF((SELECT MAX(action_date) FROM jd_database_new), MAX(action_date)) AS recency,       
        COUNT(*) AS frequency,                                   
        COUNT(DISTINCT category) AS monetary_m1,    
        COUNT(DISTINCT type) AS monetary_m2,    
        COUNT(DISTINCT shop_id) AS monetary_m3    
    FROM jd_database_new    
    WHERE type = 'Order'    
    GROUP BY customer_id    
)    
SELECT    
    CASE    
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '重要价值用户'    
        WHEN r_score < 4  AND f_score >= 4 AND m_score >= 4 THEN '重要保持用户'    
        WHEN r_score >= 4 AND f_score < 4  AND m_score >= 4 THEN '重要发展用户'    
        WHEN r_score < 4  AND f_score < 4  AND m_score >= 4 THEN '重要挽留用户'    
        WHEN r_score >= 4 AND f_score >= 4 AND m_score < 4  THEN '一般价值用户'    
        WHEN r_score < 4  AND f_score >= 4 AND m_score < 4  THEN '一般保持用户'    
        WHEN r_score >= 4 AND f_score < 4  AND m_score < 4  THEN '一般发展用户'    
        ELSE '一般挽留用户'    
    END AS '用户类型',    
    COUNT(customer_id) AS cnt    
FROM (    
    SELECT    
        customer_id,    
        NTILE(6)OVER(ORDER BY recency DESC) AS r_score,    
        NTILE(6)OVER(ORDER BY frequency) AS f_score,    
        (NTILE(6)OVER(ORDER BY monetary_m1) + NTILE(6)OVER(ORDER BY monetary_m2) + NTILE(6)OVER(ORDER BY monetary_m3)) / 3 AS m_score    
    FROM w1    
    )w2    
GROUP BY 用户类型    
ORDER BY 用户类型;
