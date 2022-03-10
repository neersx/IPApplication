-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCheckListData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetCheckListData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetCheckListData.'
	Drop procedure [dbo].[ipw_GetCheckListData]
End
Print '**** Creating Stored Procedure dbo.ipw_GetCheckListData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetCheckListData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCriteriaKey			int	
)
as
-- PROCEDURE:	ipw_GetCheckListData
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrieve data to be used for setting up a Checklist

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 NOV 2010	SF	RFC9193	1	Procedure created
-- 04 Feb 2011  LP      RFC9193 2       Prevent duplicate header rows from being returned.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	DISTINCT C.CRITERIANO as CriteriaKey,
				"+dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+" as CriteriaDescription,
				C.CHECKLISTTYPE as ChecklistTypeKey,
				isnull(
				"+dbo.fn_SqlTranslatedColumn('VALIDCHECKLISTS','CHECKLISTDESC',null,'VCL',@sLookupCulture,@pbCalledFromCentura)
				+",
				"+dbo.fn_SqlTranslatedColumn('CHECKLISTS','CHECKLISTDESC',null,'CL',@sLookupCulture,@pbCalledFromCentura)
				+") as ChecklistTypeDescription,
				cast(isnull(USERDEFINEDRULE,0) as bit) IsUserDefined,
				cast(case when IPARENT.FROMCRITERIA is null then 0 else 1 end as bit) as HasParentage,
				cast(case when ICHILDREN.CRITERIANO is null then 0 else 1 end as bit) as HasOffspring
		 from CRITERIA C
		left join INHERITS IPARENT on (IPARENT.CRITERIANO = @pnCriteriaKey)
		left join INHERITS ICHILDREN on (ICHILDREN.FROMCRITERIA = @pnCriteriaKey)
		left join CHECKLISTS CL on (CL.CHECKLISTTYPE = C.CHECKLISTTYPE)
		left join VALIDCHECKLISTS VCL on (VCL.CHECKLISTTYPE = C.CHECKLISTTYPE
								and	VCL.PROPERTYTYPE	= C.PROPERTYTYPE
								and VCL.CASETYPE	= C.CASETYPE
								and VCL.COUNTRYCODE=(
												select min(VCL1.COUNTRYCODE)
												from VALIDCHECKLISTS VCL1
												where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
												and VCL1.CASETYPE     = C.CASETYPE
												and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))												
		where C.CRITERIANO = @pnCriteriaKey"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCriteriaKey	int',
			@pnCriteriaKey = @pnCriteriaKey
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	C.CRITERIANO as CriteriaKey,
			C.QUESTIONNO as QuestionKey,
			C.SEQUENCENO as SequenceNo,
			"+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null, 'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as Question,
			Q.QUESTIONCODE as QuestionCode,
			Q.IMPORTANCELEVEL as ImportanceLevelKey,
			"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null, 'IM',@sLookupCulture,@pbCalledFromCentura)
				+ " as ImportanceLevelDescription,
				
			C.YESNOREQUIRED as YesNoRequired,
			C.COUNTREQUIRED as CountRequired,
			C.PERIODTYPEREQUIRED as PeriodRequired,
			C.AMOUNTREQUIRED as AmountRequired,
			C.DATEREQUIRED as DateRequired, /* Date Required may have been made obsolete */
			C.EMPLOYEEREQUIRED as EmployeeRequired,
			C.TEXTREQUIRED as TextRequired,
			Q.TABLETYPE as TableTypeKey,
			"+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null, 'TT',@sLookupCulture,@pbCalledFromCentura)
				+ " as TableName,
			
			C.UPDATEEVENTNO as UpdateEventNo,
			isnull(
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null, 'ECYES',@sLookupCulture,@pbCalledFromCentura)
				+ ",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null, 'EYES',@sLookupCulture,@pbCalledFromCentura)
				+ ") as UpdateEventDescription,
			C.NOEVENTNO as NoEventNo,
			isnull(
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null, 'ECNO',@sLookupCulture,@pbCalledFromCentura)
				+ ",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null, 'ENO',@sLookupCulture,@pbCalledFromCentura)
				+ ") as NoEventDescription,
			
			cast(isnull(C.DUEDATEFLAG, 0) as bit) as YesDueDateFlag,
			cast(isnull(C.NODUEDATEFLAG, 0) as bit) as NoDueDateFlag,
			
			C.YESRATENO as YesRateNo,
			"+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null, 'CTYES',@sLookupCulture,@pbCalledFromCentura)
				+ " as YesRateDescription,
			C.NORATENO as NoRateNo,
			"+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null, 'CTNO',@sLookupCulture,@pbCalledFromCentura)
				+ " as NoRateDescription,
				
			cast(isnull(C.INHERITED, 0) as bit) as IsInherited,
			
			C.PAYFEECODE as PayFeeCode,
			cast(isnull(C.ESTIMATEFLAG, 0) as bit) as IsEstimate,
			cast(isnull(C.DIRECTPAYFLAG, 0) as bit) as IsDirectPay,
			
			C.SOURCEQUESTION as SourceQuestionKey,
			C.ANSWERSOURCEYES as AnswerSourceYes,
			C.ANSWERSOURCENO as AnswerSourceNo,
						
			C.LOGDATETIMESTAMP  as LastModifiedDate
	from CHECKLISTITEM C
	join QUESTION Q on (C.QUESTIONNO = Q.QUESTIONNO)
	
	left join IMPORTANCE IM on (IM.IMPORTANCELEVEL = Q.IMPORTANCELEVEL)
	left join TABLETYPE TT on (TT.TABLETYPE = Q.TABLETYPE)
	
	left join [EVENTS] EYES on (EYES.EVENTNO = C.UPDATEEVENTNO)
	left join EVENTCONTROL ECYES on (ECYES.EVENTNO = C.UPDATEEVENTNO and C.CRITERIANO = ECYES.CRITERIANO)
	
	left join [EVENTS] ENO on (ENO.EVENTNO = C.NOEVENTNO)
	left join EVENTCONTROL ECNO on (ECNO.EVENTNO = C.NOEVENTNO and C.CRITERIANO = ECNO.CRITERIANO)
	
	left join CHARGETYPE CTYES on (CTYES.CHARGETYPENO = C.YESRATENO)
	left join CHARGETYPE CTNO on (CTNO.CHARGETYPENO = C.NORATENO)
	
	where C.CRITERIANO = @pnCriteriaKey
	order by C.SEQUENCENO"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCriteriaKey	int',
			@pnCriteriaKey = @pnCriteriaKey
End

/*If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	CIC.CRITERIANO as CriteriaKey,
				CIC.QUESTIONNO as QuestionKey,
				CIC.CONDITIONSEQNO as ConditionSeqNo,
				CIC.ANSWERBASEDONSOURCE as AnswerBasedOnSource,
				CIC.DISABLEFLAG as IsDisabled,
				CIC.ISINHERITED as IsInherited,
				CIC.LOGDATETIMESTAMP  as LastModifiedDate
		from CHECKLISTITEMCONDITION CIC
		join CHECKLISTITEM CI on (CIC.CRITERIANO = CI.CRITERIANO
								and CIC.QUESTIONNO = CI.QUESTIONNO)
		where CIC.CRITERIANO = @pnCriteriaKey
		order by CIC.QUESTIONNO, CIC.CONDITIONSEQNO ASC
	"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCriteriaKey	int',
			@pnCriteriaKey = @pnCriteriaKey
End */

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	CIL.CRITERIANO as CriteriaKey,
				CIL.LETTERNO as LetterKey,
				"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null, 'L',@sLookupCulture,@pbCalledFromCentura)
				+ " as LetterName,
				CIL.QUESTIONNO as QuestionKey,
				"+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null, 'Q',@sLookupCulture,@pbCalledFromCentura)
				+ " as QuestionName,
				CIL.REQUIREDANSWER as AnswerRequired,
				cast(isnull(CIL.INHERITED, 0) as bit) as IsInherited,
				CIL.LOGDATETIMESTAMP  as LastModifiedDate
				
		from CHECKLISTLETTER CIL
		join LETTER L on (L.LETTERNO = CIL.LETTERNO)
		left join QUESTION Q on (CIL.QUESTIONNO = Q.QUESTIONNO)
		where CIL.CRITERIANO = @pnCriteriaKey
	"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCriteriaKey	int',
			@pnCriteriaKey = @pnCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetCheckListData to public
GO
