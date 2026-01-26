/*
 ScriptName: CRUD
 Coder: Greeley
 Date: 2026-01-23
 
 vers     Date            Coder       Issue
 1.0      2026-01-23      Greeley     Initial
 1.1      2026-01-24      Greeley     Put in formatter
 1.2      2026-01-25      Patrick     Added Location Stored Procs, Ran Formatter.
 1.3      2026-01-26      Patrick      Fixed Error code.
 */

USE DB_AmeniScale;
GO


IF OBJECT_ID('dbo.sp_Amenity_Create', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.sp_Amenity_Create;
GO

IF OBJECT_ID('dbo.sp_Amenity_Read', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.sp_Amenity_Read;
GO

IF OBJECT_ID('dbo.sp_Amenity_Update', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.sp_Amenity_Update;
GO

IF OBJECT_ID('dbo.sp_Amenity_Delete', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.sp_Amenity_Delete;
GO


CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Create
    @CategoryName NVARCHAR(100),
    @BaseWeight DECIMAL(5, 2) = NULL,
    @IsNegative BIT = 0,
    @CategoryID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1
            FROM Tbl_AmenityCategories
            WHERE CategoryName = @CategoryName
        )
            THROW 50001, 'Category Name already exists.', 1;

        INSERT INTO Tbl_AmenityCategories (CategoryName, BaseWeight, IsNegative)
        VALUES (@CategoryName, @BaseWeight, @IsNegative);

        SET @CategoryID = SCOPE_IDENTITY();

        COMMIT;

        SELECT *
        FROM Tbl_AmenityCategories
        WHERE CategoryID = @CategoryID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Read
    @CategoryID INT = NULL
AS
BEGIN
    IF @CategoryID IS NULL
        SELECT *
        FROM Tbl_AmenityCategories
        ORDER BY CategoryName;
    ELSE
        SELECT *
        FROM Tbl_AmenityCategories
        WHERE CategoryID = @CategoryID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Update
    @CategoryID INT,
    @CategoryName NVARCHAR(100) = NULL,
    @BaseWeight DECIMAL(5, 2) = NULL,
    @IsNegative BIT = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_AmenityCategories
            WHERE CategoryID = @CategoryID
        )
            THROW 50002, 'CategoryID not found.', 1;

        UPDATE Tbl_AmenityCategories
        SET CategoryName = COALESCE(@CategoryName, CategoryName),
            BaseWeight = COALESCE(@BaseWeight, BaseWeight),
            IsNegative = COALESCE(@IsNegative, IsNegative)
        WHERE CategoryID = @CategoryID;

        COMMIT;

        SELECT *
        FROM Tbl_AmenityCategories
        WHERE CategoryID = @CategoryID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Delete
    @CategoryID INT,
    @Cascade BIT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_AmenityCategories
            WHERE CategoryID = @CategoryID
        )
            THROW 50003, 'CategoryID not found.', 1;

        IF EXISTS (
            SELECT 1
            FROM Tbl_Amenities
            WHERE CategoryID = @CategoryID
        )
        BEGIN
            IF @Cascade = 0
                THROW 50004, 'Category has amenities. Use Cascade=1.', 1;

            DELETE FROM Tbl_Amenities
            WHERE CategoryID = @CategoryID;
        END

        DELETE FROM Tbl_AmenityCategories
        WHERE CategoryID = @CategoryID;

        COMMIT;

        SELECT @CategoryID AS DeletedCategoryID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

-- =============================================
-- Amenity Procedures
-- =============================================

CREATE OR ALTER PROCEDURE dbo.sp_Amenity_Create
    @Name NVARCHAR(255),
    @CategoryID INT,
    @Street NVARCHAR(255),
    @City NVARCHAR(100),
    @SubdivisionID INT,
    @Latitude DECIMAL(10, 8) = NULL,
    @Longitude DECIMAL(11, 8) = NULL,
    @LocationWKT NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_AmenityCategories
            WHERE CategoryID = @CategoryID
        )
            THROW 50005, 'Invalid CategoryID.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Subdivisions
            WHERE SubdivisionID = @SubdivisionID
        )
            THROW 50006, 'Invalid SubdivisionID.', 1;

        DECLARE @Location GEOGRAPHY = NULL;

        IF @LocationWKT IS NOT NULL
        BEGIN
            SET @Location = GEOGRAPHY::STGeomFromText(@LocationWKT, 4326);

            IF @Location.STGeometryType() = 'Point'
            BEGIN
                SET @Latitude = @Location.Lat;
                SET @Longitude = @Location.Long;
            END
            ELSE
            BEGIN
                SET @Latitude = NULL;
                SET @Longitude = NULL;
            END
        END
        ELSE
        BEGIN
            IF @Latitude IS NULL OR @Longitude IS NULL
                THROW 50009, 'Latitude and Longitude are required when LocationWKT is NULL.', 1;

            SET @Location = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);
        END

        INSERT INTO Tbl_Amenities (
            Name, CategoryID, Street, City, SubdivisionID, 
            Latitude, Longitude, Location
        )
        VALUES (
            @Name, @CategoryID, @Street, @City, @SubdivisionID, 
            @Latitude, @Longitude, @Location
        );

        DECLARE @AmenityID INT = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT;

        SELECT 
            a.AmenityID,
            a.Name,
            a.CategoryID,
            ac.CategoryName,
            a.Street,
            a.City,
            a.SubdivisionID,
            a.Latitude,
            a.Longitude,
            a.GeometryType,
            a.LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        WHERE a.AmenityID = @AmenityID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Amenity_Read
    @AmenityID INT = NULL
