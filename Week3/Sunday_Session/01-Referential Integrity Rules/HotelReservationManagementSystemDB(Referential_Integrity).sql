--===================================================
-- Create Hotel Reservation Managment System Database
--===================================================
CREATE DATABASE HotelReservationSystemDb
GO

--===========================================================================
-- Use HotelReservationSystemDb database instead of master (default) database
--===========================================================================
USE HotelReservationSystemDb
GO

--================================================================================================
-- Create the following schemas: HotelManagement,StaffAndServices,Guests,Reservations and Payments
--================================================================================================
GO
CREATE SCHEMA HotelManagement
GO
CREATE SCHEMA StaffAndServices
GO
CREATE SCHEMA Guests
GO
CREATE SCHEMA Reservations
GO
CREATE SCHEMA Payments
GO

-- Create Hotels Table in HotelManagement schema (FK Constraint is missing for ManagerId column)
--==============================================================================================
CREATE TABLE HotelManagement.Hotels
(
Id INT IDENTITY PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL, 
	[Address] NVARCHAR(50) NOT NULL,
	City NVARCHAR(10) NOT NULL,
	StarRating INT NOT NULL,
	ContactNumber NVARCHAR(20) NOT NULL,
	ManagerId INT UNIQUE NOT NULL ,
	CONSTRAINT CK_Hotels_StarRating CHECK (StarRating BETWEEN 1 AND 7)
)
GO

-- Create Rooms Table in HotelManagement schema (FK Constraint is missing for HotelId column)
--===========================================================================================
CREATE TABLE HotelManagement.Rooms
(
	Id INT IDENTITY PRIMARY KEY,
	Number INT UNIQUE NOT NULL, 
	[Type] NVARCHAR(50) NOT NULL,
	Capacity INT NOT NULL,
	DailyRate DECIMAL(10,4) NOT NULL,
	[Availability] NVARCHAR(20) NOT NULL CHECK ([Availability] IN ('Available','Occupied','Maintainance')), 
	HotelId INT NOT NULL ,
)

-- Create Amenties Table in HotelManagement schema (FK Constraint is missing for RoomNumber column)
--=================================================================================================
CREATE TABLE HotelManagement.Amenities
(
	Id INT IDENTITY PRIMARY KEY,
	RoomNumber INT NOT NULL, 
	Amenity NVARCHAR(20) NOT NULL, 
)
GO

-- Create Staff Table in StaffAndServices schema (FK Constraint is missing for HotelId column)
--===========================================================================================
CREATE TABLE StaffAndServices.Staff
(
	Id INT IDENTITY PRIMARY KEY,
	FullName NVARCHAR(30) NOT NULL, 
	Position NVARCHAR(50) NOT NULL,
	Salary DECIMAL(15,4) NOT NULL,
	HotelId INT NOT NULL ,
)
GO

-- Create Services Table in StaffAndServices schema (FK Constraint is missing for StaffId column)
--===============================================================================================
CREATE TABLE StaffAndServices.Services
(
	Id INT IDENTITY PRIMARY KEY,
	ServiceName NVARCHAR(30) NOT NULL, 
	RequestDate DATETIME2 NOT NULL,
	Charge DECIMAL(15,4) NOT NULL,
	StaffId INT NOT NULL ,
)
GO

-- Create Reservations Table in Reservations schema
--=================================================
CREATE TABLE Reservations.Reservations
(
	Id INT IDENTITY PRIMARY KEY,
	BookingDate DATETIME2 NOT NULL,
	CheckInDate DATETIME2 NOT NULL,
	CheckOutDate DATETIME2 NOT NULL,
	ReservationStatus NVARCHAR(20) NOT NULL, 
	TotalPrice DECIMAL(15,4) NOT NULL,
	NumberOfAdults INT NOT NULL,
	NumberOfChildren INT NOT NULL,
)
GO
-- Create ReservationsRooms Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and RoomNumber columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsRooms
(
	Id INT IDENTITY PRIMARY KEY,
	ReservationId INT NOT NULL,
	RoomNumber INT NOT NULL,
)
GO

