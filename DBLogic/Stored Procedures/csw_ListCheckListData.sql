-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListChecklistData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListChecklistData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListChecklistData.'
	Drop procedure [dbo].[csw_ListChecklistData]
End
Print '**** Creating Stored Procedure dbo.csw_ListChecklistData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListChecklistData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnCaseKey		int,		-- Mandatory
	@pnScreenCriteriaKey	int		= null,
	@pnChecklistCriteriaKey	int		= null,
	@pnChecklistTypeKey	int		= null,
	@psOpenActionKey	nvarchar(2)	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsDisplayOnly	bit		= 0
)
as
-- PROCEDURE:	csw_ListChecklistData
-- VERSION:	21
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the questions and meta data associated with checklist.  
--		If Checklist type, Screen Criterion and Checklist criterion are not provided then it is defaulted.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 21 NOV 2007	SF	RFC5776		1	Procedure created
-- 12 FEB 2008	SF	RFC6198		2	Return valid checklist description if exists.
-- 06 MAR 2008	SF	RFC5776		3	Improve letter checking routine
-- 11 Dec 2008	MF	17136		4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 28 Jan 2009	SF	RFC7459		5	Use WorkBench screen control purpose code - 'W', 
--						Return readonly Case Details result sets Checklist and ChecklistInfo
-- 21 Sep 2009  LP  	RFC8047		6   	Pass ProfileKey as parameter to fn_GetCriteriaNO
-- 26 Oct 2009	DV	RFC8366		7	Add logic for IsAnsweredInThisSession column
-- 04 Nov 2009	MS	RFC8366		8	Change checks for YesAnswer and NoAnswer columns
-- 03 Nov 2010  DV  	RFC100413	9	Replace the join of PERIODTYPE with TABLECODE by USERCODE
-- 07 Dec 2010	LP	RFC7284		10	Return information for conditional checklists.
-- 19 Jan 2011	DV  	RFC100424	11	Fixed issue when the Date Value was not getting populated.
-- 08 Feb 2011  LP  	RFC7284		12  	Use nvarchar(max) to store SQL string.
-- 16 Feb 2011  LP  	RFC7284		13  	Return DateOption based on UPDATEEVENONO and NOEVENTNO
-- 07 Apr 2011  LP  	RFC10446	14	Prevent duplicate records from being returned for Questions attached to multiple letters.
-- 12 Sep 2013	KR	DR920		15	Return @psOpenActionKey as part of the resultset
-- 18 Sep 2013	AT	DR-920		16	Removed erroneous character.
-- 02 Nov 2015	vql	R53910		17	Adjust formatted names logic (DR-15543).
-- 26 Apr 2016	MF	R60792		18	Data problem was causing front end program to crash when multiple letters against a Question were
--						configured differently in terms of the FORPRIMECASEONLY setting.  Rework query to take the maximum
--						flag setting for the flag.
-- 19 Jul 2017	MF	71968		19	When determining the default Case program, first consider the Profile of the User.
-- 14 Sep 2017	MF	71968		20	Rework after failed test.
-- 07 Sep 2018	AV	74738		21	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
                                
Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(max)
Declare @sLookupCulture			nvarchar(10)
Declare @sProgramKey			nvarchar(8)
Declare @nScreenCriteriaNo		int
Declare @nChecklistCriteriaNo		int
Declare @nChecklistType			int
Declare @sValidChecklistDescription	nvarchar(50)
Declare @nProductCode			int
Declare @bCanPrintIfPrimeOnly		bit
Declare @nProfileKey			int

-- Initialise variables
Set @nErrorCode 		= 0
Set @sLookupCulture 		= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nChecklistType		= @pnChecklistTypeKey
Set @nScreenCriteriaNo		= @pnScreenCriteriaKey
Set @nChecklistCriteriaNo	= @pnChecklistCriteriaKey
Set @bCanPrintIfPrimeOnly	= 0

