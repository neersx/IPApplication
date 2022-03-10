-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCountries
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCountries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCountries'
	drop procedure [dbo].[wa_ListCountries]
	print '**** Creating procedure dbo.wa_ListCountries...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCountries]

-- PROCEDURE :	wa_ListCountries
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of all Countries
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF	Procedure created	

as 
	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

	SELECT	COUNTRYCODE, COUNTRY
	FROM	COUNTRY
	ORDER BY	COUNTRY

	Select @ErrorCode=@@Error

	return @ErrorCode
go

grant execute on [dbo].[wa_ListCountries] to public
go
