-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteContent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteContent.'
	Drop procedure [dbo].[qr_DeleteContent]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteContent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_DeleteContent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int		= null,
	@pnPresentationKey	int		= null,
	@pnColumnKey		int,		-- Mandatory
	@pnOldDisplaySequence	smallint	= null,
	@pnOldSortOrder		smallint	= null,
	@psOldSortDirection	nvarchar(1)	= null

)
as
-- PROCEDURE:	qr_DeleteContent
-- VERSION:	2
-- DESCRIPTION:	Delete a presentation column.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC408	1	Procedure created
-- 21 Jul 2004	TM	RFC578	2	Add new @pnPresentationKey optional parameter. Make @pnQueryKey
--					parameter optional. If the @pnPresentationKey parameter is not null,
--					use it to delete the QueryContent row, otherwise if @pnQueryKey is 
--					provided, extract the PresentationId from the Query table.  


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- If @pnQueryKey is provided, extract the PresentationId from the Query table.
If @nErrorCode = 0
and @pnQueryKey is not null
Begin
	Set @sSQLString = "
	Select 	@pnPresentationKey = PRESENTATIONID	 
	from    QUERY
	where   QUERYID = @pnQueryKey"	
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int			OUTPUT,
					  @pnQueryKey		int',
					  @pnPresentationKey	= @pnPresentationKey	OUTPUT,
					  @pnQueryKey		= @pnQueryKey
End 

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete 	QUERYCONTENT
	where	PRESENTATIONID 	= @pnPresentationKey
	and	COLUMNID 	= @pnColumnKey
	and	DISPLAYSEQUENCE = @pnOldDisplaySequence
	and	SORTORDER 	= @pnOldSortOrder
	and	SORTDIRECTION 	= @psOldSortDirection"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int,
					  @pnColumnKey		int,
					  @pnOldDisplaySequence	smallint,
					  @pnOldSortOrder	smallint,
					  @psOldSortDirection	nvarchar(1)',
					  @pnPresentationKey	= @pnPresentationKey,
					  @pnColumnKey		= @pnColumnKey,
					  @pnOldDisplaySequence	= @pnOldDisplaySequence,
					  @pnOldSortOrder	= @pnOldSortOrder,
					  @psOldSortDirection	= @psOldSortDirection

End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteContent to public
GO
