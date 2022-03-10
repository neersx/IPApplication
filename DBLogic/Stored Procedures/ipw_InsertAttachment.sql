-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertAttachment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertAttachment.'
	Drop procedure [dbo].[ipw_InsertAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertAttachment
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnActivityKey					int = null,
	@pnSequenceKey					int = null,	
	@pnCaseKey						int = null,
	@pnNameKey						int = null,
	@pnActivityTypeKey				int = null,
	@pnActivityCategoryKey			int = null,
	@pdtActivityDate				datetime = null,
	@psActivitySummary				nvarchar(200)		 = null,
	@psAttachmentName				nvarchar(508)		 = null,
	@psLocation						nvarchar(508)		 = null,	
	@psAttachmentDescription		nvarchar(508)		 = null,
	@pbIsPublic						bit		 = null,
	@pnAttachmentTypeKey			int		 = null,
	@pnLanguageKey					int		 = null,
	@pnPageCount					int		 = null
)
as
-- PROCEDURE:	ipw_InsertAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Attachment.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Sep 2008	SF		RFC5745	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


if @nErrorCode = 0
and not exists (select * 
						from ACTIVITY 
						where ACTIVITYNO = @pnActivityKey)
Begin
	exec @nErrorCode = mk_InsertContactActivity 
			@pnUserIdentityId			= @pnUserIdentityId,
			@psCulture					= @psCulture,
			@pnActivityKey				= @pnActivityKey output,
			@pnContactKey				= @pnNameKey,
			@pdtActivityDate			= @pdtActivityDate,
			@pnCaseKey					= @pnCaseKey,
			@psSummary					= @psActivitySummary,
			@pnActivityCategoryKey		= @pnActivityCategoryKey,
			@pnActivityTypeKey			= @pnActivityTypeKey,
			@pbIsIncomplete				= 0

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "SELECT @pnSequenceKey = isnull(Max(SEQUENCENO)+1,0)
						FROM ACTIVITYATTACHMENT 
						WHERE ACTIVITYNO = @pnActivityKey"
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityKey		int,
			@pnSequenceKey		int output',
			@pnActivityKey	 = @pnActivityKey,
			@pnSequenceKey	 = @pnSequenceKey output
	
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
					@psLocation,
					@psAttachmentDescription,
					@pbIsPublic,
					@pnAttachmentTypeKey,
					@pnLanguageKey,
					@pnPageCount)
				"

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnActivityKey		int,
				@pnSequenceKey		int,
				@psAttachmentName		nvarchar(254),
				@psLocation		nvarchar(254),
				@psAttachmentDescription		nvarchar(254),
				@pbIsPublic		bit,
				@pnAttachmentTypeKey		int,
				@pnLanguageKey		int,
				@pnPageCount		int',
				@pnActivityKey	 = @pnActivityKey,
				@pnSequenceKey	 = @pnSequenceKey,
				@psAttachmentName	 = @psAttachmentName,
				@psLocation	 = @psLocation,
				@psAttachmentDescription	 = @psAttachmentDescription,
				@pbIsPublic	 = @pbIsPublic,
				@pnAttachmentTypeKey	 = @pnAttachmentTypeKey,
				@pnLanguageKey	 = @pnLanguageKey,
				@pnPageCount	 = @pnPageCount


		Select @pnSequenceKey as SequenceKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertAttachment to public
GO