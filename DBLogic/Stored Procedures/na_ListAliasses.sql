----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListAliasses
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListAliasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_ListAliasses.'
	drop procedure [dbo].[na_ListAliasses]
	print '**** Creating Stored Procedure dbo.na_ListAliasses...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create    PROCEDURE dbo.na_ListAliasses
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int

-- PROCEDURE :	na_ListAliasses
-- VERSION :	5
-- DESCRIPTON:	Populate the Alias table in the NameDetails typed dataset.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18/06/2002	SF			Procedure created
-- 04 Jun 2010	MF	18703	5	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which should be returned in the list.
AS
begin
	-- disable row counts
	set nocount on
	set concat_null_yields_null off

	-- declare variables
	declare	@ErrorCode	int

	select @ErrorCode=0
	
	If @ErrorCode=0
	begin
		select

		A.ALIASDESCRIPTION	as 'AliasTypeDescription',
		NA.ALIAS		as 'Alias',
		C.COUNTRY		as 'Country',
		P.PROPERTYNAME		as 'PropertyName'
		from NAMEALIAS NA
		join ALIASTYPE A	 on (A.ALIASTYPE  = NA.ALIASTYPE)
		left join COUNTRY C	 on (C.COUNTRYCODE= NA.COUNTRYCODE)
		left join PROPERTYTYPE P on (P.PROPERTYTYPE= NA.PROPERTYTYPE)
		where NA.NAMENO = @pnNameNo
	End

	
	RETURN @ErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_ListAliasses to public
go
