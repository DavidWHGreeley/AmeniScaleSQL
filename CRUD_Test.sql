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

DECLARE @CategoryID INT, @AmenityID INT;

-- Creating Category
EXEC dbo.sp_AmenityCategory_Create 
    @CategoryName = 'Schools', 
    @BaseWeight = 10, 
    @IsNegative = 0,
    @CategoryID = @CategoryID OUTPUT;

-- Reading Category
EXEC dbo.sp_AmenityCategory_Read @CategoryID = @CategoryID;

-- Updating Category
EXEC dbo.sp_AmenityCategory_Update 
    @CategoryID = @CategoryID,
    @CategoryName = 'Schools Updated',
    @BaseWeight = 10;

-- Reading Updated Category
EXEC dbo.sp_AmenityCategory_Read @CategoryID = @CategoryID;

-- Creating Amenity
EXEC dbo.sp_Amenity_Create
    @Name = 'Kingston Secondary School',
    @CategoryID = @CategoryID,
    @Street = '145 Kirkpatrick St',
    @City = 'Kingston',
    @SubdivisionID = 1,
    @Latitude = 44.2534913,
    @Longitude = -76.5024051,
    @AmenityID = @AmenityID OUTPUT;

-- Reading Amenity
EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID;

-- Updating Amenity
EXEC dbo.sp_Amenity_Update
    @AmenityID = @AmenityID,
    @Name = 'Frontenac Secondary School',
    @Street = '1789 Bath Rd';

-- Reading Updated Amenity
EXEC dbo.sp_Amenity_Read @AmenityID = @AmenityID;

-- Deleting Amenity
EXEC dbo.sp_Amenity_Delete @AmenityID = @AmenityID;

-- Deleting Category
EXEC dbo.sp_AmenityCategory_Delete @CategoryID = @CategoryID, @Cascade = 0;

-- Reading All Categories
EXEC dbo.sp_AmenityCategory_Read;

-- Reading All Amenities
EXEC dbo.sp_Amenity_Read;

ROLLBACK;

-- Before running the script, update the # with the total rows in Tbl_Amenities
DBCC CHECKIDENT ('Tbl_Amenities', RESEED, 410);