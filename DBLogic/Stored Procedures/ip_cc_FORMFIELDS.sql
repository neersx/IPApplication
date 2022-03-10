-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_FORMFIELDS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_FORMFIELDS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_FORMFIELDS.'
	drop procedure dbo.ip_cc_FORMFIELDS
	print '**** Creating procedure dbo.ip_cc_FORMFIELDS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_FORMFIELDS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_FORMFIELDS
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the FORMFIELDS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 21 Aug 2019	MF	DR-36783 1	Function created
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


-- Prerequisite that the CCImport_FORMFIELDS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_FORMFIELDS('"+@psUserName+"')
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
		Delete FORMFIELDS
		from CCImport_FORMFIELDS I
		right join FORMFIELDS C on (C.DOCUMENTNO=I.DOCUMENTNO
					and C.FIELDNAME =I.FIELDNAME )
		where I.DOCUMENTNO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Update FORMFIELDS
		set	FIELDTYPE        =I.FIELDTYPE,
			ITEM_ID          =I.ITEM_ID,
			FIELDDESCRIPTION =I.FIELDDESCRIPTION,
			ITEMPARAMETER    =I.ITEMPARAMETER,
			RESULTSEPARATOR  =I.RESULTSEPARATOR
		from	FORMFIELDS C
		join	CCImport_FORMFIELDS I	on ( I.DOCUMENTNO=C.DOCUMENTNO
						and  I.FIELDNAME =C.FIELDNAME)
		where 	( I.FIELDTYPE         <>  C.FIELDTYPE         OR (I.FIELDTYPE         is null and C.FIELDTYPE         is not null) OR (I.FIELDTYPE         is not null and C.FIELDTYPE         is null))
		OR 	( I.ITEM_ID           <>  C.ITEM_ID           OR (I.ITEM_ID           is null and C.ITEM_ID           is not null) OR (I.ITEM_ID           is not null and C.ITEM_ID           is null))
		OR 	( I.FIELDDESCRIPTION  <>  C.FIELDDESCRIPTION  OR (I.FIELDDESCRIPTION  is null and C.FIELDDESCRIPTION  is not null) OR (I.FIELDDESCRIPTION  is not null and C.FIELDDESCRIPTION  is null))
		OR 	( I.ITEMPARAMETER     <>  C.ITEMPARAMETER     OR (I.ITEMPARAMETER     is null and C.ITEMPARAMETER     is not null) OR (I.ITEMPARAMETER     is not null and C.ITEMPARAMETER     is null))
		OR 	( I.RESULTSEPARATOR   <>  C.RESULTSEPARATOR   OR (I.RESULTSEPARATOR   is null and C.RESULTSEPARATOR   is not null) OR (I.RESULTSEPARATOR   is not null and C.RESULTSEPARATOR   is null))

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
		-- Insert the rows where existing key not found.
		Insert into FORMFIELDS(
			DOCUMENTNO,
			FIELDNAME,
			FIELDTYPE,
			ITEM_ID,
			FIELDDESCRIPTION,
			ITEMPARAMETER,
			RESULTSEPARATOR)
		select
			I.DOCUMENTNO,
			I.FIELDNAME,
			I.FIELDTYPE,
			I.ITEM_ID,
			I.FIELDDESCRIPTION,
			I.ITEMPARAMETER,
			I.RESULTSEPARATOR
		from CCImport_FORMFIELDS I
		left join FORMFIELDS C	on ( C.DOCUMENTNO=I.DOCUMENTNO
					and  C.FIELDNAME =I.FIELDNAME)
		where C.DOCUMENTNO is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
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
grant execute on dbo.ip_cc_FORMFIELDS  to public
go
