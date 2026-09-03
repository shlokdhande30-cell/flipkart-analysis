/* ============================================================
   FLIPKART SALES ANALYSIS
   Database: Flipkart_Analysis
   Table: dbo.flipkart_sales
   ============================================================ */


/* ============================================================
   1. DATABASE SETUP
   ============================================================ */

CREATE DATABASE Flipkart_Analysis;
GO

USE Flipkart_Analysis;
GO


/* ============================================================
   2. CREATE RAW SALES TABLE
   ============================================================ */

CREATE TABLE dbo.flipkart_sales
(
    Order_ID          VARCHAR(50),
    Product_Name      VARCHAR(255),
    Category          VARCHAR(100),
    Price_INR         DECIMAL(12,2),
    Quantity_Sold     INT,
    Total_Sales_INR   DECIMAL(14,2),
    Order_Date        VARCHAR(20),
    Payment_Method    VARCHAR(50),
    Customer_Rating   DECIMAL(3,2)
);
GO


/* ============================================================
   3. DATA VALIDATION
   ============================================================ */


/* 3.1 Total rows and NULL check */

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Order_ID) AS Order_IDs,
    COUNT(Product_Name) AS Product_Names,
    COUNT(Category) AS Categories,
    COUNT(Price_INR) AS Prices,
    COUNT(Quantity_Sold) AS Quantities,
    COUNT(Total_Sales_INR) AS Total_Sales,
    COUNT(Order_Date) AS Order_Dates,
    COUNT(Payment_Method) AS Payment_Methods,
    COUNT(Customer_Rating) AS Ratings
FROM dbo.flipkart_sales;


/* 3.2 Duplicate Order Check */

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Order_ID) AS Unique_Orders
FROM dbo.flipkart_sales;


/* 3.3 Invalid Values Check */

SELECT
    SUM(CASE WHEN Price_INR <= 0 THEN 1 ELSE 0 END) AS Invalid_Price,
    SUM(CASE WHEN Quantity_Sold <= 0 THEN 1 ELSE 0 END) AS Invalid_Quantity,
    SUM(CASE WHEN Total_Sales_INR <= 0 THEN 1 ELSE 0 END) AS Invalid_Sales,
    SUM(
        CASE
            WHEN Customer_Rating < 1
              OR Customer_Rating > 5
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Rating
FROM dbo.flipkart_sales;


/* 3.4 Sales Calculation Validation */

SELECT
    COUNT(*) AS Total_Rows,
    SUM(
        CASE
            WHEN ABS(
                (Price_INR * Quantity_Sold) - Total_Sales_INR
            ) > 0.01
            THEN 1
            ELSE 0
        END
    ) AS Incorrect_Sales_Calculation
FROM dbo.flipkart_sales;


/* ============================================================
   4. OVERALL BUSINESS KPIs
   ============================================================ */

SELECT
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Quantity_Sold) AS Total_Units_Sold,
    SUM(Total_Sales_INR) AS Total_Revenue,
    ROUND(AVG(Price_INR), 2) AS Average_Product_Price,
    ROUND(AVG(Customer_Rating), 2) AS Average_Rating,
    ROUND(
        SUM(Total_Sales_INR) * 1.0
        / COUNT(DISTINCT Order_ID),
        2
    ) AS Average_Order_Value
FROM dbo.flipkart_sales;


/* ============================================================
   5. CATEGORY REVENUE ANALYSIS
   ============================================================ */

SELECT
    Category,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY Category
ORDER BY Revenue DESC;


/* ============================================================
   6. CATEGORY REVENUE CONTRIBUTION
   ============================================================ */

SELECT
    Category,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(
        SUM(Total_Sales_INR) * 100.0
        / SUM(SUM(Total_Sales_INR)) OVER (),
        2
    ) AS Revenue_Share_Percent
FROM dbo.flipkart_sales
GROUP BY Category
ORDER BY Revenue DESC;


/* ============================================================
   7. TOP 10 PRODUCTS BY REVENUE
   ============================================================ */

SELECT TOP 10
    Product_Name,
    Category,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY
    Product_Name,
    Category
ORDER BY Revenue DESC;


/* ============================================================
   8. TOP 10 PRODUCTS BY UNITS SOLD
   ============================================================ */

SELECT TOP 10
    Product_Name,
    Category,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY
    Product_Name,
    Category
ORDER BY Units_Sold DESC;


/* ============================================================
   9. PAYMENT METHOD ANALYSIS
   ============================================================ */

SELECT
    Payment_Method,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY Payment_Method
ORDER BY Revenue DESC;