-- Get the ProfileKey and default 
-- Case Program for the current user
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @sProgramKey = left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8),
	       @nProfileKey = U.PROFILEID 
	from  SITECONTROL S
	join USERIDENTITY U             on (U.IDENTITYID= @pnUserIdentityId)
	join CASES C                    on (C.CASEID    = @pnCaseKey)
	join CASETYPE CT                on (C.CASETYPE  = CT.CASETYPE)
	left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
					and PA.ATTRIBUTEID=2)	-- Default Cases Program
	where S.CONTROLID = CASE WHEN CT.CRMONLY=1 THEN 'CRM Screen Control Program'
						   ELSE 'Case Screen Default Program' 
			    END"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@sProgramKey		nvarchar(8)	OUTPUT,
				  @nProfileKey          int		OUTPUT,
				  @pnCaseKey		int,
				  @pnUserIdentityId	int',
				  @sProgramKey		= @sProgramKey	OUTPUT,
				  @nProfileKey		= @nProfileKey	OUTPUT,
				  @pnCaseKey		= @pnCaseKey,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Determine screen criteria no
If @nErrorCode = 0 
and @nScreenCriteriaNo is null
Begin		
	Set @sSQLString = "
	Select	@nScreenCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'W', @sProgramKey, null, @nProfileKey)
	from CASES C
	Where C.CASEID = @pnCaseKey"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@nScreenCriteriaNo	int			OUTPUT,
				  @pnCaseKey		int,
				  @nProfileKey          int,
				  @sProgramKey		nvarchar(8)',
				  @nScreenCriteriaNo	= @nScreenCriteriaNo	OUTPUT,
				  @pnCaseKey		= @pnCaseKey,
				  @nProfileKey          = @nProfileKey,
				  @sProgramKey		= @sProgramKey
End


-- Determine default checklist type if not provided
-- With WorkBenches screen control rule, it will not be possible to
-- assign multiple frmCheckList to the rule.  Instead, all valid checklists
-- for the case will be available for selection.
-- This will choose the first one in the list.
If @nErrorCode = 0 
and @pnCaseKey is not null
and @nChecklistType is null 
Begin		
	Set @sSQLString = "
	Select top 1 @nChecklistType = VCL.CHECKLISTTYPE
	from CASES C
	join VALIDCHECKLISTS VCL on (VCL.PROPERTYTYPE	= C.PROPERTYTYPE
							and VCL.CASETYPE	= C.CASETYPE
							and VCL.COUNTRYCODE=(
											select min(VCL1.COUNTRYCODE)
											from VALIDCHECKLISTS VCL1
											where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
											and VCL1.CASETYPE     = C.CASETYPE
											and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))												
	where C.CASEID = @pnCaseKey"	
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@nChecklistType			int			OUTPUT,
				  @pnCaseKey				int',
				  @nChecklistType			= @nChecklistType	OUTPUT,
				  @pnCaseKey				= @pnCaseKey

	-- no valid rules set up, get the first one from generic list
	If @nErrorCode = 0 
	and @nChecklistType is null 
	Begin		
		
		Set @sSQLString = "
		Select top 1 @nChecklistType = C.CHECKLISTTYPE
		from CHECKLISTS C"
		
		Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@nChecklistType			int			OUTPUT',
					  @nChecklistType			= @nChecklistType	OUTPUT
	End

End


If @nErrorCode = 0
and @nScreenCriteriaNo is not null
and @nChecklistType is not null 
Begin

	Set @sSQLString = "
	Select @nChecklistCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'C', @nChecklistType, null, @nProfileKey)"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@nChecklistCriteriaNo		int			OUTPUT,
				  @nChecklistType			int,
				  @pnCaseKey				int,
				  @nProfileKey                  int',
				  @nChecklistCriteriaNo	=	@nChecklistCriteriaNo	OUTPUT,
				  @nChecklistType		=	@nChecklistType,
				  @pnCaseKey			=	@pnCaseKey,
				  @nProfileKey                  = @nProfileKey
End

-- get valid checklist description
If @nErrorCode = 0
and @nChecklistType is not null 
Begin
	Set @sSQLString = "
		select	
		@sValidChecklistDescription = "+dbo.fn_SqlTranslatedColumn('VALIDCHECKLISTS','CHECKLISTDESC',null,'VCL',@sLookupCulture,@pbCalledFromCentura)
		+" from CASES C
		join VALIDCHECKLISTS VCL on (VCL.PROPERTYTYPE	= C.PROPERTYTYPE
								and VCL.CASETYPE	= C.CASETYPE
								and VCL.COUNTRYCODE=(
												select min(VCL1.COUNTRYCODE)
												from VALIDCHECKLISTS VCL1
												where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
												and VCL1.CASETYPE     = C.CASETYPE
												and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))												
		where C.CASEID = @pnCaseKey
		and VCL.CHECKLISTTYPE = @nChecklistType"		
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@sValidChecklistDescription 	nvarchar(50) output,
						@nChecklistType 				int,
						@pnCaseKey						int',					  
						@sValidChecklistDescription 	= @sValidChecklistDescription OUTPUT,
						@nChecklistType 				= @nChecklistType,
						@pnCaseKey						= @pnCaseKey
