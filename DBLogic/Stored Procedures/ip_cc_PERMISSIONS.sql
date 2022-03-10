-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_PERMISSIONS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_PERMISSIONS.'
	drop procedure dbo.ip_cc_PERMISSIONS
	print '**** Creating procedure dbo.ip_cc_PERMISSIONS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_PERMISSIONS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_PERMISSIONS
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the PERMISSIONS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 09 May 2014	MF	S22069	2	Where IDENTITY is used on a column, the rows missing from the incoming
--					data need to be removed before the Update and Inserts to avoid potential 
--					duplicate keys on alternate index.
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


-- Prerequisite that the CCImport_PERMISSIONS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_PERMISSIONS('"+@psUserName+"')
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
		Delete PERMISSIONS
		from CCImport_PERMISSIONS I
		right join PERMISSIONS C	on ( C.PERMISSIONID=I.PERMISSIONID)
		where I.PERMISSIONID is null

		Select	@ErrorCode=@@ERROR,
			@pnRowCount=@@rowcount
	End
	
/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Update PERMISSIONS
		set	OBJECTTABLE= I.OBJECTTABLE,
			OBJECTINTEGERKEY= I.OBJECTINTEGERKEY,
			OBJECTSTRINGKEY= I.OBJECTSTRINGKEY,
			LEVELTABLE= I.LEVELTABLE,
			LEVELKEY= I.LEVELKEY,
			GRANTPERMISSION= I.GRANTPERMISSION,
			DENYPERMISSION= I.DENYPERMISSION
		from	PERMISSIONS C
		join	CCImport_PERMISSIONS I	on ( I.PERMISSIONID=C.PERMISSIONID)
		where 	( I.OBJECTTABLE      <>  C.OBJECTTABLE)
		OR 	( I.OBJECTINTEGERKEY <>  C.OBJECTINTEGERKEY OR (I.OBJECTINTEGERKEY is null and C.OBJECTINTEGERKEY is not null ) OR ( I.OBJECTINTEGERKEY is not null and C.OBJECTINTEGERKEY is null))
		OR 	( I.OBJECTSTRINGKEY  <>  C.OBJECTSTRINGKEY  OR (I.OBJECTSTRINGKEY  is null and C.OBJECTSTRINGKEY  is not null ) OR ( I.OBJECTSTRINGKEY  is not null and C.OBJECTSTRINGKEY  is null))
		OR 	( I.LEVELTABLE       <>  C.LEVELTABLE       OR (I.LEVELTABLE       is null and C.LEVELTABLE       is not null )	OR ( I.LEVELTABLE       is not null and C.LEVELTABLE       is null))
		OR 	( I.LEVELKEY         <>  C.LEVELKEY         OR (I.LEVELKEY         is null and C.LEVELKEY         is not null ) OR ( I.LEVELKEY         is not null and C.LEVELKEY         is null))
		OR 	( I.GRANTPERMISSION  <>  C.GRANTPERMISSION)
		OR 	( I.DENYPERMISSION   <>  C.DENYPERMISSION)
	
		Select	@ErrorCode=@@ERROR,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT PERMISSIONS ON

		-- Insert the rows where existing key not found.
		Insert into PERMISSIONS(
			PERMISSIONID,
			OBJECTTABLE,
			OBJECTINTEGERKEY,
			OBJECTSTRINGKEY,
			LEVELTABLE,
			LEVELKEY,
			GRANTPERMISSION,
			DENYPERMISSION)
		select	I.PERMISSIONID,
			I.OBJECTTABLE,
			I.OBJECTINTEGERKEY,
			I.OBJECTSTRINGKEY,
			I.LEVELTABLE,
			I.LEVELKEY,
			I.GRANTPERMISSION,
			I.DENYPERMISSION
		from CCImport_PERMISSIONS I
		left join PERMISSIONS C	on ( C.PERMISSIONID=I.PERMISSIONID)
		where C.PERMISSIONID is null
		
		Select	@ErrorCode=@@ERROR,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT PERMISSIONS OFF
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
grant execute on dbo.ip_cc_PERMISSIONS  to public
go
