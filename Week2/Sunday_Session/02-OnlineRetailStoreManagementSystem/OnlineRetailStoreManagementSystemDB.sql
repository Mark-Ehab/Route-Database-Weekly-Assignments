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
	Rating DECIMAL(1,1) CHECK (Rating between 0 AND 5),
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
	[Status] NVARCHAR(30) NOT NULL CHECK ([Status] IN ('Delivered','Placed','Shipped','Out For Delivery')),
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