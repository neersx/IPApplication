-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetDocItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetDocItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetDocItem.'
	Drop procedure [dbo].[ipw_GetDocItem]
End
Print '**** Creating Stored Procedure dbo.ipw_GetDocItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetDocItem
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) = null,
	@psItemCode				nvarchar(40),
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_GetDocItem
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get details of a Doc Item

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 June 2010	JC	RFC6229	1	Procedure created
-- 23 Nov 2010	JC	RFC9691	2	Change ItemCode to ItemName

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
	-- Some code here
	Set @sSQLString = "
	Select 	I.ITEM_ID as ItemKey,
			I.ITEM_NAME as ItemName,
		"+dbo.fn_SqlTranslatedColumn('ITEM','ITEM_DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as ItemDescription,
			I.ENTRY_POINT_USAGE as EntryPointUsage,
			I.SQL_QUERY as SQLQuery,
			I.ITEM_TYPE as ItemType
	from ITEM I 
	where I.ITEM_NAME = @psItemCode"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psItemCode	nvarchar(40)',
					@psItemCode	 =	@psItemCode
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetDocItem to public
GO