End

If @nErrorCode = 0
and @pbIsDisplayOnly = 0
Begin
	-- Check if the case can generate prime case only letters 
	-- (i.e. the case is either marked as prime on a case list or is not against any case list).
	Set @sSQLString = "
			Select @bCanPrintIfPrimeOnly = 
			case when exists (SELECT 1 FROM CASELISTMEMBER 
						WHERE CASEID = @pnCaseKey
						and PRIMECASE = 1)
				or not exists (Select 1
						from CASELISTMEMBER
						where CASEID = @pnCaseKey) 
			then 1 else 0 end"

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@bCanPrintIfPrimeOnly bit OUTPUT,
			@pnCaseKey	int',
			@pnCaseKey = @pnCaseKey,
			@bCanPrintIfPrimeOnly = @bCanPrintIfPrimeOnly output
End


If @nErrorCode = 0
and @pbIsDisplayOnly = 0
Begin	
	If @nChecklistType is not null 
	and @nChecklistCriteriaNo is not null
	Begin
	        -- this statement is extremely close to overflowing.
		-- must test this statement by using @psCulture = N'ZH-CHS'

		Set @sSQLString = "Select "+ char(10)+			
		+"Cast(C.QUESTIONNO as nvarchar(10))	as RowKey,"+char(10)
		+"@pnCaseKey as CaseKey," + char(10) 
		+"@nScreenCriteriaNo as ScreenCriteriaKey," + char(10)
		+"@nChecklistCriteriaNo as ChecklistCriteriaKey," + char(10)
		+"@nChecklistType as ChecklistTypeKey," + char(10)
		+"@psOpenActionKey as OpenActionKey," + char(10)			
		+"Case when A.CASEID is null and " + char(10)
		+"(C.YESNOREQUIRED=5 or C.YESNOREQUIRED=4) " + char(10)			
		+"then 1 else 0 end as IsAnsweredInThisSession," + char(10)			
		+"C.QUESTIONNO as QuestionKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('CHECKLISTITEM','QUESTION',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+" as Question," + char(10)
		-- question metadata
		+"isnull(C.YESNOREQUIRED,Q.YESNOREQUIRED) as YesNoOption," + char(10)
		+"isnull(C.COUNTREQUIRED,Q.COUNTREQUIRED) as CountOption," + char(10)		
		+"isnull(C.AMOUNTREQUIRED,Q.AMOUNTREQUIRED) as AmountOption," + char(10) 			
		+"CASE WHEN C.UPDATEEVENTNO IS NULL AND C.NOEVENTNO IS NULL THEN 0 ELSE 1 END as DateOption," + char(10)
		+"isnull(C.EMPLOYEEREQUIRED,Q.EMPLOYEEREQUIRED)as StaffNameOption," + char(10)	
		+"isnull(C.PERIODTYPEREQUIRED,Q.PERIODTYPEREQUIRED) as PeriodTypeOption," + char(10)	
		+"isnull(C.TEXTREQUIRED,Q.TEXTREQUIRED) as TextOption," + char(10)
		+"Case 	when ISNULL(C.YESNOREQUIRED,Q.YESNOREQUIRED)=1 or " + char(10)	
		+" isnull(C.COUNTREQUIRED,Q.COUNTREQUIRED)=1 or " + char(10)	
		+" isnull(C.AMOUNTREQUIRED,Q.AMOUNTREQUIRED)=1 or " + char(10)	
		+" C.DATEREQUIRED=1 OR " + char(10)	
		+" isnull(C.EMPLOYEEREQUIRED, Q.EMPLOYEEREQUIRED)=1 or " + char(10)	
		+" isnull(C.PERIODTYPEREQUIRED, Q.PERIODTYPEREQUIRED)=1 or " + char(10)	
		+" isnull(C.TEXTREQUIRED, Q.TEXTREQUIRED)=1 " + char(10)	
		+" then 1 else 0 end as 'IsAnswerRequired'," + char(10)	
		+"Case when A.CASEID is not null then 1 else 0 end as IsAnswered," + char(10)	
		+"0 as UserAcceptedRow," + char(10)	
		+"Q.TABLETYPE as ListSelectionType," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)
				+" as ListSelectionTypeDescription," + char(10)
		-- answers
		+"A.TABLECODE as ListSelectionKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+" as ListSelection," + char(10)
		-- YesAnswer and NoAnswer are for UI purpose and must be 1 or 0; YesNoAnswer is true db representation
		+"Case when A.YESNOANSWER=1 then 1 When A.YESNOANSWER is null and A.CASEID is null and isnull(C.YESNOREQUIRED,Q.YESNOREQUIRED)=4 then 1 else 0 END as 'YesAnswer'," + char(10)
		+"Case when A.YESNOANSWER=0 then 1 WHEN A.YESNOANSWER is null and A.CASEID is null and isnull(C.YESNOREQUIRED,Q.YESNOREQUIRED)=5 then 1 else 0 END as 'NoAnswer'," + char(10)
		+"A.YESNOANSWER as YesNoAnswer," + char(10)
		+"A.VALUEANSWER as AmountValue," + char(10)
		-- SQA10816 retrieve the entered deadline in caseevent for count answer and event date for date answer
		-- count and period columns are returned when 			
		+"CASE WHEN C.DUEDATEFLAG=1 or C.NODUEDATEFLAG =1 THEN CE.EVENTDUEDATE ELSE CE.EVENTDATE END as DateValue, " + char(10)
		+"isnull(CE.ENTEREDDEADLINE, A.COUNTANSWER) as CountValue, " + char(10)
		+"A.CHECKLISTTEXT as TextValue," + char(10)
		+"CE.PERIODTYPE as PeriodTypeKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)
				+" as PeriodTypeDescription," + char(10)
		+"A.EMPLOYEENO as StaffNameKey," + char(10)
		+"N.NAMECODE as StaffNameCode," + char(10)
		+"dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)	as 'StaffName'," + char(10)
		+"A.PRODUCTCODE as ProductCode," + char(10)
		+"A.PROCESSEDFLAG as IsProcessed," + char(10)
		+"C.SEQUENCENO as DisplaySequence," + char(10)

		-- other information not shown on screen.
		+"C.UPDATEEVENTNO as UpdateEventKey," + char(10)
		+"C.NOEVENTNO as NoEventKey," + char(10)
		+"C.DUEDATEFLAG	as DueDateOption," + char(10)
		+"C.NODUEDATEFLAG as NoDueDateOption," + char(10)
		-- approximately estimate whether charges may exist
		+"Case 	when C.YESRATENO is not null or C.NORATENO is not null then 1 else 0 end " + char(10)
		+" as ProduceChargeEvenIfExists," + char(10)
		-- approximately estimate whether letter may be generated
		+"Case 	when LX.CRITERIANO is not null and (LX.FORPRIMECASESONLY is null or (LX.FORPRIMECASESONLY = 1 and  @bCanPrintIfPrimeOnly = 1)) then 1 " + char(10)
		+" when LX.CRITERIANO is not null then 1 " + char(10)
		+" else 0 end as ProduceLetterEvenIfExists," + char(10)
		+"C.SOURCEQUESTION as SourceQuestion," + char(10)
		+"C.ANSWERSOURCEYES as AnswerSourceYes," + char(10)
		+"C.ANSWERSOURCENO as AnswerSourceNo" + char(10)
		+"from CHECKLISTITEM C" + char(10)
		+"join QUESTION Q ON (Q.QUESTIONNO = C.QUESTIONNO)" + char(10)
		+"left join CASECHECKLIST A on (Q.QUESTIONNO = A.QUESTIONNO AND A.CASEID = @pnCaseKey)" + char(10)
		+"left join NAME N on (N.NAMENO = A.EMPLOYEENO)" + char(10)
		+"left join TABLECODES TC on (TC.TABLETYPE = Q.TABLETYPE and TC.TABLECODE = A.TABLECODE)" + char(10)
		+"left join CASEEVENT CE " + char(10)
		+" on (CE.CASEID = A.CASEID " + char(10)
			+" and CE.EVENTNO = Case when C.NOEVENTNO is not null and A.YESNOANSWER = 0 then C.NOEVENTNO " + char(10)
			+" when C.UPDATEEVENTNO is not null and (A.YESNOANSWER=1 or coalesce(C.YESNOREQUIRED,Q.YESNOREQUIRED,0)=0) then C.UPDATEEVENTNO " + char(10)
			+" end" + char(10)
			+" and CE.CYCLE = (select max(CE1.CYCLE)" 
						+" from CASEEVENT CE1" 
						+" where CE1.EVENTNO = CE.EVENTNO and CE1.CASEID = CE.CASEID)" + char(10)
		+")" + char(10)
		+"left join TABLECODES TC1 on (TC1.TABLETYPE = 127 and TC1.USERCODE = CE.PERIODTYPE)" + char(10)
		+"left join TABLETYPE TT on (TT.TABLETYPE = Q.TABLETYPE)" + char(10)
		-- approximately estimate whether letter may be generated
		-- RFC10446: Prevent questions with multiple letters from displaying multiple times
		-- No need to return LETTERNO in the derived table as it is not returned by the query.
		+"left join (SELECT CL.CRITERIANO, CL.QUESTIONNO, max(cast(L.FORPRIMECASESONLY as tinyint)) as FORPRIMECASESONLY
		            from CHECKLISTLETTER CL
		            left join LETTER L on (L.LETTERNO = CL.LETTERNO)
		            group by CL.CRITERIANO, CL.QUESTIONNO) LX on (LX.CRITERIANO = C.CRITERIANO and LX.QUESTIONNO = C.QUESTIONNO)"+CHAR(10)
		+"where C.CRITERIANO = @nChecklistCriteriaNo" + char(10)
		+"order by C.SEQUENCENO"
                        
		execute @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey		 		int,
							  @nChecklistType			int,
							  @nScreenCriteriaNo		int,
							  @nChecklistCriteriaNo		int,
							  @bCanPrintIfPrimeOnly		bit,
							  @psOpenActionKey			nvarchar(2)',
							  @pnCaseKey		 	= @pnCaseKey,
							  @nChecklistType		= @nChecklistType,
							  @nScreenCriteriaNo		= @nScreenCriteriaNo,
							  @nChecklistCriteriaNo		= @nChecklistCriteriaNo,
							  @bCanPrintIfPrimeOnly		= @bCanPrintIfPrimeOnly,
							  @psOpenActionKey			= @psOpenActionKey
	End
	Else
	Begin
		Set @sSQLString = 
				"Select 	-1		as RowKey,						
						null		as CaseKey,
						null		as ScreenCriteriaKey,
						null		as ChecklistCriteriaKey,
						null		as ChecklistTypeKey,
						null		as IsAnsweredInThisSession,
						null		as OpenActionKey,
						null		as QuestionKey,
						null		as Question,
						null		as YesNoOption,
						null		as CountOption,
						null		as AmountOption,
						null		as DateOption,
						null		as StaffNameOption,
						null		as PeriodTypeOption,
						null		as TextOption,
						null		as IsAnswerRequired,
						null		as IsAnswered,
						null		as UserAcceptedRow,
						null		as ListSelectionType,
						null		as ListSelectionTypeDescription,
						null		as ListSelectionKey,
						null		as ListSelection,
						null		as YesAnswer,
						null		as NoAnswer,
						null		as YesNoAnswer,
						null		as AmountValue,
						null		as DateValue,
						null		as CountValue,
						null		as TextValue,
						null		as PeriodTypeKey,
						null		as PeriodTypeDescription,
						null		as StaffNameKey,
						null		as StaffNameCode,
						null		as StaffName,
						null		as ProductCode,
						null		as IsProcessed,
						null		as DisplaySequence,
						null		as UpdateEventKey,
						null		as NoEventKey,
						null		as DueDateOption,
						null		as NoDueDateOption,
						null		as SourceQuestion,
						null		as AnswerSourceYes,
						null		as AnswerSourceNo
				from CASES where 1=2"		

		exec @nErrorCode = sp_executesql @sSQLString
	End	
