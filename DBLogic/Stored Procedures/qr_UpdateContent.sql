-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_UpdateContent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_UpdateContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_UpdateContent.'
	Drop procedure [dbo].[qr_UpdateContent]
End
Print '**** Creating Stored Procedure dbo.qr_UpdateContent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_UpdateContent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int		= null,
	@pnPresentationKey	int		= null,
	@pnColumnKey		int,		-- Mandatory
	@pnDisplaySequence	smallint	= null,
	@pnSortOrder		smallint	= null,
	@psSortDirection	nvarchar(1)	= null,
	@pnGroupBySortOrder		smallint	= null,
	@psGroupBySortDirection	nvarchar(1)	= null,
	@pnOldDisplaySequence	smallint	= null,
	@pnOldSortOrder		smallint	= null,
	@psOldSortDirection	nvarchar(1)	= null

)
as
-- PROCEDURE:	qr_UpdateContent
-- VERSION:	3
-- DESCRIPTION:	Update a presentation column.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC408	1	Procedure created
-- 21 Jul 2004	TM	RFC578	2	Add new @pnPresentationKey optional parameter. Make @pnQueryKey
--					parameter optional. If the @pnPresentationKey parameter is not null,
--					use it to update the QueryContent row, otherwise if @pnQueryKey is 
--					provided, extract the PresentationId from the Query table.  
-- 03 Feb 2010	SF	RFC8483	3	Implement GROUPBYSEQUENCE, GROUPBYSORTDIR

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
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
	update 	QUERYCONTENT
	set	DISPLAYSEQUENCE	= @pnDisplaySequence,
		SORTORDER 	= @pnSortOrder,
		SORTDIRECTION 	= @psSortDirection,
		GROUPBYSEQUENCE	= @pnGroupBySortOrder,
		GROUPBYSORTDIR = @psGroupBySortDirection
	where	PRESENTATIONID 	= @pnPresentationKey
	and	COLUMNID 	= @pnColumnKey
	and	DISPLAYSEQUENCE = @pnOldDisplaySequence
	and	SORTORDER 	= @pnOldSortOrder
	and	SORTDIRECTION 	= @psOldSortDirection"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int,
					  @pnColumnKey		int,
					  @pnDisplaySequence	smallint,
					  @pnSortOrder		smallint,
					  @psSortDirection	nvarchar(1),
					  @pnGroupBySortOrder	smallint,
					  @psGroupBySortDirection nvarchar(1),
					  @pnOldDisplaySequence	smallint,
					  @pnOldSortOrder	smallint,
					  @psOldSortDirection	nvarchar(1)',
					  @pnPresentationKey	= @pnPresentationKey,
					  @pnColumnKey		= @pnColumnKey,
					  @pnDisplaySequence	= @pnDisplaySequence,
					  @pnSortOrder		= @pnSortOrder,
					  @psSortDirection	= @psSortDirection,
					  @pnGroupBySortOrder	= @pnGroupBySortOrder,
					  @psGroupBySortDirection = @psGroupBySortDirection,
					  @pnOldDisplaySequence	= @pnOldDisplaySequence,
					  @pnOldSortOrder	= @pnOldSortOrder,
					  @psOldSortDirection	= @psOldSortDirection

End

Return @nErrorCode
GO

Grant execute on dbo.qr_UpdateContent to public
GO