AS
BEGIN
    IF @AmenityID IS NULL
        SELECT 
            a.AmenityID,
            a.Name,
            a.CategoryID,
            ac.CategoryName,
            a.Street,
            a.City,
            a.SubdivisionID,
            a.Latitude,
            a.Longitude,
            a.GeometryType,
            a.LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        ORDER BY a.AmenityID;
    ELSE
        SELECT 
            a.AmenityID,
            a.Name,
            a.CategoryID,
            ac.CategoryName,
            a.Street,
            a.City,
            a.SubdivisionID,
            a.Latitude,
            a.Longitude,
            a.GeometryType,
            a.LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        WHERE a.AmenityID = @AmenityID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Amenity_Update
    @AmenityID INT,
    @Name NVARCHAR(255) = NULL,
    @CategoryID INT = NULL,
    @Street NVARCHAR(255) = NULL,
    @City NVARCHAR(100) = NULL,
    @SubdivisionID INT = NULL,
    @Latitude DECIMAL(10, 8) = NULL,
    @Longitude DECIMAL(11, 8) = NULL,
    @LocationWKT NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Amenities
            WHERE AmenityID = @AmenityID
        )
            THROW 50007, 'AmenityID not found.', 1;

        DECLARE @NewLocation GEOGRAPHY = NULL;
        DECLARE @LatUpdate DECIMAL(10, 8) = NULL;
        DECLARE @LongUpdate DECIMAL(11, 8) = NULL;

        IF @LocationWKT IS NOT NULL
        BEGIN
            SET @NewLocation = GEOGRAPHY::STGeomFromText(@LocationWKT, 4326);

            IF @NewLocation.STGeometryType() = 'Point'
            BEGIN
                SET @LatUpdate = @NewLocation.Lat;
                SET @LongUpdate = @NewLocation.Long;
            END
            ELSE
            BEGIN
                SET @LatUpdate = NULL;
                SET @LongUpdate = NULL;
            END
        END
        ELSE IF @Latitude IS NOT NULL AND @Longitude IS NOT NULL
        BEGIN
            SET @NewLocation = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);
            SET @LatUpdate = @Latitude;
            SET @LongUpdate = @Longitude;
        END

        UPDATE Tbl_Amenities
        SET Name = COALESCE(@Name, Name),
            CategoryID = COALESCE(@CategoryID, CategoryID),
            Street = COALESCE(@Street, Street),
            City = COALESCE(@City, City),
            SubdivisionID = COALESCE(@SubdivisionID, SubdivisionID),
            Latitude = CASE 
                WHEN @NewLocation IS NOT NULL THEN @LatUpdate
                ELSE COALESCE(@Latitude, Latitude)
            END,
            Longitude = CASE 
                WHEN @NewLocation IS NOT NULL THEN @LongUpdate
                ELSE COALESCE(@Longitude, Longitude)
            END,
            Location = COALESCE(@NewLocation, Location)
        WHERE AmenityID = @AmenityID;

        COMMIT;

        SELECT 
            a.AmenityID,
            a.Name,
            a.CategoryID,
            ac.CategoryName,
            a.Street,
            a.City,
            a.SubdivisionID,
            a.Latitude,
            a.Longitude,
            a.GeometryType,
            a.LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        WHERE a.AmenityID = @AmenityID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Amenity_Delete
    @AmenityID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Amenities
            WHERE AmenityID = @AmenityID
        )
            THROW 50008, 'AmenityID not found.', 1;

        DELETE FROM Tbl_Amenities
        WHERE AmenityID = @AmenityID;

        COMMIT;

        SELECT @AmenityID AS DeletedAmenityID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO



