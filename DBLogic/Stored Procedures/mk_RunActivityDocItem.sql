---------------------------------------------------------------------------------------------
-- Creation of dbo.mk_RunActivityDocItem
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_RunActivityDocItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_RunActivityDocItem.'
	drop procedure [dbo].[mk_RunActivityDocItem]
	Print '**** Creating Stored Procedure dbo.mk_RunActivityDocItem...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_RunActivityDocItem
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnDocItemKey 		int		= null,		
	@pnActivityKey		int,		-- Mandatory
	@psDocItemName		nvarchar(40)	= null
)
AS
-- PROCEDURE:	mk_RunActivityDocItem
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedures executes a doc item. The procedure returns
--		whatever the doc item selects as a result set. It caters for doc items
--		defined as both SQL statements and stored procedures.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16 May 2006  SW	RFC2985	1	Procedure created
-- 26 May 2006  SW	RFC2985	2	Implement new @psDocItemName param

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare	@sSQLString	nvarchar(4000)

Declare @sUserSQL		nvarchar(4000)
Declare @nItemType		smallint	-- For a stored procedure @nItemType = 1.
Declare @nDocItemLength		int
Declare @nSqlQueryDivisor	tinyint

Declare @sSegment1	nvarchar(4000)
Declare @sSegment2	nvarchar(4000)	
Declare @sSegment3	nvarchar(4000)
Declare @sSegment4	nvarchar(4000)
Declare @sSegment5	nvarchar(4000)	
Declare @sSegment6 	nvarchar(4000)	
Declare @sSegment7	nvarchar(4000)	
Declare @sSegment8	nvarchar(4000)	
Declare @sSegment9	nvarchar(4000)	
Declare @sSegment10	nvarchar(4000)	

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

-- To calculate length for ntext, we need to divide datalength by 2
-- but for text we do not
If exists (select 1 
	from INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'ITEM' 
	and COLUMN_NAME = 'SQL_QUERY'
	and DATA_TYPE = 'text')
Begin
	Set @nSqlQueryDivisor = 1
End
Else
Begin
	Set @nSqlQueryDivisor = 2
End

-- Find out @pnDocItemKey if not provided
If @nErrorCode = 0
and @pnDocItemKey is null
Begin

	Set @sSQLString = "
		Select	@pnDocItemKey  	= I.ITEM_ID
		from	ITEM I
		Where	I.ITEM_NAME = @psDocItemName"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocItemKey		int		OUTPUT,
				  @psDocItemName	nvarchar(40)',
				  @pnDocItemKey		= @pnDocItemKey	OUTPUT,
				  @psDocItemName	= @psDocItemName
End

If @nErrorCode = 0
Begin
	-- Get the user defined SELECT statement that needs to be executed
	-- along with an Item Type 
	
	Set @sSQLString = "
		Select	@sUserSQL  	= convert(nvarchar(4000),SQL_QUERY),
			@nDocItemLength	= datalength(SQL_QUERY)/@nSqlQueryDivisor,
			@nItemType 	= I.ITEM_TYPE
		from	ITEM I
		Where	I.ITEM_ID = @pnDocItemKey"
	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sUserSQL		nvarchar(4000)	OUTPUT,
				  @nItemType		smallint	OUTPUT,
				  @nDocItemLength	int		OUTPUT,
				  @pnDocItemKey		int,
				  @nSqlQueryDivisor	tinyint',
				  @sUserSQL		= @sUserSQL	OUTPUT,
				  @nItemType		= @nItemType	OUTPUT,
				  @nDocItemLength	= @nDocItemLength OUTPUT,
				  @pnDocItemKey		= @pnDocItemKey,
				  @nSqlQueryDivisor	= @nSqlQueryDivisor
End

-- If the DocItem SQL is less than 4000 characters long:
If @nDocItemLength <= 4000
Begin
	-- If the @sUserSQL is an SQL statement: 
	If  @sUserSQL is not null
	and @nItemType <> 1
	and @nErrorCode = 0
	Begin	
		-- In the user defined SQL replace the constants
		Set @sUserSQL  = replace(@sUserSQL,':gstrEntryPoint',@pnActivityKey)
		
		exec @nErrorCode = sp_executesql @sUserSQL 	
	
		Set @pnRowCount = @@RowCount
	End
	-- If the @sUserSQL is a stored procedure name:
	Else 	If  @sUserSQL is not null
		and @nItemType = 1
		and @nErrorCode = 0 
	Begin
		-- Run as a stored procedure by passing @pnActivityKey as the first (unnamed) parameter
		Exec (@sUserSQL + ' ' + @pnActivityKey) 
	
		Set @pnRowCount = @@RowCount
	End
End
-- Handle long strings by implementing pt_GetDocItemSql
Else If @nErrorCode = 0 
Begin
	exec @nErrorCode = dbo.pt_GetDocItemSql
			@psSegment1		= @sSegment1	output,
			@psSegment2		= @sSegment2	output,	
			@psSegment3		= @sSegment3	output,
			@psSegment4		= @sSegment4	output,
			@psSegment5		= @sSegment5	output,	
			@psSegment6		= @sSegment6 	output,	
			@psSegment7		= @sSegment7	output,	
			@psSegment8		= @sSegment8	output,	
			@psSegment9		= @sSegment9	output,	
			@psSegment10		= @sSegment10	output,	
			@pnUserIdentityId	= @pnUserIdentityId,				
			@pnDocItemKey		= @pnDocItemKey, 		
			@psSearchText1		= ':gstrEntryPoint',		
			@psReplacementText1	= @pnActivityKey

	-- Execute the long DocItem SQL:
	exec (@sSegment1 + @sSegment2 + @sSegment3 + @sSegment4 +	
	      @sSegment5 + @sSegment6 + @sSegment7 + @sSegment8 +		
	      @sSegment9 + @sSegment10)
End


Return @nErrorCode
GO

Grant exec on dbo.mk_RunActivityDocItem to public
GO
