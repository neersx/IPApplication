-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_EDERULECASE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_EDERULECASE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_EDERULECASE.'
	drop procedure dbo.ip_cc_EDERULECASE
	print '**** Creating procedure dbo.ip_cc_EDERULECASE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_EDERULECASE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_EDERULECASE
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the EDERULECASE table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 03 Apr 2017	MF	71020	2	New columns added.
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--
-- 18 Jan 2012 AvdA - for CopyConfig ignore mapping (3-5 unused here but skip to 6 if new value required)
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 		(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the CCImport_EDERULECASE table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString0		nvarchar(4000)
Declare @sSQLString1		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)
Declare @sSQLString3		nvarchar(4000)
Declare @sSQLString4		nvarchar(4000)
Declare @sSQLString5		nvarchar(4000)

Declare	@ErrorCode			int
Declare @sUserName			nvarchar(40)
Declare	@hDocument	 		int 			-- handle to the XML parameter
Declare @bOriginalKeyColumnExists	bit
Declare @nNewRows			int

Set @ErrorCode=0
Set @bOriginalKeyColumnExists = 0
Set @sUserName	= @psUserName


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString="SELECT * from dbo.fn_cc_EDERULECASE('"+@psUserName+"')
		order by "+CASE WHEN(@pnOrderBy=1)THEN "1,3" ELSE "3" END 
		
		select isnull(@sSQLString,''), isnull(@sSQLString1,''),isnull(@sSQLString2,''), isnull(@sSQLString3,''),isnull(@sSQLString4,''), isnull(@sSQLString5,'')
		
		Select	@ErrorCode=@@Error,
			@pnRowCount=@@rowcount
	End
End

-- Data Update from temporary table
-- Merge the imported data
-- @pnFunction = 2 describes the update of the system data from the temporary table
If  @ErrorCode=0
and @pnFunction=2
Begin

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update EDERULECASE
		set	WHOLECASE= I.WHOLECASE,
			CASETYPE= I.CASETYPE,
			PROPERTYTYPE= I.PROPERTYTYPE,
			COUNTRY= I.COUNTRY,
			CATEGORY= I.CATEGORY,
			SUBTYPE= I.SUBTYPE,
			BASIS= I.BASIS,
			ENTITYSIZE= I.ENTITYSIZE,
			NUMBEROFCLAIMS= I.NUMBEROFCLAIMS,
			NUMBEROFDESIGNS= I.NUMBEROFDESIGNS,
			NUMBEROFYEARSEXT= I.NUMBEROFYEARSEXT,
			STOPPAYREASON= I.STOPPAYREASON,
			SHORTTITLE= I.SHORTTITLE,
			CLASSES= I.CLASSES,
			DESIGNATEDCOUNTRIES= I.DESIGNATEDCOUNTRIES,
			TYPEOFMARK= I.TYPEOFMARK
		from	EDERULECASE C
		join	CCImport_EDERULECASE I	on ( I.CRITERIANO=C.CRITERIANO)
