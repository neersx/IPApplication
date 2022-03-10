-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_SCREENCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_SCREENCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_SCREENCONTROL.'
	drop procedure dbo.ip_cc_SCREENCONTROL
	print '**** Creating procedure dbo.ip_cc_SCREENCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_SCREENCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_SCREENCONTROL
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the SCREENCONTROL table
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


-- Prerequisite that the CCImport_SCREENCONTROL table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_SCREENCONTROL('"+@psUserName+"')
		order by "+CASE WHEN(@pnOrderBy=1)THEN "1,3,4,5" ELSE "3,4,5" END 
		
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
		Update SCREENCONTROL
		set	ENTRYNUMBER= I.ENTRYNUMBER,
			SCREENTITLE= I.SCREENTITLE,
			DISPLAYSEQUENCE= I.DISPLAYSEQUENCE,
			CHECKLISTTYPE= I.CHECKLISTTYPE,
			TEXTTYPE= I.TEXTTYPE,
			NAMETYPE= I.NAMETYPE,
			NAMEGROUP= I.NAMEGROUP,
			FLAGNUMBER= I.FLAGNUMBER,
			CREATEACTION= I.CREATEACTION,
			RELATIONSHIP= I.RELATIONSHIP,
			INHERITED= I.INHERITED,
			PROFILENAME= I.PROFILENAME,
			SCREENTIP=replace( I.SCREENTIP,char(10),char(13)+char(10)),
			MANDATORYFLAG= I.MANDATORYFLAG,
			GENERICPARAMETER=replace( I.GENERICPARAMETER,char(10),char(13)+char(10))
		from	SCREENCONTROL C
		join	CCImport_SCREENCONTROL I	on ( I.CRITERIANO=C.CRITERIANO
						and I.SCREENNAME=C.SCREENNAME
						and I.SCREENID=C.SCREENID)
" Set @sSQLString1="
		where 		( I.ENTRYNUMBER <>  C.ENTRYNUMBER OR (I.ENTRYNUMBER is null and C.ENTRYNUMBER is not null )
 OR (I.ENTRYNUMBER is not null and C.ENTRYNUMBER is null))
		OR 		( I.SCREENTITLE <>  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is not null )
 OR (I.SCREENTITLE is not null and C.SCREENTITLE is null))
		OR 		( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null )
 OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))
		OR 		( I.CHECKLISTTYPE <>  C.CHECKLISTTYPE OR (I.CHECKLISTTYPE is null and C.CHECKLISTTYPE is not null )
 OR (I.CHECKLISTTYPE is not null and C.CHECKLISTTYPE is null))
		OR 		( I.TEXTTYPE <>  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is not null )
 OR (I.TEXTTYPE is not null and C.TEXTTYPE is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null )
 OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.NAMEGROUP <>  C.NAMEGROUP OR (I.NAMEGROUP is null and C.NAMEGROUP is not null )
 OR (I.NAMEGROUP is not null and C.NAMEGROUP is null))
		OR 		( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null )
 OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))
		OR 		( I.CREATEACTION <>  C.CREATEACTION OR (I.CREATEACTION is null and C.CREATEACTION is not null )
 OR (I.CREATEACTION is not null and C.CREATEACTION is null))
		OR 		( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null )
 OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null )
 OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null )
 OR (I.PROFILENAME is not null and C.PROFILENAME is null))
		OR 		(replace( I.SCREENTIP,char(10),char(13)+char(10)) <>  C.SCREENTIP OR (I.SCREENTIP is null and C.SCREENTIP is not null )
 OR (I.SCREENTIP is not null and C.SCREENTIP is null))
		OR 		( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null )
 OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
		OR 		(replace( I.GENERICPARAMETER,char(10),char(13)+char(10)) <>  C.GENERICPARAMETER OR (I.GENERICPARAMETER is null and C.GENERICPARAMETER is not null )
 OR (I.GENERICPARAMETER is not null and C.GENERICPARAMETER is null))
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
		Insert into SCREENCONTROL(
			CRITERIANO,
			SCREENNAME,
			SCREENID,
			ENTRYNUMBER,
			SCREENTITLE,
			DISPLAYSEQUENCE,
			CHECKLISTTYPE,
			TEXTTYPE,
			NAMETYPE,
			NAMEGROUP,
			FLAGNUMBER,
			CREATEACTION,
			RELATIONSHIP,
			INHERITED,
			PROFILENAME,
			SCREENTIP,
			MANDATORYFLAG,
			GENERICPARAMETER)
		select
	 I.CRITERIANO,
	 I.SCREENNAME,
	 I.SCREENID,
	 I.ENTRYNUMBER,
	 I.SCREENTITLE,
	 I.DISPLAYSEQUENCE,
	 I.CHECKLISTTYPE,
	 I.TEXTTYPE,
	 I.NAMETYPE,
	 I.NAMEGROUP,
	 I.FLAGNUMBER,
	 I.CREATEACTION,
	 I.RELATIONSHIP,
	 I.INHERITED,
	 I.PROFILENAME,
	replace( I.SCREENTIP,char(10),char(13)+char(10)),
	 I.MANDATORYFLAG,
	replace( I.GENERICPARAMETER,char(10),char(13)+char(10))
		from CCImport_SCREENCONTROL I
		left join SCREENCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.SCREENNAME=I.SCREENNAME
						and C.SCREENID=I.SCREENID)
		where C.CRITERIANO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete SCREENCONTROL
		from CCImport_SCREENCONTROL I
		right join SCREENCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
						and C.SCREENNAME=I.SCREENNAME
						and C.SCREENID=I.SCREENID)
		where I.CRITERIANO is null"

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
grant execute on dbo.ip_cc_SCREENCONTROL  to public
go
