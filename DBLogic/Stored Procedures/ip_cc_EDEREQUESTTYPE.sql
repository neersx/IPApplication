-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_EDEREQUESTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_EDEREQUESTTYPE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_EDEREQUESTTYPE.'
	drop procedure dbo.ip_cc_EDEREQUESTTYPE
	print '**** Creating procedure dbo.ip_cc_EDEREQUESTTYPE...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_EDEREQUESTTYPE
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_EDEREQUESTTYPE
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the EDEREQUESTTYPE table
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


-- Prerequisite that the CCImport_EDEREQUESTTYPE table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_EDEREQUESTTYPE('"+@psUserName+"')
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
		Update EDEREQUESTTYPE
		set	REQUESTTYPENAME=replace( I.REQUESTTYPENAME,char(10),char(13)+char(10)),
			REQUESTORNAMETYPE= I.REQUESTORNAMETYPE,
			TRANSACTIONREASONNO= I.TRANSACTIONREASONNO,
			UPDATEEVENTNO= I.UPDATEEVENTNO,
			POLICINGNOTREQUIRED= I.POLICINGNOTREQUIRED,
			OUTPUTNOTREQUIRED= I.OUTPUTNOTREQUIRED
		from	EDEREQUESTTYPE C
		join	CCImport_EDEREQUESTTYPE I	on ( I.REQUESTTYPECODE=C.REQUESTTYPECODE)
" Set @sSQLString1="
		where 		(replace( I.REQUESTTYPENAME,char(10),char(13)+char(10)) <>  C.REQUESTTYPENAME)
		OR 		( I.REQUESTORNAMETYPE <>  C.REQUESTORNAMETYPE OR (I.REQUESTORNAMETYPE is null and C.REQUESTORNAMETYPE is not null )
 OR (I.REQUESTORNAMETYPE is not null and C.REQUESTORNAMETYPE is null))
		OR 		( I.TRANSACTIONREASONNO <>  C.TRANSACTIONREASONNO OR (I.TRANSACTIONREASONNO is null and C.TRANSACTIONREASONNO is not null )
 OR (I.TRANSACTIONREASONNO is not null and C.TRANSACTIONREASONNO is null))
		OR 		( I.UPDATEEVENTNO <>  C.UPDATEEVENTNO OR (I.UPDATEEVENTNO is null and C.UPDATEEVENTNO is not null )
 OR (I.UPDATEEVENTNO is not null and C.UPDATEEVENTNO is null))
		OR 		( I.POLICINGNOTREQUIRED <>  C.POLICINGNOTREQUIRED)
		OR		( I.OUTPUTNOTREQUIRED   <>  C.OUTPUTNOTREQUIRED)
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
		Insert into EDEREQUESTTYPE(
			REQUESTTYPECODE,
			REQUESTTYPENAME,
			REQUESTORNAMETYPE,
			TRANSACTIONREASONNO,
			UPDATEEVENTNO,
			POLICINGNOTREQUIRED,
			OUTPUTNOTREQUIRED)
		select
			I.REQUESTTYPECODE,
			replace( I.REQUESTTYPENAME,char(10),char(13)+char(10)),
			I.REQUESTORNAMETYPE,
			I.TRANSACTIONREASONNO,
			I.UPDATEEVENTNO,
			I.POLICINGNOTREQUIRED,
			I.OUTPUTNOTREQUIRED
		from CCImport_EDEREQUESTTYPE I
		left join EDEREQUESTTYPE C	on ( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
		where C.REQUESTTYPECODE is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete EDEREQUESTTYPE
		from CCImport_EDEREQUESTTYPE I
		right join EDEREQUESTTYPE C	on ( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
		where I.REQUESTTYPECODE is null"

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
grant execute on dbo.ip_cc_EDEREQUESTTYPE  to public
go
