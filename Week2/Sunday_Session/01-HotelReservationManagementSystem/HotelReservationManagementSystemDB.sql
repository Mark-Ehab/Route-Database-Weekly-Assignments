--===================================================
-- Create Hotel Reservation Managment System Database
--===================================================
CREATE DATABASE HotelReservationSystemDb

--===========================================================================
-- Use HotelReservationSystemDb database instead of master (default) database
--===========================================================================
USE HotelReservationSystemDb

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
CREATE TABLE HotelManagement.Hotels(
Id INT IDENTITY PRIMARY KEY,
[Name] NVARCHAR(30) NOT NULL, 
[Address] NVARCHAR(50) NOT NULL,
City NVARCHAR(10) NOT NULL,
StarRating INT NOT NULL,
ContactNumber NVARCHAR(20) NOT NULL,
ManagerId INT UNIQUE NOT NULL ,
CONSTRAINT CK_Hotels_StarRating CHECK (StarRating BETWEEN 1 AND 7)
)

-- Create Rooms Table in HotelManagement schema (FK Constraint is missing for HotelId column)
--===========================================================================================
CREATE TABLE HotelManagement.Rooms(
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
CREATE TABLE HotelManagement.Amenities(
Id INT IDENTITY PRIMARY KEY,
RoomNumber INT NOT NULL, 
Amenity NVARCHAR(20) NOT NULL, 
)

-- Create Staff Table in StaffAndServices schema (FK Constraint is missing for HotelId column)
--===========================================================================================
CREATE TABLE StaffAndServices.Staff(
Id INT IDENTITY PRIMARY KEY,
FullName NVARCHAR(30) NOT NULL, 
Position NVARCHAR(50) NOT NULL,
Salary DECIMAL(15,4) NOT NULL,
HotelId INT NOT NULL ,
)

-- Create Services Table in StaffAndServices schema (FK Constraint is missing for StaffId column)
--===============================================================================================
CREATE TABLE StaffAndServices.Services(
Id INT IDENTITY PRIMARY KEY,
ServiceName NVARCHAR(30) NOT NULL, 
RequestDate DATETIME2 NOT NULL,
Charge DECIMAL(15,4) NOT NULL,
StaffId INT NOT NULL ,
)

-- Create Reservations Table in Reservations schema
--=================================================
CREATE TABLE Reservations.Reservations(
Id INT IDENTITY PRIMARY KEY,
BookingDate DATETIME2 NOT NULL,
CheckInDate DATETIME2 NOT NULL,
CheckOutDate DATETIME2 NOT NULL,
ReservationStatus NVARCHAR(20) NOT NULL CHECK (ReservationStatus IN ('Reserved','Not Reserved')), 
TotalPrice DECIMAL(15,4) NOT NULL,
NumberOfAdults INT NOT NULL,
NumberOfChildren INT NOT NULL,
)

-- Create ReservationsRooms Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and RoomNumber columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsRooms(
Id INT IDENTITY PRIMARY KEY,
ReservationId INT NOT NULL,
RoomNumber INT NOT NULL,
)

-- Create ReservationsGuests Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and GuestId columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsGuests(
Id INT IDENTITY PRIMARY KEY,
ReservationId INT NOT NULL,
GuestId INT NOT NULL,
)

-- Create ReservationsServices Table in Reservations schema (FK Constraint is missing for ReservationId 
-- and ServiceId columns)
--====================================================================================================
CREATE TABLE Reservations.ReservationsServices(
Id INT IDENTITY PRIMARY KEY,
ReservationId INT NOT NULL,
ServiceId INT NOT NULL,
)

-- Create Guests Table in Guests schema
--=====================================
CREATE TABLE Guests.Guests(
Id INT IDENTITY PRIMARY KEY,
FullName NVARCHAR(30) NOT NULL, 
Nationality NVARCHAR(25) NOT NULL, 
PassportNumber NVARCHAR(25) NOT NULL,
DateOfBirth DATE NOT NULL, 
)

-- Create GuestContactDetails Table in Guests schema (FK Constraint is missing for GuestId)
--=========================================================================================
CREATE TABLE Guests.GuestContactDetails(
Id INT IDENTITY PRIMARY KEY,
Details INT NOT NULL,
GuestId INT NOT NULL,
)

-- Create Payments Table in Payments schema
--=========================================
CREATE TABLE Payments.Payments(
Id INT IDENTITY PRIMARY KEY,
Method NVARCHAR(30) NOT NULL, 
ConfirmationNumber NVARCHAR(50) NOT NULL,
Amount DECIMAL(10,4) NOT NULL,
[Date] DATE NOT NULL, 
)

-- Create ResevationsPayments Table in Payments schema (FK Constraint is missing for ReservationId 
-- and PaymentId columns)
--=================================================================================================
CREATE TABLE Payments.ReservationsPayments(
Id INT IDENTITY PRIMARY KEY,
ReservationId INT NOT NULL,
PaymentId INT NOT NULL,
)

-- Add missing foreign key constraints for previously created tables using ALTER Command
--======================================================================================
ALTER TABLE HotelManagement.Hotels
ADD CONSTRAINT FK_Hotels_ManagerId FOREIGN KEY (ManagerId) REFERENCES StaffAndServices.Staff(Id)

ALTER TABLE HotelManagement.Rooms
ADD CONSTRAINT FK_Rooms_HotelId FOREIGN KEY (HotelId) REFERENCES HotelManagement.Hotels(Id)

ALTER TABLE HotelManagement.Amenities
ADD CONSTRAINT FK_Amenities_RoomNumber FOREIGN KEY (RoomNumber) REFERENCES HotelManagement.Rooms(Id)

ALTER TABLE StaffAndServices.Staff
Add CONSTRAINT FK_Staff_HotelId FOREIGN KEY (HotelId) REFERENCES HotelManagement.Hotels(Id)

ALTER TABLE StaffAndServices.Services
Add CONSTRAINT FK_Services_StaffId FOREIGN KEY (StaffId) REFERENCES StaffAndServices.Staff(Id)

ALTER TABLE Reservations.ReservationsServices
ADD CONSTRAINT FK_ReservationsServices_ServiceId FOREIGN KEY (ServiceId) REFERENCES StaffAndServices.Services(Id)

ALTER TABLE Reservations.ReservationsServices
ADD CONSTRAINT FK_ReservationsServices_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)

ALTER TABLE Reservations.ReservationsRooms
ADD CONSTRAINT FK_ReservationsRooms_RoomNumber FOREIGN KEY (RoomNumber) REFERENCES HotelManagement.Rooms(Id)

ALTER TABLE Reservations.ReservationsRooms
ADD CONSTRAINT FK_ReservationsRooms_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)

ALTER TABLE Reservations.ReservationsGuests
ADD CONSTRAINT FK_ReservationsGuests_GuestId FOREIGN KEY (GuestId) REFERENCES Guests.Guests(Id)

ALTER TABLE Reservations.ReservationsGuests
ADD CONSTRAINT FK_ReservationsGuests_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)

ALTER TABLE Guests.GuestContactDetails
ADD CONSTRAINT FK_GuestContactDetails_GuestId FOREIGN KEY (GuestId) REFERENCES Guests.Guests(Id)

ALTER TABLE Payments.ReservationsPayments
ADD CONSTRAINT FK_ReservationsPayments_PaymentId FOREIGN KEY (PaymentId) REFERENCES Payments.Payments(Id)

ALTER TABLE Payments.ReservationsPayments
ADD CONSTRAINT FK_ReservationsPayments_ReservationId FOREIGN KEY (ReservationId) REFERENCES Reservations.Reservations(Id)
