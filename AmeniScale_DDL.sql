/*
ScriptName: DB_AmeniScale
Coder: Greeley
Date: 2026-01-22

vers     Date                    Coder			Issue
1.0      2026-01-12              Greeley		Initial
1.1      2026-01-20			     Greeley        Added AmenityCategories, Amenities, Locations, and ScoringResults tables
1.1      2026-01-22              Greeley        Normalized Address Tables (Strict 3NF)
*/

USE master
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name='DB_AmeniScale')
BEGIN
    ALTER DATABASE DB_AmeniScale SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE DB_AmeniScale
END
GO

CREATE DATABASE DB_AmeniScale
GO
USE DB_AmeniScale
GO

CREATE TABLE Tbl_Countries (
    CountryID INT PRIMARY KEY IDENTITY(1,1),
    CountryCode CHAR(2) NOT NULL,
    CountryName NVARCHAR(MAX) NOT NULL
);

CREATE TABLE Tbl_Subdivisions (
    SubdivisionID INT PRIMARY KEY IDENTITY(1,1),
    CountryID INT FOREIGN KEY REFERENCES Tbl_Countries(CountryID),
    SubdivisionCode NVARCHAR(10),
    SubdivisionName NVARCHAR(100) NOT NULL,
    Type NVARCHAR(50) DEFAULT 'Province'
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
    CategoryID INT FOREIGN KEY REFERENCES Tbl_AmenityCategories(CategoryID),
    Street NVARCHAR(255),
    City NVARCHAR(100),
    SubdivisionID INT FOREIGN KEY REFERENCES Tbl_Subdivisions(SubdivisionID),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY
);

CREATE TABLE Tbl_Locations (
    LocationID INT PRIMARY KEY IDENTITY(1,1),
    LocationName NVARCHAR(100),
    StreetNumber NVARCHAR(20),
    Street NVARCHAR(255),
    City NVARCHAR(100),
    SubdivisionID INT FOREIGN KEY REFERENCES Tbl_Subdivisions(SubdivisionID),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY,
    CalculatedScore DECIMAL(5,2),
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Tbl_ScoringResults (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT FOREIGN KEY REFERENCES Tbl_Locations(LocationID),
    -- Removed AmenityID in favor of using proxy later
    Distance DECIMAL(10,2),
    ContributionScore DECIMAL(5,2),
    CalculatedDate DATETIME DEFAULT GETDATE()
);
GO