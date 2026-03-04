/*
Performance Optimizations Applied (SQL Server)
1) Indexing strategies
2) Query restructuring
3) Faster aggregated-data retrieval alternatives
*/

/* 1) Indexing strategies */

-- Supports WHERE p.Category = @Category, JOIN on ProductID, and ProductName projection.
IF NOT EXISTS (
	SELECT 1
	FROM sys.indexes
	WHERE name = 'IX_Products_Category_ProductID'
	  AND object_id = OBJECT_ID('dbo.Products')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_Products_Category_ProductID
		ON dbo.Products (Category, ProductID)
		INCLUDE (ProductName);
END;
GO

-- Supports JOIN/GROUP BY on ProductID and SUM(Quantity) without extra lookups.
IF NOT EXISTS (
	SELECT 1
	FROM sys.indexes
	WHERE name = 'IX_Orders_ProductID_Quantity'
	  AND object_id = OBJECT_ID('dbo.Orders')
)
BEGIN
	CREATE NONCLUSTERED INDEX IX_Orders_ProductID_Quantity
		ON dbo.Orders (ProductID)
		INCLUDE (Quantity);
END;
GO


/* 2) Query restructuring for efficiency */

DECLARE @Category NVARCHAR(100) = N'Electronics';

-- Filter products first, then aggregate Orders only for matching ProductIDs.
;WITH FilteredProducts AS
(
	SELECT p.ProductID, p.ProductName
	FROM dbo.Products p
	WHERE p.Category = @Category
)
SELECT fp.ProductName,
	   SUM(o.Quantity) AS TotalSold
FROM FilteredProducts fp
JOIN dbo.Orders o
	ON o.ProductID = fp.ProductID
GROUP BY fp.ProductName
ORDER BY TotalSold DESC;


/* 3) Alternative faster aggregated-data retrieval */

/* Option A: Indexed view (great for heavy read workloads) */
-- Run once in deployment. Keep in mind write operations incur additional maintenance cost.
IF OBJECT_ID('dbo.vOrderTotalsByProduct', 'V') IS NULL
BEGIN
	EXEC ('
		CREATE VIEW dbo.vOrderTotalsByProduct
		WITH SCHEMABINDING
		AS
		SELECT
			o.ProductID,
			SUM(CONVERT(BIGINT, o.Quantity)) AS TotalSold,
			COUNT_BIG(*) AS RowCountBig
		FROM dbo.Orders o
		GROUP BY o.ProductID
	');
END;
GO

IF NOT EXISTS (
	SELECT 1
	FROM sys.indexes
	WHERE name = 'IX_vOrderTotalsByProduct_ProductID'
	  AND object_id = OBJECT_ID('dbo.vOrderTotalsByProduct')
)
BEGIN
	CREATE UNIQUE CLUSTERED INDEX IX_vOrderTotalsByProduct_ProductID
		ON dbo.vOrderTotalsByProduct (ProductID);
END;
GO

DECLARE @Category_IndexedView NVARCHAR(100) = N'Electronics';

SELECT p.ProductName,
	   v.TotalSold
FROM dbo.vOrderTotalsByProduct v
JOIN dbo.Products p
	ON p.ProductID = v.ProductID
WHERE p.Category = @Category_IndexedView
ORDER BY v.TotalSold DESC;


/* Option B: Summary table for near-real-time reporting */
-- Use this when you can refresh periodically (e.g., every 5 minutes).
IF OBJECT_ID('dbo.ProductSalesSummary', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.ProductSalesSummary
	(
		ProductID INT NOT NULL PRIMARY KEY,
		TotalSold BIGINT NOT NULL,
		LastRefreshedUtc DATETIME2(0) NOT NULL
	);
END;
GO

MERGE dbo.ProductSalesSummary AS target
USING
(
	SELECT o.ProductID,
		   SUM(CONVERT(BIGINT, o.Quantity)) AS TotalSold
	FROM dbo.Orders o
	GROUP BY o.ProductID
) AS source
ON target.ProductID = source.ProductID
WHEN MATCHED THEN
	UPDATE SET
		target.TotalSold = source.TotalSold,
		target.LastRefreshedUtc = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
	INSERT (ProductID, TotalSold, LastRefreshedUtc)
	VALUES (source.ProductID, source.TotalSold, SYSUTCDATETIME())
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
GO

DECLARE @Category_Summary NVARCHAR(100) = N'Electronics';

SELECT p.ProductName,
	   s.TotalSold,
	   s.LastRefreshedUtc
FROM dbo.ProductSalesSummary s
JOIN dbo.Products p
	ON p.ProductID = s.ProductID
WHERE p.Category = @Category_Summary
ORDER BY s.TotalSold DESC;