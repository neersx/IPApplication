-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainChecklistData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainChecklistData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainChecklistData.'
	Drop procedure [dbo].[csw_MaintainChecklistData]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainChecklistData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_MaintainChecklistData
(	
	@pnUpdatedEventEventKey			int		= null output,
	@pnUpdatedEventCycle			int		= null output,
	@pdtUpdatedEventDate			datetime = null output,
	@pbUpdatedEventIsDateDueSaved	bit		= null output,
	@psUpdatedEventControllingAction		nvarchar(2)	= null output,
	@pnUpdatedEventControllingCriteria		int		= null output,

	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey						int,	-- Mandatory
	@pnQuestionKey					smallint,	-- Mandatory
	@pnChecklistTypeKey				smallint		 = null,
	@pnScreenCriteriaKey			int		 = null,
	@pnChecklistCriteriaKey			int		 = null,
	@psOpenAction					nvarchar(2) = null,
	@pbUserAcceptedRow				bit		 = 0,
	@pbProcessQuestion				bit		 = 0,
	@pnYesNoOption					int		 = null,
	@pnCountOption					int		 = null,
	@pnAmountOption					int		 = null,
	@pnDateOption					int		 = null,
	@pnStaffNameOption				int		 = null,
	@pnPeriodTypeOption				int		 = null,
	@pnTextOption					int		 = null,
	@pbIsAnswered					bit		 = null,
	@pnListSelectionKey				int		 = null,
	@pbYesAnswer					bit		 = null,
	@pbNoAnswer						bit		 = null,
	@pbYesNoAnswer					bit		 = null,
	@pnCountValue					int		 = null,
	@pnAmountValue					decimal(11,2)		 = null,
	@ptTextValue					ntext		 = null,
	@pdtDateValue					datetime	= null,
	@pnStaffNameKey					int		 = null,
	@psPeriodTypeKey				nchar(1) = null,
	@pbIsProcessed					bit		 = null,
	@pnProductCode					int		 = null,
	@pbProduceChargeEvenIfExists			bit		= null,
	@pbProduceLetterEvenIfExists			bit		= null,
	@pnOldListSelectionKey			int		 = null,
	@pbOldYesAnswer					bit		 = null,
	@pbOldNoAnswer					bit		 = null,
	@pbOldYesNoAnswer				bit		 = null,
	@pnOldCountValue				int		 = null,
	@pnOldAmountValue				decimal(11,2)		 = null,
	@ptOldTextValue					ntext		 = null,
	@pdtOldDateValue					datetime	= null,
	@pnOldStaffNameKey				int		 = null,
    @psOldPeriodTypeKey				nchar(1) = null,
	@pbOldIsProcessed				bit		 = null,
	@pnOldProductCode				int		 = null	
)
as
-- PROCEDURE:	csw_MaintainChecklistData
-- VERSION:		17
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Manage checklist data changes. 
--				If CASECHECKLIST for CASEID/QUESTIONNO doesn't exist for a case then it is inserted, 
--				otherwise updated.
--				Update / insert applicable events when date is provided
--				Update / insert activity requests when appropriate

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 NOV 2007	SF	5776	1	Procedure created
-- 10 DEC 2007	AT	5776	2	Added Charge and Letter Generation functionality.
-- 21 DEC 2007 	SF	5776	3	Continuation
-- 3 JAN 2008 	SF	5776	4	Continuation
-- 9 JAN 2008	SF 	5776	5	Use SYSTEM_USER instead of USER when inserting Activity Request
-- 21 JAN 2008 	SF	5776	6	Use Set instead of Select when getting @@RowCount
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Jul 2010	SF	9568	8	Allow answers to be saved when the same question is answered in one or more checklists steps 
--					that is being saved in a batch
-- 24 MAy 2011	LP	10657	9	Corrected join to CaseEvent table as it was causing referential integrity error.
-- 06 Jun 2011	LP	10769	10	Only raise charges if either Yes or No Answer has been provided.
-- 22 Jun 2011	LP	10883	11	Use @bYesNoAnswer instead of @pbYesNoAnswer when determining Applicable Event to update.
-- 19 Aug 2011  DV  11069   12  Insert IDENTITYID value in ACTIVITYREQUEST table
-- 15 Sep 2011	AT	11301	13	Fix rounding of Entered Amount.
-- 06 Oct 2011	MF	11387	14	Coding correction to ensure correct cycle information is returned.
-- 11 Jan 2012	LP	11775	15	Coding correction with regards to cycle of case event to be updated
--					This is a retrofit of a fix implemented under RFC11387.
-- 12 Sep 2013	KR	DR920	16	Now saves OpenActionKey into the ACTIVITYREQUEST table.
--								Also saves the renewal debtor instead of the debtor if RATENO or ACTION is of renewal type.
-- 19 Sep 2013	AT	DR-920	17	Make RATETYPE nullable.
--								Use 'WIP Split Multi Debtor' site control instead of 'Charge Gen by All Debtors'.
--								Use left join on Actions table in case Case has no open action (checklist processed from checklist tab)
--								Consider the checklist's CHECKLISTTYPEFLAG when determining renewal or non-renewal.
--								Do not write Debtor billing information to ACTIVITYREQUEST for single debtor charges.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sUpdateString 		nvarchar(max)
Declare @sWhereString		nvarchar(max)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