-- Create ReservationsGuests Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and GuestId columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsGuests
(
	Id INT IDENTITY PRIMARY KEY,
	ReservationId INT NOT NULL,
	GuestId INT NOT NULL,
)
GO

-- Create ReservationsServices Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and ServiceId columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsServices
(
	Id INT IDENTITY PRIMARY KEY,
	ReservationId INT NOT NULL,
	ServiceId INT NOT NULL,
)
GO

-- Create Guests Table in Guests schema
--=====================================
CREATE TABLE Guests.Guests
(
	Id INT IDENTITY PRIMARY KEY,
	FullName NVARCHAR(30) NOT NULL, 
	Nationality NVARCHAR(25) NOT NULL, 
	PassportNumber NVARCHAR(25) NOT NULL UNIQUE,
	DateOfBirth DATE NOT NULL, 
)

-- Create GuestContactDetails Table in Guests schema (FK Constraint is missing for GuestId)
--=========================================================================================
CREATE TABLE Guests.GuestContactDetails
(
	Id INT IDENTITY PRIMARY KEY,
	Details INT NOT NULL,
	GuestId INT NOT NULL,
)
GO

-- Create Payments Table in Payments schema
--=========================================
CREATE TABLE Payments.Payments
(
	Id INT IDENTITY PRIMARY KEY,
	Method NVARCHAR(30) NOT NULL, 
	ConfirmationNumber NVARCHAR(50) NOT NULL,
	Amount DECIMAL(10,4) NOT NULL,
	[Date] DATE NOT NULL, 
)
GO

-- Create ResevationsPayments Table in Payments schema (FK Constraint is missing for ReservationId 
-- and PaymentId columns)
--=================================================================================================
CREATE TABLE Payments.ReservationsPayments
(
	Id INT IDENTITY PRIMARY KEY,
	ReservationId INT NOT NULL,
	PaymentId INT NOT NULL,
)
GO

-- Add missing foreign key constraints for previously created tables using ALTER Command
--======================================================================================
ALTER TABLE HotelManagement.Hotels
ADD CONSTRAINT FK_Hotels_ManagerId FOREIGN KEY (ManagerId) REFERENCES StaffAndServices.Staff(Id)
GO
ALTER TABLE HotelManagement.Rooms
ADD CONSTRAINT FK_Rooms_HotelId FOREIGN KEY (HotelId) REFERENCES HotelManagement.Hotels(Id)
GO
ALTER TABLE HotelManagement.Amenities
ADD CONSTRAINT FK_Amenities_RoomNumber FOREIGN KEY (RoomNumber) REFERENCES HotelManagement.Rooms(Id)
GO
ALTER TABLE StaffAndServices.Staff
Add CONSTRAINT FK_Staff_HotelId FOREIGN KEY (HotelId) REFERENCES HotelManagement.Hotels(Id)
GO
ALTER TABLE StaffAndServices.Services
Add CONSTRAINT FK_Services_StaffId FOREIGN KEY (StaffId) REFERENCES StaffAndServices.Staff(Id)
GO
ALTER TABLE Reservations.ReservationsServices
ADD CONSTRAINT FK_ReservationsServices_ServiceId FOREIGN KEY (ServiceId) REFERENCES StaffAndServices.Services(Id)
GO
ALTER TABLE Reservations.ReservationsServices
ADD CONSTRAINT FK_ReservationsServices_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)
GO
ALTER TABLE Reservations.ReservationsRooms
ADD CONSTRAINT FK_ReservationsRooms_RoomNumber FOREIGN KEY (RoomNumber) REFERENCES HotelManagement.Rooms(Id)
GO
ALTER TABLE Reservations.ReservationsRooms
ADD CONSTRAINT FK_ReservationsRooms_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)
GO
ALTER TABLE Reservations.ReservationsGuests
ADD CONSTRAINT FK_ReservationsGuests_GuestId FOREIGN KEY (GuestId) REFERENCES Guests.Guests(Id)
GO
ALTER TABLE Reservations.ReservationsGuests
ADD CONSTRAINT FK_ReservationsGuests_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)
GO
ALTER TABLE Guests.GuestContactDetails
ADD CONSTRAINT FK_GuestContactDetails_GuestId FOREIGN KEY (GuestId) REFERENCES Guests.Guests(Id)
GO
ALTER TABLE Payments.ReservationsPayments
ADD CONSTRAINT FK_ReservationsPayments_PaymentId FOREIGN KEY (PaymentId) REFERENCES Payments.Payments(Id)
GO
ALTER TABLE Payments.ReservationsPayments
ADD CONSTRAINT FK_ReservationsPayments_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)


