-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_PORTALSETTING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_PORTALSETTING]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_PORTALSETTING.'
	drop procedure dbo.ip_cc_PORTALSETTING
	print '**** Creating procedure dbo.ip_cc_PORTALSETTING...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_PORTALSETTING
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_PORTALSETTING
-- VERSION :	3
-- DESCRIPTION:	The comparison/display and merging of imported data for the PORTALSETTING table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Procedure created
-- 09 May 2014	MF	S22069	2	Where IDENTITY is used on a column, the rows missing from the incoming
--					data need to be removed before the Update and Inserts to avoid potential 
--					duplicate keys on alternate index.
-- 10 Apr 2017	MF	71020	3	Correction to logic problem stopping some rows from being copied.
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


-- Prerequisite that the CCImport_PORTALSETTING table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_PORTALSETTING('"+@psUserName+"')
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
		Delete PORTALSETTING
		from CCImport_PORTALSETTING I
		right join PORTALSETTING C	on ( C.SETTINGID=I.SETTINGID)
		where I.SETTINGID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update PORTALSETTING
		set	MODULEID= I.MODULEID,
			MODULECONFIGID= I.MODULECONFIGID,
			IDENTITYID= I.IDENTITYID,
			SETTINGNAME= I.SETTINGNAME,
			SETTINGVALUE= replace(CAST(I.SETTINGVALUE as NVARCHAR(MAX)),char(10),char(13)+char(10))
		from	PORTALSETTING C
		join	CCImport_PORTALSETTING I	on ( I.SETTINGID=C.SETTINGID)
" Set @sSQLString1="
		where 		( I.MODULEID <>  C.MODULEID OR (I.MODULEID is null and C.MODULEID is not null )
 OR (I.MODULEID is not null and C.MODULEID is null))
		OR 		( I.MODULECONFIGID <>  C.MODULECONFIGID OR (I.MODULECONFIGID is null and C.MODULECONFIGID is not null )
 OR (I.MODULECONFIGID is not null and C.MODULECONFIGID is null))
		OR 		( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null )
 OR (I.IDENTITYID is not null and C.IDENTITYID is null))
		OR 		( I.SETTINGNAME <>  C.SETTINGNAME)
		OR 		( replace(CAST(I.SETTINGVALUE as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.SETTINGVALUE as NVARCHAR(MAX)) OR (I.SETTINGVALUE is null and C.SETTINGVALUE is not null )
 OR (I.SETTINGVALUE is not null and C.SETTINGVALUE is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 
	
	If  @ErrorCode=0
	Begin
		Set @sSQLString="SELECT * 
		from CCImport_OVERVIEW O
		where O.TABLENAME =  'PORTALSETTING'
		and O.NEW >0  "	
		
		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @nNewRows=@@rowcount
	End	
	
	/**************** Data Insert ***************************************/
	If @ErrorCode=0 
	and @nNewRows>0
	Begin

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT PORTALSETTING ON

		-- Insert the rows where existing key not found.
		Insert into PORTALSETTING(
			SETTINGID,
			MODULEID,
			MODULECONFIGID,
			IDENTITYID,
			SETTINGNAME,
			SETTINGVALUE)
		select
			I.SETTINGID,
			I.MODULEID,
			I.MODULECONFIGID,
			I.IDENTITYID,
			I.SETTINGNAME,
			replace(CAST(I.SETTINGVALUE as NVARCHAR(MAX)),char(10),char(13)+char(10))
		from CCImport_PORTALSETTING I
		left join PORTALSETTING C	on ( C.SETTINGID=I.SETTINGID)
		where C.SETTINGID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT PORTALSETTING OFF
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
grant execute on dbo.ip_cc_PORTALSETTING  to public
go
