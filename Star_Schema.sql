-- =========================================
-- 1. CREATE DATABASE
-- =========================================
CREATE DATABASE sales_dw;
USE sales_dw;

-- =========================================
-- 2. CREATE RAW SALES TABLE (CSV DATA)
-- =========================================
CREATE TABLE raw_sales (
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Product_Name VARCHAR(100),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Region VARCHAR(50),
    Country VARCHAR(50),
    Sales DECIMAL(10,2),
    Quantity INT,
    Profit DECIMAL(10,2)
);

-- =========================================
-- 3. INSERT CSV RECORDS
-- =========================================
INSERT INTO raw_sales VALUES
('ORD-1001','2023-01-05','Amit Sharma','Consumer','Office Chair','Furniture','Chairs','South','India',8500,2,1200),
('ORD-1002','2023-01-08','Neha Verma','Corporate','Wireless Mouse','Technology','Accessories','North','India',1200,3,300),
('ORD-1003','2023-01-12','Rahul Mehta','Home Office','Printer','Technology','Machines','West','India',15000,1,2500),
('ORD-1004','2023-02-02','Priya Singh','Consumer','Notebook','Office Supplies','Paper','East','India',500,10,150),
('ORD-1005','2023-02-10','Amit Sharma','Consumer','Office Desk','Furniture','Tables','South','India',18000,1,3000),
('ORD-1006','2023-02-18','Karan Patel','Corporate','Laptop','Technology','Computers','West','India',65000,1,8000),
('ORD-1007','2023-03-05','Neha Verma','Corporate','Desk Lamp','Furniture','Furnishings','North','India',2200,2,400),
('ORD-1008','2023-03-12','Rohit Gupta','Home Office','Pen Set','Office Supplies','Art','East','India',900,5,200),
('ORD-1009','2023-03-20','Priya Singh','Consumer','Bookshelf','Furniture','Bookcases','East','India',12000,1,2200),
('ORD-1010','2023-03-25','Amit Sharma','Consumer','Monitor','Technology','Accessories','South','India',14000,1,1800);

-- =========================================
-- 4. CREATE DIMENSION TABLES
-- =========================================
CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) UNIQUE,
    segment VARCHAR(50)
);

CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) UNIQUE,
    category VARCHAR(50),
    sub_category VARCHAR(50)
);

CREATE TABLE dim_region (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(50),
    country VARCHAR(50),
    UNIQUE(region, country)
);

CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE UNIQUE,
    year INT,
    month INT,
    day INT
);

-- =========================================
-- 5. POPULATE DIMENSIONS
-- =========================================
INSERT INTO dim_customer (customer_name, segment)
SELECT DISTINCT Customer_Name, Segment
FROM raw_sales;

INSERT INTO dim_product (product_name, category, sub_category)
SELECT DISTINCT Product_Name, Category, Sub_Category
FROM raw_sales;

INSERT INTO dim_region (region, country)
SELECT DISTINCT Region, Country
FROM raw_sales;

INSERT INTO dim_date (order_date, year, month, day)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    DAY(Order_Date)
FROM raw_sales;

-- =========================================
-- 6. CREATE FACT TABLE
-- =========================================
CREATE TABLE fact_sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    region_id INT,
    date_id INT,
    sales DECIMAL(10,2),
    quantity INT,
    profit DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);

-- =========================================
-- 7. LOAD FACT TABLE
-- =========================================
INSERT INTO fact_sales (customer_id, product_id, region_id, date_id, sales, quantity, profit)
SELECT
    c.customer_id,
    p.product_id,
    r.region_id,
    d.date_id,
    rs.Sales,
    rs.Quantity,
    rs.Profit
FROM raw_sales rs
JOIN dim_customer c
    ON rs.Customer_Name = c.customer_name
JOIN dim_product p
    ON rs.Product_Name = p.product_name
JOIN dim_region r
    ON rs.Region = r.region
   AND rs.Country = r.country
JOIN dim_date d
    ON rs.Order_Date = d.order_date;

-- =========================================
-- 8. CREATE INDEXES
-- =========================================
CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_region ON fact_sales(region_id);
CREATE INDEX idx_fact_date ON fact_sales(date_id);

-- =========================================
-- 9. ANALYTICAL QUERIES
-- =========================================

-- Region-wise sales
SELECT r.region, SUM(f.sales) AS total_sales
FROM fact_sales f
JOIN dim_region r ON f.region_id = r.region_id
GROUP BY r.region;

-- Monthly sales trend
SELECT d.year, d.month, SUM(f.sales) AS monthly_sales
FROM fact_sales f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Top customers by sales
SELECT c.customer_name, SUM(f.sales) AS total_sales
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_sales DESC;

-- =========================================
-- 10. VALIDATION CHECKS
-- =========================================
SELECT COUNT(*) AS raw_records FROM raw_sales;
SELECT COUNT(*) AS fact_records FROM fact_sales;