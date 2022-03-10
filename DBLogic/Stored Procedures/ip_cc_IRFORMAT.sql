-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_cc_IRFORMAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_cc_IRFORMAT]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_cc_IRFORMAT.'
	drop procedure dbo.ip_cc_IRFORMAT
	print '**** Creating procedure dbo.ip_cc_IRFORMAT...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_cc_IRFORMAT
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_cc_IRFORMAT
-- VERSION :	1
-- DESCRIPTION:	The comparison/display and merging of imported data for the IRFORMAT table
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


-- Prerequisite that the CCImport_IRFORMAT table has been loaded

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
		Set @sSQLString="SELECT * from dbo.fn_cc_IRFORMAT('"+@psUserName+"')
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
		Update IRFORMAT
		set	SEGMENT1= I.SEGMENT1,
			SEGMENT2= I.SEGMENT2,
			SEGMENT3= I.SEGMENT3,
			SEGMENT4= I.SEGMENT4,
			SEGMENT5= I.SEGMENT5,
			INSTRUCTORFLAG= I.INSTRUCTORFLAG,
			OWNERFLAG= I.OWNERFLAG,
			STAFFFLAG= I.STAFFFLAG,
			FAMILYFLAG= I.FAMILYFLAG,
			SEGMENT6= I.SEGMENT6,
			SEGMENT7= I.SEGMENT7,
			SEGMENT8= I.SEGMENT8,
			SEGMENT9= I.SEGMENT9,
			SEGMENT1CODE= I.SEGMENT1CODE,
			SEGMENT2CODE= I.SEGMENT2CODE,
			SEGMENT3CODE= I.SEGMENT3CODE,
			SEGMENT4CODE= I.SEGMENT4CODE,
			SEGMENT5CODE= I.SEGMENT5CODE,
			SEGMENT6CODE= I.SEGMENT6CODE,
			SEGMENT7CODE= I.SEGMENT7CODE,
			SEGMENT8CODE= I.SEGMENT8CODE,
			SEGMENT9CODE= I.SEGMENT9CODE
		from	IRFORMAT C
		join	CCImport_IRFORMAT I	on ( I.CRITERIANO=C.CRITERIANO)
" Set @sSQLString1="
		where 		( I.SEGMENT1 <>  C.SEGMENT1 OR (I.SEGMENT1 is null and C.SEGMENT1 is not null )
 OR (I.SEGMENT1 is not null and C.SEGMENT1 is null))
		OR 		( I.SEGMENT2 <>  C.SEGMENT2 OR (I.SEGMENT2 is null and C.SEGMENT2 is not null )
 OR (I.SEGMENT2 is not null and C.SEGMENT2 is null))
		OR 		( I.SEGMENT3 <>  C.SEGMENT3 OR (I.SEGMENT3 is null and C.SEGMENT3 is not null )
 OR (I.SEGMENT3 is not null and C.SEGMENT3 is null))
		OR 		( I.SEGMENT4 <>  C.SEGMENT4 OR (I.SEGMENT4 is null and C.SEGMENT4 is not null )
 OR (I.SEGMENT4 is not null and C.SEGMENT4 is null))
		OR 		( I.SEGMENT5 <>  C.SEGMENT5 OR (I.SEGMENT5 is null and C.SEGMENT5 is not null )
 OR (I.SEGMENT5 is not null and C.SEGMENT5 is null))
		OR 		( I.INSTRUCTORFLAG <>  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null )
 OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null))
		OR 		( I.OWNERFLAG <>  C.OWNERFLAG OR (I.OWNERFLAG is null and C.OWNERFLAG is not null )
 OR (I.OWNERFLAG is not null and C.OWNERFLAG is null))
		OR 		( I.STAFFFLAG <>  C.STAFFFLAG OR (I.STAFFFLAG is null and C.STAFFFLAG is not null )
 OR (I.STAFFFLAG is not null and C.STAFFFLAG is null))
		OR 		( I.FAMILYFLAG <>  C.FAMILYFLAG OR (I.FAMILYFLAG is null and C.FAMILYFLAG is not null )
 OR (I.FAMILYFLAG is not null and C.FAMILYFLAG is null))
		OR 		( I.SEGMENT6 <>  C.SEGMENT6 OR (I.SEGMENT6 is null and C.SEGMENT6 is not null )
 OR (I.SEGMENT6 is not null and C.SEGMENT6 is null))
		OR 		( I.SEGMENT7 <>  C.SEGMENT7 OR (I.SEGMENT7 is null and C.SEGMENT7 is not null )
 OR (I.SEGMENT7 is not null and C.SEGMENT7 is null))
		OR 		( I.SEGMENT8 <>  C.SEGMENT8 OR (I.SEGMENT8 is null and C.SEGMENT8 is not null )
 OR (I.SEGMENT8 is not null and C.SEGMENT8 is null))
		OR 		( I.SEGMENT9 <>  C.SEGMENT9 OR (I.SEGMENT9 is null and C.SEGMENT9 is not null )
 OR (I.SEGMENT9 is not null and C.SEGMENT9 is null))
		OR 		( I.SEGMENT1CODE <>  C.SEGMENT1CODE OR (I.SEGMENT1CODE is null and C.SEGMENT1CODE is not null )
 OR (I.SEGMENT1CODE is not null and C.SEGMENT1CODE is null))
		OR 		( I.SEGMENT2CODE <>  C.SEGMENT2CODE OR (I.SEGMENT2CODE is null and C.SEGMENT2CODE is not null )
 OR (I.SEGMENT2CODE is not null and C.SEGMENT2CODE is null))
		OR 		( I.SEGMENT3CODE <>  C.SEGMENT3CODE OR (I.SEGMENT3CODE is null and C.SEGMENT3CODE is not null )
 OR (I.SEGMENT3CODE is not null and C.SEGMENT3CODE is null))
		OR 		( I.SEGMENT4CODE <>  C.SEGMENT4CODE OR (I.SEGMENT4CODE is null and C.SEGMENT4CODE is not null )
 OR (I.SEGMENT4CODE is not null and C.SEGMENT4CODE is null))
