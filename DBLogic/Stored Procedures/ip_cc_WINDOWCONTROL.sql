-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_WINDOWCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_WINDOWCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_WINDOWCONTROL.'
	drop procedure dbo.ip_cc_WINDOWCONTROL
	print '**** Creating procedure dbo.ip_cc_WINDOWCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_WINDOWCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_WINDOWCONTROL
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the WINDOWCONTROL table
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


-- Prerequisite that the CCImport_WINDOWCONTROL table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_WINDOWCONTROL('"+@psUserName+"')
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
		Delete WINDOWCONTROL
		from CCImport_WINDOWCONTROL I
		right join WINDOWCONTROL C	on ( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
		where I.WINDOWCONTROLNO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End

/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update WINDOWCONTROL
		set	CRITERIANO= I.CRITERIANO,
			NAMECRITERIANO= I.NAMECRITERIANO,
			WINDOWNAME= I.WINDOWNAME,
			ISEXTERNAL= I.ISEXTERNAL,
			DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			WINDOWTITLE=replace( I.WINDOWTITLE,char(10),char(13)+char(10)),
			WINDOWSHORTTITLE=replace( I.WINDOWSHORTTITLE,char(10),char(13)+char(10)),
			ENTRYNUMBER= I.ENTRYNUMBER,
			THEME= I.THEME,
			ISINHERITED= I.ISINHERITED
		from	WINDOWCONTROL C
		join	CCImport_WINDOWCONTROL I	on ( I.WINDOWCONTROLNO=C.WINDOWCONTROLNO)
" Set @sSQLString1="
		where 		( I.CRITERIANO <>  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is not null )
 OR (I.CRITERIANO is not null and C.CRITERIANO is null))
		OR 		( I.NAMECRITERIANO <>  C.NAMECRITERIANO OR (I.NAMECRITERIANO is null and C.NAMECRITERIANO is not null )
 OR (I.NAMECRITERIANO is not null and C.NAMECRITERIANO is null))
		OR 		( I.WINDOWNAME <>  C.WINDOWNAME)
		OR 		( I.ISEXTERNAL <>  C.ISEXTERNAL)
		OR 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null )
 OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
		OR 		(replace( I.WINDOWTITLE,char(10),char(13)+char(10)) <>  C.WINDOWTITLE OR (I.WINDOWTITLE is null and C.WINDOWTITLE is not null )
 OR (I.WINDOWTITLE is not null and C.WINDOWTITLE is null))
		OR 		(replace( I.WINDOWSHORTTITLE,char(10),char(13)+char(10)) <>  C.WINDOWSHORTTITLE OR (I.WINDOWSHORTTITLE is null and C.WINDOWSHORTTITLE is not null )
 OR (I.WINDOWSHORTTITLE is not null and C.WINDOWSHORTTITLE is null))
		OR 		( I.ENTRYNUMBER <>  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is not null )
 OR (I.ENTRYNUMBER is not null and C.ENTRYNUMBER is null))
		OR 		( I.THEME <>  C.THEME OR (I.THEME is null and C.THEME is not null )
 OR (I.THEME is not null and C.THEME is null))
		OR 		( I.ISINHERITED <>  C.ISINHERITED)
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
	

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT WINDOWCONTROL ON

		-- Insert the rows where existing key not found.
		Insert into WINDOWCONTROL(
			WINDOWCONTROLNO,
			CRITERIANO,
			NAMECRITERIANO,
			WINDOWNAME,
			ISEXTERNAL,
			DISPLAYSEQUENCE,
			WINDOWTITLE,
			WINDOWSHORTTITLE,
			ENTRYNUMBER,
			THEME,
			ISINHERITED)
		select
			I.WINDOWCONTROLNO,
			I.CRITERIANO,
			I.NAMECRITERIANO,
			I.WINDOWNAME,
			I.ISEXTERNAL,
			I.DISPLAYSEQUENCE,
			replace( I.WINDOWTITLE,char(10),char(13)+char(10)),
			replace( I.WINDOWSHORTTITLE,char(10),char(13)+char(10)),
			I.ENTRYNUMBER,
			I.THEME,
			I.ISINHERITED
		from CCImport_WINDOWCONTROL I
		left join WINDOWCONTROL C	on ( C.WINDOWCONTROLNO=I.WINDOWCONTROLNO)
		where C.WINDOWCONTROLNO is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT WINDOWCONTROL OFF
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
grant execute on dbo.ip_cc_WINDOWCONTROL  to public
go
