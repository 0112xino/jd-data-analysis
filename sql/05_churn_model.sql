-- 主要针对不同年龄、性别用户购买最多的品类Top3
SELECT    
    age_range, gender, category, num, CONCAT(round(num / total * 100, 1), "%") proportion    
FROM (    
     SELECT    
         age_range, gender, category, COUNT(*) num,    
         SUM(COUNT(*))OVER(PARTITION BY age_range, gender) total,    
         ROW_NUMBER()OVER(PARTITION BY age_range, gender ORDER BY COUNT(*) DESC) rk    
     FROM jd_database_new    
     WHERE type = 'Order' AND gender IN ('W', 'M')    
     GROUP BY age_range, gender, category    
     )s1    
 WHERE rk <= 3    
 ORDER BY age_range, gender, num DESC;
 
-- 主要针对不同产品品类中购买最多的品牌。

SELECT    
    category, brand, num, CONCAT(round(num / total * 100, 1), "%") proportion    
FROM (    
     SELECT    
         category, brand, COUNT(*) num,    
         SUM(COUNT(*))OVER(PARTITION BY category) total,    
         ROW_NUMBER()OVER(PARTITION BY category ORDER BY COUNT(*) DESC) rk    
     FROM jd_database_new    
     WHERE    
         type = 'Order'    
     GROUP BY category, brand    
     )q1    
 WHERE (CASE WHEN rk = 1 and brand = "Other" then rk = 2 ELSE rk = 1 END)    
 ORDER BY num DESC;
 
-- 主要针对用户对新品（上市30天内）的购买比例。

SELECT    
    COUNT(DISTINCT customer_id) total_buyers,    
    COUNT(DISTINCT IF(DATEDIFF(action_date, product_market_date) <= 30, customer_id, NULL)) new_priduct_buyers,    
    COUNT(DISTINCT IF(DATEDIFF(action_date, product_market_date) <= 30, customer_id, NULL)) / COUNT(DISTINCT customer_id) rt    
FROM    
    jd_database_new    
WHERE    
type = 'Order';