Declare @bYesNoAnswer		bit
Declare @bOldYesNoAnswer	bit
Declare @nApplicableEvent	int
Declare @bIsDueDateApplicable	bit
Declare @nCycle			int
Declare @bEventExists		bit
Declare @nRowCount		int
Declare @nYesRateNo		int
Declare @nNoRateNo		int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

Set @bYesNoAnswer = case when (@pbYesAnswer is null and @pbNoAnswer is null) or (@pbYesAnswer = 0 and @pbNoAnswer = 0) then null
								when @pbYesAnswer = 1 then 1 
								when @pbNoAnswer = 1 then 0								
					end
Set @bOldYesNoAnswer = case when (@pbOldYesAnswer is null and @pbOldNoAnswer is null) or (@pbOldYesAnswer = 0 and @pbOldNoAnswer = 0) then null
						when @pbOldYesAnswer = 1 then 1 
						when @pbOldNoAnswer = 1 then 0
					end


/* 
	@pbIsAnswered is populated by csw_ListChecklistData, 
	and is set as 1 if the question has been answered before and exists in CASECHECKLIST 
*/
If @nErrorCode = 0 
and @pbIsAnswered = 1  
Begin
	If (@pbYesAnswer <> @pbOldYesAnswer 
		or @pbNoAnswer <> @pbOldNoAnswer 
		or @pnListSelectionKey	<> @pnOldListSelectionKey
		or @pnCountValue <> @pnOldCountValue
		or @pnAmountValue <> @pnOldAmountValue
		or @pnStaffNameKey <> @pnOldStaffNameKey
		or @pbIsProcessed <> @pbOldIsProcessed
		or dbo.fn_IsNtextEqual(@ptTextValue, @ptOldTextValue) <> 1)
	Begin
		Exec @nErrorCode = dbo.csw_UpdateChecklistData
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnCaseKey	 = @pnCaseKey,
			@pnQuestionKey	 = @pnQuestionKey,
			@pnChecklistTypeKey	 = @pnChecklistTypeKey,
			@pnChecklistCriteriaKey	 = @pnChecklistCriteriaKey,
			@pnListSelectionKey	 = @pnListSelectionKey,
			@pbYesNoAnswer	 = @bYesNoAnswer,
			@pnCountValue	 = @pnCountValue,
			@pnAmountValue	 = @pnAmountValue,
			@ptTextValue	 = @ptTextValue,
			@pnStaffNameKey	 = @pnStaffNameKey,
			@pbIsProcessed	 = @pbIsProcessed,
			@pnProductCode	 = @pnProductCode,						
			@pnOldListSelectionKey	 = @pnOldListSelectionKey,
			@pbOldYesNoAnswer	 = @bOldYesNoAnswer,
			@pnOldCountValue	 = @pnOldCountValue,
			@pnOldAmountValue	 = @pnOldAmountValue,
			@ptOldTextValue	 = @ptOldTextValue,
			@pnOldStaffNameKey	 = @pnOldStaffNameKey,
			@pbOldIsProcessed	 = @pbOldIsProcessed,
			@pnOldProductCode	 = @pnOldProductCode,

			@pbIsListSelectionKeyInUse		= 1,
			@pbIsYesNoAnswerInUse			= 1,
			@pbIsCountValueInUse			= 1,
			@pbIsAmountValueInUse			= 1,
			@pbIsTextValueInUse				= 1,
			@pbIsStaffNameKeyInUse			= 1,
			@pbIsIsProcessedInUse			= 1,
			@pbIsProductCodeInUse			= 1
	End

	Set @nRowCount=@@ROWCOUNT
