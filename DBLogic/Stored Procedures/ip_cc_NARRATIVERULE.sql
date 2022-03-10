-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_NARRATIVERULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_NARRATIVERULE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_NARRATIVERULE.'
	drop procedure dbo.ip_cc_NARRATIVERULE
	print '**** Creating procedure dbo.ip_cc_NARRATIVERULE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_NARRATIVERULE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_NARRATIVERULE
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the NARRATIVERULE table
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


-- Prerequisite that the CCImport_NARRATIVERULE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_NARRATIVERULE('"+@psUserName+"')
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
		Update NARRATIVERULE
		set	NARRATIVENO= I.NARRATIVENO,
			WIPCODE= I.WIPCODE,
			EMPLOYEENO= I.EMPLOYEENO,
			CASETYPE= I.CASETYPE,
			PROPERTYTYPE= I.PROPERTYTYPE,
			CASECATEGORY= I.CASECATEGORY,
			SUBTYPE= I.SUBTYPE,
			TYPEOFMARK= I.TYPEOFMARK,
			COUNTRYCODE= I.COUNTRYCODE,
			LOCALCOUNTRYFLAG= I.LOCALCOUNTRYFLAG,
			FOREIGNCOUNTRYFLAG= I.FOREIGNCOUNTRYFLAG,
			DEBTORNO= I.DEBTORNO
		from	NARRATIVERULE C
		join	CCImport_NARRATIVERULE I	on ( I.NARRATIVERULENO=C.NARRATIVERULENO)
" Set @sSQLString1="
		where 		( I.NARRATIVENO <>  C.NARRATIVENO)
		OR 		( I.WIPCODE <>  C.WIPCODE)
		OR 		( I.EMPLOYEENO <>  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is not null )
 OR (I.EMPLOYEENO is not null and C.EMPLOYEENO is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null )
 OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
		OR 		( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null )
 OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
		OR 		( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null )
 OR (I.SUBTYPE is not null and C.SUBTYPE is null))
		OR 		( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null )
 OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.LOCALCOUNTRYFLAG <>  C.LOCALCOUNTRYFLAG OR (I.LOCALCOUNTRYFLAG is null and C.LOCALCOUNTRYFLAG is not null )
 OR (I.LOCALCOUNTRYFLAG is not null and C.LOCALCOUNTRYFLAG is null))
		OR 		( I.FOREIGNCOUNTRYFLAG <>  C.FOREIGNCOUNTRYFLAG OR (I.FOREIGNCOUNTRYFLAG is null and C.FOREIGNCOUNTRYFLAG is not null )
 OR (I.FOREIGNCOUNTRYFLAG is not null and C.FOREIGNCOUNTRYFLAG is null))
		OR 		( I.DEBTORNO <>  C.DEBTORNO OR (I.DEBTORNO is null and C.DEBTORNO is not null )
 OR (I.DEBTORNO is not null and C.DEBTORNO is null))
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
		Insert into NARRATIVERULE(
			NARRATIVERULENO,
			NARRATIVENO,
			WIPCODE,
			EMPLOYEENO,
			CASETYPE,
			PROPERTYTYPE,
			CASECATEGORY,
			SUBTYPE,
			TYPEOFMARK,
			COUNTRYCODE,
			LOCALCOUNTRYFLAG,
			FOREIGNCOUNTRYFLAG,
			DEBTORNO)
		select
	 I.NARRATIVERULENO,
	 I.NARRATIVENO,
	 I.WIPCODE,
	 I.EMPLOYEENO,
	 I.CASETYPE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.TYPEOFMARK,
	 I.COUNTRYCODE,
	 I.LOCALCOUNTRYFLAG,
	 I.FOREIGNCOUNTRYFLAG,
	 I.DEBTORNO
		from CCImport_NARRATIVERULE I
		left join NARRATIVERULE C	on ( C.NARRATIVERULENO=I.NARRATIVERULENO)
		where C.NARRATIVERULENO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete NARRATIVERULE
		from CCImport_NARRATIVERULE I
		right join NARRATIVERULE C	on ( C.NARRATIVERULENO=I.NARRATIVERULENO)
		where I.NARRATIVERULENO is null"

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
grant execute on dbo.ip_cc_NARRATIVERULE  to public
go
