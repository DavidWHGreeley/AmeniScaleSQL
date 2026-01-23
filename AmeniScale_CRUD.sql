
/* 
ScriptName: DB_AmeniScale_CRUD
Coder: Greeley
Date: 2026-01-22

vers     Date                    Coder			Issue
1.0      2026-01-22              Greeley		Initial
*/

USE DB_AmeniScale;
GO

SET NOCOUNT ON;

DECLARE @Rollback BIT = 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @CountryID INT;
    DECLARE @SubdivisionID INT;

    SELECT @CountryID = CountryID
    FROM Tbl_Countries
    WHERE CountryCode = 'CA';

    IF @CountryID IS NULL
    BEGIN
        INSERT INTO Tbl_Countries (CountryCode, CountryName)
        VALUES ('CA', 'Canada');

        SET @CountryID = SCOPE_IDENTITY();
        PRINT 'Inserted Country: Canada';
    END
    ELSE
        PRINT 'Country already exists: Canada';

    SELECT @SubdivisionID = SubdivisionID
    FROM Tbl_Subdivisions
    WHERE CountryID = @CountryID AND SubdivisionCode = 'ON';

    IF @SubdivisionID IS NULL
    BEGIN
        INSERT INTO Tbl_Subdivisions (CountryID, SubdivisionCode, SubdivisionName, Type)
        VALUES (@CountryID, 'ON', 'Ontario', 'Province');

        SET @SubdivisionID = SCOPE_IDENTITY();
        PRINT 'Inserted Subdivision: Ontario';
    END
    ELSE
        PRINT 'Subdivision already exists: Ontario';

    PRINT '~~~~ CREATE DATA ~~~~';

    DECLARE @CategoryID INT;
    DECLARE @AmenityID INT;

    INSERT INTO Tbl_AmenityCategories (CategoryName, BaseWeight, IsNegative)
    VALUES ('TEST_CATEGORY_HOSPITAL', 10.0, 0);

    SET @CategoryID = SCOPE_IDENTITY();
    
    INSERT INTO Tbl_Amenities
        (Name, CategoryID, Street, City, SubdivisionID, Latitude, Longitude, Location)
    VALUES
        ('TEST_AMENITY_HOSPTIAL', @CategoryID, '123 Princess St', 'Kingston', @SubdivisionID,
         44.23120000, -76.48600000,
         geography::Point(44.23120000, -76.48600000, 4326));

    SET @AmenityID = SCOPE_IDENTITY();

    PRINT CONCAT('Inserted CategoryID=', @CategoryID, ' and AmenityID=', @AmenityID);

    PRINT '~~~~ READ ~~~~';

    SELECT
        ac.CategoryID, ac.CategoryName, ac.BaseWeight, ac.IsNegative
    FROM Tbl_AmenityCategories ac
    WHERE ac.CategoryID = @CategoryID;

    SELECT
        a.AmenityID, a.Name, a.CategoryID, a.Street, a.City, a.SubdivisionID,
        a.Latitude, a.Longitude,
        a.Location.STAsText() AS LocationWKT
    FROM Tbl_Amenities a
    WHERE a.AmenityID = @AmenityID;

    PRINT '~~~~ UPDATE ~~~~';

    UPDATE Tbl_AmenityCategories
    SET BaseWeight = 10.0
    WHERE CategoryID = @CategoryID;

    UPDATE Tbl_Amenities
    SET Name = 'TEST_AMENITY_HOSPTIAL_UPDATED',
        Street = '456 Bath Rd'
    WHERE AmenityID = @AmenityID;

    SELECT
        ac.CategoryID, ac.CategoryName, ac.BaseWeight, ac.IsNegative
    FROM Tbl_AmenityCategories ac
    WHERE ac.CategoryID = @CategoryID;

    SELECT
        a.AmenityID, a.Name, a.CategoryID, a.Street, a.City
    FROM Tbl_Amenities a
    WHERE a.AmenityID = @AmenityID;

    PRINT '~~~~ DELETE ~~~~';

    DELETE FROM Tbl_Amenities
    WHERE AmenityID = @AmenityID;

    DELETE FROM Tbl_AmenityCategories
    WHERE CategoryID = @CategoryID;

    PRINT 'Deleted test Amenity + test Category';

    IF @Rollback = 1
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'ROLLBACK complete (no changes saved).';
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'ERROR OCCURRED - rolled back.';
    THROW;
END CATCH;
GO
