-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_WIPTEMPLATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_WIPTEMPLATE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_WIPTEMPLATE.'
	drop procedure dbo.ip_cc_WIPTEMPLATE
	print '**** Creating procedure dbo.ip_cc_WIPTEMPLATE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_WIPTEMPLATE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_WIPTEMPLATE
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the WIPTEMPLATE table
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


-- Prerequisite that the CCImport_WIPTEMPLATE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_WIPTEMPLATE('"+@psUserName+"')
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
		Update WIPTEMPLATE
		set	CASETYPE= I.CASETYPE,
			COUNTRYCODE= I.COUNTRYCODE,
			PROPERTYTYPE= I.PROPERTYTYPE,
			ACTION= I.ACTION,
			WIPTYPEID= I.WIPTYPEID,
			DESCRIPTION= I.DESCRIPTION,
			WIPATTRIBUTE= I.WIPATTRIBUTE,
			CONSOLIDATE= I.CONSOLIDATE,
			TAXCODE= I.TAXCODE,
			ENTERCREDITWIP= I.ENTERCREDITWIP,
			REINSTATEWIP= I.REINSTATEWIP,
			NARRATIVENO= I.NARRATIVENO,
			WIPCODESORT= I.WIPCODESORT,
			USEDBY= I.USEDBY,
			TOLERANCEPERCENT= I.TOLERANCEPERCENT,
			TOLERANCEAMT= I.TOLERANCEAMT,
			CREDITWIPCODE= I.CREDITWIPCODE,
			RENEWALFLAG= I.RENEWALFLAG,
			STATETAXCODE= I.STATETAXCODE,
			NOTINUSEFLAG= I.NOTINUSEFLAG,
			ENFORCEWIPATTRFLAG= I.ENFORCEWIPATTRFLAG,
			PREVENTWRITEDOWNFLAG= I.PREVENTWRITEDOWNFLAG
		from	WIPTEMPLATE C
		join	CCImport_WIPTEMPLATE I	on ( I.WIPCODE=C.WIPCODE)
" Set @sSQLString1="
		where 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null )
 OR (I.ACTION is not null and C.ACTION is null))
		OR 		( I.WIPTYPEID <>  C.WIPTYPEID OR (I.WIPTYPEID is null and C.WIPTYPEID is not null )
 OR (I.WIPTYPEID is not null and C.WIPTYPEID is null))
		OR 		( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.WIPATTRIBUTE <>  C.WIPATTRIBUTE OR (I.WIPATTRIBUTE is null and C.WIPATTRIBUTE is not null )
 OR (I.WIPATTRIBUTE is not null and C.WIPATTRIBUTE is null))
		OR 		( I.CONSOLIDATE <>  C.CONSOLIDATE OR (I.CONSOLIDATE is null and C.CONSOLIDATE is not null )
 OR (I.CONSOLIDATE is not null and C.CONSOLIDATE is null))
		OR 		( I.TAXCODE <>  C.TAXCODE OR (I.TAXCODE is null and C.TAXCODE is not null )
 OR (I.TAXCODE is not null and C.TAXCODE is null))
		OR 		( I.ENTERCREDITWIP <>  C.ENTERCREDITWIP OR (I.ENTERCREDITWIP is null and C.ENTERCREDITWIP is not null )
 OR (I.ENTERCREDITWIP is not null and C.ENTERCREDITWIP is null))
		OR 		( I.REINSTATEWIP <>  C.REINSTATEWIP OR (I.REINSTATEWIP is null and C.REINSTATEWIP is not null )
 OR (I.REINSTATEWIP is not null and C.REINSTATEWIP is null))
		OR 		( I.NARRATIVENO <>  C.NARRATIVENO OR (I.NARRATIVENO is null and C.NARRATIVENO is not null )
 OR (I.NARRATIVENO is not null and C.NARRATIVENO is null))
		OR 		( I.WIPCODESORT <>  C.WIPCODESORT OR (I.WIPCODESORT is null and C.WIPCODESORT is not null )
 OR (I.WIPCODESORT is not null and C.WIPCODESORT is null))
		OR 		( I.USEDBY <>  C.USEDBY OR (I.USEDBY is null and C.USEDBY is not null )
 OR (I.USEDBY is not null and C.USEDBY is null))
		OR 		( I.TOLERANCEPERCENT <>  C.TOLERANCEPERCENT OR (I.TOLERANCEPERCENT is null and C.TOLERANCEPERCENT is not null )
 OR (I.TOLERANCEPERCENT is not null and C.TOLERANCEPERCENT is null))
		OR 		( I.TOLERANCEAMT <>  C.TOLERANCEAMT OR (I.TOLERANCEAMT is null and C.TOLERANCEAMT is not null )
 OR (I.TOLERANCEAMT is not null and C.TOLERANCEAMT is null))
		OR 		( I.CREDITWIPCODE <>  C.CREDITWIPCODE OR (I.CREDITWIPCODE is null and C.CREDITWIPCODE is not null )
 OR (I.CREDITWIPCODE is not null and C.CREDITWIPCODE is null))