/* =========================================================================================================
											1. INSERT OPERATIONS 
===========================================================================================================*/
/* =======================================================
	Insert a new Guest record inside Guests.Guests Table
=========================================================*/
INSERT INTO Guests.Guests (FullName, Nationality, PassportNumber,
DateOfBirth)
VALUES ('Mina Emil','Egyptian','288009320532','1995-02-23')

--Test if previous command is executed as expected
SELECT * FROM Guests.Guests

/*======================================================================
	Insert multiple Guests in one statement inside Guests.Guests Table
========================================================================*/
INSERT INTO Guests.Guests (FullName, Nationality, PassportNumber,
DateOfBirth)
VALUES 
	('Mohamed Salah','Egyptian','288009320542','1995-10-25'),
	('Ahmed Ali','Egyptian','288009320535','1992-01-13'),
	('Leo Messi','Argentinian','288009220531','1990-06-08'),
    ('Cristiano Ronaldo','Portuguese','288009420532','1995-02-23')

--Test if previous command is executed as expected
SELECT * FROM Guests.Guests

/* =========================================================================================================
											2. UPDATE OPERATIONS
===========================================================================================================*/
/*===============================================
	 Increase DailyRate by 15% for all suites
=================================================*/
-- Insert at least one Hotel in HotelManagement.Hotels Table
-- Insert at least one Staff member (hotel manager) in StaffAndServices.Services Table
-- Turn off Foreign Key checks on both tables since they have a circular relationship before populating them
ALTER TABLE HotelManagement.Hotels NOCHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff NOCHECK CONSTRAINT [FK_Staff_HotelId];
GO
-- Insert one hotel record
INSERT INTO HotelManagement.Hotels
VALUES('Hilton','Ramsis Square, Cairo, Egypt','Cairo',5,'+0842050681',1)
GO
-- Insert one hotel manager record
INSERT INTO StaffAndServices.Staff
VALUES('Amr Saied','Manager',100000,1)

--Test if previous commands are executed as expected
SELECT * FROM HotelManagement.Hotels
SELECT * FROM StaffAndServices.Staff

-- Turn on Foreign Key checks on both tables since they have a circular relationship after populating them
ALTER TABLE HotelManagement.Hotels WITH CHECK CHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff WITH CHECK CHECK CONSTRAINT [FK_Staff_HotelId];

-- Insert at least Four records to HotelManagement.Rooms table
INSERT INTO HotelManagement.Rooms
VALUES (1,'Single',1,15000,'Available',1),
	   (2,'Double',2,30000,'Occupied',1),
	   (3,'Triple',3,45000.500,'Available',1),
	   (4,'Single',1,15000,'Maintainance',1)

--Test if previous command is executed as expected
SELECT * FROM HotelManagement.Rooms

--Increase DailyRate by 15% for all suites
UPDATE HotelManagement.Rooms
SET DailyRate = (DailyRate * (1.15))

--Test if previous command is executed as expected
SELECT * FROM HotelManagement.Rooms

