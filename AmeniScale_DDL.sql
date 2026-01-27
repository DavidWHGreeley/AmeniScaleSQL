/*
ScriptName: DB_AmeniScale
Coder: Greeley
Date: 2026-01-22

vers     Date                    Coder			Issue
1.0      2026-01-12              Greeley		Initial
1.1      2026-01-20			     Greeley        Added AmenityCategories, Amenities, Locations, and ScoringResults tables
1.1      2026-01-22              Greeley        Normalized Address Tables (Strict 3NF)
1.1      2026-01-26             Patric          Added Checks.
*/

USE master
GO
IF EXISTS(SELECT * FROM sys.databases WHERE name='DB_AmeniScale')
DROP DATABASE DB_AmeniScale

CREATE DATABASE DB_AmeniScale
GO
USE DB_AmeniScale

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
    BaseWeight DECIMAL(5,2) NOT NULL DEFAULT 0,
    IsNegative BIT DEFAULT 0
);

CREATE TABLE Tbl_Amenities (
    AmenityID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255),
    CategoryID INT FOREIGN KEY REFERENCES Tbl_AmenityCategories(CategoryID),
    Street NVARCHAR(255),
    City NVARCHAR(100),
    SubdivisionID INT FOREIGN KEY REFERENCES Tbl_Subdivisions(SubdivisionID),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY,
    GeometryType AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STGeometryType() END),
    LocationWKT AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STAsText() END)
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
    GeometryType AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STGeometryType() END),
    LocationWKT AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STAsText() END),
    CalculatedScore DECIMAL(5,2),
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Tbl_ScoringResults (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT FOREIGN KEY REFERENCES Tbl_Locations(LocationID),
    Distance DECIMAL(10,2),
    ContributionScore DECIMAL(5,2),
    CalculatedDate DATETIME DEFAULT GETDATE()
);
GO

ALTER TABLE Tbl_Amenities
ADD CONSTRAINT CK_Amenities_Latitude CHECK (Latitude BETWEEN -90 AND 90);

ALTER TABLE Tbl_Amenities
ADD CONSTRAINT CK_Amenities_Longitude CHECK (Longitude BETWEEN -180 AND 180);

ALTER TABLE Tbl_Locations
ADD CONSTRAINT CK_Locations_Latitude CHECK (Latitude BETWEEN -90 AND 90);

ALTER TABLE Tbl_Locations
ADD CONSTRAINT CK_Locations_Longitude CHECK (Longitude BETWEEN -180 AND 180);

ALTER TABLE Tbl_Countries
ADD CONSTRAINT CK_Countries_CountryCode CHECK (LEN(CountryCode) = 2);

ALTER TABLE Tbl_AmenityCategories
ADD CONSTRAINT UQ_AmenityCategories_CategoryName UNIQUE (CategoryName);

ALTER TABLE Tbl_AmenityCategories
ADD CONSTRAINT CK_AmenityCategories_BaseWeight CHECK (BaseWeight >= 0);

ALTER TABLE Tbl_Locations
ADD CONSTRAINT CK_Locations_CalculatedScore CHECK (CalculatedScore BETWEEN 0 AND 100);

ALTER TABLE Tbl_ScoringResults
ADD CONSTRAINT CK_ScoringResults_Distance CHECK (Distance >= 0);

ALTER TABLE Tbl_Countries
ADD CONSTRAINT CK_Countries_CountryCode_Format CHECK (CountryCode = UPPER(CountryCode) AND CountryCode NOT LIKE '%[^A-Z]%');