End
Else
Begin
	If exists(Select * from CASECHECKLIST where CASEID = @pnCaseKey and QUESTIONNO = @pnQuestionKey)
	Begin
		/*	In a workflow where the same question is included in
			multiple checklists and the same question has never been answered before
			the subsequent saving of the answer should be an update
		 */
	 	Exec @nErrorCode = dbo.csw_UpdateChecklistData
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnCaseKey	 = @pnCaseKey,
			@pnQuestionKey	 = @pnQuestionKey,
			@pnChecklistTypeKey	 = @pnChecklistTypeKey,
			@pnChecklistCriteriaKey	 = @pnChecklistCriteriaKey,
			@pnListSelectionKey	 = @pnListSelectionKey,
			@pbYesNoAnswer	 = @bYesNoAnswer,
			@pnCountValue	 = @pnCountValue,
			@pnAmountValue	 = @pnAmountValue,
			@ptTextValue	 = @ptTextValue,
			@pnStaffNameKey	 = @pnStaffNameKey,
			@pbIsProcessed	 = @pbIsProcessed,
			@pnProductCode	 = @pnProductCode,						
			@pnOldListSelectionKey	 = @pnOldListSelectionKey,
			@pbOldYesNoAnswer	 = @bOldYesNoAnswer,
			@pnOldCountValue	 = @pnOldCountValue,
			@pnOldAmountValue	 = @pnOldAmountValue,
			@ptOldTextValue		 = @ptOldTextValue,
			@pnOldStaffNameKey	 = @pnOldStaffNameKey,
			@pbOldIsProcessed	 = @pbOldIsProcessed,
			@pnOldProductCode	 = @pnOldProductCode,

			@pbIsListSelectionKeyInUse	= 1,
			@pbIsYesNoAnswerInUse		= 1,
			@pbIsCountValueInUse		= 1,
			@pbIsAmountValueInUse		= 1,
			@pbIsTextValueInUse		= 1,
			@pbIsStaffNameKeyInUse		= 1,
			@pbIsIsProcessedInUse		= 1,
			@pbIsProductCodeInUse		= 1,
			@pbIsBypassConcurrencyChecking	= 1
		
		Set @nRowCount=@@ROWCOUNT
	End
	Else
	Begin
		/* this question has never been answered before */
		
		Exec @nErrorCode = dbo.csw_InsertChecklistData
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnCaseKey	 = @pnCaseKey,
				@pnQuestionKey	 = @pnQuestionKey,
				@pnChecklistTypeKey	 = @pnChecklistTypeKey,
				@pnChecklistCriteriaKey	 = @pnChecklistCriteriaKey,
				@pnListSelectionKey	 = @pnListSelectionKey,
				@pbYesNoAnswer	 = @bYesNoAnswer,
				@pnCountValue	 = @pnCountValue,
				@pnAmountValue	 = @pnAmountValue,
				@ptTextValue	 = @ptTextValue,
				@pnStaffNameKey	 = @pnStaffNameKey,
				@pbIsProcessed	 = @pbIsProcessed,
				@pnProductCode	 = @pnProductCode,

				@pbIsListSelectionKeyInUse	= 1,
				@pbIsYesNoAnswerInUse		= 1,
				@pbIsCountValueInUse		= 1,
				@pbIsAmountValueInUse		= 1,
				@pbIsTextValueInUse		= 1,
				@pbIsStaffNameKeyInUse		= 1,
				@pbIsIsProcessedInUse		= 1,
				@pbIsProductCodeInUse		= 1			

		Set @nRowCount=@@ROWCOUNT
	End
End

