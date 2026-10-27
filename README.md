# 🍷 Warehouse and Retail Sales: SQL Analysis (MySQL)

An end-to-end SQL analysis of a **307,645-row** alcohol distributor dataset (2017–2020). The project covers data cleaning, aggregation, ranking and window functions to find out **what sells, who supplies it, when it sells, and where stock may be piling up.**


---

## 📌 Table of Contents
- [Project Overview](#-project-overview)
- [Dataset](#-dataset)
- [Database Setup](#-database-setup)
- [Data Cleaning](#-data-cleaning)
- [Analysis and Results](#-analysis-and-results)
- [Key Insights](#-key-insights)
- [SQL Concepts Used](#-sql-concepts-used)
- [How to Run](#-how-to-run)
- [Author](#-author)

---

## 🎯 Project Overview

A distributor sells products in two ways: through **retail stores** and directly from the **warehouse**. This project answers business questions such as:

- Which product categories and suppliers bring the most retail sales?
- Which individual products are best sellers?
- How do sales change month by month, and when is the peak?
- How is each category split between retail and warehouse sales?
- Which items are sent to stores far more than they sell (possible overstock)?

---

## 📂 Dataset

| Detail | Value |
|---|---|
| File | `Warehouse_and_Retail_Sales.csv` |
| Rows | 307,645 |
| Period | June 2017 – September 2020 (not every month is present) |
| Unique items | 34,056 |
| Unique suppliers | 396 |

| Column | Description |
|---|---|
| `year`, `month` | Period of the record |
| `supplier` | Company that supplies the product |
| `item_code` | Unique product ID |
| `item_description` | Product name with bottle size, e.g. `BURGANS ALBARINO - 750ML` |
| `item_type` | Category: WINE, LIQUOR, BEER, KEGS, NON-ALCOHOL, etc. |
| `retail_sales` | Units sold through retail stores |
| `retail_transfers` | Units moved from warehouse to retail stores |
| `warehouse_sales` | Units sold directly from the warehouse (bulk) |

> **Months available:** 2017 (Jun–Dec), 2018 (Jan–Feb), 2019 (Jan–Nov), 2020 (Jan, Mar, Jul, Sep). Yearly totals are therefore not directly comparable.

---

## 🛠 Database Setup

```sql
CREATE DATABASE warehouse_retail_sales;
USE  warehouse_retail_sales;

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
```

Load the CSV using **MySQL Workbench → Table Data Import Wizard**, then verify:

```sql
SELECT * FROM SALES;
SELECT count(*) FROM SALES ;   -- 307645
```

---

## 🧹 Data Cleaning

Checks on the raw data found:

| Issue | Count |
|---|---|
| Missing `supplier` | 167 |
| Missing `item_type` | 1 |
| Missing `retail_sales` | 3 |
| Negative `retail_sales` | 113 |
| Negative `retail_transfers` | 1,016 |
| Negative `warehouse_sales` | 716 |
| Non-product types (REF, DUNNAGE, STR_SUPPLIES) | 627 |

A clean view keeps only real products, fills missing suppliers with `UNKNOWN`, removes negative values (returns/corrections) and extracts the bottle size:

```sql
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
```

**Result:** 305,319 clean rows used for all analysis below.

---

## 📊 Analysis and Results

### Q1. Total sales by item type
```sql
SELECT item_type , 
round(sum(retail_sales)) as total_retail_sales ,
round(sum(warehouse_sales)) as total_warehouse_sales
from sale
group by item_type
order by total_retail_sales desc;
```
| item_type | total_retail_sales | total_warehouse_sales |
|---|---|---|
| LIQUOR | 801,684 | 94,968 |
| WINE | 745,192 | 1,156,326 |
| BEER | 573,920 | 6,524,314 |
| NON-ALCOHOL | 34,056 | 26,157 |
| KEGS | 0 | 118,621 |

### Q2. Top 10 suppliers by retail sales
```sql
select supplier , round( sum(retail_sales)) as total_retail_sales
from sale
group by supplier 
order by total_retail_sales desc
limit 10;
```
| supplier | total_retail_sales |
|---|---|
| E & J GALLO WINERY | 165,979 |
| DIAGEO NORTH AMERICA INC | 145,250 |
| CONSTELLATION BRANDS | 131,559 |
| ANHEUSER BUSCH INC | 109,887 |
| JIM BEAM BRANDS CO | 96,076 |
| MILLER BREWING COMPANY | 87,102 |
| CROWN IMPORTS | 84,438 |
| SAZERAC CO | 70,384 |
| BACARDI USA INC | 66,465 |
| THE WINE GROUP | 64,163 |

### Q3. Top 10 products by retail sales
```sql
select item_description ,
item_code,
round(sum(retail_sales) ,2) as total_retail_sales from sale
group by item_description , item_code
order by total_retail_sales desc
limit 10 ;
```
| item_description | item_code | total_retail_sales |
|---|---|---|
| TITO'S HANDMADE VODKA - 1.75L | 53929 | 27,580.50 |
| CORONA EXTRA LOOSE NR - 12OZ | 23445 | 25,064.00 |
| HEINEKEN LOOSE NR - 12OZ | 23886 | 17,761.00 |
| MILLER LITE 30PK CAN - 12OZ | 90590 | 14,440.00 |
| BUD LIGHT 30PK CAN | 90468 | 12,299.00 |
| BOWMAN'S VODKA - 1.75L | 35840 | 12,126.72 |
| MILLER LITE HIGH GRAPHIC LOOSE NR - 12OZ | 23905 | 10,373.77 |
| STELLA ARTOIS LOOSE NR - 11.2OZ | 26187 | 10,354.00 |
| CORONA EXTRA 2/12 NR - 12OZ | 96750 | 9,755.19 |
| PINNACLE VODKA - 1.75L | 40932 | 8,676.40 |

### Q4. Monthly retail sales trend
```sql
select year, month ,
round(sum(retail_sales),2) as monthly_retail_sales
from sale
group by year , month
order by year ,month asc;
```
| year | month | monthly_retail_sales |
|---|---|---|
| 2017 | 6 | 97,049.43 |
| 2017 | 7 | 92,260.40 |
| 2017 | 8 | 86,853.25 |
| 2017 | 9 | 90,117.76 |
| 2017 | 10 | 88,793.79 |
| 2017 | 11 | 97,945.92 |
| **2017** | **12** | **130,882.70** |
| 2018 | 1 | 75,463.04 |
| 2018 | 2 | 77,475.85 |
| 2019 | 1 | 75,883.27 |
| 2019 | 2 | 79,936.16 |
| 2019 | 3 | 84,293.16 |
| 2019 | 4 | 80,182.16 |
| 2019 | 5 | 94,785.72 |
| 2019 | 6 | 90,699.41 |
| 2019 | 7 | 90,550.85 |
| 2019 | 8 | 90,443.91 |
| 2019 | 9 | 81,960.28 |
| 2019 | 10 | 87,997.20 |
| 2019 | 11 | 101,425.42 |
| 2020 | 1 | 74,140.83 |
| 2020 | 3 | 109,300.83 |
| 2020 | 7 | 94,406.95 |
| 2020 | 9 | 82,003.46 |

### Q5. Year-wise sales by item type
```sql
select year , item_type ,
round(sum(retail_sales),2) as yearly_retail_sales,
round(sum(warehouse_sales),2) as yearly_warehouse_sales
from sale
group by year ,item_type
order by year desc ;
```
| year | item_type | yearly_retail_sales | yearly_warehouse_sales |
|---|---|---|---|
| 2020 | LIQUOR | 137,524.70 | 13,045.24 |
| 2020 | WINE | 111,790.39 | 199,237.21 |
| 2020 | BEER | 99,779.15 | 1,169,370.04 |
| 2020 | NON-ALCOHOL | 10,757.83 | 4,284.63 |
| 2020 | KEGS | 0.00 | 12,630.00 |
| 2019 | LIQUOR | 356,956.16 | 49,497.62 |
| 2019 | WINE | 324,926.64 | 533,302.34 |
| 2019 | BEER | 262,301.54 | 2,958,396.26 |
| 2019 | NON-ALCOHOL | 13,973.20 | 12,132.91 |
| 2019 | KEGS | 0.00 | 57,143.00 |
| 2018 | WINE | 58,995.89 | 85,773.03 |
| 2018 | LIQUOR | 57,155.90 | 6,646.78 |
| 2018 | BEER | 35,242.69 | 425,695.57 |
| 2018 | NON-ALCOHOL | 1,544.41 | 1,992.21 |
| 2018 | KEGS | 0.00 | 9,798.00 |
| 2017 | LIQUOR | 250,047.48 | 25,778.55 |
| 2017 | WINE | 249,478.86 | 338,013.11 |
| 2017 | BEER | 176,596.81 | 1,970,852.12 |
| 2017 | NON-ALCOHOL | 7,780.10 | 7,747.51 |
| 2017 | KEGS | 0.00 | 39,050.00 |

> Each year covers a different number of months, so compare the share between categories rather than the totals across years.

### Q6. Retail vs warehouse share (%) by item type
```sql
select item_type ,
round(100*sum(retail_sales)/(sum(retail_sales)+sum(warehouse_sales)),2) as retail_share_pct,
round(100*sum(warehouse_sales)/(sum(retail_sales)+sum(warehouse_sales)),2) as warehouse_share_pct
from sale
group by item_type 
order by retail_share_pct;
```
| item_type | retail_share_pct | warehouse_share_pct |
|---|---|---|
| KEGS | 0.00 | 100.00 |
| BEER | 8.09 | 91.91 |
| WINE | 39.19 | 60.81 |
| NON-ALCOHOL | 56.56 | 43.44 |
| LIQUOR | 89.41 | 10.59 |

### Q7. Month-over-month growth in retail sales (window function `LAG`)
```sql
 WITH monthly AS (
    SELECT year, month, SUM(retail_sales) AS sales
    FROM sale
    GROUP BY year, month
)
SELECT year, month,
       ROUND(sales, 2) AS sales,
       ROUND(100 * (sales - LAG(sales) OVER (ORDER BY year, month))
             / LAG(sales) OVER (ORDER BY year, month), 2) AS mom_growth_pct
FROM monthly
ORDER BY year, month;
```
| year | month | sales | mom_growth_pct |
|---|---|---|---|
| 2017 | 6 | 97,049.43 | NULL |
| 2017 | 7 | 92,260.40 | -4.93 |
| 2017 | 8 | 86,853.25 | -5.86 |
| 2017 | 9 | 90,117.76 | 3.76 |
| 2017 | 10 | 88,793.79 | -1.47 |
| 2017 | 11 | 97,945.92 | 10.31 |
| 2017 | 12 | 130,882.70 | 33.63 |
| 2018 | 1 | 75,463.04 | -42.34 |
| 2018 | 2 | 77,475.85 | 2.67 |
| 2019 | 1 | 75,883.27 | -2.06 |
| 2019 | 2 | 79,936.16 | 5.34 |
| 2019 | 3 | 84,293.16 | 5.45 |
| 2019 | 4 | 80,182.16 | -4.88 |
| 2019 | 5 | 94,785.72 | 18.21 |
| 2019 | 6 | 90,699.41 | -4.31 |
| 2019 | 7 | 90,550.85 | -0.16 |
| 2019 | 8 | 90,443.91 | -0.12 |
| 2019 | 9 | 81,960.28 | -9.38 |
| 2019 | 10 | 87,997.20 | 7.37 |
| 2019 | 11 | 101,425.42 | 15.26 |
| 2020 | 1 | 74,140.83 | -26.90 |
| 2020 | 3 | 109,300.83 | 47.42 |
| 2020 | 7 | 94,406.95 | -13.63 |
| 2020 | 9 | 82,003.46 | -13.14 |

> Growth is calculated between consecutive rows, so it is not a true month-over-month change where months are missing (for example Jan 2020 → Mar 2020).

### Q8. Rank items inside each supplier (`RANK`)
```sql
select item_type ,
item_code,
supplier,
rank() over (partition by supplier 
order by sum(retail_sales) desc) as rnk
from sale
group by supplier ,item_type , item_code;
```
This query ranks every item inside each supplier by its total retail sales, where rank 1 is that supplier's best-selling item. It returns 37,218 rows across 394 suppliers. Example of the top 3 items for three large suppliers:

| supplier | item_type | item_code | rnk |
|---|---|---|---|
| E & J GALLO WINERY | WINE | 82889 | 1 |
| E & J GALLO WINERY | WINE | 84678 | 2 |
| E & J GALLO WINERY | LIQUOR | 73534 | 3 |
| DIAGEO NORTH AMERICA INC | LIQUOR | 35254 | 1 |
| DIAGEO NORTH AMERICA INC | BEER | 96067 | 2 |
| DIAGEO NORTH AMERICA INC | LIQUOR | 38580 | 3 |
| ANHEUSER BUSCH INC | BEER | 90468 | 1 |
| ANHEUSER BUSCH INC | BEER | 26187 | 2 |
| ANHEUSER BUSCH INC | BEER | 97918 | 3 |

### Q9. Best-selling product
```sql
select item_description as bottel_size,
sum(retail_sales) as total_sale
from sale
group by bottel_size
order by total_sale desc
limit 1;
```
| bottel_size | total_sale |
|---|---|
| TITO'S HANDMADE VODKA - 1.75L | 27,580.50 |

The query groups by the full `item_description`, so the top result is the best-selling product, and Tito's Handmade Vodka (1.75L) is the winner.

### Q10. Possible overstock (transfers higher than sales)
```sql
select item_type,
item_code ,
sum(retail_sales) as total_retail,
sum(retail_transfers) as total_transfer,
(sum(retail_transfers) -sum(retail_sales)) as over_stock
from sale 
group by item_type ,item_code 
having total_retail < total_transfer;
```
**Result:** 4,754 items were sent to stores in larger quantities than they sold: 2,318 wine, 1,491 liquor, 905 beer and 40 non-alcohol items. The five items with the largest gap:

| item_type | item_code | total_retail | total_transfer | over_stock |
|---|---|---|---|---|
| BEER | 50744 | 3,865.70 | 4,273.00 | 407.30 |
| LIQUOR | 73075 | 444.16 | 772.75 | 328.59 |
| LIQUOR | 53929 | 27,580.50 | 27,889.33 | 308.83 |
| BEER | 36780 | 387.00 | 691.00 | 304.00 |
| BEER | 48978 | 470.50 | 742.00 | 271.50 |

---

## 💡 Key Insights

1. **Liquor leads retail** (about 802K units), followed by wine (745K) and beer (574K).
2. **Beer is a warehouse business:** 92% of beer sales happen from the warehouse, probably bulk sales to bars and restaurants. Liquor is the opposite, with 89% sold through retail.
3. **Wine is split:** 61% warehouse and 39% retail.
4. **Holiday peak:** December 2017 is the highest month (130,883 units, +33.6% over November), and January is the lowest month every year.
5. **Top supplier:** E & J Gallo Winery leads retail sales, followed by Diageo and Constellation Brands.
6. **Top product:** Tito's Handmade Vodka 1.75L is the single best seller, and 8 of the top 10 products are beer or vodka.
7. **Overstock risk:** 4,754 items received more transfers than they sold, a good starting point for inventory planning.

---

## 🧠 SQL Concepts Used

- `CREATE DATABASE / TABLE / VIEW`
- Data cleaning with `COALESCE`, `NULL` checks and filters
- String functions: `SUBSTRING_INDEX`, `TRIM`
- Aggregation: `SUM`, `ROUND`, `COUNT`
- `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`
- CTEs (`WITH`)
- Window functions: `RANK() OVER (PARTITION BY ...)`, `LAG()`

---

## ▶️ How to Run

1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/<repo-name>.git
   ```
2. Open **MySQL Workbench** and run the database and table setup.
3. Import `Warehouse_and_Retail_Sales.csv` into the `sales` table.
4. Run the clean view, then the queries Q1 to Q10 from `warehouse_retail_sales.sql`.

---

## 📁 Repository Structure

```
├── Warehouse_and_Retail_Sales.csv
├── warehouse_retail_sales.sql
└── README.md
```

---

## 👤 Author

**Virendra Malviya**
BCA Student | Aspiring Data Analyst
Skills: SQL · Python · Excel · Power BI

🔗 [GitHub](https://github.com/Virndra7489) · [LinkedIn](https://www.linkedin.com/in/virendra-malviya)

---

⭐ If you found this project useful, please give it a star!