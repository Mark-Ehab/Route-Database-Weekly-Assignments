--======================================================
-- Create Online Retail Store Management System Database
--======================================================
CREATE DATABASE OnlineRetailStoreDb

--===========================================================================
-- Use OnlineRetailStoreDb database instead of master (default) database
--===========================================================================
USE OnlineRetailStoreDb

-- Create Suppliers Table in DBO Schema
--=====================================
CREATE TABLE Suppliers
(
	Id INT PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL,
	Country NVARCHAR(20) NOT NULL,
	Email NVARCHAR(20) UNIQUE NOT NULL,
	[Address] NVARCHAR(20) NOT NULL,
	ContactNumber NVARCHAR(20)
)

-- Create Categories Table in DBO Schema
--======================================
CREATE TABLE Categories
(
	Id INT PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL,
	[Description] NVARCHAR(200),
	MainCategory INT FOREIGN KEY REFERENCES Categories(Id)
)

-- Create Products Table in DBO Schema
--=====================================
CREATE TABLE Products
(
	Id INT PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL,
	StockQuantity INT NOT NULL,
	AddedDate DATE NOT NULL,
	[Description] NVARCHAR(200),
	UnitPrice DECIMAL(10,2) NOT NULL,
	CategoryId INT FOREIGN KEY REFERENCES Categories(Id)
)

-- Create Products_Suppliers Table in DBO Schema
--==============================================
CREATE TABLE Products_Suppliers
(
	SupplierId INT NOT NULL FOREIGN KEY REFERENCES Suppliers(Id),
	ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
	PRIMARY KEY(SupplierId,ProductId)
)

-- Create StoctTransactions Table in DBO Schema
--=============================================
CREATE TABLE StoctTransactions
(
	Id INT PRIMARY KEY,
	TranDate DATETIME2 NOT NULL,
	QuantityChange INT NOT NULL,
	[Type] NVARCHAR(30) NOT NULL,
	Reference NVARCHAR(30) NOT NULL,
	ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id)
)

-- Create Customers Table in DBO Schema
--=====================================
CREATE TABLE Customers
(
	Id INT PRIMARY KEY,
	[FullName] NVARCHAR(30) NOT NULL,
	Email NVARCHAR(30) NOT NULL UNIQUE,
	ShippingAddress NVARCHAR(30) NOT NULL,
	PhoneNumber NVARCHAR(30),
	RegistrationDate DATE NOT NULL,
)

-- Create Reviews Table in DBO Schema
--===================================
CREATE TABLE Reviews
(
	Id INT PRIMARY KEY,
	Rating DECIMAL(2,1) CHECK (Rating between 0 AND 5),
	Comment NVARCHAR(200),
	[Date] DATE,
	ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
	CustomerId INT NOT NULL FOREIGN KEY REFERENCES Customers(Id)
)

-- Create Orders Table in DBO Schema
--==================================
CREATE TABLE Orders
(
	Id INT PRIMARY KEY,
	TotalAmount DECIMAL(8,3) NOT NULL,
	[Status] NVARCHAR(30) NOT NULL CHECK ([Status] IN ('Delivered','Placed','Shipped','Out For Delivery','Cancelled','Premium','Standard')),
	[Date] DATETIME2 NOT NULL,
	CustomerId INT NOT NULL FOREIGN KEY REFERENCES Customers(Id)
)

-- Create OrderItems Table in DBO Schema
--======================================
CREATE TABLE OrderItems
(
	Id INT PRIMARY KEY,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(8,3) NOT NULL,
	ProductId INT NOT NULL FOREIGN KEY REFERENCES Products(Id),
	OrderId INT NOT NULL FOREIGN KEY REFERENCES Orders(Id),
)

-- Create Shipments Table in DBO Schema
-- ====================================
CREATE TABLE Shipments
(
	Id INT PRIMARY KEY,
	[Date] DATETIME2 NOT NULL,
	DeliveryDate DATETIME2 NOT NULL,
	CarrierName NVARCHAR(30) NOT NULL,
	TrackingNumber INT NOT NULL,
	OrderId INT NOT NULL FOREIGN KEY REFERENCES Orders(Id)
)

-- Create Payments Table in DBO Schema
-- ===================================
CREATE TABLE Payments
(
	Id INT PRIMARY KEY,
	[Date] DATETIME2 NOT NULL,
	Amount DECIMAL(7,2) NOT NULL,
	[Status] NVARCHAR(20) NOT NULL CHECK ([Status] in ('Completed','Pending','Failed','Cancelled','Refunded')),
	Method   NVARCHAR(20) NOT NULL 
)