/*===============================================================
	 Update ReservationStatus: If CheckoutDate < GETDATE() →
	'Completed' If CheckinDate > GETDATE() → 'Upcoming' Else →
	'Active'
=================================================================*/
--Insert at least three records to Reservations.Reservations table
INSERT INTO Reservations.Reservations
VALUES 
	('2025-05-04 12:00 PM','2025-08-10 02:00 PM','2025-08-17 12:00 PM','-',15000,2,2),
	('2026-05-04 12:00 PM','2026-08-10 02:00 PM','2026-08-17 12:00 PM','-',25000.878,1,3),
	('2025-06-04 12:00 PM','2025-12-10 02:00 PM','2025-12-17 12:00 PM','-',35000,3,1)

--Test if previous command is executed as expected
SELECT * FROM Reservations.Reservations

-- Update ReservationStatus to eihter 'Completed', 'Upcoming' or 'Active' based on CheckInDate
UPDATE Reservations.Reservations
SET ReservationStatus = 
Case
	WHEN CheckOutDate < GETDATE() THEN 'Completed'
	WHEN CheckInDate > GETDATE() THEN 'Upcoming'
	ELSE 'Active'
END

--Test if previous command is executed as expected
SELECT * FROM Reservations.Reservations

/* =========================================================================================================
											3. DELETE OPERATIONS
===========================================================================================================*/
/*===============================================
	 Delete Reservation_Guest for a reservation
=================================================*/
--Insert at least two records in Reservations.ReservationsGuests table
INSERT INTO Reservations.ReservationsGuests
VALUES (1,1),
	   (3,3)

--Test if previous command is executed as expected
SELECT * FROM Reservations.ReservationsGuests

-- Delete one record from Reservations.ReservationsGuests table for a reservation
DELETE Reservations.ReservationsGuests
WHERE ReservationId = 1

--Test if previous command is executed as expected
SELECT * FROM Reservations.ReservationsGuests


/* =========================================================================================================
											4. MERGE OPERATION 
===========================================================================================================*/
/* ===================================================================
	Create table #StaffUpdates (StaffId, FullName, Position, Salary)
	MERGE logic:
	Match → Update Position + Salary
	Not matched in Hotel DB → Insert
	Not matched in Update table → Delete
======================================================================*/
-- Turn off Foreign Key checks on both tables since they have a circular relationship before populating them
ALTER TABLE HotelManagement.Hotels NOCHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff NOCHECK CONSTRAINT [FK_Staff_HotelId];

-- Insert at least three records into StaffAndServices.Staff table 
INSERT INTO StaffAndServices.Staff
VALUES('Sara Mahmoud','House Keeping',20000,1),
	  ('Ahmed Mubarak','Receptionist',30000,1),
	  ('Omar Farouk','Room Service',20000,1)

--Test if previous command is executed as expected
SELECT * FROM StaffAndServices.Staff

-- Turn on Foreign Key checks on both tables since they have a circular relationship after populating them
ALTER TABLE HotelManagement.Hotels WITH CHECK CHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff WITH CHECK CHECK CONSTRAINT [FK_Staff_HotelId];

--Create a local temporary table called #StaffUpdates in Dbo Schema
CREATE TABLE #StaffUpdates 
(
	Id INT PRIMARY KEY,
	FullName NVARCHAR(20) NOT NULL,
	Position NVARCHAR(20) NOT NULL,
	Salary DECIMAL(10,2) NOT NULL,
)

--DROP TABLE #StaffUpdates 

-- Insert two records into #StaffUpdates table
INSERT INTO #StaffUpdates 
VALUES(2,'Amira Mousad','Room Service',25000),
	  (5,'Soliman Eid','Receptionist',35000)

--Test if previous command is executed as expected
SELECT * FROM #StaffUpdates 

