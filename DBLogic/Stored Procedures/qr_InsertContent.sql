-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_InsertContent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_InsertContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_InsertContent.'
	Drop procedure [dbo].[qr_InsertContent]
End
Print '**** Creating Stored Procedure dbo.qr_InsertContent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.qr_InsertContent
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
	@psGroupBySortDirection	nvarchar(1)	= null
)
as
-- PROCEDURE:	qr_InsertContent
-- VERSION:	4
-- DESCRIPTION:	Add a new column for presentation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC408	1	Procedure created
-- 16 Mar 2003	JEK	RFC1169	2	Implement ContextID column.
-- 21 Jul 2004	TM	RFC578	3	Add new @pnPresentationKey optional parameter. Make @pnQueryKey
--					parameter optional. If the @pnPresentationKey parameter is not null,
--					extract ContextID from the QueryPresentation table, otherwise if 
--					@pnQueryKey is provided, extract the PresentationId and ContextId  
--					from the Query table.  
-- 03 Feb 2010	SF	RFC8483	4	Implement GROUPBYSEQUENCE, GROUPBYSORTDIR

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nContextId		int

-- Initialise variables
Set @nErrorCode = 0

-- If the @pnPresentationKey parameter is not null, extract ContextID from the QueryPresentation table.
If @nErrorCode = 0
and @pnPresentationKey is not null
Begin
	Set @sSQLString = "
	Select 	@nContextId	 = CONTEXTID	 
	from    QUERYPRESENTATION
	where   PRESENTATIONID = @pnPresentationKey"	
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int,
					  @nContextId		int			OUTPUT',
					  @pnPresentationKey	= @pnPresentationKey,
					  @nContextId		= @nContextId		OUTPUT
End
Else If 
-- If @pnQueryKey is provided, extract the PresentationId and ContextId from the Query table.
@nErrorCode = 0
and @pnQueryKey is not null
Begin
	Set @sSQLString = "
	Select 	@nContextId	   = CONTEXTID,
		@pnPresentationKey = PRESENTATIONID	 
	from    QUERY
	where   QUERYID = @pnQueryKey"	
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int			OUTPUT,
					  @nContextId		int			OUTPUT,
					  @pnQueryKey		int',
					  @pnPresentationKey	= @pnPresentationKey	OUTPUT,
					  @nContextId		= @nContextId		OUTPUT,	
					  @pnQueryKey		= @pnQueryKey
End 

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into QUERYCONTENT
		(PRESENTATIONID,
		CONTEXTID,
		COLUMNID,
		DISPLAYSEQUENCE,
		SORTORDER,
		SORTDIRECTION,
		GROUPBYSEQUENCE, 
		GROUPBYSORTDIR)
	values	(@pnPresentationKey,
		@nContextId,
		@pnColumnKey,
		@pnDisplaySequence,
		@pnSortOrder,
		@psSortDirection,
		@pnGroupBySortOrder,
		@psGroupBySortDirection)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey    int,
					  @nContextId		int,
					  @pnColumnKey		int,
					  @pnDisplaySequence	smallint,
					  @pnSortOrder		smallint,
					  @psSortDirection	nvarchar(1),
					  @pnGroupBySortOrder		smallint,
					  @psGroupBySortDirection	nvarchar(1)',
					  @pnPresentationKey    = @pnPresentationKey,
					  @nContextId		= @nContextId,
					  @pnColumnKey		= @pnColumnKey,
					  @pnDisplaySequence	= @pnDisplaySequence,
					  @pnSortOrder		= @pnSortOrder,
					  @psSortDirection	= @psSortDirection,
					  @pnGroupBySortOrder	= @pnGroupBySortOrder,
					  @psGroupBySortDirection	= @psGroupBySortDirection

End

Return @nErrorCode
GO

Grant execute on dbo.qr_InsertContent to public
GO
