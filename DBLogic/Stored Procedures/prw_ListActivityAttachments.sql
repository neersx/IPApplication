-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListActivityAttachments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListActivityAttachments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListActivityAttachments.'
	Drop procedure [dbo].[prw_ListActivityAttachments]
End
Print '**** Creating Stored Procedure dbo.prw_ListActivityAttachments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListActivityAttachments
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnPriorArtKey		int				= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	prw_ListActivityAttachments
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Activity Attachments for a particular Prior Art Key

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Feb 2011	JC		RFC6563	1		Procedure created
-- 19 May 2015	DV		R47600	2		Remove check for WorkBench Attachments site control 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @dtToday			datetime

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	AA.ACTIVITYNO					as ActivityKey,
	AA.SEQUENCENO					as SequenceKey,
	A.PRIORARTID					as PriorArtKey,
	AA.ATTACHMENTNAME				as AttachmentName,
	"+dbo.fn_SqlTranslatedColumn('ACTIVITYATTACHMENT','ATTACHMENTDESC',null,'AA',@sLookupCulture,@pbCalledFromCentura)	
				 +" as AttachmentDescription,			
	cast(isnull(AA.PUBLICFLAG,0) as bit)		as IsPublic,	
	AA.FILENAME						as FileName,
	AA.ATTACHMENTTYPE				as AttachmentTypeKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)	
				 +" as AttachmentTypeDescription,
	A.ACTIVITYTYPE				as ActivityTypeKey,			
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCA',@sLookupCulture,@pbCalledFromCentura)	
				 +" as ActivityTypeDescription,	
	A.ACTIVITYCATEGORY				as ActivityCategoryKey,			
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,@pbCalledFromCentura)	
				 +" as ActivityCategoryDescription,		
	A.ACTIVITYDATE					as ActivityDate,
	A.SUMMARY						as ActivitySummary,
	AA.LANGUAGENO					as LanguageKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)	
				 +" as LanguageDescription,			
	AA.PAGECOUNT					as PageCount,
	A.LOGDATETIMESTAMP				as ActivityLastModifiedDate,
	AA.LOGDATETIMESTAMP				as LastModifiedDate
	from ACTIVITY A
	join ACTIVITYATTACHMENT AA		on (AA.ACTIVITYNO = A.ACTIVITYNO)
	-- Is Attachments topic available?
	join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, @pbCalledFromCentura, @dtToday) TS
					on (TS.IsAvailable=1)		
	left join TABLECODES TC1	on (TC1.TABLECODE = AA.ATTACHMENTTYPE)
	left join TABLECODES TC2	on (TC2.TABLECODE = AA.LANGUAGENO)	
	left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
	left join TABLECODES TCA	on (TCA.TABLECODE = A.ACTIVITYTYPE)
	where A.PRIORARTID = @pnPriorArtKey
	order by isnull(AA.ATTACHMENTNAME, AA.FILENAME)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@dtToday			datetime,
			@pnPriorArtKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@dtToday			= @dtToday,
			@pnPriorArtKey		= @pnPriorArtKey		

End

Return @nErrorCode
GO

Grant execute on dbo.prw_ListActivityAttachments to public
GO