--Merge between StaffAndServices.Staff table as Source INTO #StaffUpdates table as Target
MERGE INTO #StaffUpdates AS Target
USING StaffAndServices.Staff AS Source  
ON (Source.Id = Target.Id)
WHEN MATCHED THEN
	UPDATE SET Target.Position = Source.Position,Target.Salary = Source.Salary
WHEN NOT MATCHED BY Target THEN
	INSERT (Id,FullName,Position,Salary) 
	VALUES(Source.Id,Source.FullName,Source.Position,Source.Salary)
WHEN NOT MATCHED BY Source THEN
	DELETE;

--Test if previous command is executed as expected
SELECT * FROM #StaffUpdates 

/* =========================================================================================================
										Data Referential Integrity Rules
===========================================================================================================*/

/*==============================================================================
	1) If a hotel is deleted from the Hotels table, what is the appropriate
       behavior for the rooms belonging to that hotel? Explain which
       foreign key rule you would choose and why And Represent Rule
================================================================================*/

/*
	Suitable Foreign Key Rule ==> ON DELETE CASCADE
	Reason ==> The appropriate behavior for those rooms belonging to that hotel to be deleted shall
	           be also deleted as result (Cascade) cause rooms won't exist independently if the hotel
	           they are related to is deleted or isn't exist (Whole-Part Relation)
*/

/*
	Turn off Foreign Key checks on both tables since they have a circular relationship before modifying them
*/
ALTER TABLE HotelManagement.Hotels NOCHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff NOCHECK CONSTRAINT [FK_Staff_HotelId];

/*
	Drop Foreign Key constraint nammed FK_Staff_HotelId on HotelId column on StaffAndServices.Staff
	table
*/
ALTER TABLE StaffAndServices.Staff
DROP CONSTRAINT FK_Staff_HotelId

/*
	Add new Foreign Key constraint nammed FK_Staff_HotelId on HotelId column on StaffAndServices.Staff 
	table with DELETE ON CASCADE data referential integrity rule
*/
ALTER TABLE StaffAndServices.Staff
ADD CONSTRAINT FK_Staff_HotelId
FOREIGN KEY (HotelId) 
REFERENCES HotelManagement.Hotels(Id)
ON DELETE CASCADE

/*
	Turn on Foreign Key checks on both tables since they have a circular relationship after modifying them
*/
ALTER TABLE HotelManagement.Hotels WITH CHECK CHECK CONSTRAINT [FK_Hotels_ManagerId];
ALTER TABLE StaffAndServices.Staff WITH CHECK CHECK CONSTRAINT [FK_Staff_HotelId];

/*
	Drop Foreign Key constraint nammed FK_Rooms_HotelId on HotelId column on HotelManagement.Rooms 
	table
*/
ALTER TABLE HotelManagement.Rooms
DROP CONSTRAINT FK_Rooms_HotelId

/*
	Add new Foreign Key constraint nammed FK_Rooms_HotelId on HotelId column on HotelManagement.Rooms 
	table with ON DELETE CASCADE data referential integrity rule
*/
ALTER TABLE HotelManagement.Rooms
ADD CONSTRAINT FK_Rooms_HotelId 
FOREIGN KEY (HotelId) 
REFERENCES HotelManagement.Hotels(Id)
ON DELETE CASCADE

/*
	Delete a Hotel record from HotelManagement.Hotels table
*/
DELETE HotelManagement.Hotels 
WHERE Id = 5

/*
	Test if previous command is executed as expected
*/
SELECT * FROM HotelManagement.Hotels  
SELECT * FROM HotelManagement.Rooms
SELECT * FROM StaffAndServices.Staff

/*==============================================================================
	2) When a room is deleted from the Rooms table, what should happen to the 
	   related records in Amenities? Which rule makes the most sense for this 
	   relationship, and why? And Represent Rule
================================================================================*/

