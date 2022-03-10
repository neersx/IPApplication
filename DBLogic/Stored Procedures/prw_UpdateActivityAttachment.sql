-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_UpdateActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_UpdateActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_UpdateActivityAttachment.'
	Drop procedure [dbo].[prw_UpdateActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.prw_UpdateActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.prw_UpdateActivityAttachment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbUpdateActivity		bit		= 0,
	@pnActivityKey			int,
	@pnSequenceKey			int,	
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
	@pnPageCount			int		= null,
	@pdtActivityLastModifiedDate	datetime	= null OUTPUT,
	@pdtLastModifiedDate		datetime	= null OUTPUT
)
as
-- PROCEDURE:	prw_UpdateActivityAttachment
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update an Activity Attachment attached to a Prior Art.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC		RFC6563	1		Procedure created
-- 04 May 2011	KR		RFC6557	2		Small syntax error has been fixed

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF
-- Reset so the next procedure gets the default
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
set @nErrorCode = 0

If @nErrorCode = 0 and @pbUpdateActivity = 1
Begin

	Set @sSQLString = "UPDATE ACTIVITY
		SET PRIORARTID		= @pnPriorArtKey,
			ACTIVITYDATE	= @pdtActivityDate,
			ACTIVITYTYPE	= @pnActivityTypeKey,
			ACTIVITYCATEGORY = @pnActivityCategoryKey,
			SUMMARY		= @psActivitySummary
		WHERE ACTIVITYNO	= @pnActivityKey
		  AND LOGDATETIMESTAMP	= @pdtActivityLastModifiedDate 
		  
		Select	@pdtActivityLastModifiedDate = LOGDATETIMESTAMP
		from	ACTIVITY
		where	ACTIVITYNO	= @pnActivityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnActivityKey		int,			
		@pnPriorArtKey		int,
		@pdtActivityDate	datetime,
		@pnActivityTypeKey	int,
		@pnActivityCategoryKey	int,
		@psActivitySummary nvarchar(254),
		@pdtActivityLastModifiedDate datetime output',
		@pnActivityKey		= @pnActivityKey,
		@pnPriorArtKey		= @pnPriorArtKey,
		@pdtActivityDate	= @pdtActivityDate,
		@pnActivityTypeKey	= @pnActivityTypeKey,
		@pnActivityCategoryKey	= @pnActivityCategoryKey,
		@psActivitySummary	= @psActivitySummary,
		@pdtActivityLastModifiedDate	 = @pdtActivityLastModifiedDate OUTPUT
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "UPDATE ACTIVITYATTACHMENT
		SET ATTACHMENTNAME	= @psAttachmentName,
			FILENAME	= @psFileName,
			ATTACHMENTDESC	= @psAttachmentDescription,
			PUBLICFLAG	= @pbIsPublic,
			ATTACHMENTTYPE	= @pnAttachmentTypeKey,
			LANGUAGENO	= @pnLanguageKey,
			PAGECOUNT	= @pnPageCount
		WHERE ACTIVITYNO	= @pnActivityKey
		  AND SEQUENCENO	= @pnSequenceKey
		  AND LOGDATETIMESTAMP	= @pdtLastModifiedDate

		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	ACTIVITYATTACHMENT
		where	ACTIVITYNO	= @pnActivityKey			
		and	SEQUENCENO	= @pnSequenceKey"

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
		@pdtLastModifiedDate		datetime output',
		@pnActivityKey			= @pnActivityKey,
		@pnSequenceKey			= @pnSequenceKey,
		@psAttachmentName		= @psAttachmentName,
		@psFileName			= @psFileName,
		@psAttachmentDescription	= @psAttachmentDescription,
		@pbIsPublic			= @pbIsPublic,
		@pnAttachmentTypeKey		= @pnAttachmentTypeKey,
		@pnLanguageKey			= @pnLanguageKey,
		@pnPageCount			= @pnPageCount,
		@pdtLastModifiedDate		= @pdtLastModifiedDate OUTPUT

	Select @pdtActivityLastModifiedDate	as ActivityLastModifiedDate,
		@pdtLastModifiedDate		as LastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.prw_UpdateActivityAttachment to public
GO