-- Create Orders_Payments Table in DBO Schema
-- ==========================================
CREATE TABLE Orders_Payments
(
	OrderId INT NOT NULL FOREIGN KEY REFERENCES Orders(Id),
	PaymentId INT NOT NULL FOREIGN KEY REFERENCES Payments(Id),
	PRIMARY KEY (OrderId,PaymentId)
)

/* =========================================================================================================
											1. INSERT OPERATIONS 
===========================================================================================================*/
/*=================================
	Insert a new Customer Record
===================================*/
INSERT INTO Customers (Id,FullName, PhoneNumber, Email,
ShippingAddress, RegistrationDate)
VALUES ('1','Mina Emil','+201123056732','Mina@gmail.com','Ain Shams, Cairo, Egypt','2022-01-01')

--Test if previous command is executed as expected
SELECT * FROM Customers

/*======================================
	Insert new three Suppliers Records
========================================*/
INSERT INTO Suppliers
VALUES (1,'Mohamed Salah','Egypt','MoSalah@gmail.com','Shoubra,Cairo,Egypt','+201025056732'),
       (2,'Mohamed Fathy','Egypt','MoFathy@gmail.com','Sheraton,Cairo,Egypt','+201066056732'),
	   (3,'Omar Marmoush','Egypt','Marmoush@gmail.com','Maadi,Cairo,Egypt','+201025077732')

--Test if previous command is executed as expected
SELECT * FROM Suppliers

/*======================================
	Insert new two Categories Records
========================================*/
INSERT INTO Categories (Id,[Name],[Description])
VALUES (1,'Electronics','Some description about Electronics category'),
	   (2,'Clothes','Some description about Clothes category')

--Test if previous command is executed as expected
SELECT * FROM Categories

/*===============================================
	Insert a Product but only (Name, UnitPrice)
================================================*/
/*
	Drop all NOT NULL constraints on columns of Products table except (Name, UnitPrice) 
	columns to be able to populate Products table only on (Name, UnitPrice) columns 
*/
ALTER TABLE Products
ALTER COLUMN StockQuantity INT NULL
ALTER TABLE Products
ALTER COLUMN AddedDate DATE NULL

--Insert a Product record but only on (Name, UnitPrice) columns 
INSERT INTO Products (Id,[Name], UnitPrice) --Id is added cause it's the Primary Key for this table
VALUES(1,'Razer Blade 16', 700000.470)

--Test if previous command is executed as expected
SELECT * FROM Products

/*===========================================================================
	- Create table ArchivedStock (TranId, ProductId, QuantityChange,TranDate) 
	- Insert into ArchivedStock all StockTransactions before 2023
============================================================================*/
/*
	Create table ArchivedStock with the following columns (TranId, ProductId, 
	QuantityChange,TranDate) in Dbo (Default Schema) 
*/
CREATE TABLE ArchivedStock
(
	TranId INT PRIMARY KEY,
	ProductId INT NOT NULL,
	QuantityChange INT NOT NULL,
	TranDate DATETIME2 NOT NULL
)

-- Insert some products in Products table
INSERT INTO Products 
VALUES(2,'ASUS Duo', 100 , '2022-03-14' , 'Some Description',70000.470,1),
	  (3,'Lenovo Legion 5 Pro', 200 , '2023-05-15' , 'Some Description',90000,1),
	  (4,'LV Coat', 100 , '2023-11-15' , 'Some Description',9000,2),
	  (5,'Gucci T-Shirt', 500 , '2023-12-01' , 'Some Description',6000,2)

--Test if previous command is executed as expected
SELECT * FROM Products

-- Insert some transactions in StockTransactions table
INSERT INTO StoctTransactions
VALUES (1,'2019-04-04 12:08 PM', 2, 'Added to stock','-',2),
	   (2,'2020-04-23 04:28 PM', 1, 'Removed from stock','-',4),
	   (3,'2021-05-22 07:28 AM', 3, 'Added to stock','-',5),
	   (4,'2022-11-24 05:02 PM', 1, 'Removed from stock','-',1),
	   (5,'2023-10-30 07:10 PM', 2, 'Added to stock','-',3),
	   (6,'2024-02-28 06:12 PM', 1, 'Removed from stock','-',1),
	   (7,'2025-08-30 08:40 PM', 2, 'Added to stock','-',5)