/*
	Suitable Foreign Key Rule ==> ON DELETE SET NULL
	Reason ==> Related Amenities to the room to be deleted shall be set to NULL
			   (Unassigned) until been assigned to other room
	Also can be set to default room number which means 
	Foreign Key Rule can be ON DELETE SET DEFAULT
*/

/*
	Drop Foreign Key constraint nammed FK_Amenities_RoomNumber on RoomNumber column on HotelManagement.Amenities 
	table
*/
ALTER TABLE HotelManagement.Amenities
DROP CONSTRAINT FK_Amenities_RoomNumber

/*
	Drop NOT NULL constraint on RoomNumber column on HotelManagement.Amenities 
	table
*/
ALTER TABLE HotelManagement.Amenities
ALTER COLUMN RoomNumber INT NULL

/*
	Add Foreign Key constraint nammed FK_Amenities_RoomNumber on RoomNumber column on HotelManagement.Amenities 
	table with ON DELETE SET NULL referential integrity rule
*/
ALTER TABLE HotelManagement.Amenities
ADD CONSTRAINT FK_Amenities_RoomNumber 
FOREIGN KEY (RoomNumber)
REFERENCES HotelManagement.Rooms(Id)
ON DELETE SET NULL


/*
	Delete a room record from HotelManagement.Rooms table
*/
DELETE HotelManagement.Rooms
WHERE Id = 1

/*
	Test if previous command is executed as expected
*/
SELECT * FROM HotelManagement.Rooms
SELECT * FROM HotelManagement.Amenities 

/*==============================================================================
	3) If a staff member’s ID changes, what impact should this have on
       the Services they are linked to? Which update rule is most
       suitable? And Represent Rule
================================================================================*/

/*
	Suitable Foreign Key Rule ==> ON UPDATE CASCADE
	Reason ==> Services that are linked to staff member whose Id is updated shall have their
			   linked staff member Id uptated too (CASCADE) cause there is no reason to set
			   it to NULL or a Default value as the staff member whose staff id is still on
			   the system
*/

/*
	Create version 2 of Staff Table in StaffAndServices schema without an IDENTITY Primary Key
	to try the ON UPDATE CASCADE referential integrity rule through it cause the first version 
	is using an IDENTITY Primary Key
*/
CREATE TABLE StaffAndServices.StaffV2
(
	Id INT PRIMARY KEY,
	FullName NVARCHAR(30) NOT NULL, 
	Position NVARCHAR(50) NOT NULL,
	Salary DECIMAL(15,4) NOT NULL,
	HotelId INT NOT NULL FOREIGN KEY REFERENCES HotelManagement.Hotels(Id) 
)

/*
	Insert data from StaffAndServices.Staff table into StaffAndServices.StaffV2 table
*/
INSERT INTO StaffAndServices.StaffV2
SELECT * FROM StaffAndServices.Staff

/*
	Test if previous command is executed as expected
*/
SELECT * FROM StaffAndServices.StaffV2

/*
	Drop Foreign Key constraint nammed FK_Services_StaffId on StaffId column on StaffAndServices.Services 
	table
*/
ALTER TABLE StaffAndServices.Services
DROP CONSTRAINT FK_Services_StaffId 

/*
	Add Foreign Key constraint nammed FK_Services_StaffId on StaffId column on StaffAndServices.Services 
	table with ON UPDATE CASCADE referential integrity rule and make it refer to Id column which is PK
	of StaffAndServices.StaffV2 table
*/
ALTER TABLE StaffAndServices.Services
ADD CONSTRAINT FK_Services_StaffId
FOREIGN KEY (StaffId)
REFERENCES StaffAndServices.StaffV2(Id)
ON UPDATE CASCADE

/*
	Update the Id of a Staff member record in StaffAndServices.StaffV2 table
*/
UPDATE StaffAndServices.StaffV2
SET Id = 5
WHERE Id = 2

/*
	Test if previous command is executed as expected
*/
SELECT * FROM StaffAndServices.StaffV2
SELECT * FROM StaffAndServices.Services