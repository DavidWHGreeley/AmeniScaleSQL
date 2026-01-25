/*
ScriptName: CRUD
Coder: Greeley
Date: 2026-01-23

vers     Date                    Coder			Issue
1.0      2026-01-23              Greeley		Initial
*/

USE DB_AmeniScale;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Create
    @CategoryName NVARCHAR(100),
    @BaseWeight DECIMAL(5,2) = NULL,
    @IsNegative BIT = 0,
    @CategoryID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (SELECT 1 FROM Tbl_AmenityCategories WHERE CategoryName = @CategoryName)
            THROW 50001, 'Category Name already exists.', 1;

        INSERT INTO Tbl_AmenityCategories (CategoryName, BaseWeight, IsNegative)
        VALUES (@CategoryName, @BaseWeight, @IsNegative);

        SET @CategoryID = SCOPE_IDENTITY();

        COMMIT;

        SELECT * FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Read
    @CategoryID INT = NULL
AS
BEGIN
    IF @CategoryID IS NULL
        SELECT * FROM Tbl_AmenityCategories ORDER BY CategoryName;
    ELSE
        SELECT * FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID;
END
GO


CREATE OR ALTER PROCEDURE dbo.sp_AmenityCategory_Update
    @CategoryID INT,
    @CategoryName NVARCHAR(100) = NULL,
    @BaseWeight DECIMAL(5,2) = NULL,
    @IsNegative BIT = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID)
            THROW 50002, 'CategoryID not found.', 1;

        UPDATE Tbl_AmenityCategories
        SET
            CategoryName = COALESCE(@CategoryName, CategoryName),
            BaseWeight   = COALESCE(@BaseWeight, BaseWeight),
            IsNegative   = COALESCE(@IsNegative, IsNegative)
        WHERE CategoryID = @CategoryID;

        COMMIT;

        SELECT * FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
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

        IF NOT EXISTS (SELECT 1 FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID)
            THROW 50003, 'CategoryID not found.', 1;

        IF EXISTS (SELECT 1 FROM Tbl_Amenities WHERE CategoryID = @CategoryID)
        BEGIN
            IF @Cascade = 0
                THROW 50004, 'Category has amenities. Use Cascade=1.', 1;

            DELETE FROM Tbl_Amenities WHERE CategoryID = @CategoryID;
        END

        DELETE FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID;

        COMMIT;

        SELECT @CategoryID AS DeletedCategoryID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Amenity_Create
    @Name NVARCHAR(255),
    @CategoryID INT,
    @Street NVARCHAR(255),
    @City NVARCHAR(100),
    @SubdivisionID INT,
    @Latitude DECIMAL(10,8),
    @Longitude DECIMAL(11,8),
    @AmenityID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM Tbl_AmenityCategories WHERE CategoryID = @CategoryID)
            THROW 50005, 'Invalid CategoryID.', 1;

        IF NOT EXISTS (SELECT 1 FROM Tbl_Subdivisions WHERE SubdivisionID = @SubdivisionID)
            THROW 50006, 'Invalid SubdivisionID.', 1;

        DECLARE @Location GEOGRAPHY =
            geography::Point(@Latitude, @Longitude, 4326);

        INSERT INTO Tbl_Amenities
            (Name, CategoryID, Street, City, SubdivisionID,
             Latitude, Longitude, Location)
        VALUES
            (@Name, @CategoryID, @Street, @City, @SubdivisionID,
             @Latitude, @Longitude, @Location);

        SET @AmenityID = SCOPE_IDENTITY();

        COMMIT;

        SELECT
            AmenityID, Name, CategoryID, Street, City,
            Latitude, Longitude,
            Location.STAsText() AS LocationWKT
        FROM Tbl_Amenities
        WHERE AmenityID = @AmenityID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
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
            a.*, ac.CategoryName,
            a.Location.STAsText() AS LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        ORDER BY a.Name;
    ELSE
        SELECT
            a.*, ac.CategoryName,
            a.Location.STAsText() AS LocationWKT
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
    @Latitude DECIMAL(10,8) = NULL,
    @Longitude DECIMAL(11,8) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM Tbl_Amenities WHERE AmenityID = @AmenityID)
            THROW 50007, 'AmenityID not found.', 1;

        DECLARE @NewLocation GEOGRAPHY = NULL;

        IF @Latitude IS NOT NULL AND @Longitude IS NOT NULL
            SET @NewLocation = geography::Point(@Latitude, @Longitude, 4326);

        UPDATE Tbl_Amenities
        SET
            Name          = COALESCE(@Name, Name),
            CategoryID    = COALESCE(@CategoryID, CategoryID),
            Street        = COALESCE(@Street, Street),
            City          = COALESCE(@City, City),
            SubdivisionID = COALESCE(@SubdivisionID, SubdivisionID),
            Latitude      = COALESCE(@Latitude, Latitude),
            Longitude     = COALESCE(@Longitude, Longitude),
            Location      = COALESCE(@NewLocation, Location)
        WHERE AmenityID = @AmenityID;

        COMMIT;

        SELECT
            a.*, ac.CategoryName,
            a.Location.STAsText() AS LocationWKT
        FROM Tbl_Amenities a
        JOIN Tbl_AmenityCategories ac ON ac.CategoryID = a.CategoryID
        WHERE a.AmenityID = @AmenityID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
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

        IF NOT EXISTS (SELECT 1 FROM Tbl_Amenities WHERE AmenityID = @AmenityID)
            THROW 50008, 'AmenityID not found.', 1;

        DELETE FROM Tbl_Amenities WHERE AmenityID = @AmenityID;

        COMMIT;

        SELECT @AmenityID AS DeletedAmenityID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO
