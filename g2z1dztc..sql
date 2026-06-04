CREATE TABLE Staff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    StaffName VARCHAR(100) NOT NULL,
    StaffRole VARCHAR(50) NOT NULL 
        CHECK (StaffRole IN ('Manager', 'Sales Staff', 'Stock Clerk')),
    ContactNumber VARCHAR(20) NOT NULL,
    HireDate DATE NOT NULL,
    Login_Infos VARCHAR(155) NOT NULL UNIQUE,  
    
);
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NOT NULL UNIQUE,  
    Email VARCHAR(100) UNIQUE NULL,    
    Address VARCHAR(255) NULL,          
    JoinDate DATE NOT NULL DEFAULT GETDATE(),  
    LoyaltyPoints INT NOT NULL DEFAULT 0  
);

CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    SupplierName VARCHAR(100) NOT NULL,
    ContactPhone VARCHAR(20) NOT NULL UNIQUE  
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(255) NOT NULL,
    Category VARCHAR(50) NOT NULL 
        CHECK (Category IN ('Snacks', 'Beverages', 'Dairy', 'Bakery')),
    Price DECIMAL(10,2) NOT NULL 
        CHECK (Price > 0),
    StockQuantity INT NOT NULL 
        CHECK (StockQuantity >= 0),
    ExpiryDate DATE NULL,  
    SupplierID INT NOT NULL 
        FOREIGN KEY REFERENCES Suppliers(SupplierID)
        
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    SaleDate DATETIME NOT NULL DEFAULT GETDATE(),
    StaffID INT NOT NULL 
        FOREIGN KEY REFERENCES Staff(StaffID)
        ON DELETE NO ACTION,  
    CustomerID INT NULL 
        FOREIGN KEY REFERENCES Customers(CustomerID)
        ON DELETE SET NULL,
    ProductID INT NOT NULL 
        FOREIGN KEY REFERENCES Products(ProductID)
        ON DELETE NO ACTION,
    Quantity INT NOT NULL 
        CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL 
        CHECK (UnitPrice > 0),
    TotalAmount AS (Quantity * UnitPrice)  
);

INSERT INTO Staff (StaffName, StaffRole, ContactNumber, HireDate, Login_Infos) VALUES
('Ali Hassan', 'Sales Staff', '0791112222', '2025-01-15', 'ahassan:user123'),  
('Mariam Khalil', 'Sales Staff', '0793334444', '2025-03-20', 'mkhalil:ssuser1'),
('Fatima Al-Said', 'Manager', '0795556666', '2024-06-01', 'fsaid:adminf'),
('Ahmad Ibrahim', 'Stock Clerk', '0797778888', '2025-09-10', 'aibrahim:scusera');
SELECT * FROM Staff;

INSERT INTO Customers(CustomerName, Phone, Email, Address, JoinDate, LoyaltyPoints) VALUES
('Sarah Ahmed', '0791234567', 'sarah.ahmed@email.com', 'Amman, Abdali Mall, PO Box 12345', '2026-01-10', 150),  
('Omar Fawzi', '0799876543', 'omar.fawzi@gmail.com', 'Zarqa, City Center Street 45', '2026-02-15', 75),   
('Layla Mahmoud', '0794567890', NULL, 'Irbid, University Street 78, Apt 12', '2026-04-01', 0);   

SELECT CustomerID, CustomerName, Phone, Email, LoyaltyPoints, JoinDate
FROM Customers
ORDER BY CustomerID;


USE HyperMaxStoreDB;
GO
 
-- 1) Suppliers  (Products need a supplier to exist first) -----
INSERT INTO Suppliers (SupplierName, ContactPhone) VALUES
('Frito-Lay',    '0791000001'),
('Coca-Cola Co', '0791000002'),
('Nestle',       '0791000003'),
('Almarai',      '0791000004');
 
-- 2) Products  (each links to a SupplierID above) -------------
-- A few expiry dates are set close to today's date so the
-- "products near expiry (7 days)" report shows real results.
INSERT INTO Products (ProductName, Category, Price, StockQuantity, ExpiryDate, SupplierID) VALUES
('Lays Chips', 'Snacks',    1.50, 100, '2026-12-31', 1),
('Coca Cola',  'Beverages', 2.00, 150, NULL,         2),
('Sprite',     'Beverages', 1.80, 120, NULL,         2),
('Milk 1L',    'Dairy',     3.50,  80, '2026-06-05', 4),
('Croissant',  'Bakery',    2.50,  50, '2026-06-03', 3),
('Doritos',    'Snacks',    2.50,  50, '2026-06-08', 1);
 
-- 3) Sales  (need Staff, Customers and Products to exist) ------
-- Do NOT insert TotalAmount: it is calculated automatically.
-- NULL CustomerID = a walk-in customer.
INSERT INTO Sales (StaffID, CustomerID, ProductID, Quantity, UnitPrice) VALUES
(1, 1,    1, 10, 1.50),   -- Ali sold Lays Chips to Sarah
(2, NULL, 2,  5, 2.00),   -- Mariam sold Coca Cola (walk-in)
(2, NULL, 3,  3, 1.80),   -- Mariam sold Sprite (walk-in)
(1, 2,    1,  7, 1.50),   -- Ali sold Lays Chips to Omar
(3, 3,    4,  2, 3.50),   -- Fatima sold Milk to Layla
(4, NULL, 6,  4, 2.50);   -- Ahmad sold Doritos (walk-in)
 
-- 4) Quick checks ---------------------------------------------
SELECT * FROM Suppliers;
SELECT * FROM Products;
SELECT * FROM Sales;
 


 SELECT  sa.SaleID,
        sa.SaleDate,
        st.StaffName,
        ISNULL(c.CustomerName, 'Walk-in') AS Customer,
        p.ProductName,
        p.Category,
        sa.Quantity,
        sa.UnitPrice,
        sa.TotalAmount
FROM        Sales      sa
JOIN        Staff      st ON sa.StaffID    = st.StaffID
LEFT JOIN   Customers  c  ON sa.CustomerID = c.CustomerID
JOIN        Products   p  ON sa.ProductID  = p.ProductID
ORDER BY    sa.SaleDate DESC;



CREATE INDEX IX_Sales_SaleDate ON Sales(SaleDate);

CREATE INDEX IX_Products_Category ON Products(Category);


SELECT ProductID, ProductName, Category, ExpiryDate, StockQuantity
FROM Products
WHERE ExpiryDate IS NOT NULL
  AND ExpiryDate BETWEEN CAST(GETDATE() AS DATE)
                     AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
ORDER BY ExpiryDate;



SELECT p.Category,
       COUNT(*)           AS NumberOfSales,
       SUM(s.Quantity)    AS UnitsSold,
       SUM(s.TotalAmount) AS Revenue
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY Revenue DESC;



SELECT st.StaffName,
       COUNT(*)           AS NumberOfSales,
       SUM(s.TotalAmount) AS Revenue
FROM Sales s
JOIN Staff st ON s.StaffID = st.StaffID
GROUP BY st.StaffName
ORDER BY Revenue DESC;


SELECT ProductID, ProductName, Category, StockQuantity
FROM Products
WHERE StockQuantity < 60
ORDER BY StockQuantity;