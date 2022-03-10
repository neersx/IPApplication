---------------------------------------------------------------------------------------------
-- Creation of dbo.naw_RunNameDocItem
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_RunNameDocItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_RunNameDocItem.'
	drop procedure [dbo].[naw_RunNameDocItem]
	Print '**** Creating Stored Procedure dbo.naw_RunNameDocItem...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_RunNameDocItem
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnDocItemKey 		int,		-- Mandatory
	@pnNameKey 		int 		= null,
	@psNameCode 		nvarchar(20) 	= null,
	@pbUseNameKey		bit		= 0
)
AS
-- PROCEDURE:	naw_RunNameDocItem
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedures executes a doc item. The procedure returns
--		whatever the doc item selects as a result set. It caters for doc items
--		defined as both SQL statements and stored procedures.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16 Jan 2007  AU	4678	1	Procedure created
-- 22 Dec 2010	MF	10129	2	Allow additional parameters to be passed into the SQL associated with the Doc Item:
--						@pnUserIdentityId as :gstrUserId
--						@psCulture        as :gstrCulture
-- 29 Jan 2015  DV	35249	3	Add an additional optional parameter @pbUseNameKey for using the Name Key as entry point
--					DocItems that are defined as a stored procedure need to be extended to allow additional parameters:
--						@pnUserIdentityId as @pnUserIdentityId
--						@psCulture        as @psCulture

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare	@sSQLString	nvarchar(max)

Declare @sUserSQL		nvarchar(max)
Declare @nItemType		smallint	-- For a stored procedure @nItemType = 1.

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin
	-- Get the user defined SELECT statement that needs to be executed
	-- along with an Item Type
	
	Set @sSQLString=
	"Select @sUserSQL  	= convert(nvarchar(max),SQL_QUERY),
		@nItemType 	= I.ITEM_TYPE"

	-- If the @psNameCode is not provided, it is extracted from the @pnNameKey:  
	If @pnNameKey is not null
	and (@psNameCode is null and @pbUseNameKey = 0)
	Begin
		Set @sSQLString = @sSQLString+"," 
			+char(10)+"@psNameCode	= N.NAMECODE" 
	  		+char(10)+"from ITEM I" 
			+char(10)+"left join NAME N	on (N.NAMENO = @pnNameKey)" 
			+char(10)+"Where I.ITEM_ID = @pnDocItemKey"

	End
	Else Begin
		Set @sSQLString = @sSQLString+
			+char(10)+"from ITEM I" 
			+char(10)+"Where I.ITEM_ID = @pnDocItemKey"		
	End	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sUserSQL		nvarchar(max)		OUTPUT,
				  @nItemType		smallint		OUTPUT,
				  @psNameCode		nvarchar(20)		OUTPUT,
				  @pnDocItemKey		int,
				  @pnNameKey		int',
				  @sUserSQL		= @sUserSQL		OUTPUT,
				  @nItemType		= @nItemType		OUTPUT,
				  @psNameCode		= @psNameCode 		OUTPUT,
				  @pnDocItemKey		= @pnDocItemKey,
				  @pnNameKey		= @pnNameKey
End

-- If the @sUserSQL is an SQL statement: 
If  @sUserSQL is not null
and @nItemType <> 1
and @nErrorCode = 0
Begin	
	-- In the user defined SQL replace the constants
	if @pbUseNameKey = 0
	Begin	
		Set @sUserSQL  = replace(@sUserSQL,':gstrEntryPoint', dbo.fn_WrapQuotes(@psNameCode,0,0))
	End
	Else
	Begin
		Set @sUserSQL  = replace(@sUserSQL,':gstrEntryPoint', CAST(@pnNameKey as nvarchar))
	End
	Set @sUserSQL  = replace(@sUserSQL,':gstrUserId',    dbo.fn_WrapQuotes(@pnUserIdentityId,0,0))

	If @psCulture is not null
		Set @sUserSQL  = replace(@sUserSQL,':gstrCulture',   dbo.fn_WrapQuotes(@psCulture,0,0))
	else
		Set @sUserSQL  = replace(@sUserSQL,':gstrCulture',   "''")

	exec @nErrorCode = sp_executesql @sUserSQL 	

	Set @pnRowCount = @@RowCount
End
-- If the @sUserSQL is a stored procedure name:
Else 	If  @sUserSQL is not null
	and @nItemType = 1
	and @nErrorCode = 0 
Begin
	-------------------------------------------
	-- Pass @psNameCode or @pnNameKey to the stored 
	-- procedure as the first unnamed parameter
	-------------------------------------------
	If @pbUseNameKey = 0
	Begin
		Set @sSQLString = @sUserSQL + ' ' + dbo.fn_WrapQuotes(@psNameCode,0,0)		
	End
	Else
	Begin
		Set @sSQLString = @sUserSQL + ' ' + CAST(@pnNameKey as nvarchar)	
	End

	-----------------------------------------
	-- Check if the stored procedure has a
	-- parameter to accept the UserIdentityId
	-----------------------------------------
	If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	          where SPECIFIC_NAME=@sUserSQL
	          and ORDINAL_POSITION=2
	          and DATA_TYPE='int')
		Set @sSQLString=@sSQLString + ', ' + CAST(@pnUserIdentityId as nvarchar)
	
	-----------------------------------------
	-- Check if the stored procedure has a
	-- parameter to accept the Culter
	-----------------------------------------
	If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	          where SPECIFIC_NAME=@sUserSQL
	          and ORDINAL_POSITION=3
	          and DATA_TYPE='nvarchar')
	and @psCulture is not null
		Set @sSQLString=@sSQLString + ', ' + dbo.fn_WrapQuotes(@psCulture,0,0)

	Exec (@sSQLString) 

	Select	@nErrorCode = @@ERROR,
		@pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant exec on dbo.naw_RunNameDocItem to public
GO