--Test if previous command is executed as expected
SELECT * FROM StoctTransactions

--Insert into ArchivedStock all StockTransactions before 2023
INSERT INTO ArchivedStock (TranId,ProductId,QuantityChange,TranDate)
SELECT Id,ProductId,QuantityChange,TranDate FROM StoctTransactions
WHERE TranDate < '2023'

--Test if previous command is executed as expected
SELECT * FROM ArchivedStock

/* =========================================================================================================
											2.TEMPORARY TABLES
===========================================================================================================*/
/*===========================================================================
	- Create #CustomerOrders with (OrderId, CustomerId, TotalAmount)
	- Insert customers who made orders above 5000
============================================================================*/
-- Insert some customer records in Customers table
INSERT INTO Customers
VALUES ('2','Amr Elsolia','+201123326732','Amr@gmail.com','Haram, Giza, Egypt','2021-04-11'),
	   ('3','Amr Mustafa','+201135326732','AmrM@gmail.com','Dokki, Cairo, Egypt','2020-05-11'),
	   ('4','Youssf Khaled','+201123248732','Joe@gmail.com','Gesr el swis, Cairo, Egypt','2023-09-23'),
	   ('5','Mahmoud Helmy','+201123996732','Helmy@gmail.com','Obour, Cairo, Egypt','2019-01-30'),
	   ('6','Mohamed Masoud','+201129026732','MoMasoud@gmail.com','5th District, Cairo, Egypt','2024-05-11')

--Test if previous command is executed as expected
SELECT * FROM Customers

-- Insert some Order records in Customers table
INSERT INTO Orders
VALUES ('1',2000,'Delivered','2025-01-01',2),
	   ('2',20000,'Cancelled','2025-02-03',1),
	   ('3',1000,'Out For Delivery','2025-03-04',4),
	   ('4',55000,'Shipped','2025-04-05',6),
	   ('5',200,'Cancelled','2025-05-06',5),
	   ('6',59000.933,'Placed','2025-06-02',3)

--Test if previous command is executed as expected
SELECT * FROM Orders

--Create local temporary table called #CustomerOrders with the following columns (OrderId, CustomerId, TotalAmount)
CREATE TABLE #CustomerOrders
(
	OrderId INT PRIMARY KEY,
	CustomerId INT NOT NULL,
	TotalAmount DECIMAL(8,3)
)

--Insert customers who made orders above 5000 into #CustomerOrders table
INSERT INTO #CustomerOrders (OrderId,CustomerId,TotalAmount)
SELECT Id,CustomerId,TotalAmount FROM ORDERS
WHERE TotalAmount > 5000.00

--Test if previous command is executed as expected
SELECT * FROM #CustomerOrders

/*===========================================================================
	- Create ##TopRatedProducts with (ProductId, Rating)
	- Insert products with rating ≥ 4.5
============================================================================*/
-- Insert some Review records in Reviews table
INSERT INTO Reviews
VALUES ('1',2,'Some Comment','2025-01-01',2,4),
	   ('2',1.5,'Some Comment','2025-02-03',1,2),
	   ('3',4.5,'Some Comment','2025-03-04',4,1),
	   ('4',3,'Some Comment','2025-04-05',2,3),
	   ('5',5,'Some Comment','2025-05-06',5,4),
	   ('6',4,'Some Comment','2025-06-02',3,6)

--Test if previous command is executed as expected
SELECT * FROM Reviews

--Create global temporary table called ##TopRatedProducts with the following columns (ProductId, Rating)
CREATE TABLE ##TopRatedProducts
(
	Id INT IDENTITY PRIMARY KEY, 
	ProductId INT,
	Rating DECIMAL(2,1) 
)

--Insert customers who made orders above 5000 into #CustomerOrders table
INSERT INTO ##TopRatedProducts
SELECT ProductId,Rating FROM Reviews
WHERE Rating >= 4.5

--Test if previous command is executed as expected
SELECT * FROM ##TopRatedProducts

