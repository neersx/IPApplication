-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertActivityAttachment.'
	Drop procedure [dbo].[prw_InsertActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.prw_InsertActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertActivityAttachment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnActivityKey			int		= null	OUTPUT,
	@pnSequenceKey			int		= null	OUTPUT,	
	@pdtActivityLastModifiedDate	datetime	= null	OUTPUT,
	@pdtLastModifiedDate		datetime	= null	OUTPUT,
	@pnPriorArtKey			int		= null,
	@pnActivityTypeKey		int		= null,
	@pnActivityCategoryKey		int		= null,
	@pdtActivityDate		datetime	= null,
	@psActivitySummary		nvarchar(254)	= null,
	@psAttachmentName		nvarchar(254)	= null,
	@psFileName			nvarchar(254)	= null,	
	@psAttachmentDescription	nvarchar(254)	= null,
	@pbIsPublic			bit		= 0,
	@pnAttachmentTypeKey		int		= null,
	@pnLanguageKey			int		= null,
	@pnPageCount			int		= null
)
as
-- PROCEDURE:	prw_InsertActivityAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment for a Prior Art.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 7 Dec 2010	JC		RFC9624	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

if @nErrorCode = 0 and @pnActivityKey is null
Begin
	exec @nErrorCode = mk_InsertContactActivity 
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnActivityKey		= @pnActivityKey output,
		@pdtActivityDate	= @pdtActivityDate,
		@pnPriorArtKey		= @pnPriorArtKey,
		@psSummary		= @psActivitySummary,
		@pnActivityCategoryKey	= @pnActivityCategoryKey,
		@pnActivityTypeKey	= @pnActivityTypeKey,
		@pbIsIncomplete		= 0

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "SELECT @pnSequenceKey = isnull(Max(SEQUENCENO)+1,0)
				FROM ACTIVITYATTACHMENT 
				WHERE ACTIVITYNO = @pnActivityKey"
	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'
		@pnActivityKey	int,
		@pnSequenceKey	int output',
		@pnActivityKey	= @pnActivityKey,
		@pnSequenceKey	= @pnSequenceKey output
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Insert into ACTIVITYATTACHMENT
			(ACTIVITYNO,
			SEQUENCENO,
			ATTACHMENTNAME,
			FILENAME,
			ATTACHMENTDESC,
			PUBLICFLAG,
			ATTACHMENTTYPE,
			LANGUAGENO,
			PAGECOUNT)
		values (
			@pnActivityKey,
			@pnSequenceKey,
			@psAttachmentName,
			@psFileName,
			@psAttachmentDescription,
			@pbIsPublic,
			@pnAttachmentTypeKey,
			@pnLanguageKey,
			@pnPageCount)

		Select	@pdtActivityLastModifiedDate = LOGDATETIMESTAMP
		from	ACTIVITY
		where	ACTIVITYNO	= @pnActivityKey
		
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	ACTIVITYATTACHMENT
		where	ACTIVITYNO	= @pnActivityKey			
		and	SEQUENCENO	= @pnSequenceKey
		
			"

		exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@pnActivityKey			int,
			@pnSequenceKey			int,
			@psAttachmentName		nvarchar(254),
			@psFileName			nvarchar(254),
			@psAttachmentDescription	nvarchar(254),
			@pbIsPublic			bit,
			@pnAttachmentTypeKey		int,
			@pnLanguageKey			int,
			@pnPageCount			int,
			@pdtActivityLastModifiedDate	datetime output,
			@pdtLastModifiedDate		datetime output',
			@pnActivityKey		=	@pnActivityKey,
			@pnSequenceKey		=	@pnSequenceKey,
			@psAttachmentName	=	@psAttachmentName,
			@psFileName		=	@psFileName,
			@psAttachmentDescription	= @psAttachmentDescription,
			@pbIsPublic			= @pbIsPublic,
			@pnAttachmentTypeKey		= @pnAttachmentTypeKey,
			@pnLanguageKey			= @pnLanguageKey,
			@pnPageCount			= @pnPageCount,
			@pdtActivityLastModifiedDate	= @pdtActivityLastModifiedDate OUTPUT,
			@pdtLastModifiedDate		= @pdtLastModifiedDate OUTPUT

		Select @pnActivityKey			as ActivityKey,
			@pnSequenceKey			as SequenceKey,
			@pdtActivityLastModifiedDate	as ActivityLastModifiedDate,
			@pdtLastModifiedDate		as LastModifiedDate
	End
End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertActivityAttachment to public
GO