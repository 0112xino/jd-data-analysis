-- 行为漏斗
WITH e1 AS (    
    SELECT    
        COUNT(DISTINCT CASE WHEN type = 'PageView' THEN customer_id END) AS view_uv,    
        COUNT(DISTINCT CASE WHEN type = 'SavedCart' THEN customer_id END) AS cart_uv,    
        COUNT(DISTINCT CASE WHEN type = 'Order' THEN customer_id END) AS order_uv,    
        COUNT(DISTINCT CASE WHEN type = 'Follow' THEN customer_id END) AS follow_uv    
    FROM jd_database_new    
)    
SELECT    
    view_uv AS 浏览用户数,    
    cart_uv AS 加购用户数,    
    order_uv AS 下单用户数,    
    follow_uv AS 关注用户数,    
CONCAT(ROUND(100.0 * cart_uv / view_uv, 2), '%') AS 浏览_加购转化率,    
    CONCAT(ROUND(100.0 * order_uv / cart_uv, 2), '%') AS 加购_下单转化率,    
    CONCAT(ROUND(100.0 * follow_uv / order_uv, 2), '%') AS 下单_关注转化率,    
    CONCAT(ROUND(100.0 * order_uv / view_uv, 2), '%') AS 浏览_下单转化率,    
    CONCAT(ROUND(100.0 * follow_uv / view_uv, 2), '%') AS 浏览_关注转化率    
FROM e1;