/* =========================================================================================================
											3. UPDATE OPERATIONS
===========================================================================================================*/
/*=============================================================
	Increase all UnitPrice by 10% for products under 100 EGP
===============================================================*/
-- Insert some products in Products table with UnitPrice under 100 EGP
INSERT INTO Products 
VALUES(6,'Logitech Mouse', 100 , '2019-03-14' , 'Some Description',70,1),
	  (7,'Defacto Socks', 200 , '2020-05-15' , 'Some Description',20,2),
	  (8,'Zara Jacket', 100 , '2024-11-15' , 'Some Description',50,2)

--Test if previous command is executed as expected
SELECT * FROM Products

--Increase all UnitPrice by 10% for products under 100 EGP
UPDATE Products
SET UnitPrice = (UnitPrice*(1.1))
WHERE UnitPrice < 100

--Test if previous command is executed as expected
SELECT * FROM Products

/*==================================================================
	Update Order Status: If TotalAmount > 5000 → “Premium” Else →
	“Standard”
===================================================================*/
UPDATE Orders
SET Status = 
CASE
	WHEN TotalAmount > 5000 THEN 'Premium'
	ELSE 'Standard'
END

--Test if previous command is executed as expected
SELECT * FROM Orders

/* =========================================================================================================
											4. DELETE OPERATIONS
===========================================================================================================*/
/*=================================
	Delete a Review by ReviewId
===================================*/
DELETE Reviews
WHERE Id = 5

--Test if previous command is executed as expected
SELECT * FROM Reviews

/*============================================
	Delete all Orders with Status = Cancelled
=============================================*/
--Delete all records of Orders table
DELETE Orders;

-- Insert back all records in Orders table with updated statuses
INSERT INTO Orders
VALUES ('1',2000,'Delivered','2025-01-01',2),
	   ('2',20000,'Cancelled','2025-02-03',1),
	   ('3',1000,'Out For Delivery','2025-03-04',4),
	   ('4',55000,'Shipped','2025-04-05',6),
	   ('5',200,'Cancelled','2025-05-06',5),
	   ('6',59000.933,'Placed','2025-06-02',3)

--Test if previous command is executed as expected
SELECT * FROM Orders

--Delete all Orders with Status of Cancelled
DELETE Orders
WHERE [Status] = 'Cancelled'

--Test if previous command is executed as expected
SELECT * FROM Orders

-- Insert some records in OrderItems table
INSERT INTO OrderItems
VALUES ('1',2,900,3,3),
	   ('2',1,1000,4,1),
	   ('3',3,5000,2,6)

--Test if previous command is executed as expected
SELECT * FROM OrderItems

/*============================================
	Delete OrderItems for a given OrderId
=============================================*/
DELETE OrderItems
WHERE OrderId = 1

--Test if previous command is executed as expected
SELECT * FROM OrderItems

/* =========================================================================================================
											5. MERGE OPERATION 
===========================================================================================================*/
/*======================================================================
	Create table #ProductsUpdate (ProductId, Name, UnitPrice,
	StockQuantity)
	MERGE logic:
	If product exists → UPDATE price & stock
	If new → INSERT
	If a product exists in main table but not in update table →
	DELETE
========================================================================*/
/*
	Create a local temporary table called #ProductsUpdate with following columns 
	(ProductId, Name, UnitPrice,StockQuantity)
*/
CREATE TABLE #ProductsUpdate
(
	ProductId INT PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL,
	UnitPrice DECIMAL(10,2) NOT NULL,
	StockQuantity INT ,
)

-- Insert some products in Products table
INSERT INTO #ProductsUpdate 
VALUES(3,'Dell G4', 60000.470, 50),
	  (7,'Defacto Skirt',  900, 230),
	  (9,'Armani Coat',  50000,400)

--Test if previous command is executed as expected
SELECT * FROM #ProductsUpdate

/*
	MERGE logic:
	If product exists → UPDATE price & stock
	If new → INSERT
	If a product exists in main table but not in update table →
	DELETE
*/
MERGE INTO #ProductsUpdate AS Target
USING Products AS Source
On (Source.Id = Target.ProductId)
WHEN MATCHED THEN
	UPDATE SET Target.UnitPrice = Source.UnitPrice,Target.StockQuantity = Source.StockQuantity
WHEN NOT MATCHED BY Target THEN
	INSERT (ProductId,Name,UnitPrice,StockQuantity) VALUES(Source.Id,Source.[Name],Source.UnitPrice,Source.StockQuantity)
WHEN NOT MATCHED BY Source THEN
DELETE;

--Test if previous command is executed as expected
SELECT * FROM #ProductsUpdate

