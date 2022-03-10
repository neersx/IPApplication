-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_PORTALTAB
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_PORTALTAB]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_PORTALTAB.'
	drop procedure dbo.ip_cc_PORTALTAB
	print '**** Creating procedure dbo.ip_cc_PORTALTAB...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_PORTALTAB
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_PORTALTAB
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the PORTALTAB table
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


-- Prerequisite that the CCImport_PORTALTAB table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_PORTALTAB('"+@psUserName+"')
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
		Delete PORTALTAB
		from CCImport_PORTALTAB I
		right join PORTALTAB C	on ( C.TABID=I.TABID)
		where I.TABID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update PORTALTAB
		set	TABNAME= I.TABNAME,
			IDENTITYID= I.IDENTITYID,
			TABSEQUENCE= I.TABSEQUENCE,
			PORTALID= I.PORTALID,
			CSSCLASSNAME= I.CSSCLASSNAME,
			CANRENAME= I.CANRENAME,
			CANDELETE= I.CANDELETE,
			PARENTTABID= I.PARENTTABID
		from	PORTALTAB C
		join	CCImport_PORTALTAB I	on ( I.TABID=C.TABID)
" Set @sSQLString1="
		where 		( I.TABNAME <>  C.TABNAME)
		OR 		( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null )
 OR (I.IDENTITYID is not null and C.IDENTITYID is null))
		OR 		( I.TABSEQUENCE <>  C.TABSEQUENCE)
		OR 		( I.PORTALID <>  C.PORTALID OR (I.PORTALID is null and C.PORTALID is not null )
 OR (I.PORTALID is not null and C.PORTALID is null))
		OR 		( I.CSSCLASSNAME <>  C.CSSCLASSNAME OR (I.CSSCLASSNAME is null and C.CSSCLASSNAME is not null )
 OR (I.CSSCLASSNAME is not null and C.CSSCLASSNAME is null))
		OR 		( I.CANRENAME <>  C.CANRENAME)
		OR 		( I.CANDELETE <>  C.CANDELETE)
		OR 		( I.PARENTTABID <>  C.PARENTTABID OR (I.PARENTTABID is null and C.PARENTTABID is not null )
 OR (I.PARENTTABID is not null and C.PARENTTABID is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
	

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT PORTALTAB ON

		-- Insert the rows where existing key not found.
		Insert into PORTALTAB(
			TABID,
			TABNAME,
			IDENTITYID,
			TABSEQUENCE,
			PORTALID,
			CSSCLASSNAME,
			CANRENAME,
			CANDELETE,
			PARENTTABID)
		select
			I.TABID,
			I.TABNAME,
			I.IDENTITYID,
			I.TABSEQUENCE,
			I.PORTALID,
			I.CSSCLASSNAME,
			I.CANRENAME,
			I.CANDELETE,
			I.PARENTTABID
		from CCImport_PORTALTAB I
		left join PORTALTAB C	on ( C.TABID=I.TABID)
		where C.TABID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT PORTALTAB OFF
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
grant execute on dbo.ip_cc_PORTALTAB  to public
go
