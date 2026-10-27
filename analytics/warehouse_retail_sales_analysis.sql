-- =====================================================
-- Warehouse and Retail Sales: SQL Analysis (MySQL)
-- Rows: ~307,645 | Years: 2017-2020
-- =====================================================
-- 1. CREATE DATABASE AND TABLE ------------------------
CREATE DATABASE warehouse_retail_sales;
USE  warehouse_retail_sales;

-- CREATE TABLE 

CREATE TABLE sales(
    year              INT,
    month             INT,
    supplier          VARCHAR(150),
    item_code         VARCHAR(30),
    item_description  VARCHAR(255),
    item_type         VARCHAR(30),
    retail_sales      DECIMAL(12,2),
    retail_transfers  DECIMAL(12,2),
    warehouse_sales   DECIMAL(12,2)
);

-- 3. BASIC CHECKS -------------------------------------
 SELECT * FROM SALES;
 SELECT count(*) FROM SALES ;

-- 4. CLEAN VIEW (only real products, no nulls, no negatives) --
CREATE OR REPLACE VIEW sale AS
SELECT
    year, month,
    COALESCE(supplier, 'UNKNOWN') AS supplier,
    item_code, item_description, item_type,
    retail_sales, retail_transfers, warehouse_sales,
    TRIM(SUBSTRING_INDEX(item_description, '-', -1)) AS item_size
FROM sales
WHERE item_type IN ('WINE', 'LIQUOR', 'BEER', 'KEGS', 'NON-ALCOHOL')
  AND retail_sales      IS NOT NULL
  AND retail_sales      >= 0
  AND retail_transfers  >= 0
  AND warehouse_sales   >= 0;

-- Q1. Total sales by item type
SELECT item_type , 
round(sum(retail_sales)) as total_retail_sales ,
round(sum(warehouse_sales)) as total_warehouse_sales
from sale
group by item_type
order by total_retail_sales desc;
-- Q2. Top 10 suppliers by retail sales
select supplier , round( sum(retail_sales)) as total_retail_sales
from sale
group by supplier 
order by total_retail_sales desc
limit 10;

-- Q3. Top 10 products by retail sales
select item_description ,
item_code,
round(sum(retail_sales) ,2) as total_retail_sales from sale
group by item_description , item_code
order by total_retail_sales desc
limit 10 ;
	
-- Q4. Monthly retail sales trend
select year, month ,
round(sum(retail_sales),2) as monthly_retail_sales
from sale
group by year , month
order by year ,month asc;
-- Q5. Year-wise sales by item type
select year , item_type ,
round(sum(retail_sales),2) as yearly_retail_sales,
round(sum(warehouse_sales),2) as yearly_warehouse_sales
from sale
group by year ,item_type
order by year desc ;
-- Q6. Retail vs warehouse share (%) by item type
select item_type ,
round(100*sum(retail_sales)/(sum(retail_sales)+sum(warehouse_sales)),2) as retail_share_pct,
round(100*sum(warehouse_sales)/(sum(retail_sales)+sum(warehouse_sales)),2) as warehouse_share_pct
from sale
group by item_type 
order by retail_share_pct;
-- Q7. Month-over-month growth in retail sales (window function)

-- Q8. Rank suppliers inside each item type

-- Q9. Best-selling bottle sizes
-- Q10. Items where transfers to stores are much higher than sales (possible overstock)
-- Q11. Running (cumulative) total of retail sales