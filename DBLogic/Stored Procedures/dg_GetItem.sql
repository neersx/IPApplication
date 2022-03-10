-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_GetItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_GetItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_GetItem.'
	Drop procedure [dbo].[dg_GetItem]
End
Print '**** Creating Stored Procedure dbo.dg_GetItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_GetItem
	@pnItemId		int = null,
	@psItemName		nvarchar(40) = null
AS
-- Procedure :	dg_GetItem
-- VERSION :	2
-- DESCRIPTION:	This stored procedure will return a single Item record
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who     Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 04 Nov 11  	PK      RFC10708	1       Initial creation
-- 22 Dec 11	PK	RFC11035	2	Add ItemName as parameter and make ItemId optional

-- Declare variables
Declare	@nErrorCode			int
Declare @sSQLString 		nvarchar(4000)

-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If not @pnItemId is null
	Set @psItemName = null

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	i.ITEM_ID as ItemID,
			i.ITEM_NAME as ItemName,
			i.SQL_QUERY as SQLQuery,
			i.ITEM_DESCRIPTION as ItemDescription,
			i.ITEM_TYPE as ItemType,
			i.ENTRY_POINT_USAGE as EntryPointUsage,
			i.SQL_DESCRIBE as SQLDescribe,
			i.SQL_INTO as SQLInto
		From	ITEM i " + 
		case when not @pnItemId is null then 
		"Where	i.ITEM_ID = @pnItemId" end +
		case when not @psItemName is null then 
		"Where	i.ITEM_NAME = @psItemName" end

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnItemId		int,
			@psItemName		nvarchar(40)',
			@pnItemId		= @pnItemId,
			@psItemName		= @psItemName
		
	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_GetItem to Public
go