-- locate other information for further processing
If @nErrorCode = 0
Begin
	-- locate the applicable event to be updated / inserted
	-- applicable event = C.NOEVENTNO is not null and @bYesNoAnswer = 0 or
	--					  C.UPDATEEVENTNO is not null and (@bYesNoAnswer = 1 or @pnYesOption is null or @pnYesOption = 0)	
	-- does case event exists?  cycle.
	-- does yesrate / norate exist?

	Set @sSQLString = "Select 
			@nApplicableEvent = Case 	when C.NOEVENTNO is not null and @bYesNoAnswer = 0 then C.NOEVENTNO " + char(10)
		+"					when C.UPDATEEVENTNO is not null and (@bYesNoAnswer = 1 or isnull(C.YESNOREQUIRED, 0) > 0) then C.UPDATEEVENTNO " + char(10)
		+"				end," + char(10)
		+"	@bIsDueDateApplicable = Case " + char(10)
		+"					when	(C.NOEVENTNO is not null and @bYesNoAnswer = 0 and C.NODUEDATEFLAG = 1)" + char(10)			
		+"							or  ((C.UPDATEEVENTNO is not null and (@bYesNoAnswer = 1 or isnull(C.YESNOREQUIRED, 0) > 0)) " + char(10)			
		+"							and C.DUEDATEFLAG = 1) then 1 else 0 end," + char(10)			
		-- yes rate no / no rate no
		+"	@nYesRateNo = C.YESRATENO," + char(10)
		+"	@nNoRateNo = C.NORATENO," + char(10)
		-- case event
		+"  @bEventExists = case when CE.EVENTNO is null then 0 else 1 end," + char(10)
		+"	@nCycle = CE.CYCLE" + char(10)
		+"from CHECKLISTITEM C" + char(10) 
		-- check if the event exists on the case.
		+"left join CASEEVENT CE on (CE.CASEID = @pnCaseKey and CE.EVENTNO = " + char(10)
		+"					Case 	when C.NOEVENTNO is not null and @bYesNoAnswer = 0 then C.NOEVENTNO " + char(10)
		+"							when C.UPDATEEVENTNO is not null and (@bYesNoAnswer = 1 or isnull(C.YESNOREQUIRED, 0) > 0) then C.UPDATEEVENTNO " + char(10)
		+"					end " + char(10)
		+"					and CE.CYCLE = (select max(CE1.CYCLE) 
											from CASEEVENT CE1 
											where CE1.EVENTNO = CE.EVENTNO 
											and CE1.CASEID = @pnCaseKey))" + char(10)
		+"where C.CRITERIANO = @pnChecklistCriteriaKey"+char(10)		
		+"and C.QUESTIONNO = @pnQuestionKey"

		Exec @nErrorCode = sp_executesql @sSQLString,
						N'@nApplicableEvent		int output,
						@bIsDueDateApplicable		bit output,
						@nCycle				int output,
						@bEventExists			bit output,
						@nYesRateNo			int output,
						@nNoRateNo			int output,
						@pnChecklistCriteriaKey		int,
						@pnCaseKey			int,
						@pnQuestionKey			int,
						@bYesNoAnswer			bit',
						@nApplicableEvent		= @nApplicableEvent output,
						@bIsDueDateApplicable		= @bIsDueDateApplicable output,			
						@nCycle				= @nCycle output,
						@bEventExists			= @bEventExists output,
						@nYesRateNo			= @nYesRateNo output,
						@nNoRateNo			= @nNoRateNo output,
						@pnCaseKey			= @pnCaseKey,
						@pnQuestionKey			= @pnQuestionKey,
						@pnChecklistCriteriaKey		= @pnChecklistCriteriaKey,
						@bYesNoAnswer			= @bYesNoAnswer
End



