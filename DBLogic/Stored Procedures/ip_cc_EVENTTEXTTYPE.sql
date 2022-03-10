-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_EVENTTEXTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_EVENTTEXTTYPE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_EVENTTEXTTYPE.'
	drop procedure dbo.ip_cc_EVENTTEXTTYPE
	print '**** Creating procedure dbo.ip_cc_EVENTTEXTTYPE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_EVENTTEXTTYPE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_EVENTTEXTTYPE
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the EVENTTEXTTYPE table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 06 Dec 2019	MF	DR-28833 1	Function created
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


-- Prerequisite that the CCImport_EVENTTEXTTYPE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_EVENTTEXTTYPE('"+@psUserName+"')
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

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete EVENTTEXTTYPE
		from CCImport_EVENTTEXTTYPE I
		right join EVENTTEXTTYPE C on (C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID )
		where I.EVENTTEXTTYPEID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Update EVENTTEXTTYPE
		set	DESCRIPTION    =I.DESCRIPTION,
			ISEXTERNAL     =I.ISEXTERNAL,
			SHARINGALLOWED =I.SHARINGALLOWED
		from	EVENTTEXTTYPE C
		join	CCImport_EVENTTEXTTYPE I	on ( I.EVENTTEXTTYPEID=C.EVENTTEXTTYPEID)
		where 	( I.DESCRIPTION     <>  C.DESCRIPTION     OR (I.DESCRIPTION     is null and C.DESCRIPTION     is not null) OR (I.DESCRIPTION    is not null and C.DESCRIPTION      is null))
		OR 	( I.ISEXTERNAL      <>  C.ISEXTERNAL      OR (I.ISEXTERNAL      is null and C.ISEXTERNAL      is not null) OR (I.ISEXTERNAL      is not null and C.ISEXTERNAL      is null))
		OR 	( I.SHARINGALLOWED  <>  C.SHARINGALLOWED  OR (I.SHARINGALLOWED  is null and C.SHARINGALLOWED  is not null) OR (I.SHARINGALLOWED  is not null and C.SHARINGALLOWED  is null))

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
		set IDENTITY_INSERT EVENTTEXTTYPE ON

		-- Insert the rows where existing key not found.

		Insert into EVENTTEXTTYPE(
			EVENTTEXTTYPEID,
			DESCRIPTION,
			ISEXTERNAL,
			SHARINGALLOWED)
		select
			I.EVENTTEXTTYPEID,
			I.DESCRIPTION,
			I.ISEXTERNAL,
			I.SHARINGALLOWED
		from CCImport_EVENTTEXTTYPE I
		left join EVENTTEXTTYPE C	on ( C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID)
		where C.EVENTTEXTTYPEID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		set IDENTITY_INSERT EVENTTEXTTYPE OFF
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
grant execute on dbo.ip_cc_EVENTTEXTTYPE  to public
go