" Set @sSQLString2="
		OR 		( I.RENEWALFLAG <>  C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is not null) 
OR (I.RENEWALFLAG is not null and C.RENEWALFLAG is null))
		OR 		( I.STATETAXCODE <>  C.STATETAXCODE OR (I.STATETAXCODE is null and C.STATETAXCODE is not null) 
OR (I.STATETAXCODE is not null and C.STATETAXCODE is null))
		OR 		( I.NOTINUSEFLAG <>  C.NOTINUSEFLAG)
		OR 		( I.ENFORCEWIPATTRFLAG <>  C.ENFORCEWIPATTRFLAG OR (I.ENFORCEWIPATTRFLAG is null and C.ENFORCEWIPATTRFLAG is not null) 
OR (I.ENFORCEWIPATTRFLAG is not null and C.ENFORCEWIPATTRFLAG is null))
		OR 		( I.PREVENTWRITEDOWNFLAG <>  C.PREVENTWRITEDOWNFLAG OR (I.PREVENTWRITEDOWNFLAG is null and C.PREVENTWRITEDOWNFLAG is not null) 
OR (I.PREVENTWRITEDOWNFLAG is not null and C.PREVENTWRITEDOWNFLAG is null))
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
		Insert into WIPTEMPLATE(
			WIPCODE,
			CASETYPE,
			COUNTRYCODE,
			PROPERTYTYPE,
			ACTION,
			WIPTYPEID,
			DESCRIPTION,
			WIPATTRIBUTE,
			CONSOLIDATE,
			TAXCODE,
			ENTERCREDITWIP,
			REINSTATEWIP,
			NARRATIVENO,
			WIPCODESORT,
			USEDBY,
			TOLERANCEPERCENT,
			TOLERANCEAMT,
			CREDITWIPCODE,
			RENEWALFLAG,
			STATETAXCODE,
			NOTINUSEFLAG,
			ENFORCEWIPATTRFLAG,
			PREVENTWRITEDOWNFLAG)
		select
	 I.WIPCODE,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.ACTION,
	 I.WIPTYPEID,
	 I.DESCRIPTION,
	 I.WIPATTRIBUTE,
	 I.CONSOLIDATE,
	 I.TAXCODE,
	 I.ENTERCREDITWIP,
	 I.REINSTATEWIP,
	 I.NARRATIVENO,
	 I.WIPCODESORT,
	 I.USEDBY,
	 I.TOLERANCEPERCENT,
	 I.TOLERANCEAMT,
	 I.CREDITWIPCODE,
	 I.RENEWALFLAG,
	 I.STATETAXCODE,
	 I.NOTINUSEFLAG,
	 I.ENFORCEWIPATTRFLAG,
	 I.PREVENTWRITEDOWNFLAG
		from CCImport_WIPTEMPLATE I
		left join WIPTEMPLATE C	on ( C.WIPCODE=I.WIPCODE)
		where C.WIPCODE is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete WIPTEMPLATE
		from CCImport_WIPTEMPLATE I
		right join WIPTEMPLATE C	on ( C.WIPCODE=I.WIPCODE)
		where I.WIPCODE is null"

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
grant execute on dbo.ip_cc_WIPTEMPLATE  to public
go