" Set @sSQLString2="
		OR 		( I.SEGMENT5CODE <>  C.SEGMENT5CODE OR (I.SEGMENT5CODE is null and C.SEGMENT5CODE is not null) 
OR (I.SEGMENT5CODE is not null and C.SEGMENT5CODE is null))
		OR 		( I.SEGMENT6CODE <>  C.SEGMENT6CODE OR (I.SEGMENT6CODE is null and C.SEGMENT6CODE is not null) 
OR (I.SEGMENT6CODE is not null and C.SEGMENT6CODE is null))
		OR 		( I.SEGMENT7CODE <>  C.SEGMENT7CODE OR (I.SEGMENT7CODE is null and C.SEGMENT7CODE is not null) 
OR (I.SEGMENT7CODE is not null and C.SEGMENT7CODE is null))
		OR 		( I.SEGMENT8CODE <>  C.SEGMENT8CODE OR (I.SEGMENT8CODE is null and C.SEGMENT8CODE is not null) 
OR (I.SEGMENT8CODE is not null and C.SEGMENT8CODE is null))
		OR 		( I.SEGMENT9CODE <>  C.SEGMENT9CODE OR (I.SEGMENT9CODE is null and C.SEGMENT9CODE is not null) 
OR (I.SEGMENT9CODE is not null and C.SEGMENT9CODE is null))
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
		Insert into IRFORMAT(
			CRITERIANO,
			SEGMENT1,
			SEGMENT2,
			SEGMENT3,
			SEGMENT4,
			SEGMENT5,
			INSTRUCTORFLAG,
			OWNERFLAG,
			STAFFFLAG,
			FAMILYFLAG,
			SEGMENT6,
			SEGMENT7,
			SEGMENT8,
			SEGMENT9,
			SEGMENT1CODE,
			SEGMENT2CODE,
			SEGMENT3CODE,
			SEGMENT4CODE,
			SEGMENT5CODE,
			SEGMENT6CODE,
			SEGMENT7CODE,
			SEGMENT8CODE,
			SEGMENT9CODE)
		select
	 I.CRITERIANO,
	 I.SEGMENT1,
	 I.SEGMENT2,
	 I.SEGMENT3,
	 I.SEGMENT4,
	 I.SEGMENT5,
	 I.INSTRUCTORFLAG,
	 I.OWNERFLAG,
	 I.STAFFFLAG,
	 I.FAMILYFLAG,
	 I.SEGMENT6,
	 I.SEGMENT7,
	 I.SEGMENT8,
	 I.SEGMENT9,
	 I.SEGMENT1CODE,
	 I.SEGMENT2CODE,
	 I.SEGMENT3CODE,
	 I.SEGMENT4CODE,
	 I.SEGMENT5CODE,
	 I.SEGMENT6CODE,
	 I.SEGMENT7CODE,
	 I.SEGMENT8CODE,
	 I.SEGMENT9CODE
		from CCImport_IRFORMAT I
		left join IRFORMAT C	on ( C.CRITERIANO=I.CRITERIANO)
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
		Delete IRFORMAT
		from CCImport_IRFORMAT I
		right join IRFORMAT C	on ( C.CRITERIANO=I.CRITERIANO)
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
grant execute on dbo.ip_cc_IRFORMAT  to public
go
