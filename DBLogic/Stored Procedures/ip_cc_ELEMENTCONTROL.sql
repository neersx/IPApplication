-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_ELEMENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_ELEMENTCONTROL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_ELEMENTCONTROL.'
	drop procedure dbo.ip_cc_ELEMENTCONTROL
	print '**** Creating procedure dbo.ip_cc_ELEMENTCONTROL...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_ELEMENTCONTROL
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_ELEMENTCONTROL
-- VERSION :	2
-- DESCRIPTION:	The comparison/display and merging of imported data for the ELEMENTCONTROL table
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


-- Prerequisite that the CCImport_ELEMENTCONTROL table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_ELEMENTCONTROL('"+@psUserName+"')
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
		Delete ELEMENTCONTROL
		from CCImport_ELEMENTCONTROL I
		right join ELEMENTCONTROL C	on ( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
		where I.ELEMENTCONTROLNO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@rowcount
	End
/**************** Data Update ***************************************/
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update ELEMENTCONTROL
		set	TOPICCONTROLNO= I.TOPICCONTROLNO,
			ELEMENTNAME= I.ELEMENTNAME,
			SHORTLABEL=replace( I.SHORTLABEL,char(10),char(13)+char(10)),
			FULLLABEL=replace( I.FULLLABEL,char(10),char(13)+char(10)),
			BUTTON=replace( I.BUTTON,char(10),char(13)+char(10)),
			TOOLTIP=replace( I.TOOLTIP,char(10),char(13)+char(10)),
			LINK=replace( I.LINK,char(10),char(13)+char(10)),
			LITERAL=replace( I.LITERAL,char(10),char(13)+char(10)),
			DEFAULTVALUE=replace( I.DEFAULTVALUE,char(10),char(13)+char(10)),
			ISHIDDEN= I.ISHIDDEN,
			ISMANDATORY= I.ISMANDATORY,
			ISREADONLY= I.ISREADONLY,
			ISINHERITED= I.ISINHERITED,
			FILTERNAME= I.FILTERNAME,
			FILTERVALUE=replace( I.FILTERVALUE,char(10),char(13)+char(10))
		from	ELEMENTCONTROL C
		join	CCImport_ELEMENTCONTROL I	on ( I.ELEMENTCONTROLNO=C.ELEMENTCONTROLNO)
" Set @sSQLString1="
		where 		( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
		OR 		( I.ELEMENTNAME <>  C.ELEMENTNAME)
		OR 		(replace( I.SHORTLABEL,char(10),char(13)+char(10)) <>  C.SHORTLABEL OR (I.SHORTLABEL is null and C.SHORTLABEL is not null )
 OR (I.SHORTLABEL is not null and C.SHORTLABEL is null))
		OR 		(replace( I.FULLLABEL,char(10),char(13)+char(10)) <>  C.FULLLABEL OR (I.FULLLABEL is null and C.FULLLABEL is not null )
 OR (I.FULLLABEL is not null and C.FULLLABEL is null))
		OR 		(replace( I.BUTTON,char(10),char(13)+char(10)) <>  C.BUTTON OR (I.BUTTON is null and C.BUTTON is not null )
 OR (I.BUTTON is not null and C.BUTTON is null))
		OR 		(replace( I.TOOLTIP,char(10),char(13)+char(10)) <>  C.TOOLTIP OR (I.TOOLTIP is null and C.TOOLTIP is not null )
 OR (I.TOOLTIP is not null and C.TOOLTIP is null))
		OR 		(replace( I.LINK,char(10),char(13)+char(10)) <>  C.LINK OR (I.LINK is null and C.LINK is not null )
 OR (I.LINK is not null and C.LINK is null))
		OR 		(replace( I.LITERAL,char(10),char(13)+char(10)) <>  C.LITERAL OR (I.LITERAL is null and C.LITERAL is not null )
 OR (I.LITERAL is not null and C.LITERAL is null))
		OR 		(replace( I.DEFAULTVALUE,char(10),char(13)+char(10)) <>  C.DEFAULTVALUE OR (I.DEFAULTVALUE is null and C.DEFAULTVALUE is not null )
 OR (I.DEFAULTVALUE is not null and C.DEFAULTVALUE is null))
		OR 		( I.ISHIDDEN <>  C.ISHIDDEN)
		OR 		( I.ISMANDATORY <>  C.ISMANDATORY)
		OR 		( I.ISREADONLY <>  C.ISREADONLY)
		OR 		( I.ISINHERITED <>  C.ISINHERITED)
		OR 		( I.FILTERNAME <>  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is not null )
 OR (I.FILTERNAME is not null and C.FILTERNAME is null))
		OR 		(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is not null )
 OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))
"
		exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)

		Set @ErrorCode=@@Error 
		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	/**************** Data Insert ***************************************/
	If @ErrorCode=0
	Begin
	

		-- Insert the rows where existing key not found.
		SET IDENTITY_INSERT ELEMENTCONTROL ON

		-- Insert the rows where existing key not found.
		Insert into ELEMENTCONTROL(
			ELEMENTCONTROLNO,
			TOPICCONTROLNO,
			ELEMENTNAME,
			SHORTLABEL,
			FULLLABEL,
			BUTTON,
			TOOLTIP,
			LINK,
			LITERAL,
			DEFAULTVALUE,
			ISHIDDEN,
			ISMANDATORY,
			ISREADONLY,
			ISINHERITED,
			FILTERNAME,
			FILTERVALUE)
		select
			I.ELEMENTCONTROLNO,
			I.TOPICCONTROLNO,
			I.ELEMENTNAME,
			replace( I.SHORTLABEL,char(10),char(13)+char(10)),
			replace( I.FULLLABEL,char(10),char(13)+char(10)),
			replace( I.BUTTON,char(10),char(13)+char(10)),
			replace( I.TOOLTIP,char(10),char(13)+char(10)),
			replace( I.LINK,char(10),char(13)+char(10)),
			replace( I.LITERAL,char(10),char(13)+char(10)),
			replace( I.DEFAULTVALUE,char(10),char(13)+char(10)),
			I.ISHIDDEN,
			I.ISMANDATORY,
			I.ISREADONLY,
			I.ISINHERITED,
			I.FILTERNAME,
			replace( I.FILTERVALUE,char(10),char(13)+char(10))
		from CCImport_ELEMENTCONTROL I
		left join ELEMENTCONTROL C	on ( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
		where C.ELEMENTCONTROLNO is null

		Select	@ErrorCode=@@Error,
			@pnRowCount=@pnRowCount+@@rowcount

		SET IDENTITY_INSERT ELEMENTCONTROL OFF
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
grant execute on dbo.ip_cc_ELEMENTCONTROL  to public
go
