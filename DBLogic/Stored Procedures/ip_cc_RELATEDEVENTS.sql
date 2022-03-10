-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_RELATEDEVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_RELATEDEVENTS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_RELATEDEVENTS.'
	drop procedure dbo.ip_cc_RELATEDEVENTS
	print '**** Creating procedure dbo.ip_cc_RELATEDEVENTS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_RELATEDEVENTS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_RELATEDEVENTS
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the RELATEDEVENTS table
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


-- Prerequisite that the CCImport_RELATEDEVENTS table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_RELATEDEVENTS('"+@psUserName+"')
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
		Update RELATEDEVENTS
		set	RELATEDEVENT= I.RELATEDEVENT,
			CLEAREVENT= I.CLEAREVENT,
			CLEARDUE= I.CLEARDUE,
			SATISFYEVENT= I.SATISFYEVENT,
			UPDATEEVENT= I.UPDATEEVENT,
			CREATENEXTCYCLE= I.CREATENEXTCYCLE,
			ADJUSTMENT= I.ADJUSTMENT,
			INHERITED= I.INHERITED,
			RELATIVECYCLE= I.RELATIVECYCLE,
			CLEAREVENTONDUECHANGE= I.CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE= I.CLEARDUEONDUECHANGE
		from	RELATEDEVENTS C
		join	CCImport_RELATEDEVENTS I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.RELATEDNO=C.RELATEDNO)
" Set @sSQLString1="
		where 		( I.RELATEDEVENT <>  C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is not null )
 OR (I.RELATEDEVENT is not null and C.RELATEDEVENT is null))
		OR 		( I.CLEAREVENT <>  C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is not null )
 OR (I.CLEAREVENT is not null and C.CLEAREVENT is null))
		OR 		( I.CLEARDUE <>  C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is not null )
 OR (I.CLEARDUE is not null and C.CLEARDUE is null))
		OR 		( I.SATISFYEVENT <>  C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is not null )
 OR (I.SATISFYEVENT is not null and C.SATISFYEVENT is null))
		OR 		( I.UPDATEEVENT <>  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null )
 OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null))
		OR 		( I.CREATENEXTCYCLE <>  C.CREATENEXTCYCLE OR (I.CREATENEXTCYCLE is null and C.CREATENEXTCYCLE is not null )
 OR (I.CREATENEXTCYCLE is not null and C.CREATENEXTCYCLE is null))
		OR 		( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null )
 OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
		OR 		( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null )
 OR (I.INHERITED is not null and C.INHERITED is null))
		OR 		( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null )
 OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
		OR 		( I.CLEAREVENTONDUECHANGE <>  C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is not null )
 OR (I.CLEAREVENTONDUECHANGE is not null and C.CLEAREVENTONDUECHANGE is null))
		OR 		( I.CLEARDUEONDUECHANGE <>  C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is not null )
 OR (I.CLEARDUEONDUECHANGE is not null and C.CLEARDUEONDUECHANGE is null))
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
		Insert into RELATEDEVENTS(
			CRITERIANO,
			EVENTNO,
			RELATEDNO,
			RELATEDEVENT,
			CLEAREVENT,
			CLEARDUE,
			SATISFYEVENT,
			UPDATEEVENT,
			CREATENEXTCYCLE,
			ADJUSTMENT,
			INHERITED,
			RELATIVECYCLE,
			CLEAREVENTONDUECHANGE,
			CLEARDUEONDUECHANGE)
		select
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.RELATEDNO,
	 I.RELATEDEVENT,
	 I.CLEAREVENT,
	 I.CLEARDUE,
	 I.SATISFYEVENT,
	 I.UPDATEEVENT,
	 I.CREATENEXTCYCLE,
	 I.ADJUSTMENT,
	 I.INHERITED,
	 I.RELATIVECYCLE,
	 I.CLEAREVENTONDUECHANGE,
	 I.CLEARDUEONDUECHANGE
		from CCImport_RELATEDEVENTS I
		left join RELATEDEVENTS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.RELATEDNO=I.RELATEDNO)
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
		Delete RELATEDEVENTS
		from CCImport_RELATEDEVENTS I
		right join RELATEDEVENTS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.RELATEDNO=I.RELATEDNO)
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
grant execute on dbo.ip_cc_RELATEDEVENTS  to public
go
