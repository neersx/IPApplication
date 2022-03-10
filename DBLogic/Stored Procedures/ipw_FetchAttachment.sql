-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchAttachment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchAttachment.'
	Drop procedure [dbo].[ipw_FetchAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchAttachment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnActivityKey		int = null,
	@pnSequenceKey		int = null,
	@pbIsNewRow			bit = 0,
	@pnCaseKey			int = null,  -- for defaulting a new row
	@pnNameKey			int = null	 -- for defaulting a new row
)
as
-- PROCEDURE:	ipw_FetchAttachment
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Attachment business entity.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Sep 2008	SF		RFC5745	1		Procedure created
-- 02 Oct 2008	SF		RFC5745	2		Continuation...
-- 15 Apr 2013	DV		R13270	3		Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql		R53910	4		Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
and @pbIsNewRow = 0
and @pnActivityKey is not null
and @pnSequenceKey is not null
Begin
	Set @sSQLString = "Select

	CAST(AA.ACTIVITYNO as nvarchar(11))+'^'+CAST(AA.SEQUENCENO as nvarchar(10))		
									as RowKey,
	AA.ACTIVITYNO					as ActivityKey,
	AA.SEQUENCENO					as SequenceKey,
	A.NAMENO						as NameKey,
	N.NAMECODE						as NameCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)		as DisplayName,
	A.CASEID						as CaseKey,
	C.IRN							as CaseReference,
	AA.ATTACHMENTNAME				as AttachmentName,
	"+dbo.fn_SqlTranslatedColumn('ACTIVITYATTACHMENT','ATTACHMENTDESC',null,'AA',@sLookupCulture,@pbCalledFromCentura)	
			     +" as AttachmentDescription,			
	cast(AA.PUBLICFLAG as bit)		as IsPublic,	
	AA.FILENAME						as Location,
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
	AA.PAGECOUNT					as PageCount
	from ACTIVITYATTACHMENT AA
	join ACTIVITY A				on (A.ACTIVITYNO = AA.ACTIVITYNO)
	left join NAME N			on (A.NAMENO = N.NAMENO)
	left join CASES C			on (A.CASEID = C.CASEID)
	left join TABLECODES TC1	on (TC1.TABLECODE = AA.ATTACHMENTTYPE)
	left join TABLECODES TC2	on (TC2.TABLECODE = AA.LANGUAGENO)	
	left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
	left join TABLECODES TCA	on (TCA.TABLECODE = A.ACTIVITYTYPE)
	where AA.ACTIVITYNO = @pnActivityKey
	and		AA.SEQUENCENO = @pnSequenceKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnActivityKey		int,
			@pnSequenceKey		int',
			@pnActivityKey		= @pnActivityKey,
			@pnSequenceKey		= @pnSequenceKey

End
Else
Begin
	Set @sSQLString = "Select

	CAST(isnull(A.ACTIVITYNO, -1) as nvarchar(11))+'^-1'
									as RowKey,
	isnull(A.ACTIVITYNO, -1)		as ActivityKey,
	-1								as SequenceKey,
	N.NAMENO						as NameKey,
	N.NAMECODE						as NameCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)		as DisplayName,
	C.CASEID						as CaseKey,
	C.IRN							as CaseReference,
	null							as AttachmentName,
	null							as AttachmentDescription,			
	0								as IsPublic,	
	null							as Location,
	null							as AttachmentTypeKey,
	null							as AttachmentTypeDescription,
	A.ACTIVITYTYPE					as ActivityTypeKey,			
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCA',@sLookupCulture,@pbCalledFromCentura)	
			     +" as ActivityTypeDescription,	
	A.ACTIVITYCATEGORY				as ActivityCategoryKey,			
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,@pbCalledFromCentura)	
			     +" as ActivityCategoryDescription,		
	A.ACTIVITYDATE					as ActivityDate,
	A.SUMMARY						as ActivitySummary,
	null							as LanguageKey,
	null							as LanguageDescription,			
	null							as PageCount
	from (select @pnNameKey as NameKey, @pnCaseKey as CaseKey, @pnActivityKey as ActivityKey) as KEYS
	left join ACTIVITY A		on (A.ACTIVITYNO = KEYS.ActivityKey)
	left join NAME N			on (N.NAMENO = KEYS.NameKey)
	left join CASES C			on (C.CASEID = KEYS.CaseKey)
	left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
	left join TABLECODES TCA	on (TCA.TABLECODE = A.ACTIVITYTYPE)
	where 1=1"
	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnActivityKey		int,
			@pnCaseKey			int,
			@pnNameKey			int',
			@pnActivityKey		= @pnActivityKey,
			@pnCaseKey			= @pnCaseKey,
			@pnNameKey			= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchAttachment to public
GO