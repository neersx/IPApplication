-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_COUNTRY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_COUNTRY]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_COUNTRY.'
	drop procedure dbo.ip_cc_COUNTRY
	print '**** Creating procedure dbo.ip_cc_COUNTRY...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_COUNTRY
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_COUNTRY
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the COUNTRY table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
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


-- Prerequisite that the CCImport_COUNTRY table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_COUNTRY('"+@psUserName+"')
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
		Update COUNTRY
		set	ALTERNATECODE= I.ALTERNATECODE,
			COUNTRY= I.COUNTRY,
			INFORMALNAME= I.INFORMALNAME,
			COUNTRYABBREV= I.COUNTRYABBREV,
			COUNTRYADJECTIVE= I.COUNTRYADJECTIVE,
			RECORDTYPE= I.RECORDTYPE,
			ISD= I.ISD,
			STATELITERAL= I.STATELITERAL,
			POSTCODELITERAL= I.POSTCODELITERAL,
			POSTCODEFIRST= I.POSTCODEFIRST,
			WORKDAYFLAG= I.WORKDAYFLAG,
			DATECOMMENCED= I.DATECOMMENCED,
			DATECEASED= I.DATECEASED,
			NOTES=replace( I.NOTES,char(10),char(13)+char(10)),
			STATEABBREVIATED= I.STATEABBREVIATED,
			ALLMEMBERSFLAG= I.ALLMEMBERSFLAG,
			NAMESTYLE= I.NAMESTYLE,
			ADDRESSSTYLE= I.ADDRESSSTYLE,
			DEFAULTTAXCODE= I.DEFAULTTAXCODE,
			REQUIREEXEMPTTAXNO= I.REQUIREEXEMPTTAXNO,
			DEFAULTCURRENCY= I.DEFAULTCURRENCY,
			POSTCODESEARCHCODE= I.POSTCODESEARCHCODE,
			POSTCODEAUTOFLAG= I.POSTCODEAUTOFLAG,
			POSTALNAME= I.POSTALNAME,
			PRIORARTFLAG= I.PRIORARTFLAG
		from	COUNTRY C
		join	CCImport_COUNTRY I	on ( I.COUNTRYCODE=C.COUNTRYCODE)
" Set @sSQLString1="
		where 		( I.ALTERNATECODE <>  C.ALTERNATECODE OR (I.ALTERNATECODE is null and C.ALTERNATECODE is not null )
 OR (I.ALTERNATECODE is not null and C.ALTERNATECODE is null))
		OR 		( I.COUNTRY <>  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is not null )
 OR (I.COUNTRY is not null and C.COUNTRY is null))
		OR 		( I.INFORMALNAME <>  C.INFORMALNAME OR (I.INFORMALNAME is null and C.INFORMALNAME is not null )
 OR (I.INFORMALNAME is not null and C.INFORMALNAME is null))
		OR 		( I.COUNTRYABBREV <>  C.COUNTRYABBREV OR (I.COUNTRYABBREV is null and C.COUNTRYABBREV is not null )
 OR (I.COUNTRYABBREV is not null and C.COUNTRYABBREV is null))
		OR 		( I.COUNTRYADJECTIVE <>  C.COUNTRYADJECTIVE OR (I.COUNTRYADJECTIVE is null and C.COUNTRYADJECTIVE is not null )
 OR (I.COUNTRYADJECTIVE is not null and C.COUNTRYADJECTIVE is null))
		OR 		( I.RECORDTYPE <>  C.RECORDTYPE OR (I.RECORDTYPE is null and C.RECORDTYPE is not null )
 OR (I.RECORDTYPE is not null and C.RECORDTYPE is null))
		OR 		( I.ISD <>  C.ISD OR (I.ISD is null and C.ISD is not null )
 OR (I.ISD is not null and C.ISD is null))
		OR 		( I.STATELITERAL <>  C.STATELITERAL OR (I.STATELITERAL is null and C.STATELITERAL is not null )
 OR (I.STATELITERAL is not null and C.STATELITERAL is null))
		OR 		( I.POSTCODELITERAL <>  C.POSTCODELITERAL OR (I.POSTCODELITERAL is null and C.POSTCODELITERAL is not null )
 OR (I.POSTCODELITERAL is not null and C.POSTCODELITERAL is null))
		OR 		( I.POSTCODEFIRST <>  C.POSTCODEFIRST OR (I.POSTCODEFIRST is null and C.POSTCODEFIRST is not null )
 OR (I.POSTCODEFIRST is not null and C.POSTCODEFIRST is null))
		OR 		( I.WORKDAYFLAG <>  C.WORKDAYFLAG OR (I.WORKDAYFLAG is null and C.WORKDAYFLAG is not null )
 OR (I.WORKDAYFLAG is not null and C.WORKDAYFLAG is null))
		OR 		( I.DATECOMMENCED <>  C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is not null )
 OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null))
		OR 		( I.DATECEASED <>  C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is not null )
 OR (I.DATECEASED is not null and C.DATECEASED is null))
		OR 		(replace( I.NOTES,char(10),char(13)+char(10)) <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null )
 OR (I.NOTES is not null and C.NOTES is null))
		OR 		( I.STATEABBREVIATED <>  C.STATEABBREVIATED OR (I.STATEABBREVIATED is null and C.STATEABBREVIATED is not null )
 OR (I.STATEABBREVIATED is not null and C.STATEABBREVIATED is null))
		OR 		( I.ALLMEMBERSFLAG <>  C.ALLMEMBERSFLAG)
		OR 		( I.NAMESTYLE <>  C.NAMESTYLE OR (I.NAMESTYLE is null and C.NAMESTYLE is not null )
 OR (I.NAMESTYLE is not null and C.NAMESTYLE is null))
