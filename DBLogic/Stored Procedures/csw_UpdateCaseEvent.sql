-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCaseEvent									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCaseEvent.'
	Drop procedure [dbo].[csw_UpdateCaseEvent]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCaseEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnEventKey			int,		-- Mandatory
	@pnEventCycle			smallint,	-- Mandatory
	@pdtEventDate			datetime	= null,
	@pdtEventDueDate		datetime	= null,
	@pnEventTextType		smallint	= null,
	@ptEventText			nvarchar(max)	= null,
	@pnPeriod			smallint	= null,
	@psPeriodTypeKey		nchar(1)	= null,
	@psCreatedByActionCode		nvarchar(2)	= null,
	@pnCreatedByCriteriaKey		int		= null,
	@pnSendMethodKey		int		= null,
	@pdtSendDate			datetime	= null,
	@pdtReceiptDate			datetime	= null,
	@psReference			nvarchar(50)	= null,
	@pnStaffKey			int		= null,
	@pnDisplayOrder			int		= null,
	@pnPolicingBatchNo		int		= null,
	@psResponsibleNameTypeKey	nvarchar(6)	= null,
	@pnFromCaseKey			int		= null,
	@pbIsStopPolicing		bit		= null,
	@pnDueDateRespKey			int	=	null,
	@pbOldIsStopPolicing		int		= null,
	@pbIsEventKeyInUse		bit 		= 0,
	@pbIsEventCycleInUse		bit 		= 0,
	@pbIsEventDateInUse		bit 		= 0,
	@pbIsEventDueDateInUse		bit 		= 0,
	@pbIsEventTextInUse		bit 		= 0,
	@pbIsPeriodInUse		bit		= 0,
	@pbIsPeriodTypeKeyInUse		bit		= 0,
	@pbIsCreatedByActionCodeInUse	bit 		= 0,
	@pbIsCreatedByCriteriaKeyInUse	bit 		= 0,
	@pbIsSendMethodKeyInUse		bit 		= 0,
	@pbIsSendDateInUse		bit 		= 0,
	@pbIsReceiptDateInUse		bit 		= 0,
	@pbIsReferenceInUse		bit 		= 0,
	@pbIsPolicingBatchNoInUse	bit 		= 0,
	@pbIsStaffKeyInUse		bit		= 0,
	@pbIsDisplayOrderInUse		bit		= 0,
	@pbIsResponsibleNameTypeKeyInUse bit		= 0,
	@pbIsFromCaseKeyInUse		bit		= 0,
	@pbIsStopPolicingInUse		bit		= 0,
	@pbIsDueDateRespKeyInUse	bit		= 0	
)
as
-- PROCEDURE:	csw_UpdateCaseEvent
-- VERSION:	27
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseEvent if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 10 May 2006	AU	RFC3866		1	Procedure created
-- 15 JAN 2008	SF	RFC5708		2	Update to include more parameters
-- 11 FEB 2008	SF	RFC6197		3 	Do not update DISPLAYORDER if it is more than 9001 (9999 is generated for UI in Docketing Wizard)
-- 11 Nov 2008	SF	RFC3392		4	Added Period and PeriodTypeKey parameters, enlarged CreatedByActionCode field.
-- 12 Nov 2008	SF	RFC3392		5	Backout field length change.
-- 4 Dec 2008	SF	RFC3392		6	Fix incorrect RFC number
-- 8 Sep 2009	KR	RFC6950		7	Added DUEDATERESPNAMETYPE and FROMCASEID to the update
-- 10 Sep 2009	SF	RFC7631		8	Make sure FROMCASEID parameters are nullable
-- 14 Feb 2011	AT	RFC10034	9	Added IsStopPolicing logic.
-- 01 Mar 2011	AT	RFC10034	10	Fixed bug processing stop policing flag when null.
-- 22 Jul 2011	MF	RFC10972	11	If the EVENTDATE is being cleared out then the OCCURREDFLAG must be set to 0 to indicate that the
--						CaseEvent may be recalculated or deleted.
-- 06 Sep 2011  DV      RFC11012       	12      Revert the code added in RFC10972 as it was an interim solution for scenarion where @pbIsStopPolicing 
--						was incorrectly being set to 1 even after the Event Date was cleared.
-- 25 Jan 2012	MF	RFC11817	13	Set the @nOccurredFlag to 1 if there is an EventDate. This was not being set if the EventDate had not changed
--						and as a result the TypeOfRequest written to Policing was incorrectly set to a value of 2 instead of 3.
-- 11 Dec 2012	LP	RFC12830	14	Allow setting of OCCURREDFLAG to 0 (False) if Stop Policing is manually set to Off.
-- 27 Feb 2013	LP	RFC13253	15	OCCURREDFLAG must be TRUE as long as there is an EVENTDATE, regardless of @pbIsStopPolicing parameter.
-- 18 Apr 2013	LP	RFC13415	16	Event Text will now be recorded in the EVENTLONGTEXT, setting ISLONGFLAG = TRUE.
-- 25 Jun 2013	MF	RFC13602	17	When @pbIsStopPolicing=1 we need to ensure the @nOccurredFlag gets set to 1 and the TypeOfRequest for Policing to 3.
--						When @pbIsStopPolicing is cleared or set to 0 when it previously was set to 1 then the OccurredFlag is set to 0 and due date recalculated
--						by setting TypeOfRequest for Policing to 6.
-- 17 Dec 2013  MS      R28198          18      Fix OldEventText check to use fn_IsNtextEqual
-- 08 Apr 2014	MS	R31303		19	Check LogDateTimeStamp for concurrency and remove unnecessary old parameters
-- 07 Oct 2014	MF	R40077		20	Type Of Request for POLICING not being set correctly to value 2 when the EventDate is cleared out and the Due Date is manually entered at the same time.
-- 21 Oct 2014	MF	R40507		21	If the entered Period against a CaseEvent is changed the DATEDUESAVED is getting set to 1 and as a result the Due Date is not recalcuated.
-- 11 Nov 2014	MF	R40781		22	When updating a CASEEVENT the EVENTDUEDATE may be provided along with the EVENTDATE.  If the DATEDUESAVED was not previously set
--						to 1 then it should only be set if the date provided is different to what already existed.
-- 02 Mar 2015	MS	R43203		23	Added @pnEventTextType parameter and insert EventText into CASEEVENTTEXT and EVENTTEXT tables
-- 10 Sep 2015	MF	R51906		24	This is a revisit of RFC40781.  The code was incorrectly clearing EVENTDUEDATE whenever EVENTDATE is set.  This introduced an inconsistency in behaviour.
-- 03 Oct 2016	MF	69013		25	Need to take into consideration if EventText is being shared with other CASEEVENT rows.  If so this can cause the system to think that the CASEEVENT
--						row has been updated since this transaction began and as a result throw a concurrency error. To get around this we can compare the LOGTRANSACTIONNO
--						against what is currently set for the current process (@@SPID).
-- 23 Nov 2016	DV	R62369		25	Remove concurrency check when updating case events
-- 12 May 2017	MF	71074		26	If the Period amount or the Period Type is changed then this implies that the user wishes to recalculate the due date.  
--						As such, the system should cause Policing to be raised with a TypeOfRequest of 2 which will trigger the recalculation (consistent with client/server).
-- 13 Mar 2019	DV	DR26323		27	Fixed issue where DueDateResp field was not visible even when configured

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(MAX)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)
Declare @nOccurredFlag 	decimal(1,0)
Declare @nTypeOfRequest tinyint
Declare @nRowCount	int
Declare @bEventDateExists bit
Declare @bRunPolicing	bit
Declare @nRowCountEventText int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @bEventDateExists = 0
Set @bRunPolicing = 0