" Set @sSQLString1="
		where 		( I.WHOLECASE <>  C.WHOLECASE OR (I.WHOLECASE is null and C.WHOLECASE is not null )
 OR (I.WHOLECASE is not null and C.WHOLECASE is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.COUNTRY <>  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is not null )
 OR (I.COUNTRY is not null and C.COUNTRY is null))
		OR 		( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null )
 OR (I.CATEGORY is not null and C.CATEGORY is null))
		OR 		( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null )
 OR (I.SUBTYPE is not null and C.SUBTYPE is null))
		OR 		( I.BASIS <>  C.BASIS OR (I.BASIS is null and C.BASIS is not null )
 OR (I.BASIS is not null and C.BASIS is null))
		OR 		( I.ENTITYSIZE <>  C.ENTITYSIZE OR (I.ENTITYSIZE is null and C.ENTITYSIZE is not null )
 OR (I.ENTITYSIZE is not null and C.ENTITYSIZE is null))
		OR 		( I.NUMBEROFCLAIMS <>  C.NUMBEROFCLAIMS OR (I.NUMBEROFCLAIMS is null and C.NUMBEROFCLAIMS is not null )
 OR (I.NUMBEROFCLAIMS is not null and C.NUMBEROFCLAIMS is null))
		OR 		( I.NUMBEROFDESIGNS <>  C.NUMBEROFDESIGNS OR (I.NUMBEROFDESIGNS is null and C.NUMBEROFDESIGNS is not null )
 OR (I.NUMBEROFDESIGNS is not null and C.NUMBEROFDESIGNS is null))
		OR 		( I.NUMBEROFYEARSEXT <>  C.NUMBEROFYEARSEXT OR (I.NUMBEROFYEARSEXT is null and C.NUMBEROFYEARSEXT is not null )
 OR (I.NUMBEROFYEARSEXT is not null and C.NUMBEROFYEARSEXT is null))
		OR 		( I.STOPPAYREASON <>  C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is not null )
 OR (I.STOPPAYREASON is not null and C.STOPPAYREASON is null))
		OR 		( I.SHORTTITLE <>  C.SHORTTITLE OR (I.SHORTTITLE is null and C.SHORTTITLE is not null )
 OR (I.SHORTTITLE is not null and C.SHORTTITLE is null))
		OR 		( I.CLASSES <>  C.CLASSES OR (I.CLASSES is null and C.CLASSES is not null )
 OR (I.CLASSES is not null and C.CLASSES is null))
		OR 		( I.DESIGNATEDCOUNTRIES <>  C.DESIGNATEDCOUNTRIES OR (I.DESIGNATEDCOUNTRIES is null and C.DESIGNATEDCOUNTRIES is not null )
 OR (I.DESIGNATEDCOUNTRIES is not null and C.DESIGNATEDCOUNTRIES is null))
		OR 		( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null )
 OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Set @ErrorCode=@@Error 
		Set @pnRowCount=@@rowcount
	End 

	/**************** Data Insert ***************************************/
		If @ErrorCode=0
		Begin
	

		-- Insert the rows where existing key not found.
		Set @sSQLString= "

		-- Insert the rows where existing key not found.
		Insert into EDERULECASE(
			CRITERIANO,
			WHOLECASE,
			CASETYPE,
			PROPERTYTYPE,
			COUNTRY,
			CATEGORY,
			SUBTYPE,
			BASIS,
			ENTITYSIZE,
			NUMBEROFCLAIMS,
			NUMBEROFDESIGNS,
			NUMBEROFYEARSEXT,
			STOPPAYREASON,
			SHORTTITLE,
			CLASSES,
			DESIGNATEDCOUNTRIES,
			TYPEOFMARK)
		select
			I.CRITERIANO,
			I.WHOLECASE,
			I.CASETYPE,
			I.PROPERTYTYPE,
			I.COUNTRY,
			I.CATEGORY,
			I.SUBTYPE,
			I.BASIS,
			I.ENTITYSIZE,
			I.NUMBEROFCLAIMS,
			I.NUMBEROFDESIGNS,
			I.NUMBEROFYEARSEXT,
			I.STOPPAYREASON,
			I.SHORTTITLE,
			I.CLASSES,
			I.DESIGNATEDCOUNTRIES,
			I.TYPEOFMARK
		from CCImport_EDERULECASE I
		left join EDERULECASE C	on ( C.CRITERIANO=I.CRITERIANO)
		where C.CRITERIANO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete EDERULECASE
		from CCImport_EDERULECASE I
		right join EDERULECASE C	on ( C.CRITERIANO=I.CRITERIANO)
		where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End
End

-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- ( no mapping is allowed for CopyConfig - return null)
If  @ErrorCode=0
and @pnFunction=3
Begin
	Set @sSQLString=null

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End

RETURN @ErrorCode
go
grant execute on dbo.ip_cc_EDERULECASE  to public
go