" Set @sSQLString2="
		OR 		( I.ADDRESSSTYLE <>  C.ADDRESSSTYLE OR (I.ADDRESSSTYLE is null and C.ADDRESSSTYLE is not null) 
OR (I.ADDRESSSTYLE is not null and C.ADDRESSSTYLE is null))
		OR 		( I.DEFAULTTAXCODE <>  C.DEFAULTTAXCODE OR (I.DEFAULTTAXCODE is null and C.DEFAULTTAXCODE is not null) 
OR (I.DEFAULTTAXCODE is not null and C.DEFAULTTAXCODE is null))
		OR 		( I.REQUIREEXEMPTTAXNO <>  C.REQUIREEXEMPTTAXNO OR (I.REQUIREEXEMPTTAXNO is null and C.REQUIREEXEMPTTAXNO is not null) 
OR (I.REQUIREEXEMPTTAXNO is not null and C.REQUIREEXEMPTTAXNO is null))
		OR 		( I.DEFAULTCURRENCY <>  C.DEFAULTCURRENCY OR (I.DEFAULTCURRENCY is null and C.DEFAULTCURRENCY is not null) 
OR (I.DEFAULTCURRENCY is not null and C.DEFAULTCURRENCY is null))
		OR 		( I.POSTCODESEARCHCODE <>  C.POSTCODESEARCHCODE OR (I.POSTCODESEARCHCODE is null and C.POSTCODESEARCHCODE is not null) 
OR (I.POSTCODESEARCHCODE is not null and C.POSTCODESEARCHCODE is null))
		OR 		( I.POSTCODEAUTOFLAG <>  C.POSTCODEAUTOFLAG OR (I.POSTCODEAUTOFLAG is null and C.POSTCODEAUTOFLAG is not null) 
OR (I.POSTCODEAUTOFLAG is not null and C.POSTCODEAUTOFLAG is null))
		OR 		( I.POSTALNAME <>  C.POSTALNAME OR (I.POSTALNAME is null and C.POSTALNAME is not null) 
OR (I.POSTALNAME is not null and C.POSTALNAME is null))
		OR 		( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null) 
OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
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
		Insert into COUNTRY(
			COUNTRYCODE,
			ALTERNATECODE,
			COUNTRY,
			INFORMALNAME,
			COUNTRYABBREV,
			COUNTRYADJECTIVE,
			RECORDTYPE,
			ISD,
			STATELITERAL,
			POSTCODELITERAL,
			POSTCODEFIRST,
			WORKDAYFLAG,
			DATECOMMENCED,
			DATECEASED,
			NOTES,
			STATEABBREVIATED,
			ALLMEMBERSFLAG,
			NAMESTYLE,
			ADDRESSSTYLE,
			DEFAULTTAXCODE,
			REQUIREEXEMPTTAXNO,
			DEFAULTCURRENCY,
			POSTCODESEARCHCODE,
			POSTCODEAUTOFLAG,
			POSTALNAME,
			PRIORARTFLAG)
		select
	 I.COUNTRYCODE,
	 I.ALTERNATECODE,
	 I.COUNTRY,
	 I.INFORMALNAME,
	 I.COUNTRYABBREV,
	 I.COUNTRYADJECTIVE,
	 I.RECORDTYPE,
	 I.ISD,
	 I.STATELITERAL,
	 I.POSTCODELITERAL,
	 I.POSTCODEFIRST,
	 I.WORKDAYFLAG,
	 I.DATECOMMENCED,
	 I.DATECEASED,
	replace( I.NOTES,char(10),char(13)+char(10)),
	 I.STATEABBREVIATED,
	 I.ALLMEMBERSFLAG,
	 I.NAMESTYLE,
	 I.ADDRESSSTYLE,
	 I.DEFAULTTAXCODE,
	 I.REQUIREEXEMPTTAXNO,
	 I.DEFAULTCURRENCY,
	 I.POSTCODESEARCHCODE,
	 I.POSTCODEAUTOFLAG,
	 I.POSTALNAME,
	 I.PRIORARTFLAG
		from CCImport_COUNTRY I
		left join COUNTRY C	on ( C.COUNTRYCODE=I.COUNTRYCODE)
		where C.COUNTRYCODE is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete COUNTRY
		from CCImport_COUNTRY I
		right join COUNTRY C	on ( C.COUNTRYCODE=I.COUNTRYCODE)
		where I.COUNTRYCODE is null"

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
grant execute on dbo.ip_cc_COUNTRY  to public
go
