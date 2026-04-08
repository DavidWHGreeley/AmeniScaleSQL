/*
ScriptName: CRUD Test
Coder: Greeley
Date: 2026-01-23

vers     Date                    Coder			Issue
0.1      2026-01-23              Greeley		Initial
0.2      2026-02-07              Greeley        Added 

*/

/*
IMPORTANT: Before running the script, update the # with the total rows in 
Tbl_Amenities at the bottom of the page in the CHECKIDENT fn.
*/

USE DB_AmeniScale;
GO

BEGIN TRAN;
    DECLARE @CategoryID INT, @AmenityID INT, @AmenityID2 INT, @LocationID INT;
    EXEC dbo.sp_AmenityCategory_Create 
        @CategoryName = 'Schools', 
        @BaseWeight = 10, 
        @IsNegative = 0,
        @CategoryID = @CategoryID OUTPUT;
    
    EXEC dbo.sp_AmenityCategory_Read @CategoryID = @CategoryID;
    
    EXEC dbo.sp_AmenityCategory_Update 
        @CategoryID = @CategoryID,
        @CategoryName = 'Schools Updated',
        @BaseWeight = 10;
    
    EXEC dbo.sp_AmenityCategory_Read @CategoryID = @CategoryID;
    
    EXEC dbo.sp_Amenity_Create
        @Name = 'Kingston Secondary School',
        @CategoryID = @CategoryID,
        @Street = '145 Kirkpatrick St',
        @City = 'Kingston',
        @SubdivisionID = 1,
        @Latitude = 44.2534913,
        @Longitude = -76.5024051,
        @LocationWKT = NULL;

    SELECT TOP (1) @AmenityID = AmenityID
    FROM dbo.Tbl_Amenities
    WHERE Name = 'Kingston Secondary School'
      AND CategoryID = @CategoryID
      AND Street = '145 Kirkpatrick St'
      AND City = 'Kingston'
      AND SubdivisionID = 1
    ORDER BY AmenityID DESC;

    EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID;
    
    EXEC dbo.sp_Amenity_Update
        @AmenityID = @AmenityID,
        @Name = 'Frontenac Secondary School',
        @Street = '1789 Bath Rd',
        @LocationWKT = NULL,
        @Latitude = NULL,
        @Longitude = NULL;
    
    EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID;

    EXEC dbo.sp_Amenity_Create
        @Name = 'School Walkway',
        @CategoryID = @CategoryID,
        @Street = 'Bath Rd',
        @City = 'Kingston',
        @SubdivisionID = 1,
        @Latitude = NULL,
        @Longitude = NULL,
        @LocationWKT = 'LINESTRING (-76.50240 44.25349, -76.50190 44.25380, -76.50140 44.25410)';

    SELECT TOP (1) @AmenityID2 = AmenityID
    FROM dbo.Tbl_Amenities
    WHERE Name = 'School Walkway'
      AND CategoryID = @CategoryID
      AND Street = 'Bath Rd'
      AND City = 'Kingston'
      AND SubdivisionID = 1
    ORDER BY AmenityID DESC;

    EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID2;

    EXEC dbo.sp_Amenity_Update
        @AmenityID = @AmenityID2,
        @Name = 'School Walkway Updated',
        @LocationWKT = 'POLYGON ((-76.50240 44.25349, -76.50190 44.25349, -76.50190 44.25410, -76.50240 44.25410, -76.50240 44.25349))',
        @Latitude = NULL,
        @Longitude = NULL;

    EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID2;
    
    EXEC dbo.sp_Amenity_Delete @AmenityID = @AmenityID;
    EXEC dbo.sp_Amenity_Delete @AmenityID = @AmenityID2;
    
    EXEC dbo.sp_AmenityCategory_Delete @CategoryID = @CategoryID, @Cascade = 0;
    
    EXEC dbo.sp_AmenityCategory_Read;
    
    EXEC dbo.sp_Amenity_Read

    EXEC dbo.sp_Amenity_GetInRadius
        @Latitude =  44.233334,
        @Longitude = -76.500000,
        @SearchRadiusMeters = 1000.00;

    PRINT '~~~ LOCATION CRUD ~~~';
    EXEC dbo.sp_Location_Create 
        @LocationName = 'Frontenac County Schools Museum',
        @StreetNumber = '414',
        @Street = 'Regent St',
        @City = 'Kingston',
        @SubdivisionID = 1,
        @Latitude = 44.2315,
        @Longitude = -76.4950,
        @CalculatedScore = 500.00;

    SELECT TOP (1) @LocationID = LocationID
    FROM dbo.Tbl_Locations
    WHERE LocationName = 'Frontenac County Schools Museum'
      AND StreetNumber = '414'
      AND Street = 'Regent St'
      AND City = 'Kingston'
      AND SubdivisionID = 1
      AND Latitude = 44.2315
      AND Longitude = -76.4950
      AND CalculatedScore = 500.00
    ORDER BY LocationID DESC;

    EXEC dbo.sp_Location_Read @LocationID = @LocationID;
    
    EXEC dbo.sp_Location_Update 
        @LocationID = @LocationID,
        @LocationName = 'The School of Cool';

    EXEC dbo.sp_Location_Read @LocationID = @LocationID;

    EXEC dbo.sp_GetTheoreticalMaxScore;

ROLLBACK;
    


DBCC CHECKIDENT ('Tbl_Amenities', RESEED, 1787);
GO