End

/* following is display only in Case Details window */
If @nErrorCode = 0
and @pbIsDisplayOnly = 1
Begin	
	If @nChecklistType is not null 
	and @nChecklistCriteriaNo is not null
	Begin
		
		Set @sSQLString = "Select "+ char(10)+			
		+"Cast(C.QUESTIONNO as nvarchar(10))	as RowKey,"+char(10)
		+"@pnCaseKey as CaseKey," + char(10) 
		+"@nScreenCriteriaNo as ScreenCriteriaKey," + char(10)
		+"@nChecklistCriteriaNo as ChecklistCriteriaKey," + char(10)
		+"@nChecklistType as ChecklistTypeKey," + char(10)		
		+"@psOpenActionKey as OpenActionKey," + char(10)	
		+"C.QUESTIONNO as QuestionKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('CHECKLISTITEM','QUESTION',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+" as Question," + char(10)
		-- question metadata
		+"Case when A.CASEID is not null then 1 else 0 end as IsAnswered," + char(10)	
		+"Q.TABLETYPE as ListSelectionType," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)
				+" as ListSelectionTypeDescription," + char(10)
		-- answers
		+"A.TABLECODE as ListSelectionKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+" as ListSelection," + char(10)
		-- YesAnswer and NoAnswer are for UI purpose and must be 1 or 0; YesNoAnswer is true db representation
		+"Case when A.YESNOANSWER=1 then 1 WHEN A.YESNOANSWER is null and A.CASEID is null and isnull(C.YESNOREQUIRED,Q.YESNOREQUIRED)=4 then 1 else 0 END as 'YesAnswer'," + char(10)
		+"Case when A.YESNOANSWER=0 then 1 WHEN A.YESNOANSWER is null and A.CASEID is null and isnull(C.YESNOREQUIRED,Q.YESNOREQUIRED)=5 then 1 else 0 END as 'NoAnswer'," + char(10)
		+"A.YESNOANSWER as YesNoAnswer," + char(10)
		+"A.VALUEANSWER as AmountValue," + char(10)
		-- SQA10816 retrieve the entered deadline in caseevent for count answer and event date for date answer
		-- count and period columns are returned when 			
		+"CE.EVENTDATE as DateValue, " + char(10)
		+"isnull(CE.ENTEREDDEADLINE, A.COUNTANSWER) as CountValue, " + char(10)
		+"A.CHECKLISTTEXT as TextValue," + char(10)
		+"CE.PERIODTYPE as PeriodTypeKey," + char(10)
		+ dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)
				+" as PeriodTypeDescription," + char(10)
		+"A.EMPLOYEENO as StaffNameKey," + char(10)
		+"N.NAMECODE as StaffNameCode," + char(10)
		+"dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)	as 'StaffName'," + char(10)
		+"A.PRODUCTCODE as ProductCode," + char(10)
		+"A.PROCESSEDFLAG as IsProcessed," + char(10)
		+"C.SEQUENCENO as DisplaySequence" + char(10)
		
		+"from CHECKLISTITEM C" + char(10)
		+"join QUESTION Q ON (Q.QUESTIONNO = C.QUESTIONNO)" + char(10)
		+"left join CASECHECKLIST A on (Q.QUESTIONNO = A.QUESTIONNO AND A.CASEID = @pnCaseKey)" + char(10)
		+"left join NAME N on (N.NAMENO = A.EMPLOYEENO)" + char(10)
		+"left join TABLECODES TC on (TC.TABLETYPE = Q.TABLETYPE and TC.TABLECODE = A.TABLECODE)" + char(10)
		+"left join CASEEVENT CE " + char(10)
		+" on (CE.CASEID = A.CASEID " + char(10)
			+" and CE.EVENTNO = Case when C.NOEVENTNO is not null and A.YESNOANSWER = 0 then C.NOEVENTNO " + char(10)
			+" when C.UPDATEEVENTNO is not null and (A.YESNOANSWER=1 or coalesce(C.YESNOREQUIRED,Q.YESNOREQUIRED,0)=0) then C.UPDATEEVENTNO " + char(10)
			+" end" + char(10)
			+" and CE.CYCLE = (select max(CE1.CYCLE)" 
						+" from CASEEVENT CE1" 
						+" where CE1.EVENTNO = CE.EVENTNO and CE1.CASEID = CE.CASEID)" + char(10)
		+")" + char(10)
		+"left join TABLECODES TC1 on (TC1.TABLETYPE = 127 and TC1.USERCODE = CE.PERIODTYPE)" + char(10)
		+"left join TABLETYPE TT on (TT.TABLETYPE = Q.TABLETYPE)" + char(10)		
		+"where C.CRITERIANO = @nChecklistCriteriaNo" + char(10)
		+"order by C.SEQUENCENO"

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey		 		int,
							  @nChecklistType			int,
							  @nScreenCriteriaNo		int,
							  @nChecklistCriteriaNo		int,
							  @bCanPrintIfPrimeOnly		bit,
							  @psOpenActionKey			nvarchar(2)',
							  @pnCaseKey		 		= @pnCaseKey,
							  @nChecklistType			= @nChecklistType,
							  @nScreenCriteriaNo		= @nScreenCriteriaNo,
							  @nChecklistCriteriaNo		= @nChecklistCriteriaNo,
							  @bCanPrintIfPrimeOnly		= @bCanPrintIfPrimeOnly,
							  @psOpenActionKey			= @psOpenActionKey
	End
	Else
	Begin
		Set @sSQLString = 
				"Select 	-1		as RowKey,						
						null		as CaseKey,
						null		as ScreenCriteriaKey,
						null		as ChecklistCriteriaKey,
						null		as ChecklistTypeKey,
						null		as OpenActionKey, 
						null		as QuestionKey,
						null		as Question,
						null		as IsAnswered,
						null		as ListSelectionType,
						null		as ListSelectionTypeDescription,
						null		as ListSelectionKey,
						null		as ListSelection,
						null		as YesAnswer,
						null		as NoAnswer,
						null		as YesNoAnswer,
						null		as AmountValue,
						null		as DateValue,
						null		as CountValue,
						null		as TextValue,
						null		as PeriodTypeKey,
						null		as PeriodTypeDescription,
						null		as StaffNameKey,
						null		as StaffNameCode,
						null		as StaffName,
						null		as ProductCode,
						null		as IsProcessed,
						null		as DisplaySequence						
				from CASES where 1=2"		

		exec @nErrorCode = sp_executesql @sSQLString
	End	