-- update event
If @nErrorCode = 0
and (@nRowCount > 0 or (@nRowCount = 0 and @pbUserAcceptedRow = 1))
and @pdtDateValue is not null 
and (@pnDateOption is null or @pnDateOption > 0)
and @nApplicableEvent is not null
Begin

	If (@bEventExists = 1)
	Begin
		Set @sAnd = ' and ' 
		Set @sWhereString = char(10) + " where "
		Set @sComma = ''
		
		Set @sUpdateString = "Update CASEEVENT
				Set " + char(10)
		Set @sWhereString = @sWhereString + char(10)
		+"				CASEID = @pnCaseKey and" + char(10) 
		+"				EVENTNO = @nApplicableEvent and" + char(10) 
		+"				CYCLE = isnull(@nCycle,1)" + char(10) 
		
		If @bIsDueDateApplicable = 1				
		Begin
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "DATEDUESAVED = "
					+ "CASE WHEN @pdtDateValue is not null and @pdtDateValue <> @pdtOldDateValue THEN 1 ELSE 0 END"
			Set @sComma = ","
		End

		If @bIsDueDateApplicable = 1 and @pdtDateValue is not null
		Begin
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "EVENTDUEDATE = @pdtDateValue, 
					OCCURREDFLAG = 0"
			Set @sComma = ","
		End
		Else
		Begin
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "EVENTDATE = @pdtDateValue, 
					OCCURREDFLAG = 4"
			Set @sComma = ","
		End

		If @pnPeriodTypeOption is not null 
		and @pnPeriodTypeOption > 0
		and @psPeriodTypeKey in ('D', 'M', 'Y')
		Begin
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "PERIODTYPE = @psPeriodTypeKey"
			Set @sComma = ","
		End

		If @pnCountOption is not null 
		and @pnCountOption > 0
		Begin
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "ENTEREDDEADLINE = "
				+ "CASE WHEN @psPeriodTypeKey is not null THEN @pnCountValue ELSE NULL END"
			Set @sComma = ","
		End

		Set @sSQLString = @sUpdateString + @sWhereString

		exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnCaseKey				int,
				@nApplicableEvent		int,
				@nCycle					int,
				@pdtDateValue			datetime,
				@pdtOldDateValue		datetime,
				@psPeriodTypeKey		nchar(1),
				@pnCountValue			int',
				@pnCaseKey				= @pnCaseKey,		
				@nApplicableEvent		= @nApplicableEvent,
				@nCycle					= @nCycle,
				@pdtDateValue			= @pdtDateValue,
				@pdtOldDateValue		= @pdtOldDateValue,
				@psPeriodTypeKey		= @psPeriodTypeKey,
				@pnCountValue			= @pnCountValue
	End
	Else
	Begin
		-- insert the event				
		Set @sComma = ','
		
		Set @sSQLString = "Insert CASEEVENT(CASEID,EVENTNO,CYCLE"
		Set @sUpdateString = "values (@pnCaseKey,@nApplicableEvent,isnull(@nCycle,1)" 
		
		If @bIsDueDateApplicable = 1				
		Begin
			Set @sSQLString = @sSQLString + char(10) + @sComma + "DATEDUESAVED"
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + 
				"CASE WHEN @pdtDateValue is not null and @pdtDateValue <> @pdtOldDateValue THEN 1 ELSE 0 END"					
		End

		If @bIsDueDateApplicable = 1 and @pdtDateValue is not null
		Begin
			Set @sSQLString = @sSQLString +  char(10) + @sComma + "EVENTDUEDATE,OCCURREDFLAG"
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "@pdtDateValue,0"					
		End
		Else
		Begin
			Set @sSQLString = @sSQLString +  char(10) + @sComma + "EVENTDATE,OCCURREDFLAG"
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "@pdtDateValue,4"										
		End

		If @pnPeriodTypeOption is not null 
		and @pnPeriodTypeOption > 0
		and @psPeriodTypeKey in ('D', 'M', 'Y')
		Begin
			Set @sSQLString = @sSQLString +  char(10) + @sComma + "PERIODTYPE"
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + "@psPeriodTypeKey"
		End

		If @pnCountOption is not null 
		and @pnCountOption > 0
		Begin
			Set @sSQLString = @sSQLString +  char(10) + @sComma + "ENTEREDDEADLINE"
			Set @sUpdateString = @sUpdateString + char(10) + @sComma + 
				+ "CASE WHEN @psPeriodTypeKey is not null THEN @pnCountValue ELSE NULL END"
		End

		Set @sSQLString = @sSQLString + ')' + @sUpdateString + ')'

		exec @nErrorCode=sp_executesql @sSQLString,
	      	N'@pnCaseKey				int,
				@nApplicableEvent		int,
				@nCycle					int,
				@pdtDateValue			datetime,
				@pdtOldDateValue		datetime,
				@psPeriodTypeKey		nchar(1),
				@pnCountValue			int',
				@pnCaseKey				= @pnCaseKey,		
				@nApplicableEvent		= @nApplicableEvent,
				@nCycle					= @nCycle,
				@pdtDateValue			= @pdtDateValue,
				@pdtOldDateValue		= @pdtOldDateValue,
				@psPeriodTypeKey		= @psPeriodTypeKey,
				@pnCountValue			= @pnCountValue
	End

	-- prepare to publish the event details

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select " + char(10) 
		+"		@pnUpdatedEventEventKey = CE.EVENTNO," + char(10) 
		+"		@pnUpdatedEventCycle = CE.CYCLE," + char(10) 
		+"		@pdtUpdatedEventDate = @pdtDateValue," + char(10) 
		+"		@pbUpdatedEventIsDateDueSaved = CE.DATEDUESAVED," + char(10) 
		+"		@psUpdatedEventControllingAction = E.CONTROLLINGACTION," + char(10)
		+"		@pnUpdatedEventControllingCriteria = ISNULL(OA.CRITERIANO,EC.CRITERIANO)" + char(10)
		+"from CASEEVENT CE" + char(10) 
		+"left join EVENTS E on (E.EVENTNO = CE.EVENTNO)" + char(10) 
		+"left join EVENTCONTROL EC on (EC.EVENTNO = @nApplicableEvent)" + char(10) 
		+"left join OPENACTION OA on (OA.CASEID = @pnCaseKey and EC.CRITERIANO = OA.CRITERIANO and OA.LASTEVENT = EC.EVENTNO and OA.POLICEEVENTS = 1)" + char(10) 		
		+"where CE.CASEID = @pnCaseKey" + char(10) 
		+"and CE.EVENTNO = @nApplicableEvent" + char(10) 
		+"and CE.CYCLE = (select max(CE2.CYCLE) 
							from CASEEVENT CE2 
							where CE2.EVENTNO = CE.EVENTNO 
							and CE2.CASEID = CE.CASEID)" + char(10)
		+"order by OA.DATEUPDATED DESC"
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUpdatedEventEventKey		int output,
						@pnUpdatedEventCycle			int output,
						@pdtUpdatedEventDate			datetime output,
						@pbUpdatedEventIsDateDueSaved	bit output,
						@psUpdatedEventControllingAction		nvarchar(2) output,
						@pnUpdatedEventControllingCriteria		int output,
						@nApplicableEvent				int,
						@pnCaseKey		 				int,
						@pdtDateValue					datetime',
						@pnUpdatedEventEventKey			= @pnUpdatedEventEventKey output,
						@pnUpdatedEventCycle			= @pnUpdatedEventCycle output,
						@pdtUpdatedEventDate			= @pdtUpdatedEventDate output,
						@pbUpdatedEventIsDateDueSaved	= @pbUpdatedEventIsDateDueSaved output,
						@psUpdatedEventControllingAction = @psUpdatedEventControllingAction output,
						@pnUpdatedEventControllingCriteria = @pnUpdatedEventControllingCriteria output,
						@nApplicableEvent				= @nApplicableEvent,						  
						@pnCaseKey		 				= @pnCaseKey,
						@pdtDateValue					= @pdtDateValue

	End		
