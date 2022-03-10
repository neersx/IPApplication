-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_PROTECTCODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_PROTECTCODES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_PROTECTCODES.'
	drop procedure dbo.ip_cc_PROTECTCODES
	print '**** Creating procedure dbo.ip_cc_PROTECTCODES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_PROTECTCODES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_PROTECTCODES
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the PROTECTCODES table
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


-- Prerequisite that the CCImport_PROTECTCODES table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_PROTECTCODES('"+@psUserName+"')
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
		Update PROTECTCODES
		set	TABLECODE= I.TABLECODE,
			TABLETYPE= I.TABLETYPE,
			EVENTNO= I.EVENTNO,
			CASERELATIONSHIP= I.CASERELATIONSHIP,
			NAMERELATIONSHIP= I.NAMERELATIONSHIP,
			NUMBERTYPE= I.NUMBERTYPE,
			CASETYPE= I.CASETYPE,
			NAMETYPE= I.NAMETYPE,
			ADJUSTMENT= I.ADJUSTMENT,
			TEXTTYPE= I.TEXTTYPE,
			FAMILY= I.FAMILY
		from	PROTECTCODES C
		join	CCImport_PROTECTCODES I	on ( I.PROTECTKEY=C.PROTECTKEY)
" Set @sSQLString1="
		where 		( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null )
 OR (I.TABLECODE is not null and C.TABLECODE is null))
		OR 		( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null )
 OR (I.TABLETYPE is not null and C.TABLETYPE is null))
		OR 		( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null )
 OR (I.EVENTNO is not null and C.EVENTNO is null))
		OR 		( I.CASERELATIONSHIP <>  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null )
 OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))
		OR 		( I.NAMERELATIONSHIP <>  C.NAMERELATIONSHIP OR (I.NAMERELATIONSHIP is null and C.NAMERELATIONSHIP is not null )
 OR (I.NAMERELATIONSHIP is not null and C.NAMERELATIONSHIP is null))
		OR 		( I.NUMBERTYPE <>  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null )
 OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null))
		OR 		( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null )
 OR (I.CASETYPE is not null and C.CASETYPE is null))
		OR 		( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null )
 OR (I.NAMETYPE is not null and C.NAMETYPE is null))
		OR 		( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null )
 OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
		OR 		( I.TEXTTYPE <>  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is not null )
 OR (I.TEXTTYPE is not null and C.TEXTTYPE is null))
		OR 		( I.FAMILY <>  C.FAMILY OR (I.FAMILY is null and C.FAMILY is not null )
 OR (I.FAMILY is not null and C.FAMILY is null))
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
		Insert into PROTECTCODES(
			PROTECTKEY,
			TABLECODE,
			TABLETYPE,
			EVENTNO,
			CASERELATIONSHIP,
			NAMERELATIONSHIP,
			NUMBERTYPE,
			CASETYPE,
			NAMETYPE,
			ADJUSTMENT,
			TEXTTYPE,
			FAMILY)
		select
	 I.PROTECTKEY,
	 I.TABLECODE,
	 I.TABLETYPE,
	 I.EVENTNO,
	 I.CASERELATIONSHIP,
	 I.NAMERELATIONSHIP,
	 I.NUMBERTYPE,
	 I.CASETYPE,
	 I.NAMETYPE,
	 I.ADJUSTMENT,
	 I.TEXTTYPE,
	 I.FAMILY
		from CCImport_PROTECTCODES I
		left join PROTECTCODES C	on ( C.PROTECTKEY=I.PROTECTKEY)
		where C.PROTECTKEY is null
			"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

/**************** Data Delete ***************************************/
	If @ErrorCode=0
	Begin

		-- Delete the rows where imported key not found.
		Set @sSQLString= "
		Delete PROTECTCODES
		from CCImport_PROTECTCODES I
		right join PROTECTCODES C	on ( C.PROTECTKEY=I.PROTECTKEY)
		where I.PROTECTKEY is null"

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
grant execute on dbo.ip_cc_PROTECTCODES  to public
go
