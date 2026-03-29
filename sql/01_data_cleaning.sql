-- 由于原始表中缺失值类型多样，统一将缺失值修改为NULL
ALTER TABLE jd_database
MODIFY COLUMN customer_id TEXT,
MODIFY COLUMN product_id TEXT,
MODIFY COLUMN action_date TEXT,
MODIFY COLUMN action_id TEXT,
MODIFY COLUMN type TEXT,
MODIFY COLUMN age_range TEXT,
MODIFY COLUMN gender TEXT,
MODIFY COLUMN customer_register_date TEXT,
MODIFY COLUMN customer_level TEXT,
MODIFY COLUMN city_level TEXT,
MODIFY COLUMN brand TEXT,
MODIFY COLUMN shop_id TEXT,
MODIFY COLUMN category TEXT,
MODIFY COLUMN product_market_date TEXT,
MODIFY COLUMN vender_id TEXT,
MODIFY COLUMN fans_number TEXT,
MODIFY COLUMN vip_number TEXT,
MODIFY COLUMN shop_register_date TEXT,
MODIFY COLUMN shop_category TEXT,
MODIFY COLUMN shop_score TEXT;


UPDATE jd_database
SET
  customer_id = NULLIF(customer_id, 'Null'),
  product_id = NULLIF(product_id, 'Null'),
  action_date = NULLIF(action_date, 'Null'),
  action_id = NULLIF(action_id, 'Null'),
  type = NULLIF(type, 'Null'),
  age_range = NULLIF(age_range, 'Null'),
  gender = NULLIF(gender, 'Null'),
  customer_register_date = NULLIF(customer_register_date, 'Null'),
  customer_level = NULLIF(customer_level, 'Null'),
  city_level = NULLIF(city_level, 'Null'),
  brand = NULLIF(brand, 'Null'),
  shop_id = NULLIF(shop_id, 'Null'),
  category = NULLIF(category, 'Null'),
  product_market_date = NULLIF(product_market_date, 'Null'),
  vender_id = NULLIF(vender_id, 'Null'),
  fans_number = NULLIF(fans_number, 'Null'),
  vip_number = NULLIF(vip_number, 'Null'),
  shop_register_date = NULLIF(shop_register_date, 'Null'),
  shop_category = NULLIF(shop_category, 'Null'),
  shop_score = NULLIF(shop_score, 'Null');
  
  
  ALTER TABLE jd_database
MODIFY COLUMN customer_id INT,
MODIFY COLUMN product_id INT,
MODIFY COLUMN action_date DATE,
MODIFY COLUMN action_id INT,
MODIFY COLUMN type VARCHAR(50),
MODIFY COLUMN age_range INT,
MODIFY COLUMN gender VARCHAR(10),
MODIFY COLUMN customer_register_date DATE,
MODIFY COLUMN customer_level INT,
MODIFY COLUMN city_level INT,
MODIFY COLUMN brand VARCHAR(100),
MODIFY COLUMN shop_id INT,
MODIFY COLUMN category VARCHAR(100),
MODIFY COLUMN product_market_date DATE,
MODIFY COLUMN vender_id INT,
MODIFY COLUMN fans_number INT,
MODIFY COLUMN vip_number INT,
MODIFY COLUMN shop_register_date DATE,
MODIFY COLUMN shop_category VARCHAR(100),
MODIFY COLUMN shop_score DOUBLE;


UPDATE jd_database
SET age_range = NULL
WHERE age_range IS NULL 
   OR age_range = '' 
   OR TRIM(age_range) = '' 
   OR TRIM(CAST(age_range AS CHAR)) = 'NULL'
   OR city_level = 0;  

-- 统计缺失值
SELECT    
    COUNT(customer_id), COUNT(product_id), COUNT(action_date), COUNT(action_id), COUNT(type),    
    COUNT(age_range), COUNT(gender), COUNT(customer_register_date), COUNT(customer_level), COUNT(city_level),    
    COUNT(brand), COUNT(shop_id), COUNT(category), COUNT(product_market_date), COUNT(vender_id),    
    COUNT(fans_number), COUNT(vip_number), COUNT(shop_register_date), COUNT(shop_category), COUNT(shop_score)    
FROM    
    jd_database;
    
    
-- 处理缺失值
SET SQL_SAFE_UPDATES = 0;    
DELETE FROM jd_database WHERE age_range IS NULL;    
DELETE FROM jd_database WHERE city_level IS NULL;    
SET SQL_SAFE_UPDATES = 1;

-- 查询重复值
SELECT    
    customer_id    
FROM 
    jd_database    
GROUP BY customer_id, product_id, action_date, action_id, type, age_range, gender,customer_register_date, customer_level, city_level, brand, shop_id, category,product_market_date, vender_id, fans_number, vip_number, shop_register_date, shop_category, shop_score    
HAVING COUNT(*) > 1;

--去重并创建新表存储清洗后的数据
CREATE TABLE jd_database_new AS    
SELECT DISTINCT * FROM jd_database;    
SELECT    
    COUNT(*)    
FROM    
    jd_database    
UNION ALL    
SELECT    
    COUNT(*)    
FROM    
    jd_database_new;

-- 查看是否含有异常值
SELECT    
    MAX(age_range),    
    MIN(age_range),    
    MAX(customer_level),    
    MIN(customer_level),    
    MAX(city_level),    
    MIN(city_level),    
    MAX(shop_score),    
    MIN(shop_score)    
FROM    
    jd_database_new;
  
-- 修正异常值
SET SQL_SAFE_UPDATES = 0;    
UPDATE jd_database_new SET shop_score = 0 WHERE shop_score < 0;    
SET SQL_SAFE_UPDATES = 1;

-- 删除不符合业务意义的逻辑错误值
SET SQL_SAFE_UPDATES = 0;    
DELETE FROM jd_database_new    
WHERE action_date < customer_register_date    
   OR action_date < product_market_date    
   OR action_date < shop_register_date    
   OR product_market_date < shop_register_date;    
SET SQL_SAFE_UPDATES = 1;

-- 做一些变量的描述性统计
SELECT    
     COUNT(DISTINCT customer_id),    
     COUNT(action_date), MAX(action_date), MIN(action_date),    
     COUNT(age_range), AVG(age_range), STDDEV_SAMP(age_range), MAX(age_range), MIN(age_range),    
     COUNT(customer_level), AVG(customer_level), STDDEV_SAMP(customer_level), MAX(customer_level), MIN(customer_level),    
     COUNT(city_level), AVG(city_level), STDDEV_SAMP(city_level), MAX(city_level), MIN(city_level),    
     COUNT(fans_number), AVG(fans_number), STDDEV_SAMP(fans_number), MAX(fans_number), MIN(fans_number),    
     COUNT(vip_number), AVG(vip_number), STDDEV_SAMP(vip_number), MAX(vip_number), MIN(vip_number),    
     COUNT(shop_score), AVG(shop_score), STDDEV_SAMP(shop_score), MAX(shop_score), MIN(shop_score)    
from jd_database_new;
