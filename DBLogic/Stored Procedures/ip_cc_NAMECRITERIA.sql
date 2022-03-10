-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_NAMECRITERIA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_NAMECRITERIA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_NAMECRITERIA.'
	drop procedure dbo.ip_cc_NAMECRITERIA
	print '**** Creating procedure dbo.ip_cc_NAMECRITERIA...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_NAMECRITERIA
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_NAMECRITERIA
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the NAMECRITERIA table
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


-- Prerequisite that the CCImport_NAMECRITERIA table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_NAMECRITERIA('"+@psUserName+"')
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
		Update NAMECRITERIA
		set	PURPOSECODE= I.PURPOSECODE,
			PROGRAMID= I.PROGRAMID,
			USEDASFLAG= I.USEDASFLAG,
			SUPPLIERFLAG= I.SUPPLIERFLAG,
			DATAUNKNOWN= I.DATAUNKNOWN,
			COUNTRYCODE= I.COUNTRYCODE,
			LOCALCLIENTFLAG= I.LOCALCLIENTFLAG,
			CATEGORY= I.CATEGORY,
			NAMETYPE= I.NAMETYPE,
			USERDEFINEDRULE= I.USERDEFINEDRULE,
			RULEINUSE= I.RULEINUSE,
			DESCRIPTION=replace( I.DESCRIPTION,char(10),char(13)+char(10)),
			RELATIONSHIP= I.RELATIONSHIP,
			PROFILEID= I.PROFILEID
		from	NAMECRITERIA C
		join	CCImport_NAMECRITERIA I	on ( I.NAMECRITERIANO=C.NAMECRITERIANO)
" Set @sSQLString1="
		where 		( I.PURPOSECODE <>  C.PURPOSECODE)
		OR 		( I.PROGRAMID <>  C.PROGRAMID OR (I.PROGRAMID is null and C.PROGRAMID is not null )
 OR (I.PROGRAMID is not null and C.PROGRAMID is null))
		OR 		( I.USEDASFLAG <>  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is not null )
 OR (I.USEDASFLAG is not null and C.USEDASFLAG is null))
		OR 		( I.SUPPLIERFLAG <>  C.SUPPLIERFLAG OR (I.SUPPLIERFLAG is null and C.SUPPLIERFLAG is not null )
 OR (I.SUPPLIERFLAG is not null and C.SUPPLIERFLAG is null))
		OR 		( I.DATAUNKNOWN <>  C.DATAUNKNOWN)
		OR 		( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null )
 OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
		OR 		( I.LOCALCLIENTFLAG <>  C.LOCALCLIENTFLAG OR (I.LOCALCLIENTFLAG is null and C.LOCALCLIENTFLAG is not null )
 OR (I.LOCALCLIENTFLAG is not null and C.LOCALCLIENTFLAG is null))
		OR 		( I.CATEGORY <>  C.CATEGORY OR (I.CATEGORY is null and C.CATEGORY is not null )
 OR (I.CATEGORY is not null and C.CATEGORY is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null )
 OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.USERDEFINEDRULE <>  C.USERDEFINEDRULE)
		OR 		( I.RULEINUSE <>  C.RULEINUSE)
		OR 		(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null )
 OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
		OR 		( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null )
 OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
		OR 		( I.PROFILEID <>  C.PROFILEID OR (I.PROFILEID is null and C.PROFILEID is not null )
 OR (I.PROFILEID is not null and C.PROFILEID is null))
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
		Insert into NAMECRITERIA(
			NAMECRITERIANO,
			PURPOSECODE,
			PROGRAMID,
			USEDASFLAG,
			SUPPLIERFLAG,
			DATAUNKNOWN,
			COUNTRYCODE,
			LOCALCLIENTFLAG,
			CATEGORY,
			NAMETYPE,
			USERDEFINEDRULE,
			RULEINUSE,
			DESCRIPTION,
			RELATIONSHIP,
			PROFILEID)
		select
	 I.NAMECRITERIANO,
	 I.PURPOSECODE,
	 I.PROGRAMID,
	 I.USEDASFLAG,
	 I.SUPPLIERFLAG,
	 I.DATAUNKNOWN,
	 I.COUNTRYCODE,
	 I.LOCALCLIENTFLAG,
	 I.CATEGORY,
	 I.NAMETYPE,
	 I.USERDEFINEDRULE,
	 I.RULEINUSE,
	replace( I.DESCRIPTION,char(10),char(13)+char(10)),
	 I.RELATIONSHIP,
	 I.PROFILEID
		from CCImport_NAMECRITERIA I
		left join NAMECRITERIA C	on ( C.NAMECRITERIANO=I.NAMECRITERIANO)
		where C.NAMECRITERIANO is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete NAMECRITERIA
		from CCImport_NAMECRITERIA I
		right join NAMECRITERIA C	on ( C.NAMECRITERIANO=I.NAMECRITERIANO)
		where I.NAMECRITERIANO is null"

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
grant execute on dbo.ip_cc_NAMECRITERIA  to public
go
