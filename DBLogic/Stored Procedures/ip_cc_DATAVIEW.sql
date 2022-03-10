-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_DATAVIEW
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_DATAVIEW]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_DATAVIEW.'
	drop procedure dbo.ip_cc_DATAVIEW
	print '**** Creating procedure dbo.ip_cc_DATAVIEW...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_DATAVIEW
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_DATAVIEW
-- VERSION :	3
-- DESCRIPTION:	The comparison/display and merging of imported data for the DATAVIEW table
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


-- Prerequisite that the CCImport_DATAVIEW table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_DATAVIEW('"+@psUserName+"')
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
		Delete DATAVIEW
		from CCImport_DATAVIEW I
		right join DATAVIEW C	on ( C.VIEWID=I.VIEWID)
		where I.VIEWID is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @nNewRows=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update DATAVIEW
		set	CATEGORY= I.CATEGORY,
			TITLE= I.TITLE,
			DESCRIPTION= replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			IDENTITYID= I.IDENTITYID,
			STYLE= I.STYLE,
			SORTID= I.SORTID,
			FILTERID= I.FILTERID,
			FORMATID= I.FORMATID
		from	DATAVIEW C
		join	CCImport_DATAVIEW I	on ( I.VIEWID=C.VIEWID)
" Set @sSQLString1="
		where 		( I.CATEGORY <>  C.CATEGORY)
		OR 		( I.TITLE <>  C.TITLE)
		OR 		( replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.DESCRIPTION as NVARCHAR(MAX)) OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null )
 OR (I.IDENTITYID is not null and C.IDENTITYID is null))
		OR 		( I.STYLE <>  C.STYLE)
		OR 		( I.SORTID <>  C.SORTID OR (I.SORTID is null and C.SORTID is not null )
 OR (I.SORTID is not null and C.SORTID is null))
		OR 		( I.FILTERID <>  C.FILTERID OR (I.FILTERID is null and C.FILTERID is not null )
 OR (I.FILTERID is not null and C.FILTERID is null))
		OR 		( I.FORMATID <>  C.FORMATID OR (I.FORMATID is null and C.FORMATID is not null )
 OR (I.FORMATID is not null and C.FORMATID is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Set @ErrorCode=@@Error 
		Set @pnRowCount=@@rowcount
	End 
If  @ErrorCode=0
	Begin
		Set @sSQLString="SELECT * 
		from CCImport_OVERVIEW O
		where O.TABLENAME =  'DATAVIEW'
		and O.NEW >0  "	
		
		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End	
	
	/**************** Data Insert ***************************************/
	If @ErrorCode=0 
	and @nNewRows>0
	Begin

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT DATAVIEW ON

		-- Insert the rows where existing key not found.
		Insert into DATAVIEW(
			VIEWID,
			CATEGORY,
			TITLE,
			DESCRIPTION,
			IDENTITYID,
			STYLE,
			SORTID,
			FILTERID,
			FORMATID)
		select
			I.VIEWID,
			I.CATEGORY,
			I.TITLE,
			replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)),
			I.IDENTITYID,
			I.STYLE,
			I.SORTID,
			I.FILTERID,
			I.FORMATID
		from CCImport_DATAVIEW I
		left join DATAVIEW C	on ( C.VIEWID=I.VIEWID)
		where C.VIEWID is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT DATAVIEW OFF
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
grant execute on dbo.ip_cc_DATAVIEW  to public
go
