-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDocGenAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDocGenAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDocGenAttachment.'
	Drop procedure [dbo].[ipw_InsertDocGenAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDocGenAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertDocGenAttachment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psFileName			nvarchar(254),	-- Mandatory,	
	@pnCaseKey			int		= null,
	@pnNameKey			int		= null,
	@pnActivityTypeKey		int,
	@pnActivityCategoryKey		int,
	@pdActivityDate			datetime,	-- Mandatory
	@psAttachmentName		nvarchar(254)	= null,
	@pbIsPublic			bit		= 0,
	@psAttachmentCaseSummary	nvarchar(254)	= null,
	@psAttachmentNameSummary	nvarchar(254)	= null,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	ipw_InsertDocGenAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment from Document Generation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 8 Sept 2010	JC	R10201	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @sActivitySummary	nvarchar(254)

set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

if @nErrorCode = 0 
Begin
	Set @sSQLString = "SELECT @sActivitySummary = 
				CASE 
				WHEN @pnCaseKey IS NOT NULL THEN  Replace(Replace(@psAttachmentCaseSummary,'{0}', 
					"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AT',@sLookupCulture,@pbCalledFromCentura)+"),'{1}', C.IRN)
				WHEN @pnNameKey IS NOT NULL THEN  Replace(Replace(@psAttachmentNameSummary,'{0}', 
					"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AT',@sLookupCulture,@pbCalledFromCentura)+"),'{1}', N.NAMECODE)
				ELSE "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'AT',@sLookupCulture,@pbCalledFromCentura)+"
				END
			FROM TABLECODES AT
			LEFT JOIN CASES C ON (C.CASEID = @pnCaseKey)
			LEFT JOIN NAME N ON (N.NAMENO = @pnNameKey)
			WHERE AT.TABLECODE = @pnActivityTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityTypeKey		int,
			@pnCaseKey			int,
			@pnNameKey			int,
			@psAttachmentCaseSummary	nvarchar(254),
			@psAttachmentNameSummary	nvarchar(254),
			@sActivitySummary		nvarchar(254) output',
			@pnActivityTypeKey		= @pnActivityTypeKey,
			@pnCaseKey			= @pnCaseKey,
			@pnNameKey			= @pnNameKey,
			@psAttachmentCaseSummary	= @psAttachmentCaseSummary,
			@psAttachmentNameSummary	= @psAttachmentNameSummary,
			@sActivitySummary		= @sActivitySummary output
End


if @nErrorCode = 0
Begin
	exec @nErrorCode=ipw_InsertSingleActivityAttachment 
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey		= @pnCaseKey,
		@pnNameKey		= @pnNameKey,
		@pnActivityTypeKey	= @pnActivityTypeKey,
		@pnActivityCategoryKey	= @pnActivityCategoryKey,
		@pdActivityDate		= @pdActivityDate,
		@psActivitySummary	= @sActivitySummary,
		@psAttachmentName	= @psAttachmentName,
		@psFileName		= @psFileName,
		@pbIsPublic		= @pbIsPublic
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertDocGenAttachment to public
GO