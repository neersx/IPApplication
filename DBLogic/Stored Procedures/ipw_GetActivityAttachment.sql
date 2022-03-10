-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetActivityAttachment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetActivityAttachment.'
	Drop procedure [dbo].[ipw_GetActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_GetActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetActivityAttachment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey		int		= null,
	@pnSequenceKey		int		= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsNewRow		bit		= 0,
	@pnCaseKey		int		= null,  -- for defaulting a new row
	@pnNameKey		int		= null,	 -- for defaulting a new row
	@pnPriorArtKey		int		= null,	 -- for defaulting a new row
	@pnEventKey		int		= null,
	@pnEventCycle		smallint	= null
)
as
-- PROCEDURE:	ipw_GetActivityAttachment
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get an activity attachment

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Sep 2010	JC	RFC9304	1	Procedure created
-- 23 Feb 2011	JC	RFC6563	2	Add Prior Art
-- 12 Oct 2011	LP	RFC6896	3	Add EventKey and EventCycle parameters
-- 19 May 2015	DV	R47600	4	Remove check for WorkBench Attachments site control 
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @bIsExternalUser	bit
Declare @dtToday			datetime

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin

	If @pbIsNewRow = 0
	and @pnActivityKey is not null
	and @pnSequenceKey is not null
	Begin

		Set @sSQLString = "Select
		AA.ACTIVITYNO					as ActivityKey,
		AA.SEQUENCENO					as SequenceKey,
		A.NAMENO						as NameKey,
		N.NAMECODE						as NameCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
										as DisplayName,
		A.CASEID						as CaseKey,
		C.IRN							as CaseReference,
		A.PRIORARTID					as PriorArtKey,
		A.EVENTNO					as EventKey,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)	
					 +" as EventDescription,
		A.CYCLE					as EventCycle,
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
		from ACTIVITYATTACHMENT AA
		join ACTIVITY A				on (A.ACTIVITYNO = AA.ACTIVITYNO)
		-- Is Attachments topic available?
		join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, @pbCalledFromCentura, @dtToday) TS
						on (TS.IsAvailable=1)	
		left join NAME N			on (A.NAMENO = N.NAMENO)
		left join CASES C			on (A.CASEID = C.CASEID)
		left join TABLECODES TC1	on (TC1.TABLECODE = AA.ATTACHMENTTYPE)
		left join TABLECODES TC2	on (TC2.TABLECODE = AA.LANGUAGENO)	
		left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
		left join TABLECODES TCA	on (TCA.TABLECODE = A.ACTIVITYTYPE)
		left join EVENTS E		on (E.EVENTNO = A.EVENTNO)
		where AA.ACTIVITYNO = @pnActivityKey
		and		AA.SEQUENCENO = @pnSequenceKey"

		If @bIsExternalUser = 1
		Begin
			Set @sSQLString = @sSQLString + char(10) + "and AA.PUBLICFLAG = 1"	
		End
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnUserIdentityId	int,
				@pbCalledFromCentura bit,
				@dtToday			datetime,
				@pnActivityKey		int,
				@pnSequenceKey		int',
				@pnUserIdentityId   = @pnUserIdentityId,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@dtToday			= @dtToday,
				@pnActivityKey		= @pnActivityKey,
				@pnSequenceKey		= @pnSequenceKey		
	End
	Else
	Begin	
		If @pnActivityKey is not null
		Begin
			Set @sSQLString = "Select
			A.ACTIVITYNO					as ActivityKey,
			A.ACTIVITYTYPE					as ActivityTypeKey,			
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCA',@sLookupCulture,@pbCalledFromCentura)	
						 +" as ActivityTypeDescription,	
			A.ACTIVITYCATEGORY				as ActivityCategoryKey,			
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,@pbCalledFromCentura)	
						 +" as ActivityCategoryDescription,		
			A.ACTIVITYDATE					as ActivityDate,
			A.SUMMARY						as ActivitySummary
			from ACTIVITY A
			left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
			left join TABLECODES TCA	on (TCA.TABLECODE = A.ACTIVITYTYPE)
			where A.ACTIVITYNO = @pnActivityKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityKey	int',
					@pnActivityKey	= @pnActivityKey
		End
		Else If @pnCaseKey is not null
		Begin
			Set @sSQLString = "Select
			C.CASEID	as CaseKey,
			C.IRN		as CaseReference" + CHAR(10) +
			CASE WHEN @pnEventKey is not null THEN 
			", @pnEventKey	as EventKey, @pnEventCycle as EventCycle," 
			+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)	
					 +" as EventDescription" ELSE NULL END
			+ CHAR(10) +
			"from CASES C" + CHAR(10) +
			CASE WHEN @pnEventKey is not null THEN "left join EVENTS E on (E.EVENTNO = @pnEventKey)" ELSE NULL END
			+ CHAR(10) +
			"where	C.CASEID = @pnCaseKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int,
					@pnEventKey	int,
					@pnEventCycle	smallint',
					@pnCaseKey	= @pnCaseKey,
					@pnEventKey	= @pnEventKey,
					@pnEventCycle	= @pnEventCycle
		End
		Else If @pnNameKey is not null
		Begin
			Set @sSQLString = "Select
			N.NAMENO	as NameKey,
			N.NAMECODE	as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)	as DisplayName
			from NAME N
			where	N.NAMENO = @pnNameKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					@pnNameKey	= @pnNameKey
		End
		Else If @pnPriorArtKey is not null
		Begin
			Set @sSQLString = "Select
			P.PRIORARTID	as PriorArtKey
			from SEARCHRESULTS P
			where	P.PRIORARTID = @pnPriorArtKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPriorArtKey	int',
					@pnPriorArtKey	= @pnPriorArtKey
		End
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetActivityAttachment to public
GO