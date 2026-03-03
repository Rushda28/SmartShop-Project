USE SmartShopDB;
GO

-- 1. Branches 
CREATE TABLE Branches (
    BranchID INT PRIMARY KEY,
    BranchName VARCHAR(50),
    Location VARCHAR(50)
);

INSERT INTO Branches VALUES 
(1, 'Online Store', 'Digital'), (2, 'London Central', 'London'),
(3, 'Glasgow Store', 'Glasgow'), (4, 'Birmingham Hub', 'Birmingham'),
(5, 'Leeds Outlet', 'Leeds'), (6, 'Manchester North', 'Manchester');

-- 2. Staff 
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY,
    StaffName VARCHAR(50),
    Role VARCHAR(50),
    BranchID INT FOREIGN KEY REFERENCES Branches(BranchID)
);

INSERT INTO Staff VALUES 
(101, 'Alice', 'Manager', 1), (102, 'Bob', 'Sales', 2),
(103, 'Charlie', 'Sales', 3), (104, 'David', 'Support', 4),
(105, 'Eve', 'Manager', 5), (106, 'Frank', 'Sales', 6);

-- 3. Suppliers 
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    SupplierName VARCHAR(50),
    ContactCity VARCHAR(50)
);

INSERT INTO Suppliers VALUES 
(201, 'TechCorp', 'London'), (202, 'GlobalGear', 'Manchester'),
(203, 'EliteSupplies', 'Glasgow'), (204, 'PrimeParts', 'Birmingham'),
(205, 'NordicTech', 'Leeds'), (206, 'EuroGoods', 'Bristol');

-- 4. Products 
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Category VARCHAR(50),
    Price DECIMAL(10,2),
    SupplierID INT FOREIGN KEY REFERENCES Suppliers(SupplierID)
);

INSERT INTO Products VALUES 
(1, 'Laptop', 'Electronics', 800.00, 201), (2, 'Mouse', 'Accessories', 25.00, 202),
(3, 'Keyboard', 'Accessories', 45.00, 203), (4, 'Monitor', 'Electronics', 150.00, 204),
(5, 'Desk Lamp', 'Home', 30.00, 205), (6, 'HDMI Cable', 'Accessories', 15.00, 206);

-- 5.Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    Email VARCHAR(50),
    RegistrationDate DATE
);

INSERT INTO Customers VALUES 
(1, 'John Doe', 'john@mail.com', '2025-01-01'), (2, 'Jane Smith', 'jane@mail.com', '2025-01-05'),
(3, 'Mike Ross', 'mike@mail.com', '2025-02-10'), (4, 'Rachel Zane', 'rachel@mail.com', '2025-02-15'),
(5, 'Harvey Specter', 'harvey@mail.com', '2025-02-20'), (6, 'Donna Paulsen', 'donna@mail.com', '2025-02-25');


-- 6. Sales
CREATE TABLE Sales (
    SalesID INT PRIMARY KEY,
    OrderDate DATE,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    BranchID INT FOREIGN KEY REFERENCES Branches(BranchID),
    Quantity INT
);

INSERT INTO Sales VALUES 
(501, '2026-01-01', 1, 1, 1, 1), (502, '2026-01-02', 2, 2, 2, 3),
(503, '2026-01-03', 3, 4, 3, 2), (504, '2026-01-04', 4, 1, 4, 1),
(505, '2026-01-05', 5, 5, 5, 5), (506, '2026-01-06', 6, 6, 6, 10);

-- 7. Inventory
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY,
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    BranchID INT FOREIGN KEY REFERENCES Branches(BranchID),
    StockLevel INT,
    LastRestockDate DATE
);

INSERT INTO Inventory VALUES 
(1, 1, 1, 200, '2026-01-01'), (2, 2, 2, 170, '2026-01-01'),
(3, 3, 3, 110, '2026-01-01'), (4, 4, 4, 85, '2026-01-01'),
(5, 5, 5, 40, '2026-01-01'), (6, 6, 6, 15, '2026-01-01');

TRUNCATE TABLE Sales;


INSERT INTO Sales (SalesID, OrderDate, CustomerID, ProductID, BranchID, Quantity) VALUES 
(501, '2026-01-15', 1, 1, 1, 2), -- Jan: High value Laptop
(502, '2026-02-10', 2, 2, 2, 5), -- Feb: Accessories
(503, '2026-03-05', 3, 4, 3, 1), -- Mar: Monitor
(504, '2026-04-20', 4, 1, 4, 1), -- Apr: Laptop
(505, '2026-05-12', 5, 5, 5, 3), -- May: Home/Lamp
(506, '2026-06-18', 6, 6, 6, 10),-- Jun: Bulk Accessories
(507, '2026-01-25', 2, 3, 1, 2), -- More Jan data
(508, '2026-03-28', 5, 2, 2, 4); -- More Mar data

USE SmartShopDB; 
GO

-- Top 5 Selling Products by Total Quantity
SELECT TOP 5 
    p.ProductName, 
    SUM(s.Quantity) AS TotalUnitsSold
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalUnitsSold DESC;

-- Monthly Revenue across different Branches
SELECT 
    b.BranchName, 
    FORMAT(s.OrderDate, 'yyyy-MM') AS SalesMonth, 
    SUM(s.Quantity * p.Price) AS MonthlyRevenue
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
JOIN Branches b ON s.BranchID = b.BranchID
GROUP BY b.BranchName, FORMAT(s.OrderDate, 'yyyy-MM')
ORDER BY SalesMonth ASC;

--  stock shortages by Branch (Threshold < 20)
SELECT 
    b.BranchName, 
    p.ProductName, 
    i.StockLevel
FROM Inventory i
JOIN Branches b ON i.BranchID = b.BranchID
JOIN Products p ON i.ProductID = p.ProductID
WHERE i.StockLevel < 20;

-- Identify Top 5 Customers by Total Spend
SELECT TOP 5 
    c.CustomerName, 
    COUNT(s.SalesID) AS TotalOrders,
    SUM(s.Quantity * p.Price) AS TotalSpent
FROM Sales s
JOIN Customers c ON s.CustomerID = c.CustomerID
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerName
ORDER BY TotalSpent DESC;

CREATE INDEX idx_OrderDate ON Sales(OrderDate);--creating a non-clustered index to reduce the search time

BEGIN TRANSACTION;
UPDATE Inventory SET StockLevel = StockLevel - 1 WHERE ProductID = 1;
INSERT INTO Sales (ProductID, Quantity, OrderDate) VALUES (1, 1, GETDATE());
COMMIT;--locking mechanism

INSERT INTO Sales (SalesID, ProductID, Quantity, OrderDate)
VALUES (999, 1, 9999, GETDATE()); -- A human typo that the DB allows(9999 instead of 9)

SELECT ProductID, Price, PromotionType FROM Products; 
-- Error: Invalid column name 'PromotionType'

-- Trying to apply a 'Buy One Get One' (BOGO) logic 
-- but the table doesn't have a 'PromotionID' or 'Discount' column.
SELECT SalesID, ProductID, (Price * 0.5) AS BOGO_Price 
FROM Sales 
JOIN Products ON Sales.ProductID = Products.ProductID
WHERE PromotionType = 'BOGO';