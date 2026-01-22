/*
ScriptName: DB_AmeniScale
Coder: Greeley
Date: 2026-01-12

vers     Date                    Coder			Issue
1.0      2026-01-12              Greeley		Initial
1.1      2026-01-20			     Greeley        Added AmenityCategories, Amenities, Locations, and ScoringResults tables
*/

USE master
GO
ALTER DATABASE DB_AmeniScale SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

USE master
GO
IF EXISTS(SELECT * FROM sys.databases WHERE name='DB_AmeniScale')
DROP DATABASE DB_AmeniScale

CREATE DATABASE DB_AmeniScale
GO
USE DB_AmeniScale

CREATE TABLE tbl_Example
(
	ID INT PRIMARY KEY IDENTITY(1,1),
	StatusString VARCHAR(MAX) NOT NULL,
);

CREATE TABLE Tbl_AmenityCategories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    BaseWeight DECIMAL(5,2),
    IsNegative BIT DEFAULT 0
);

CREATE TABLE Tbl_Amenities (
    AmenityID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES AmenityCategories(CategoryID),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY
);

CREATE TABLE Tbl_Locations (
    LocationID INT PRIMARY KEY IDENTITY(1,1),
    Address NVARCHAR(500),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY,
    CalculatedScore DECIMAL(5,2)
);

CREATE TABLE Tbl_ScoringResults (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT FOREIGN KEY REFERENCES Locations(LocationID),
    Distance DECIMAL(10,2),
    ContributionScore DECIMAL(5,2),
    CalculatedDate DATETIME DEFAULT GETDATE()
);