CREATE OR ALTER PROCEDURE dbo.sp_Location_Create
    @LocationName NVARCHAR(255),
    @StreetNumber NVARCHAR(255),
    @Street NVARCHAR(255),
    @City NVARCHAR(100),
    @SubdivisionID INT,
    @Latitude DECIMAL(10, 8),
    @Longitude DECIMAL(11, 8),
    @LocationID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Subdivisions
            WHERE SubdivisionID = @SubdivisionID
        )
            THROW 50006, 'Invalid SubdivisionID.', 1;

        DECLARE @GeogLocation GEOGRAPHY = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);

        INSERT INTO Tbl_Locations (
            LocationName, StreetNumber, Street, City, SubdivisionID, 
            Latitude, Longitude, Location
        )
        VALUES (
            @LocationName, @StreetNumber, @Street, @City, @SubdivisionID, 
            @Latitude, @Longitude, @GeogLocation
        );

        SET @LocationID = SCOPE_IDENTITY();

        COMMIT;

        SELECT *, Location.STAsText() AS LocationWKT
        FROM Tbl_Locations
        WHERE LocationID = @LocationID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Location_Read
    @LocationID INT = NULL
AS
BEGIN
    IF @LocationID IS NULL
        SELECT *, Location.STAsText() AS LocationWKT
        FROM Tbl_Locations
        ORDER BY LocationName;
    ELSE
        SELECT *, Location.STAsText() AS LocationWKT
        FROM Tbl_Locations
        WHERE LocationID = @LocationID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Location_Update
    @LocationID INT,
    @LocationName NVARCHAR(255) = NULL,
    @StreetNumber NVARCHAR(255) = NULL,
    @Street NVARCHAR(255) = NULL,
    @City NVARCHAR(100) = NULL,
    @SubdivisionID INT = NULL,
    @Latitude DECIMAL(10, 8) = NULL,
    @Longitude DECIMAL(11, 8) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Locations
            WHERE LocationID = @LocationID
        )
            THROW 50011, 'LocationID not found.', 1;

        DECLARE @NewGeog GEOGRAPHY = NULL;

        IF @Latitude IS NOT NULL AND @Longitude IS NOT NULL
            SET @NewGeog = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);

        UPDATE Tbl_Locations
        SET LocationName = COALESCE(@LocationName, LocationName),
            StreetNumber = COALESCE(@StreetNumber, StreetNumber),
            Street = COALESCE(@Street, Street),
            City = COALESCE(@City, City),
            SubdivisionID = COALESCE(@SubdivisionID, SubdivisionID),
            Latitude = COALESCE(@Latitude, Latitude),
            Longitude = COALESCE(@Longitude, Longitude),
            Location = COALESCE(@NewGeog, Location)
        WHERE LocationID = @LocationID;

        COMMIT;

        SELECT *, Location.STAsText() AS LocationWKT
        FROM Tbl_Locations
        WHERE LocationID = @LocationID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Location_Delete
    @LocationID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (
            SELECT 1
            FROM Tbl_Locations
            WHERE LocationID = @LocationID
        )
            THROW 50012, 'LocationID not found.', 1;

        DELETE FROM Tbl_Locations
        WHERE LocationID = @LocationID;

        COMMIT;

        SELECT @LocationID AS DeletedLocationID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK;
        THROW;
    END CATCH
END
GO