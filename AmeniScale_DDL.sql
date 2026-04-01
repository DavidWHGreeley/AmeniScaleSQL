/*
ScriptName: DB_AmeniScale
Coder: Greeley
Date: 2026-01-22

vers     Date                    Coder			Issue
0.1      2026-01-12              Greeley		Initial
0.2      2026-01-20			     Greeley        Added AmenityCategories, Amenities, Locations, and ScoringResults tables
0.3      2026-01-22              Greeley        Normalized Address Tables (Strict 3NF)
0.4      2026-01-26              Patric         Added Checks.
0.5      2026-01-31              Greeley        Allow for re-running of code without errors
0.6      2026-03-18              Cody           Added Tbl_ScoredIsochrones
*/

USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'DB_AmeniScale')
BEGIN
    ALTER DATABASE DB_AmeniScale SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DB_AmeniScale;
END
GO

CREATE DATABASE DB_AmeniScale;
GO

USE DB_AmeniScale;
GO

IF OBJECT_ID('Tbl_ScoringResults', 'U') IS NOT NULL DROP TABLE Tbl_ScoringResults;
IF OBJECT_ID('Tbl_Locations', 'U') IS NOT NULL DROP TABLE Tbl_Locations;
IF OBJECT_ID('Tbl_Amenities', 'U') IS NOT NULL DROP TABLE Tbl_Amenities;
IF OBJECT_ID('Tbl_AmenityCategories', 'U') IS NOT NULL DROP TABLE Tbl_AmenityCategories;
IF OBJECT_ID('Tbl_Subdivisions', 'U') IS NOT NULL DROP TABLE Tbl_Subdivisions;
IF OBJECT_ID('Tbl_Countries', 'U') IS NOT NULL DROP TABLE Tbl_Countries;
IF OBJECT_ID('Tbl_ScoredIsochrones', 'U') IS NOT NULL DROP TABLE Tbl_ScoredIsochrones;
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
    BaseWeight DECIMAL(5,2) NOT NULL DEFAULT 0,
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
    Location GEOGRAPHY,
    GeometryType AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STGeometryType() END),
    LocationWKT AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STAsText() END)
);

-- TODO: Street Number is it's own column. Does it need to be? Can we combine with Street?
-- Is there any thirdparty API reasons you might want it in it's own column? :D
CREATE TABLE Tbl_Locations (
    LocationID INT PRIMARY KEY IDENTITY(1,1),
    LocationName NVARCHAR(100) NULL,
    StreetNumber NVARCHAR(20) NULL,
    Street NVARCHAR(255) NULL,
    City NVARCHAR(100) NULL,
    SubdivisionID INT FOREIGN KEY REFERENCES Tbl_Subdivisions(SubdivisionID)  NOT NULL,
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Location GEOGRAPHY,
    GeometryType AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STGeometryType() END),
    LocationWKT AS (CASE WHEN Location IS NULL THEN NULL ELSE Location.STAsText() END),
    CalculatedScore DECIMAL(10,2),
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

CREATE TABLE Tbl_ScoredIsochrones (
    IsochroneID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT FOREIGN KEY REFERENCES Tbl_Locations(LocationID),
    TravelTime INT, --different rings
    Polygon GEOMETRY,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Tbl_Users (
    UserID      INT PRIMARY KEY IDENTITY(1,1),
    DisplayName NVARCHAR(100) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Tbl_Battles (
    BattleID INT PRIMARY KEY IDENTITY(1,1),
    BattleCode UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    CreatedByUserID INT FOREIGN KEY REFERENCES Tbl_Users(UserID),
    CreatedDate DATETIME DEFAULT GETDATE(),
    ExpiresAt DATETIME NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'open'
        CONSTRAINT CK_Battles_Status CHECK (Status IN ('open', 'closed', 'expired')),
    MaxParticipants INT NULL
);

CREATE TABLE Tbl_BattleParticipants (
    ParticipantID INT PRIMARY KEY IDENTITY(1,1),
    BattleID INT NOT NULL FOREIGN KEY REFERENCES Tbl_Battles(BattleID),
    UserID INT NOT NULL FOREIGN KEY REFERENCES Tbl_Users(UserID),
    LocationID INT NOT NULL FOREIGN KEY REFERENCES Tbl_Locations(LocationID),
    JoinedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_BattleParticipants_BattleUser UNIQUE (BattleID, UserID)
);

ALTER TABLE Tbl_Battles
ADD CONSTRAINT UQ_Battles_BattleCode UNIQUE (BattleCode);


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
ADD CONSTRAINT CK_Locations_CalculatedScore CHECK (CalculatedScore BETWEEN 0 AND 99999999.99);

ALTER TABLE Tbl_ScoringResults
ADD CONSTRAINT CK_ScoringResults_Distance CHECK (Distance >= 0);

ALTER TABLE Tbl_Countries
ADD CONSTRAINT CK_Countries_CountryCode_Format CHECK (CountryCode = UPPER(CountryCode) AND CountryCode NOT LIKE '%[^A-Z]%');