If @nErrorCode = 0
Begin
	-- Check whether policing is required or not
	Set @sSQLString = "
			Select @bRunPolicing = 1 ,
			       @nTypeOfRequest = CASE WHEN(ENTEREDDEADLINE<>@pnPeriod        and @pnPeriod        is not null) THEN 2
						      WHEN(ENTEREDDEADLINE is null           and @pnPeriod        is not null) THEN 2	
						      WHEN(PERIODTYPE     <>@psPeriodTypeKey and @psPeriodTypeKey is not null) THEN 2
						      WHEN(PERIODTYPE      is null           and @psPeriodTypeKey is not null) THEN 2
						      ELSE NULL
						 END
			from CASEEVENT CE
			where 	CE.CASEID  = @pnCaseKey
			and 	CE.EVENTNO = @pnEventKey
			and 	CE.CYCLE   = @pnEventCycle
			and	((@pbIsEventDateInUse                = 1 and CE.EVENTDATE           <> @pdtEventDate)
				or (@pbIsEventDueDateInUse           = 1 and CE.EVENTDUEDATE        <> @pdtEventDueDate)
				or (@pbIsCreatedByActionCodeInUse    = 1 and CE.CREATEDBYACTION     <> @psCreatedByActionCode)
				or (@pbIsCreatedByCriteriaKeyInUse   = 1 and CE.CREATEDBYCRITERIA   <> @pnCreatedByCriteriaKey)
				or (@pbIsResponsibleNameTypeKeyInUse = 1 and CE.DUEDATERESPNAMETYPE <> @psResponsibleNameTypeKey)
				or (@pbIsPeriodInUse                 = 1 and @pbIsPeriodTypeKeyInUse =1 
				                                         and (CE.ENTEREDDEADLINE    <> @pnPeriod or CE.PERIODTYPE <> @psPeriodTypeKey))
				or (@pbIsStopPolicingInUse           = 1 and @pbIsStopPolicing      <> @pbOldIsStopPolicing))"


	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@bRunPolicing			bit		output,
		        @nTypeOfRequest			tinyint		output,
			@pnCaseKey			int,
			@pnEventKey			int,
			@pnEventCycle			smallint,
			@pdtEventDate			datetime,
			@pdtEventDueDate		datetime,
			@pnPeriod			smallint,
			@psPeriodTypeKey		nchar(1),
			@psCreatedByActionCode		nvarchar(2),
			@pnCreatedByCriteriaKey		int,
			@psResponsibleNameTypeKey	nvarchar(6),
			@pbIsStopPolicing		bit,
			@pbOldIsStopPolicing		bit,
			@pbIsEventKeyInUse		bit,
			@pbIsEventCycleInUse		bit,
			@pbIsEventDateInUse		bit,
			@pbIsEventDueDateInUse		bit,
			@pbIsCreatedByActionCodeInUse	bit,
			@pbIsCreatedByCriteriaKeyInUse	bit,
			@pbIsResponsibleNameTypeKeyInUse bit,
			@pbIsPeriodInUse		bit,
			@pbIsPeriodTypeKeyInUse		bit,
			@pbIsStopPolicingInUse		bit',
			@bRunPolicing			= @bRunPolicing		output,
			@nTypeOfRequest			= @nTypeOfRequest	output,
			@pnCaseKey	 		= @pnCaseKey,
			@pnEventKey	 		= @pnEventKey,
			@pnEventCycle	 		= @pnEventCycle,
			@pdtEventDate	 		= @pdtEventDate,
			@pdtEventDueDate	 	= @pdtEventDueDate,
			@pnPeriod			= @pnPeriod,
			@psPeriodTypeKey		= @psPeriodTypeKey,
			@psCreatedByActionCode	 	= @psCreatedByActionCode,
			@pnCreatedByCriteriaKey	 	= @pnCreatedByCriteriaKey,
			@psResponsibleNameTypeKey 	= @psResponsibleNameTypeKey,
			@pbIsStopPolicing		= @pbIsStopPolicing,
			@pbOldIsStopPolicing		= @pbOldIsStopPolicing,
			@pbIsEventKeyInUse		= @pbIsEventKeyInUse,
			@pbIsEventCycleInUse		= @pbIsEventCycleInUse,
			@pbIsEventDateInUse		= @pbIsEventDateInUse,
			@pbIsEventDueDateInUse		= @pbIsEventDueDateInUse,
			@pbIsCreatedByActionCodeInUse	= @pbIsCreatedByActionCodeInUse,
			@pbIsCreatedByCriteriaKeyInUse	= @pbIsCreatedByCriteriaKeyInUse,
			@pbIsResponsibleNameTypeKeyInUse = @pbIsResponsibleNameTypeKeyInUse,
			@pbIsPeriodInUse		= @pbIsPeriodInUse,
			@pbIsPeriodTypeKeyInUse		= @pbIsPeriodTypeKeyInUse,
			@pbIsStopPolicingInUse		= @pbIsStopPolicingInUse
