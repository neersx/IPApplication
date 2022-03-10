-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetCaseBillingNarrative
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetCaseBillingNarrative]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetCaseBillingNarrative.'
	Drop procedure [dbo].[ts_GetCaseBillingNarrative]
End
Print '**** Creating Stored Procedure dbo.ts_GetCaseBillingNarrative...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_GetCaseBillingNarrative
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey				int,
	@pnLanguageKey			int	= null
)
as
-- PROCEDURE:	ts_GetCaseBillingNarrative
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrive the billing narrative in default language set against the debtor

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 APR 2011	SF		10349	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString				nvarchar(4000)
Declare @sLookupCulture			nvarchar(10)

Declare @bIsCaseNarrativeRequired bit
Declare @bIsKeepingHistory bit
Declare @nCaseNarrativeLanguageKey int


-- Initialise variables
Set @nErrorCode = 0
Set	@bIsCaseNarrativeRequired = 0
Set @bIsKeepingHistory = 0

If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bIsCaseNarrativeRequired = ISNULL(SC.COLBOOLEAN,0)
	from SITECONTROL SC 
	where SC.CONTROLID = 'Timesheet show Case Narrative'"

	Exec  @nErrorCode = sp_executesql @sSQLString,
				N'@bIsCaseNarrativeRequired bit	OUTPUT',
				  @bIsCaseNarrativeRequired = @bIsCaseNarrativeRequired OUTPUT
End

If @nErrorCode = 0
and @bIsCaseNarrativeRequired = 1
Begin		
	Set @sSQLString = "
	Select	@bIsKeepingHistory = ISNULL(SC.COLBOOLEAN,0)
	from SITECONTROL SC 
	where SC.CONTROLID = 'KEEPSPECIHISTORY'"

	Exec  @nErrorCode = sp_executesql @sSQLString,
				N'@bIsKeepingHistory bit	OUTPUT',
				  @bIsKeepingHistory = @bIsKeepingHistory OUTPUT
End

-- Case Billing Narrative
-- Return only if SITECONTROL Timesheet show Case Narrative is true
If @nErrorCode = 0
and @bIsCaseNarrativeRequired = 1
and @pnLanguageKey is null
Begin
	exec dbo.bi_GetBillingLanguage 
		@pnLanguageKey		= @nCaseNarrativeLanguageKey output,	-- The language in which a bill is to be prepared.
		@pnUserIdentityId	= @pnUserIdentityId,					-- Mandatory
		@pnCaseKey			= @pnCaseKey							-- The key of the main case being billed. 	
End
	
	
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select
		C.CASEID		as CaseKey,
		C.TEXTTYPE		as TextTypeCode,
		C.TEXTNO		as TextSubSequence,
		C.LANGUAGE		as LanguageKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
					+ " as LanguageDescription,
		"+dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT','TEXT','C',@sLookupCulture,@pbCalledFromCentura)
					+ " as Text,
		CASE 
			WHEN @pnLanguageKey = C.LANGUAGE THEN 1
			WHEN @nCaseNarrativeLanguageKey = C.LANGUAGE THEN 2
		ELSE 3 END as BestFit
		from CASETEXT C
		left join TABLECODES TC	on (TC.TABLECODE = C.LANGUAGE)" +
		
	CASE 
		WHEN @bIsKeepingHistory = 1 THEN
		
		"left join (	select CASEID, TEXTTYPE, LANGUAGE, CLASS, MAX( convert(nvarchar(24),MODIFIEDDATE, 21)+cast(TEXTNO as nvarchar(6)) ) as LATESTDATE
				from CASETEXT
				where TEXTTYPE = '_B'
				group by CASEID, TEXTTYPE, LANGUAGE, CLASS	
				) CT2 on (CT2.CASEID = C.CASEID
						and   CT2.TEXTTYPE = C.TEXTTYPE
						and   (CT2.CLASS = C.CLASS or (CT2.CLASS is null and C.CLASS is null))
						and   (	(CT2.LANGUAGE = C.LANGUAGE)
							    or	(CT2.LANGUAGE	IS NULL
								 and C.LANGUAGE IS NULL))  )"
	END + 									
	"	
		where C.CASEID = @pnCaseKey
		and C.TEXTTYPE = '_B'
		and @bIsCaseNarrativeRequired = 1
		and (C.LANGUAGE = isnull(@pnLanguageKey,@nCaseNarrativeLanguageKey) or C.LANGUAGE is null)
	" +
	CASE 
		WHEN @bIsKeepingHistory = 1 THEN
	
	"	and ( (convert(nvarchar(24),C.MODIFIEDDATE, 21)+cast(C.TEXTNO as nvarchar(6))) = CT2.LATESTDATE
				or CT2.LATESTDATE is null )"
	END	+
	"order by BestFit"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey					int,
			  @nCaseNarrativeLanguageKey    int,
              @pnLanguageKey				int,
              @bIsCaseNarrativeRequired		bit',
			  @pnCaseKey	 				= @pnCaseKey,
			  @pnLanguageKey				= @pnLanguageKey,
              @nCaseNarrativeLanguageKey	= @nCaseNarrativeLanguageKey,
              @bIsCaseNarrativeRequired		= @bIsCaseNarrativeRequired
              
	
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select
			@nCaseNarrativeLanguageKey as DefaultDebtorLanguageKey"
			
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCaseNarrativeLanguageKey    int',
              @nCaseNarrativeLanguageKey	= @nCaseNarrativeLanguageKey
End

Return @nErrorCode
GO

Grant execute on dbo.ts_GetCaseBillingNarrative to public
GO
