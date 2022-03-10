-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_TOPICDEFAULTSETTIN_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_TOPICDEFAULTSETTIN_]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_TOPICDEFAULTSETTIN_.'
	drop procedure dbo.ip_cc_TOPICDEFAULTSETTIN_
	print '**** Creating procedure dbo.ip_cc_TOPICDEFAULTSETTIN_...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_TOPICDEFAULTSETTIN_
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_TOPICDEFAULTSETTIN_
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the TOPICDEFAULTSETTINGS table
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


-- Prerequisite that the CCImport_TOPICDEFAULTSETTINGS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_TOPICDEFAULTSETTIN_('"+@psUserName+"')
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
		Delete TOPICDEFAULTSETTINGS
		from CCImport_TOPICDEFAULTSETTINGS I
		right join TOPICDEFAULTSETTINGS C	on ( C.DEFAULTSETTINGNO=I.DEFAULTSETTINGNO)
		where I.DEFAULTSETTINGNO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update TOPICDEFAULTSETTINGS
		set	CRITERIANO= I.CRITERIANO,
			NAMECRITERIANO= I.NAMECRITERIANO,
			TOPICNAME= I.TOPICNAME,
			FILTERNAME= I.FILTERNAME,
			FILTERVALUE=replace( I.FILTERVALUE,char(10),char(13)+char(10)),
			ISINHERITED= I.ISINHERITED
		from	TOPICDEFAULTSETTINGS C
		join	CCImport_TOPICDEFAULTSETTINGS I	on ( I.DEFAULTSETTINGNO=C.DEFAULTSETTINGNO)
" Set @sSQLString1="
		where 		( I.CRITERIANO <>  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is not null )
 OR (I.CRITERIANO is not null and C.CRITERIANO is null))
		OR 		( I.NAMECRITERIANO <>  C.NAMECRITERIANO OR (I.NAMECRITERIANO is null and C.NAMECRITERIANO is not null )
 OR (I.NAMECRITERIANO is not null and C.NAMECRITERIANO is null))
		OR 		( I.TOPICNAME <>  C.TOPICNAME)
		OR 		( I.FILTERNAME <>  C.FILTERNAME)
		OR 		(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE)
		OR 		( I.ISINHERITED <>  C.ISINHERITED OR (I.ISINHERITED is null and C.ISINHERITED is not null )
 OR (I.ISINHERITED is not null and C.ISINHERITED is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
	

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT TOPICDEFAULTSETTINGS ON

		-- Insert the rows where existing key not found.
		Insert into TOPICDEFAULTSETTINGS(
			DEFAULTSETTINGNO,
			CRITERIANO,
			NAMECRITERIANO,
			TOPICNAME,
			FILTERNAME,
			FILTERVALUE,
			ISINHERITED)
		select
			I.DEFAULTSETTINGNO,
			I.CRITERIANO,
			I.NAMECRITERIANO,
			I.TOPICNAME,
			I.FILTERNAME,
			replace( I.FILTERVALUE,char(10),char(13)+char(10)),
			I.ISINHERITED
		from CCImport_TOPICDEFAULTSETTINGS I
		left join TOPICDEFAULTSETTINGS C	on ( C.DEFAULTSETTINGNO=I.DEFAULTSETTINGNO)
		where C.DEFAULTSETTINGNO is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT TOPICDEFAULTSETTINGS OFF
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
grant execute on dbo.ip_cc_TOPICDEFAULTSETTIN_  to public
go