End

If @nErrorCode = 0 
Begin 
	-- SQA9421 product code to be returned 
	Set @sSQLString = "SELECT "+ char(10)+			
		+"@pnCaseKey				as RowKey,"+char(10)
		+"@pnCaseKey				as CaseKey," + char(10)
		+"@nScreenCriteriaNo		as ScreenCriteriaKey," + char(10)
		+"@nChecklistCriteriaNo		as ChecklistCriteriaKey," + char(10)
		+"@nChecklistType			as ChecklistTypeKey," + char(10)	
		+"@psOpenActionKey as OpenActionKey," + char(10)		
		+"isnull(@sValidChecklistDescription," 
		+dbo.fn_SqlTranslatedColumn('CHECKLISTS','CHECKLISTDESC',null,'CLT',@sLookupCulture,@pbCalledFromCentura)
			+ ") as 'ChecklistTypeDescription'," + char(10)
		+"ISNULL(SC.COLBOOLEAN,1)	as ProcessChecklist," + char(10)
		+"C.PRODUCTCODE			as ProductCode
	FROM CHECKLISTS CLT 
	LEFT JOIN SITECONTROL SC on (SC.CONTROLID = 'Process Checklist')
	LEFT JOIN SITECONTROL SCProdCode on (SCProdCode.CONTROLID = 'Product Recorded on WIP')
	LEFT JOIN CRITERIA C on (SCProdCode.COLBOOLEAN = 1 and C.CRITERIANO = @nChecklistCriteriaNo)
	WHERE CLT.CHECKLISTTYPE = @nChecklistType"

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnCaseKey		 		int,
						  @nChecklistType			int,
						  @nScreenCriteriaNo		int,
						  @nChecklistCriteriaNo		int,
						  @sValidChecklistDescription nvarchar(50),
						  @psOpenActionKey			nvarchar(2)',
						  @pnCaseKey		 		= @pnCaseKey,
						  @nChecklistType			= @nChecklistType,
						  @nScreenCriteriaNo		= @nScreenCriteriaNo,
						  @nChecklistCriteriaNo		= @nChecklistCriteriaNo,
						  @sValidChecklistDescription = @sValidChecklistDescription,
						  @psOpenActionKey			= @psOpenActionKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListChecklistData to public
GO