End

-- Generate Charges
If @nErrorCode = 0
and @pbProcessQuestion = 1
and (@nRowCount > 0 or (@nRowCount = 0 and @pbUserAcceptedRow = 1)) -- @nRowCount from insert/update of CaseChecklist
Begin

DECLARE @bChargeExists 		bit
DECLARE @bChargeAllDebtors 	bit
DECLARE @sRatesTempTable 	nvarchar(30)
DECLARE @nChargeRateNo		int
DECLARE @bRateNoExists		bit

set @bRateNoExists = 0

	If (@nYesRateNo is not null or @nNoRateNo is not null)
	Begin
		-- Pick the charge rate to use (Yes/No)
		Select @nChargeRateNo = case when @pbYesAnswer = 1 then cast(@nYesRateNo as nvarchar(11))
					when @pbNoAnswer = 1 then cast(@nNoRateNo as nvarchar(11)) end

		if (@nErrorCode = 0 and @nChargeRateNo is not null)
		Begin
			-- Create and Populate a Rate Nos TEMP TABLE
			Set @sRatesTempTable = '##Rates_' + Cast(@@SPID as nvarchar(30))
			
			If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sRatesTempTable )
			Begin 
				Set @sSQLString = 'DROP TABLE ' + @sRatesTempTable
			
				Exec @nErrorCode=sp_executesql @sSQLString
			End
			
			If @nErrorCode=0
			Begin
				Set @sSQLString = 'Create table ' + @sRatesTempTable + '(
						RATENO 		int NOT NULL,
						RATETYPE	int NULL)'
			
				Exec @nErrorCode=sp_executesql @sSQLString
			End

			-- Fill the Rates Temp Table
			exec @nErrorCode = 
				cs_GetRateNos
					@pnUserIdentityId	=@pnUserIdentityId,
					@psCulture		=@psCulture,
					@pnCaseKey		=@pnCaseKey,
					@pnChargeTypeNo		=@nChargeRateNo,
					@pnRatesTempTable	=@sRatesTempTable,
					@pbCalledFromCentura	=0

			-- Check if any rates were returned
			Set @sSQLString = "Select @bRateNoExists = case when exists(select 1 from " + @sRatesTempTable + " where RATENO IS NOT NULL) then 1 else 0 end"
	
			exec @nErrorCode = sp_executesql @sSQLString,
						N'@bRateNoExists	bit output',
						@bRateNoExists = @bRateNoExists output
		End
	End

	-- Request Charges
	If (@bRateNoExists = 1)
	Begin
		
		Set @bChargeAllDebtors = 0
		
		Set @sSQLString = "
			SELECT @bChargeAllDebtors = COLBOOLEAN 
			FROM SITECONTROL 
			WHERE CONTROLID = 'WIP Split Multi Debtor'"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@bChargeAllDebtors	bit OUTPUT',
				@bChargeAllDebtors = @bChargeAllDebtors OUTPUT
				
		
		Set @sSQLString = 
		"
		INSERT INTO ACTIVITYREQUEST(
		CASEID, SQLUSER, WHENREQUESTED, PROGRAMID, QUESTIONNO, ACTIVITYTYPE, ACTIVITYCODE, RATENO,
		PAYFEECODE, ESTIMATEFLAG, DIRECTPAYFLAG, ENTEREDQUANTITY, ENTEREDAMOUNT, EMPLOYEENO, 
		[ACTION], PROCESSED, TRANSACTIONFLAG, LETTERDATE, PRODUCTCODE, CHECKLISTTYPE, 
		SEPARATEDEBTORFLAG, DEBTOR, BILLPERCENTAGE,IDENTITYID)
		
		SELECT @pnCaseKey, SYSTEM_USER, GETDATE(), 'WorkBnch', @pnQuestionKey, 32, 3202, RATES.RATENO, 
		CLI.PAYFEECODE, CLI.ESTIMATEFLAG, CLI.DIRECTPAYFLAG, @pnCountValue, @pnAmountValue, @pnStaffNameKey, 
		@psOpenAction, 0, 0, isnull(@pdtDateValue, getdate()), null, @pnChecklistTypeKey, 
		@bChargeAllDebtors, CN.DEBTOR, CN.BILLPERCENTAGE, @pnUserIdentityId
		FROM " + @sRatesTempTable + " AS RATES 
			left join ACTIONS AS ACTIONS on (ACTIONS.ACTION = @psOpenAction)
			left join CHECKLISTS AS CL on (CL.CHECKLISTTYPE = @pnChecklistTypeKey)"
			
		if (@bChargeAllDebtors = 1)
		Begin
			-- return all debtors
			Set @sSQLString = @sSQLString + char(10) + "CROSS JOIN (SELECT CNX.NAMENO as DEBTOR, CNX.BILLPERCENTAGE, CNX.NAMETYPE
											FROM CASENAME CNX
											WHERE CNX.CASEID = @pnCaseKey
											AND CNX.NAMETYPE IN ('D','Z')) AS CN"
		END
		ELSE
		BEGIN
			-- return a row with null debtors so it's not set in ACTIVITYREQUEST
			Set @sSQLString = @sSQLString + "CROSS JOIN (SELECT NULL AS DEBTOR, NULL AS BILLPERCENTAGE, NULL AS NAMETYPE) AS CN"
		END
		
		Set @sSQLString = @sSQLString + char(10) + "LEFT JOIN CHECKLISTITEM CLI on (CLI.CRITERIANO = @pnChecklistCriteriaKey
																					AND CLI.QUESTIONNO = @pnQuestionKey)
													WHERE 1=1"

		if (@pbProduceChargeEvenIfExists != 1)
		Begin
			-- Exclude charges already included
			Set @sSQLString = @sSQLString + char(10) + "AND RATES.RATENO NOT IN (SELECT RATENO
								FROM ACTIVITYREQUEST 
								WHERE CASEID = @pnCaseKey
								and RATENO IS NOT NULL)"
		End
		
		if (@bChargeAllDebtors = 1)
		Begin
			-- filter for non-renewal or renewal debtor
			Set @sSQLString = @sSQLString + char(10) + "AND
									CN.NAMETYPE =	CASE 
													WHEN exists (select * from CASENAME WHERE NAMETYPE = 'Z' AND CASEID = @pnCaseKey)
														AND
														(RATES.RATETYPE = 1601
														OR (RATES.RATETYPE IS NULL AND ACTIONS.ACTIONTYPEFLAG = 1)
														OR (RATES.RATETYPE IS NULL AND ACTIONS.ACTION IS NULL AND CL.CHECKLISTTYPEFLAG = 1))
													THEN 'Z'
													ELSE 'D'
													END" + CHAR(10) 
		END

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey		int, 
			@pnQuestionKey		int, 
			@pnCountValue 		int, 
			@pnAmountValue		decimal(11,2), 
			@pnStaffNameKey		int, 
			@pdtDateValue		datetime, 
			@pnChecklistTypeKey	int, 
			@bChargeAllDebtors	bit,
			@pnChecklistCriteriaKey	int,
			@pnUserIdentityId       int,
			@psOpenAction		nvarchar(2)',
			@pnCaseKey = @pnCaseKey,
			@pnQuestionKey = @pnQuestionKey,
			@pnCountValue = @pnCountValue,
			@pnAmountValue = @pnAmountValue,
			@pnStaffNameKey = @pnStaffNameKey,
			@pdtDateValue = @pdtDateValue,
			@pnChecklistTypeKey = @pnChecklistTypeKey,
			@bChargeAllDebtors = @bChargeAllDebtors,
			@pnChecklistCriteriaKey = @pnChecklistCriteriaKey,
			@pnUserIdentityId = @pnUserIdentityId,
			@psOpenAction = @psOpenAction
			
		if (@nErrorCode = 0 and @bChargeAllDebtors = 1)
		Begin
			-- Clear the split wip fields if only generating for one debtor.
			Set @sSQLString = 
				"update ACTIVITYREQUEST
				SET SEPARATEDEBTORFLAG = NULL, DEBTOR = NULL, BILLPERCENTAGE = NULL
				WHERE BILLPERCENTAGE = 100
				AND CASEID = @pnCaseKey
				AND QUESTIONNO = @pnQuestionKey
				AND EMPLOYEENO = @pnStaffNameKey
				AND [ACTION] = @psOpenAction
				AND CHECKLISTTYPE = @pnChecklistTypeKey
				AND IDENTITYID = @pnUserIdentityId
				AND SEPARATEDEBTORFLAG = 1
				AND ACTIVITYTYPE = 32
				AND ACTIVITYCODE = 3202
				AND PROCESSED = 0
				AND TRANSACTIONFLAG = 0"
				
			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int, 
				@pnQuestionKey			int, 
				@pnStaffNameKey			int,
				@psOpenAction			nvarchar(2),
				@pnChecklistTypeKey		int,
				@pnUserIdentityId       int',
				@pnCaseKey = @pnCaseKey,
				@pnQuestionKey = @pnQuestionKey,
				@pnStaffNameKey = @pnStaffNameKey,
				@psOpenAction = @psOpenAction,
				@pnChecklistTypeKey = @pnChecklistTypeKey,
				@pnUserIdentityId = @pnUserIdentityId
		End
	End

	-- Drop the rates temp table
	If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sRatesTempTable )
	Begin 
		Set @sSQLString = 'DROP TABLE ' + @sRatesTempTable
	
		Exec @nErrorCode=sp_executesql @sSQLString
	End
