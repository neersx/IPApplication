-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_RATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_RATES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_RATES.'
	drop procedure dbo.ip_cc_RATES
	print '**** Creating procedure dbo.ip_cc_RATES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_RATES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_RATES
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the RATES table
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


-- Prerequisite that the CCImport_RATES table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_RATES('"+@psUserName+"')
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
		Update RATES
		set	RATEDESC= I.RATEDESC,
			RATETYPE= I.RATETYPE,
			USETYPEOFMARK= I.USETYPEOFMARK,
			RATENOSORT= I.RATENOSORT,
			CALCLABEL1= I.CALCLABEL1,
			CALCLABEL2= I.CALCLABEL2,
			ACTION= I.ACTION,
			AGENTNAMETYPE= I.AGENTNAMETYPE
		from	RATES C
		join	CCImport_RATES I	on ( I.RATENO=C.RATENO)
" Set @sSQLString1="
		where 		( I.RATEDESC <>  C.RATEDESC OR (I.RATEDESC is null and C.RATEDESC is not null )
 OR (I.RATEDESC is not null and C.RATEDESC is null))
		OR 		( I.RATETYPE <>  C.RATETYPE OR (I.RATETYPE is null and C.RATETYPE is not null )
 OR (I.RATETYPE is not null and C.RATETYPE is null))
		OR 		( I.USETYPEOFMARK <>  C.USETYPEOFMARK OR (I.USETYPEOFMARK is null and C.USETYPEOFMARK is not null )
 OR (I.USETYPEOFMARK is not null and C.USETYPEOFMARK is null))
		OR 		( I.RATENOSORT <>  C.RATENOSORT OR (I.RATENOSORT is null and C.RATENOSORT is not null )
 OR (I.RATENOSORT is not null and C.RATENOSORT is null))
		OR 		( I.CALCLABEL1 <>  C.CALCLABEL1 OR (I.CALCLABEL1 is null and C.CALCLABEL1 is not null )
 OR (I.CALCLABEL1 is not null and C.CALCLABEL1 is null))
		OR 		( I.CALCLABEL2 <>  C.CALCLABEL2 OR (I.CALCLABEL2 is null and C.CALCLABEL2 is not null )
 OR (I.CALCLABEL2 is not null and C.CALCLABEL2 is null))
		OR 		( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null )
 OR (I.ACTION is not null and C.ACTION is null))
		OR 		( I.AGENTNAMETYPE <>  C.AGENTNAMETYPE OR (I.AGENTNAMETYPE is null and C.AGENTNAMETYPE is not null )
 OR (I.AGENTNAMETYPE is not null and C.AGENTNAMETYPE is null))
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
		Insert into RATES(
			RATENO,
			RATEDESC,
			RATETYPE,
			USETYPEOFMARK,
			RATENOSORT,
			CALCLABEL1,
			CALCLABEL2,
			ACTION,
			AGENTNAMETYPE)
		select
	 I.RATENO,
	 I.RATEDESC,
	 I.RATETYPE,
	 I.USETYPEOFMARK,
	 I.RATENOSORT,
	 I.CALCLABEL1,
	 I.CALCLABEL2,
	 I.ACTION,
	 I.AGENTNAMETYPE
		from CCImport_RATES I
		left join RATES C	on ( C.RATENO=I.RATENO)
		where C.RATENO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete RATES
		from CCImport_RATES I
		right join RATES C	on ( C.RATENO=I.RATENO)
		where I.RATENO is null"

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
grant execute on dbo.ip_cc_RATES  to public
go