End

If @nErrorCode = 0 and exists (Select 1 from CASEEVENT where CASEID = @pnCaseKey and EVENTNO = @pnEventKey
						and CYCLE 	= @pnEventCycle)
Begin
	Set @sUpdateString = "
	Update CE
	Set "

	Set @sWhereString = "
	From CASEEVENT CE 
	Where CE.CASEID 	= @pnCaseKey
	and   CE.EVENTNO = @pnEventKey
	and   CE.CYCLE 	= @pnEventCycle"

	-- When Event Date has been updated
	If @pbIsEventDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EVENTDATE = @pdtEventDate"
		Set @sComma = ","
		-- Event Date has been entered
		If @pdtEventDate is not null OR @pbIsStopPolicing=1
		Begin
			Set @nOccurredFlag = 1
			Set @bEventDateExists = 1			
		End
		Else
		-- Event Date has been cleared
		Begin
			Set @nOccurredFlag = 0
		End
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OCCURREDFLAG = @nOccurredFlag"

	End
	-- Event Date not updated but a value exists
	-- Ensure that OCCURREDFLAG is TRUE
	Else If (@pbIsEventDateInUse = 0 
		and @pdtEventDate is not null)
	Begin
		Set @nOccurredFlag = 1
		Set @bEventDateExists = 1
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OCCURREDFLAG = @nOccurredFlag"
	End

	-- When Stop Police checkbox updated AND Event Date was not entered or updated
	-- OCCURREDFLAG should always be TRUE if Event Date exists
	If (@pbIsStopPolicingInUse = 1
		and @pbIsEventDateInUse = 0 
		and @bEventDateExists = 0)
	Begin
		Set @nOccurredFlag = 1
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OCCURREDFLAG = @nOccurredFlag"
	End	
	
	If @pbIsEventDueDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EVENTDUEDATE = @pdtEventDueDate"
		Set @sComma = ","
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DATEDUESAVED = CASE WHEN(@pdtEventDueDate is null) THEN 0"
		                                   +CHAR(10)+        "                    WHEN(@pdtEventDueDate =EVENTDUEDATE) THEN DATEDUESAVED"
		                                   +CHAR(10)+        "                    WHEN(@pdtEventDueDate<>EVENTDUEDATE OR EVENTDUEDATE is null) THEN 1 ELSE 0 END"
	End

	If @pbIsPeriodInUse		= 1 
	and @pbIsPeriodTypeKeyInUse =1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ENTEREDDEADLINE  = @pnPeriod, PERIODTYPE = @psPeriodTypeKey"
		Set @sComma = ","
	End

	If @pbIsCreatedByActionCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CREATEDBYACTION = @psCreatedByActionCode"
		Set @sComma = ","
	End

	If @pbIsCreatedByCriteriaKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CREATEDBYCRITERIA = @pnCreatedByCriteriaKey"
		Set @sComma = ","
	End
	
	If @pbIsSendMethodKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SENDMETHOD = @pnSendMethodKey"
		Set @sComma = ","
	End
	
	If @pbIsSendDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SENTDATE = @pdtSendDate"
		Set @sComma = ","
	End
	
	If @pbIsReceiptDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RECEIPTDATE = @pdtReceiptDate"
		Set @sComma = ","
	End
	
	If @pbIsReferenceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RECEIPTREFERENCE = @psReference"
		Set @sComma = ","
	End
	
	If @pbIsStaffKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EMPLOYEENO = @pnStaffKey"
		Set @sComma = ","
	End
	
	If @pbIsDisplayOrderInUse = 1
	Begin
	
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DISPLAYORDER = CASE WHEN isnull(@pnDisplayOrder,9001) > 9000 THEN DISPLAYORDER ELSE @pnDisplayOrder END"
		/* display order is not essential in concurrency check but cannot insert 9999 which is typically generated for UI  */
		Set @sComma = ","
	End

	If @pbIsResponsibleNameTypeKeyInUse = 1
	Begin
	
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DUEDATERESPNAMETYPE = @psResponsibleNameTypeKey"
		Set @sComma = ","
	End

	If @pbIsFromCaseKeyInUse = 1
	Begin
	
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FROMCASEID = @pnFromCaseKey"
		Set @sComma = ","
	End

	If @pbIsDueDateRespKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EMPLOYEENO = @pnDueDateRespKey"
		Set @sComma = ","	
	End


	Set @sSQLString = @sUpdateString + @sWhereString
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey			int,
			@pnEventKey			int,
			@pnEventCycle			smallint,
			@pdtEventDate			datetime,
			@nOccurredFlag			decimal(1,0),
			@pdtEventDueDate		datetime,			
			@pnPeriod			smallint,
			@psPeriodTypeKey		nchar(1),
			@psCreatedByActionCode		nvarchar(2),
			@pnCreatedByCriteriaKey		int,
			@pnSendMethodKey		int,
			@pdtSendDate			datetime,
			@pdtReceiptDate			datetime,
			@psReference			nvarchar(50),
			@pnStaffKey			int,
			@pnDisplayOrder			int,
			@pnPolicingBatchNo		int,
			@psResponsibleNameTypeKey	nvarchar(6),
			@pnFromCaseKey			int,
			@pnDueDateRespKey		int',
			@pnCaseKey	 		= @pnCaseKey,
			@pnEventKey	 		= @pnEventKey,
			@pnEventCycle	 		= @pnEventCycle,
			@pdtEventDate	 		= @pdtEventDate,
			@nOccurredFlag			= @nOccurredFlag,
			@pdtEventDueDate	 	= @pdtEventDueDate,			
			@pnPeriod			= @pnPeriod,
			@psPeriodTypeKey		= @psPeriodTypeKey,
			@psCreatedByActionCode	 	= @psCreatedByActionCode,
			@pnCreatedByCriteriaKey	 	= @pnCreatedByCriteriaKey,
			@pnSendMethodKey		= @pnSendMethodKey,
			@pdtSendDate			= @pdtSendDate,
			@pdtReceiptDate			= @pdtReceiptDate,
			@psReference			= @psReference,					  
			@pnStaffKey			= @pnStaffKey,
			@pnDisplayOrder			= @pnDisplayOrder,
			@pnPolicingBatchNo		= @pnPolicingBatchNo,
			@psResponsibleNameTypeKey	= @psResponsibleNameTypeKey,
			@pnFromCaseKey			= @pnFromCaseKey,
			@pnDueDateRespKey		= @pnDueDateRespKey

	Set @nRowCount = @@RowCount

	If @nErrorCode = 0 and @pbIsEventTextInUse = 1
	Begin
		exec @nErrorCode = csw_UpdateEventText
			@nRowCount		= @nRowCountEventText	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnEventCycle		= @pnEventCycle,
			@pnEventTextType	= @pnEventTextType,
			@ptEventText		= @ptEventText
	End

	If @nErrorCode = 0 and (@nRowCount > 0 or @nRowCountEventText > 0) and ISNULL(@bRunPolicing,0) = 1	
	Begin
		-- (3) Police Occurred Event, (2) Police Due Event, (6) Recalculate Due Date
		Set @nTypeOfRequest = CASE WHEN( @nTypeOfRequest=2) THEN 2
					   WHEN(@nOccurredFlag = 1) THEN 3 
					   WHEN(@pdtEventDueDate is not null and ISNULL(@pbIsStopPolicing,0)=0) THEN 2 -- police manually entered due date
					   WHEN(@pbOldIsStopPolicing=1       and ISNULL(@pbIsStopPolicing,0)=0) THEN 6 -- recalculate due date
					   ELSE 2
		                      END

		exec @nErrorCode = ipw_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnCycle		= @pnEventCycle,
			@psAction		= @psCreatedByActionCode,
			@pnCriteriaNo		= @pnCreatedByCriteriaKey,
			@pnTypeOfRequest	= @nTypeOfRequest,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCaseEvent to public
GO