/* ============================================================
   10. MONTHLY SALES TREND
   ============================================================ */

SELECT
    FORMAT(
        TRY_CONVERT(date, Order_Date, 105),
        'yyyy-MM'
    ) AS Sales_Month,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue
FROM dbo.flipkart_sales
GROUP BY
    FORMAT(
        TRY_CONVERT(date, Order_Date, 105),
        'yyyy-MM'
    )
ORDER BY Sales_Month;


/* ============================================================
   11. MONTHLY REVENUE RANKING
   CTE + RANK()
   ============================================================ */

WITH Monthly_Sales AS
(
    SELECT
        FORMAT(
            TRY_CONVERT(date, Order_Date, 105),
            'yyyy-MM'
        ) AS Sales_Month,
        COUNT(DISTINCT Order_ID) AS Total_Orders,
        SUM(Quantity_Sold) AS Units_Sold,
        SUM(Total_Sales_INR) AS Revenue
    FROM dbo.flipkart_sales
    GROUP BY
        FORMAT(
            TRY_CONVERT(date, Order_Date, 105),
            'yyyy-MM'
        )
)
SELECT
    Sales_Month,
    Total_Orders,
    Units_Sold,
    Revenue,
    RANK() OVER (
        ORDER BY Revenue DESC
    ) AS Revenue_Rank
FROM Monthly_Sales
ORDER BY Revenue DESC;


/* ============================================================
   12. REVENUE VS CUSTOMER SATISFACTION
   ============================================================ */

SELECT
    Category,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY Category
ORDER BY Avg_Rating DESC;


/* ============================================================
   13. TOP PRODUCT WITHIN EACH CATEGORY
   CTE + ROW_NUMBER() + PARTITION BY
   ============================================================ */

WITH Product_Sales AS
(
    SELECT
        Category,
        Product_Name,
        SUM(Quantity_Sold) AS Units_Sold,
        SUM(Total_Sales_INR) AS Revenue,
        ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
    FROM dbo.flipkart_sales
    GROUP BY
        Category,
        Product_Name
),
Ranked_Products AS
(
    SELECT
        Category,
        Product_Name,
        Units_Sold,
        Revenue,
        Avg_Rating,
        ROW_NUMBER() OVER
        (
            PARTITION BY Category
            ORDER BY Revenue DESC
        ) AS Product_Rank
    FROM Product_Sales
)
SELECT
    Category,
    Product_Name,
    Units_Sold,
    Revenue,
    Avg_Rating
FROM Ranked_Products
WHERE Product_Rank = 1
ORDER BY Revenue DESC;


/* ============================================================
   14. MONTH-OVER-MONTH REVENUE GROWTH
   CTE + LAG()
   ============================================================ */

WITH Monthly_Sales AS
(
    SELECT
        FORMAT(
            TRY_CONVERT(date, Order_Date, 105),
            'yyyy-MM'
        ) AS Sales_Month,
        SUM(Total_Sales_INR) AS Revenue
    FROM dbo.flipkart_sales
    GROUP BY
        FORMAT(
            TRY_CONVERT(date, Order_Date, 105),
            'yyyy-MM'
        )
),
Monthly_Growth AS
(
    SELECT
        Sales_Month,
        Revenue,
        LAG(Revenue) OVER (
            ORDER BY Sales_Month
        ) AS Previous_Month_Revenue
    FROM Monthly_Sales
)
SELECT
    Sales_Month,
    Revenue,
    Previous_Month_Revenue,
    ROUND(
        (Revenue - Previous_Month_Revenue) * 100.0
        / NULLIF(Previous_Month_Revenue, 0),
        2
    ) AS MoM_Growth_Percent
FROM Monthly_Growth
ORDER BY Sales_Month;


/* ============================================================
   15. HIGH-REVENUE PRODUCTS WITH BELOW-AVERAGE RATINGS
   Subquery + HAVING
   ============================================================ */

SELECT
    Product_Name,
    Category,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY
    Product_Name,
    Category
HAVING
    AVG(Customer_Rating) <
    (
        SELECT AVG(Customer_Rating)
        FROM dbo.flipkart_sales
    )
ORDER BY Revenue DESC;


/* ============================================================
   16. OPTIONAL: COMPLETE PRODUCT PERFORMANCE
   ============================================================ */

SELECT
    Product_Name,
    Category,
    SUM(Quantity_Sold) AS Units_Sold,
    SUM(Total_Sales_INR) AS Revenue,
    ROUND(AVG(Price_INR), 2) AS Avg_Price,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM dbo.flipkart_sales
GROUP BY
    Product_Name,
    Category
ORDER BY Revenue DESC;