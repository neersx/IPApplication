-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocItems
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocItems.'
	Drop procedure [dbo].[ipw_ListDocItems]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocItems...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocItems
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListDocItems
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List all doc items

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 May 2010	JC	RFC6229	1	Procedure created
-- 23 Nov 2010	JC	RFC9691	2	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture	nvarchar(10)

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
			I.ENTRY_POINT_USAGE as EntryPointUsage
	from ITEM I 
	order by 2"	

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocItems to public
GO
