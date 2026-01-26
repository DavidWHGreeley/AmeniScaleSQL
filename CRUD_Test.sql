/*
ScriptName: CRUD Test
Coder: Greeley
Date: 2026-01-23

vers     Date                    Coder			Issue
1.0      2026-01-23              Greeley		Initial
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
        @LocationWKT = NULL,
        @AmenityID = @AmenityID OUTPUT;
    
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
        @LocationWKT = 'LINESTRING (-76.50240 44.25349, -76.50190 44.25380, -76.50140 44.25410)',
        @AmenityID = @AmenityID2 OUTPUT;

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
    
    EXEC dbo.sp_Amenity_Read;

    PRINT '~~~ LOCATION CRUD ~~~';
    EXEC dbo.sp_Location_Create 
        @LocationName = 'Frontenac County Schools Museum',
        @StreetNumber = '414',
        @Street = 'Regent St',
        @City = 'Kingston',
        @SubdivisionID = 1,
        @Latitude = 44.2315,
        @Longitude = -76.4950,
        @LocationID = @LocationID OUTPUT;

    EXEC dbo.sp_Location_Read @LocationID = @LocationID;
    
    EXEC dbo.sp_Location_Update 
        @LocationID = @LocationID,
        @LocationName = 'The School of Cool';

    EXEC dbo.sp_Location_Read @LocationID = @LocationID;

ROLLBACK;
    


DBCC CHECKIDENT ('Tbl_Amenities', RESEED, 1828);
GO
