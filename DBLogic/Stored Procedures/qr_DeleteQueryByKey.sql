-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteQueryByKey
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteQueryByKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteQueryByKey.'
	Drop procedure [dbo].[qr_DeleteQueryByKey]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteQueryByKey...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.qr_DeleteQueryByKey
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryKey			int		-- Mandatory
)
as
-- PROCEDURE:	qr_DeleteQueryByKey
-- VERSION:	3
-- DESCRIPTION:	Delete a query without checking for concurrency.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Dec 2003	JEK	RFC398	1	Procedure created
-- 14 May 2004	JEK	RFC1447	2	Deleting query does not always delete presentation/filter.
-- 09 Sep 2004	MB	SQA9658	3	Deleting query lines and query totals


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @nOldFilterKey		int
declare @nOldPresentationKey	int
declare @tblLineFilterIds 		TABLE (FilterId int )

-- Initialise variables
Set @nErrorCode 		= 0

-- save filter id s for each line in a temporary table
If @nErrorCode = 0
Begin
	Insert into @tblLineFilterIds (FilterId) 
	(select FILTERID from QUERYLINE where QUERYID = @pnQueryKey
	and FILTERID is not null)
	
	Set @nErrorCode = @@ERROR
End

-- delete from QUERYLINETOTAL
If @nErrorCode = 0
Begin
	Delete from QUERYLINETOTAL where LINEID in (select LINEID from QUERYLINE where QUERYID = @pnQueryKey)

	Set @nErrorCode = @@ERROR
End

-- delete from QUERYLINE
If @nErrorCode = 0
Begin
	Delete from QUERYLINE where QUERYID = @pnQueryKey

	Set @nErrorCode = @@ERROR
End

-- delete from QUERYFILTER where filter was attached to QUERYLINE
If @nErrorCode = 0
Begin
	Delete from QUERYFILTER where FILTERID in (select FilterId from  @tblLineFilterIds)

	Set @nErrorCode = @@ERROR
End


-- Locate the old filter and presentation keys
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	@nOldFilterKey 		= FILTERID,
		@nOldPresentationKey 	= PRESENTATIONID
	from	QUERY
	where	QUERYID = @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nOldFilterKey	int	output,
					  @nOldPresentationKey	int	output,
					  @pnQueryKey		int',
					  @nOldFilterKey	= @nOldFilterKey output,
					  @nOldPresentationKey	= @nOldPresentationKey output,
					  @pnQueryKey		= @pnQueryKey
End

-- Delete the query
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	QUERY
	where	QUERYID		= @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryKey		int',
					  @pnQueryKey		= @pnQueryKey

End

-- Delete any orphaned filter criteria
If @nErrorCode = 0
and @nOldFilterKey is not null
Begin
	exec @nErrorCode = qr_DeleteFilter
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnFilterKey		= @nOldFilterKey
End

-- Delete any orphaned presentation
If @nErrorCode = 0
and @nOldPresentationKey is not null
Begin
	exec @nErrorCode = qr_DeletePresentation
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnPresentationKey	= @nOldPresentationKey
End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteQueryByKey to public
GO