End -- Generate Charges


-- Generate Letters
If @nErrorCode = 0
and @pbProcessQuestion = 1
and (@nRowCount > 0 or (@nRowCount = 0 and @pbUserAcceptedRow = 1)) -- @nRowCount from insert/update of CaseChecklist
Begin
	If (@bYesNoAnswer is not null)
	Begin
			exec @nErrorCode = 
				csw_GenerateChecklistLetters
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnCaseKey = @pnCaseKey,
					@pnChecklistTypeKey = @pnChecklistTypeKey,
					@pnScreenCriteriaKey = @pnScreenCriteriaKey,
					@pnChecklistCriteriaKey = @pnChecklistCriteriaKey,
					@pnQuestionKey = @pnQuestionKey,
					@pbYesNoValue = @bYesNoAnswer,
					@pdtDateValue = @pdtDateValue,
					@pnStaffNameKey = @pnStaffNameKey,
					@pbProduceLetterEvenIfExists = @pbProduceLetterEvenIfExists
	
	End
End -- Generate Letters


If @nErrorCode = 0
Begin
	-- publish values to data adapter
	Select	@pnUpdatedEventEventKey			as UpdatedEventEventKey,
			@pnUpdatedEventCycle			as UpdatedEventCycle,
			@pdtUpdatedEventDate			as UpdatedEventDate,
			@pbUpdatedEventIsDateDueSaved	as UpdatedEventIsDateDueSaved,
			@psUpdatedEventControllingAction as UpdatedEventControllingAction,
			@pnUpdatedEventControllingCriteria as UpdatedEventControllingCriteria

End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainChecklistData to public
GO
