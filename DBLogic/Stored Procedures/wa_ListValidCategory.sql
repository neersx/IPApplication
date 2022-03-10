-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListValidCategory
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListValidCategory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListValidCategory'
	drop procedure [dbo].[wa_ListValidCategory]
	print '**** Creating procedure dbo.wa_ListValidCategory...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListValidCategory]
			@sCaseType		char(1),
			@sCountry	 	varchar(3)  = NULL,
			@sPropertyType		char(1)     = NULL

-- PROCEDURE :	wa_ListValidCategory
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of all Case Categorie rows for a given Case Type or Ccountry & Property combination
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 27/08/2001	MF	Procedure created

AS
begin
	-- disable row counts
	set nocount on
	
	-- declare variables
	declare	@ErrorCode	int
	declare @sSql		nvarchar(4000)	-- to allow a dynamically constructed selec

	-- initialise variables
	set @ErrorCode=0

	if  @sCountry      is not null
	and @sPropertyType is not null
	and @sCaseType     is not null
	begin
		set @sSql=		"SELECT	CASECATEGORY, CASECATEGORYDESC"
			 +char(10)+	"FROM	VALIDCATEGORY V"
			 +char(10)+	"WHERE	V.CASETYPE='"+@sCaseType+"'"
			 +char(10)+	"and	V.PROPERTYTYPE='"+@sPropertyType+"'"
			 +char(10)+	"and	V.COUNTRYCODE=(	select min(V1.COUNTRYCODE) from VALIDCATEGORY V1"
			 +char(10)+	"			where V1.COUNTRYCODE in ('"+@sCountry+"','ZZZ')"
			 +char(10)+	"			and   V1.CASETYPE=V.CASETYPE"
			 +char(10)+	"			and   V1.PROPERTYTYPE=V.PROPERTYTYPE)"
			 +char(10)+	"ORDER BY CASECATEGORYDESC"
	end
	else if @sCaseType is not null
	begin
		set @sSql=		"SELECT	CASECATEGORY, CASECATEGORYDESC"
			 +char(10)+	"FROM	CASECATEGORY"
			 +char(10)+	"WHERE	CASETYPE='"+@sCaseType+"'"
			 +char(10)+	"ORDER BY CASECATEGORYDESC"
	end

	Execute @ErrorCode=sp_executesql @sSql

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListValidCategory] to public
go
