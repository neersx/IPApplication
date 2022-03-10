-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateActivityAttachment.'
	Drop procedure [dbo].[ipw_UpdateActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_UpdateActivityAttachment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbUpdateActivity		bit		= 0,
	@pnActivityKey			int,
	@pnSequenceKey			int,	
	@pnCaseKey			int		= null,
	@pnNameKey			int		= null,
	@pnPriorArtKey			int		= null,
	@pnEventKey			int		= null,
	@pnEventCycle			int		= null,
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
	@pdtActivityLastModifiedDate	datetime	= null,
	@pdtLastModifiedDate		datetime	= null
)
as
-- PROCEDURE:	ipw_UpdateActivityAttachment
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jan 2011	JC	RFC9624	1	Procedure created
-- 23 Feb 2011	JC	RFC6563	2	Add Prior Art
-- 25 Aug 2011	JC	RFC9599	3	Fix use of Prior Art Key
-- 12 Oct 2011	LP	RFC6896	4	Add EventKey and EventCycle parameters

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF
-- Reset so the next procedure gets the default
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
set @nErrorCode = 0

If @nErrorCode = 0 and @pbUpdateActivity = 1
Begin

	Set @sSQLString = "UPDATE ACTIVITY
			SET CASEID			= @pnCaseKey,
				NAMENO			= @pnNameKey,
				PRIORARTID		= @pnPriorArtKey,
				ACTIVITYDATE		= @pdtActivityDate,
				ACTIVITYTYPE		= @pnActivityTypeKey,
				ACTIVITYCATEGORY	= @pnActivityCategoryKey,
				SUMMARY			= @psActivitySummary,
				EVENTNO			= @pnEventKey,
				CYCLE			= @pnEventCycle
			WHERE ACTIVITYNO		= @pnActivityKey
			  AND LOGDATETIMESTAMP		= @pdtActivityLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@pnActivityKey			int,
			@pnCaseKey			int,
			@pnNameKey			int,
			@pnPriorArtKey			int,
			@pnEventKey			int,
			@pnEventCycle			int,
			@pdtActivityDate		datetime,
			@pnActivityTypeKey		int,
			@pnActivityCategoryKey		int,
			@psActivitySummary		nvarchar(254),
			@pdtActivityLastModifiedDate	datetime',
			@pnActivityKey			= @pnActivityKey,
			@pnCaseKey			= @pnCaseKey,
			@pnNameKey			= @pnNameKey,
			@pnPriorArtKey			= @pnPriorArtKey,
			@pnEventKey			= @pnEventKey,
			@pnEventCycle			= @pnEventCycle,
			@pdtActivityDate		= @pdtActivityDate,
			@pnActivityTypeKey		= @pnActivityTypeKey,
			@pnActivityCategoryKey		= @pnActivityCategoryKey,
			@psActivitySummary		= @psActivitySummary,
			@pdtActivityLastModifiedDate	= @pdtActivityLastModifiedDate
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
			  AND LOGDATETIMESTAMP	= @pdtLastModifiedDate"

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
			@pdtLastModifiedDate		datetime',
			@pnActivityKey			= @pnActivityKey,
			@pnSequenceKey			= @pnSequenceKey,
			@psAttachmentName		= @psAttachmentName,
			@psFileName			= @psFileName,
			@psAttachmentDescription	= @psAttachmentDescription,
			@pbIsPublic			= @pbIsPublic,
			@pnAttachmentTypeKey		= @pnAttachmentTypeKey,
			@pnLanguageKey			= @pnLanguageKey,
			@pnPageCount			= @pnPageCount,
			@pdtLastModifiedDate		= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateActivityAttachment to public
GO