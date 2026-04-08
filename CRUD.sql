/*
 ScriptName: CRUD
 Coder: Greeley
 Date: 2026-01-23
 
 vers     Date            Coder       Issue
 1.0      2026-01-23      Greeley     Initial
 1.1      2026-01-24      Greeley     Put in formatter
 1.2      2026-01-25      Patrick     Added Location Stored Procs, Ran Formatter.
 1.3      2026-01-26      Patrick     Fixed Error code.
 1.4      2026-02-07      Greeley     SP for getting items in radius
 1.5      2026-03-02      Patrick     SP for getting items in isochrone polygon
 1.6      2026-03-18      Cody        SP for inserting created isochrones
 */
USE DB_AmeniScale;
GO

IF OBJECT_ID('dbo.sp_AmenityCategory_Create', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_AmenityCategory_Create;
GO

IF OBJECT_ID('dbo.sp_AmenityCategory_Read', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_AmenityCategory_Read;
GO

IF OBJECT_ID('dbo.sp_AmenityCategory_Update', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_AmenityCategory_Update;
GO

IF OBJECT_ID('dbo.sp_AmenityCategory_Delete', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_AmenityCategory_Delete;
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

IF OBJECT_ID('dbo.sp_Amenity_GetInRadius', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Amenity_GetInRadius;
GO

IF OBJECT_ID('dbo.sp_Amenity_GetInIsochrone', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Amenity_GetInIsochrone;
GO

IF OBJECT_ID('dbo.sp_Location_Create', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Location_Create;
GO

IF OBJECT_ID('dbo.sp_Location_Read', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Location_Read;
GO

IF OBJECT_ID('dbo.sp_Location_Update', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Location_Update;
GO

IF OBJECT_ID('dbo.sp_Location_Delete', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Location_Delete;
GO

IF OBJECT_ID('dbo.sp_Country_Read', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Country_Read;
GO

IF OBJECT_ID('dbo.sp_Subdivision_Read', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Subdivision_Read;
GO

IF OBJECT_ID('dbo.sp_InsertIsochrone', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_InsertIsochrone;
GO

IF OBJECT_ID('dbo.sp_GetTheoreticalMaxScore', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_GetTheoreticalMaxScore;
GO

IF OBJECT_ID('dbo.sp_User_Create', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_User_Create;
GO

IF OBJECT_ID('dbo.sp_Battle_Leaderboard', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Battle_Leaderboard;
GO

IF OBJECT_ID('dbo.sp_Battle_Create', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Battle_Create;
GO

IF OBJECT_ID('dbo.sp_Battle_GetByCode', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Battle_GetByCode;
GO

IF OBJECT_ID('dbo.sp_Battle_Join', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Battle_Join;
GO

IF OBJECT_ID('dbo.sp_Battle_GetByUser', 'P') IS NOT NULL
	DROP PROCEDURE dbo.sp_Battle_GetByUser;
GO

CREATE PROCEDURE dbo.sp_AmenityCategory_Create @CategoryName NVARCHAR(100),
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
				) THROW 50001,
			'Category Name already exists.',
			1;
			INSERT INTO Tbl_AmenityCategories (
				CategoryName,
				BaseWeight,
				IsNegative
				)
			VALUES (
				@CategoryName,
				@BaseWeight,
				@IsNegative
				);

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

CREATE PROCEDURE dbo.sp_AmenityCategory_Read @CategoryID INT = NULL
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

CREATE PROCEDURE dbo.sp_AmenityCategory_Update @CategoryID INT,
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
				) THROW 50002,
			'CategoryID not found.',
			1;
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

CREATE PROCEDURE dbo.sp_AmenityCategory_Delete @CategoryID INT,
	@Cascade BIT = 0
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		IF NOT EXISTS (
				SELECT 1
				FROM Tbl_AmenityCategories
				WHERE CategoryID = @CategoryID
				) THROW 50003,
			'CategoryID not found.',
			1;
			IF EXISTS (
					SELECT 1
					FROM Tbl_Amenities
					WHERE CategoryID = @CategoryID
					)
			BEGIN
				IF @Cascade = 0 THROW 50004,
					'Category has amenities. Use Cascade=1.',
					1;
					DELETE
					FROM Tbl_Amenities
					WHERE CategoryID = @CategoryID;
			END

		DELETE
		FROM Tbl_AmenityCategories
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

CREATE PROCEDURE dbo.sp_Amenity_Create @Name NVARCHAR(255),
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

		IF NULLIF(LTRIM(RTRIM(@Name)), '') IS NULL THROW 50010,
			'Amenity Name is required.',
			1;
			IF NOT EXISTS (
					SELECT 1
					FROM Tbl_AmenityCategories
					WHERE CategoryID = @CategoryID
					) THROW 50005,
				'Invalid CategoryID.',
				1;
				IF NOT EXISTS (
						SELECT 1
						FROM Tbl_Subdivisions
						WHERE SubdivisionID = @SubdivisionID
						) THROW 50006,
					'Invalid SubdivisionID.',
					1;
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
			IF @Latitude IS NULL
				OR @Longitude IS NULL THROW 50009,
				'Latitude and Longitude are required when LocationWKT is NULL.',
				1;
				SET @Location = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);
		END

		INSERT INTO Tbl_Amenities (
			Name,
			CategoryID,
			Street,
			City,
			SubdivisionID,
			Latitude,
			Longitude,
			Location
			)
		VALUES (
			@Name,
			@CategoryID,
			@Street,
			@City,
			@SubdivisionID,
			@Latitude,
			@Longitude,
			@Location
			);

		DECLARE @AmenityID INT = CONVERT(INT, SCOPE_IDENTITY());

		COMMIT;

		SELECT a.AmenityID,
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

CREATE PROCEDURE dbo.sp_Amenity_Read @AmenityID INT = NULL
AS
BEGIN
	IF @AmenityID IS NULL
		SELECT a.AmenityID,
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
		SELECT a.AmenityID,
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

CREATE PROCEDURE dbo.sp_Amenity_Update @AmenityID INT,
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
				) THROW 50007,
			'AmenityID not found.',
			1;
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
		ELSE IF @Latitude IS NOT NULL
			AND @Longitude IS NOT NULL
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
				WHEN @NewLocation IS NOT NULL
					THEN @LatUpdate
				ELSE COALESCE(@Latitude, Latitude)
				END,
			Longitude = CASE 
				WHEN @NewLocation IS NOT NULL
					THEN @LongUpdate
				ELSE COALESCE(@Longitude, Longitude)
				END,
			Location = COALESCE(@NewLocation, Location)
		WHERE AmenityID = @AmenityID;

		COMMIT;

		SELECT a.AmenityID,
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

CREATE PROCEDURE dbo.sp_Amenity_Delete @AmenityID INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		IF NOT EXISTS (
				SELECT 1
				FROM Tbl_Amenities
				WHERE AmenityID = @AmenityID
				) THROW 50008,
			'AmenityID not found.',
			1;
			DELETE
			FROM Tbl_Amenities
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

CREATE PROCEDURE dbo.sp_Amenity_GetInRadius @Latitude DECIMAL(10, 8),
	@Longitude DECIMAL(11, 8),
	@SearchRadiusMeters DECIMAL(10, 2)
AS
BEGIN
	-- TODO: Add in any error checking
	DECLARE @UserLocation GEOGRAPHY = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);

	SELECT a.AmenityID,
		a.Name,
		a.Street,
		a.City,
		a.CategoryID,
		c.CategoryName,
		a.SubdivisionID,
		a.Latitude,
		a.Longitude,
		a.GeometryType,
		a.LocationWKT,
		c.IsNegative,
		@UserLocation.STDistance(a.Location) AS DistanceInMeters
	FROM Tbl_Amenities a
	LEFT JOIN Tbl_AmenityCategories c ON a.CategoryID = c.CategoryID
	WHERE @UserLocation.STDistance(a.Location) <= @SearchRadiusMeters
	ORDER BY DistanceInMeters ASC;
END
GO

CREATE PROCEDURE dbo.sp_Amenity_GetInIsochrone @PolygonWKT NVARCHAR(MAX)
AS
BEGIN
	-- TODO: Add in any error checking
	DECLARE @IsochroneArea GEOGRAPHY = GEOGRAPHY::STGeomFromText(@PolygonWKT, 4326);

	SELECT a.AmenityID,
		a.Name,
		a.Street,
		a.City,
		a.CategoryID,
		c.CategoryName,
		a.SubdivisionID,
		a.Latitude,
		a.Longitude,
		a.GeometryType,
		a.LocationWKT,
		c.BaseWeight,
		c.IsNegative
	FROM Tbl_Amenities a
	LEFT JOIN Tbl_AmenityCategories c ON a.CategoryID = c.CategoryID
	WHERE a.Location.STIntersects(@IsochroneArea) = 1
END
GO

CREATE PROCEDURE dbo.sp_Location_Create @LocationName NVARCHAR(255),
	@StreetNumber NVARCHAR(255),
	@Street NVARCHAR(255),
	@City NVARCHAR(100),
	@SubdivisionID INT,
	@Latitude DECIMAL(10, 8),
	@Longitude DECIMAL(11, 8),
	@CalculatedScore DECIMAL(10, 2)
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		IF NOT EXISTS (
				SELECT 1
				FROM Tbl_Subdivisions
				WHERE SubdivisionID = @SubdivisionID
				) THROW 50006,
			'Invalid SubdivisionID.',
			1;
			IF @Latitude NOT BETWEEN - 90
					AND 90 THROW 50018,
						'Latitude must be between -90 and 90.',
						1;
				IF @Longitude NOT BETWEEN - 180
						AND 180 THROW 50019,
							'Longitude must be between -180 and 180.',
							1;
					DECLARE @GeogLocation GEOGRAPHY = GEOGRAPHY::Point(@Latitude, @Longitude, 4326);

		INSERT INTO Tbl_Locations (
			LocationName,
			StreetNumber,
			Street,
			City,
			SubdivisionID,
			Latitude,
			Longitude,
			Location,
			CalculatedScore
			)
		VALUES (
			@LocationName,
			@StreetNumber,
			@Street,
			@City,
			@SubdivisionID,
			@Latitude,
			@Longitude,
			@GeogLocation,
			@CalculatedScore
			);

		DECLARE @LocationID INT = CONVERT(INT, SCOPE_IDENTITY());

		COMMIT;

		SELECT *,
			Location.STAsText() AS LocationWKT
		FROM Tbl_Locations
		WHERE LocationID = @LocationID;

		SELECT SCOPE_IDENTITY() AS LocationID;--This is to prep to insert the LocationID into Isochrones table
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_Location_Read @LocationID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @LocationID IS NULL
		SELECT l.LocationID,
			l.LocationName,
			l.StreetNumber,
			l.Street,
			l.City,
			l.SubdivisionID,
			l.GeometryType,
			l.Latitude,
			l.Longitude,
			l.Location.STAsText() AS LocationWKT
		FROM Tbl_Locations l
		ORDER BY l.LocationName;
	ELSE
		SELECT l.LocationID,
			l.LocationName,
			l.StreetNumber,
			l.Street,
			l.City,
			l.SubdivisionID,
			l.GeometryType,
			l.Latitude,
			l.Longitude,
			l.Location.STAsText() AS LocationWKT
		FROM Tbl_Locations l
		WHERE l.LocationID = @LocationID;
END
GO

CREATE PROCEDURE dbo.sp_Location_Update @LocationID INT,
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
				) THROW 50011,
			'LocationID not found.',
			1;
			DECLARE @NewGeog GEOGRAPHY = NULL;

		IF @Latitude IS NOT NULL
			AND @Longitude IS NOT NULL
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

		SELECT *,
			Location.STAsText() AS LocationWKT
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

CREATE PROCEDURE dbo.sp_Location_Delete @LocationID INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		IF NOT EXISTS (
				SELECT 1
				FROM Tbl_Locations
				WHERE LocationID = @LocationID
				) THROW 50012,
			'LocationID not found.',
			1;
			DELETE
			FROM Tbl_Locations
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

CREATE PROCEDURE dbo.sp_Country_Read @CountryID INT = NULL
AS
BEGIN
	IF @CountryID IS NULL
		SELECT *
		FROM Tbl_Countries;
	ELSE
		SELECT *
		FROM Tbl_Countries
		WHERE CountryID = @CountryID;
END
GO

CREATE PROCEDURE dbo.sp_Subdivision_Read @SubdivisionID INT = NULL
AS
BEGIN
	IF @SubdivisionID IS NULL
		SELECT *
		FROM Tbl_Subdivisions;
	ELSE
		SELECT *
		FROM Tbl_Subdivisions
		WHERE SubdivisionID = @SubdivisionID;
END
GO

CREATE PROCEDURE dbo.sp_InsertIsochrone @LocationID INT,
	@TravelTime INT,
	@WKT NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN;

		INSERT INTO Tbl_ScoredIsochrones (
			LocationID,
			TravelTime,
			Polygon
			)
		VALUES (
			@LocationID,
			@TravelTime,
			geometry::STGeomFromText(@WKT, 4326)
			);

		COMMIT TRAN;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_GetTheoreticalMaxScore
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT SUM(ac.BaseWeight) AS TheoreticalMax
		FROM Tbl_Amenities a
		INNER JOIN Tbl_AmenityCategories ac ON a.CategoryID = ac.CategoryID
		WHERE ac.IsNegative = 0;
	END TRY

	BEGIN CATCH
		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_User_Create @DisplayName NVARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		INSERT INTO dbo.Tbl_Users (DisplayName)
		VALUES (@DisplayName);

		SELECT UserID,
			DisplayName,
			CreatedDate
		FROM dbo.Tbl_Users
		WHERE UserID = SCOPE_IDENTITY();
	END TRY

	BEGIN CATCH
		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_Battle_Leaderboard @BattleCode UNIQUEIDENTIFIER
AS
BEGIN
	SELECT u.DisplayName,
		l.LocationName,
		l.CalculatedScore AS Score,
		bp.JoinedDate,
		l.Latitude,
		l.Longitude
	FROM Tbl_BattleParticipants bp
	JOIN Tbl_Battles b ON b.BattleID = bp.BattleID
	JOIN Tbl_Users u ON u.UserID = bp.UserID
	JOIN Tbl_Locations l ON l.LocationID = bp.LocationID
	WHERE b.BattleCode = @BattleCode
	ORDER BY l.CalculatedScore DESC;
END
GO

CREATE PROCEDURE dbo.sp_Battle_Create @UserID INT,
	@ExpiresAt DATETIME
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		IF NOT EXISTS (
				SELECT 1
				FROM Tbl_Users
				WHERE UserID = @UserID
				) THROW 50020,
			'UserID not found.',
			1;
			IF @ExpiresAt <= GETDATE() THROW 50021,
				'ExpiresAt must be in future.',
				1;
				DECLARE @BattleCode UNIQUEIDENTIFIER = NEWID();

		INSERT INTO Tbl_Battles (
			BattleCode,
			CreatedByUserID,
			ExpiresAt
			)
		VALUES (
			@BattleCode,
			@UserID,
			@ExpiresAt
			);

		SELECT BattleID,
			BattleCode,
			ExpiresAt,
			STATUS
		FROM Tbl_Battles
		WHERE BattleCode = @BattleCode;

		COMMIT;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_Battle_GetByCode @BattleCode UNIQUEIDENTIFIER
AS
BEGIN
	SELECT BattleID,
		BattleCode,
		CreatedByUserID,
		ExpiresAt,
		STATUS
	FROM Tbl_Battles
	WHERE BattleCode = @BattleCode;
END
GO

CREATE PROCEDURE dbo.sp_Battle_Join @BattleCode UNIQUEIDENTIFIER,
	@UserID INT,
	@LocationID INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN;

		DECLARE @BattleID INT,
			@Status NVARCHAR(20),
			@ExpiresAt DATETIME;

		SELECT @BattleID = BattleID,
			@Status = STATUS,
			@ExpiresAt = ExpiresAt
		FROM Tbl_Battles
		WHERE BattleCode = @BattleCode;

		IF @BattleID IS NULL THROW 50022,
			'Battle not found',
			1;
			IF @Status <> 'open' THROW 50023,
				'Battle is not open',
				1;
				IF @ExpiresAt < GETDATE() THROW 50024,
					'Battle has expired',
					1;
					IF EXISTS (
							SELECT 1
							FROM Tbl_BattleParticipants
							WHERE BattleID = @BattleID
								AND UserID = @UserID
							) THROW 50026,
						'User already submitted for this battle',
						1;
						INSERT INTO Tbl_BattleParticipants (
							BattleID,
							UserID,
							LocationID
							)
						VALUES (
							@BattleID,
							@UserID,
							@LocationID
							);

		COMMIT;

		EXEC dbo.sp_Battle_Leaderboard @BattleCode = @BattleCode;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		THROW;
	END CATCH
END
GO

CREATE PROCEDURE dbo.sp_Battle_GetByUser
    @UserID INT
AS
BEGIN
    SELECT b.BattleID, b.BattleCode, b.CreatedDate, b.ExpiresAt, b.Status
    FROM Tbl_Battles b
    JOIN Tbl_BattleParticipants bp ON bp.BattleID = b.BattleID
    WHERE bp.UserID = @UserID
    ORDER BY b.CreatedDate DESC;
END
GO

