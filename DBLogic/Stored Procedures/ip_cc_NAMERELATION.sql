-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_NAMERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_NAMERELATION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_NAMERELATION.'
	drop procedure dbo.ip_cc_NAMERELATION
	print '**** Creating procedure dbo.ip_cc_NAMERELATION...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_NAMERELATION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_NAMERELATION
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the NAMERELATION table
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


-- Prerequisite that the CCImport_NAMERELATION table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_NAMERELATION('"+@psUserName+"')
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
		Update NAMERELATION
		set	RELATIONDESCR= I.RELATIONDESCR,
			REVERSEDESCR= I.REVERSEDESCR,
			SHOWFLAG= I.SHOWFLAG,
			USEDBYNAMETYPE= I.USEDBYNAMETYPE,
			CRMONLY= I.CRMONLY,
			ETHICALWALL= I.ETHICALWALL
		from	NAMERELATION C
		join	CCImport_NAMERELATION I	on ( I.RELATIONSHIP=C.RELATIONSHIP)
" Set @sSQLString1="
		where 		( I.RELATIONDESCR <>  C.RELATIONDESCR OR (I.RELATIONDESCR is null and C.RELATIONDESCR is not null )
 OR (I.RELATIONDESCR is not null and C.RELATIONDESCR is null))
		OR 		( I.REVERSEDESCR <>  C.REVERSEDESCR OR (I.REVERSEDESCR is null and C.REVERSEDESCR is not null )
 OR (I.REVERSEDESCR is not null and C.REVERSEDESCR is null))
		OR 		( I.SHOWFLAG <>  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is not null )
 OR (I.SHOWFLAG is not null and C.SHOWFLAG is null))
		OR 		( I.USEDBYNAMETYPE <>  C.USEDBYNAMETYPE OR (I.USEDBYNAMETYPE is null and C.USEDBYNAMETYPE is not null )
 OR (I.USEDBYNAMETYPE is not null and C.USEDBYNAMETYPE is null))
		OR 		( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null )
 OR (I.CRMONLY is not null and C.CRMONLY is null))
		OR 		( I.ETHICALWALL <>  C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is not null )
 OR (I.ETHICALWALL is not null and C.ETHICALWALL is null))
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
		Insert into NAMERELATION(
			RELATIONSHIP,
			RELATIONDESCR,
			REVERSEDESCR,
			SHOWFLAG,
			USEDBYNAMETYPE,
			CRMONLY,
			ETHICALWALL)
		select
			I.RELATIONSHIP,
			I.RELATIONDESCR,
			I.REVERSEDESCR,
			I.SHOWFLAG,
			I.USEDBYNAMETYPE,
			I.CRMONLY,
			I.ETHICALWALL
		from CCImport_NAMERELATION I
		left join NAMERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
		where C.RELATIONSHIP is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete NAMERELATION
		from CCImport_NAMERELATION I
		right join NAMERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
		where I.RELATIONSHIP is null"

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
grant execute on dbo.ip_cc_NAMERELATION  to public
go
