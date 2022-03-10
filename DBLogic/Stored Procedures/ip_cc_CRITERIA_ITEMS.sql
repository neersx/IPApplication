-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_CRITERIA_ITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_CRITERIA_ITEMS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_CRITERIA_ITEMS.'
	drop procedure dbo.ip_cc_CRITERIA_ITEMS
	print '**** Creating procedure dbo.ip_cc_CRITERIA_ITEMS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_CRITERIA_ITEMS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_CRITERIA_ITEMS
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the CRITERIA_ITEMS table
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


-- Prerequisite that the CCImport_CRITERIA_ITEMS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_CRITERIA_ITEMS('"+@psUserName+"')
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
		Update CRITERIA_ITEMS
		set	DESCRIPTION= I.DESCRIPTION,
			QUERY= replace(CAST(I.QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			CELL1= I.CELL1,
			LITERAL1= I.LITERAL1,
			CELL2= I.CELL2,
			LITERAL2= I.LITERAL2,
			CELL3= I.CELL3,
			LITERAL3= I.LITERAL3,
			CELL4= I.CELL4,
			LITERAL4= I.LITERAL4,
			CELL5= I.CELL5,
			LITERAL5= I.LITERAL5,
			CELL6= I.CELL6,
			LITERAL6= I.LITERAL6,
			BACKLINK= I.BACKLINK
		from	CRITERIA_ITEMS C
		join	CCImport_CRITERIA_ITEMS I	on ( I.CRITERIA_ID=C.CRITERIA_ID)
" Set @sSQLString1="
		where 		( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( replace(CAST(I.QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.QUERY as NVARCHAR(MAX)) OR (I.QUERY is null and C.QUERY is not null )
 OR (I.QUERY is not null and C.QUERY is null))
		OR 		( I.CELL1 <>  C.CELL1 OR (I.CELL1 is null and C.CELL1 is not null )
 OR (I.CELL1 is not null and C.CELL1 is null))
		OR 		( I.LITERAL1 <>  C.LITERAL1 OR (I.LITERAL1 is null and C.LITERAL1 is not null )
 OR (I.LITERAL1 is not null and C.LITERAL1 is null))
		OR 		( I.CELL2 <>  C.CELL2 OR (I.CELL2 is null and C.CELL2 is not null )
 OR (I.CELL2 is not null and C.CELL2 is null))
		OR 		( I.LITERAL2 <>  C.LITERAL2 OR (I.LITERAL2 is null and C.LITERAL2 is not null )
 OR (I.LITERAL2 is not null and C.LITERAL2 is null))
		OR 		( I.CELL3 <>  C.CELL3 OR (I.CELL3 is null and C.CELL3 is not null )
 OR (I.CELL3 is not null and C.CELL3 is null))
		OR 		( I.LITERAL3 <>  C.LITERAL3 OR (I.LITERAL3 is null and C.LITERAL3 is not null )
 OR (I.LITERAL3 is not null and C.LITERAL3 is null))
		OR 		( I.CELL4 <>  C.CELL4 OR (I.CELL4 is null and C.CELL4 is not null )
 OR (I.CELL4 is not null and C.CELL4 is null))
		OR 		( I.LITERAL4 <>  C.LITERAL4 OR (I.LITERAL4 is null and C.LITERAL4 is not null )
 OR (I.LITERAL4 is not null and C.LITERAL4 is null))
		OR 		( I.CELL5 <>  C.CELL5 OR (I.CELL5 is null and C.CELL5 is not null )
 OR (I.CELL5 is not null and C.CELL5 is null))
		OR 		( I.LITERAL5 <>  C.LITERAL5 OR (I.LITERAL5 is null and C.LITERAL5 is not null )
 OR (I.LITERAL5 is not null and C.LITERAL5 is null))
		OR 		( I.CELL6 <>  C.CELL6 OR (I.CELL6 is null and C.CELL6 is not null )
 OR (I.CELL6 is not null and C.CELL6 is null))
		OR 		( I.LITERAL6 <>  C.LITERAL6 OR (I.LITERAL6 is null and C.LITERAL6 is not null )
 OR (I.LITERAL6 is not null and C.LITERAL6 is null))
		OR 		( I.BACKLINK <>  C.BACKLINK OR (I.BACKLINK is null and C.BACKLINK is not null )
 OR (I.BACKLINK is not null and C.BACKLINK is null))
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
		Insert into CRITERIA_ITEMS(
			CRITERIA_ID,
			DESCRIPTION,
			QUERY,
			CELL1,
			LITERAL1,
			CELL2,
			LITERAL2,
			CELL3,
			LITERAL3,
			CELL4,
			LITERAL4,
			CELL5,
			LITERAL5,
			CELL6,
			LITERAL6,
			BACKLINK)
		select
	 I.CRITERIA_ID,
	 I.DESCRIPTION,
	 replace(CAST(I.QUERY as NVARCHAR(MAX)),char(10),char(13)+char(10)),
	 I.CELL1,
	 I.LITERAL1,
	 I.CELL2,
	 I.LITERAL2,
	 I.CELL3,
	 I.LITERAL3,
	 I.CELL4,
	 I.LITERAL4,
	 I.CELL5,
	 I.LITERAL5,
	 I.CELL6,
	 I.LITERAL6,
	 I.BACKLINK
		from CCImport_CRITERIA_ITEMS I
		left join CRITERIA_ITEMS C	on ( C.CRITERIA_ID=I.CRITERIA_ID)
		where C.CRITERIA_ID is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete CRITERIA_ITEMS
		from CCImport_CRITERIA_ITEMS I
		right join CRITERIA_ITEMS C	on ( C.CRITERIA_ID=I.CRITERIA_ID)
		where I.CRITERIA_ID is null"

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
grant execute on dbo.ip_cc_CRITERIA_ITEMS  to public
go
