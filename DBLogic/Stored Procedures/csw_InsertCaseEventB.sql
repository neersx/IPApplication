-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseEventB									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseEventB]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseEventB.'
	Drop procedure [dbo].[csw_InsertCaseEventB]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseEventB...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertCaseEventB
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey				int,		-- Mandatory.
	@pnEventKey				int,		-- Mandatory.
	@pnEventCycle				smallint,	-- Mandatory.
	@pdtEventDate				datetime	= null,
	@pdtEventDueDate			datetime	= null,
	@pnEventTextType			smallint	= null,
	@ptEventText				nvarchar(max)	= null,
	@pnPeriod				smallint	= null,
	@psPeriodTypeKey			nchar(1)	= null,
	@psCreatedByActionCode			nvarchar(2)	= null,
	@pnCreatedByCriteriaKey			int		= null,
	@pnPolicingBatchNo			int		= null,
	@pnStaffKey				int		= null,
	@psResponsibleNameTypeKey		nvarchar(6)	= null,
	@pbIsStopPolicing			bit		= null,
	@pnFromCaseKey				int		= null,
	@pbIsEventKeyInUse			bit		= 0,
	@pbIsEventCycleInUse			bit		= 0,
	@pbIsEventDateInUse			bit		= 0,
	@pbIsEventDueDateInUse			bit		= 0,
	@pbIsEventTextInUse			bit		= 0,
	@pbIsPeriodInUse			bit		= 0,
	@pbIsPeriodTypeKeyInUse 		bit		= 0,
	@pbIsCreatedByActionCodeInUse		bit	 	= 0,
	@pbIsCreatedByCriteriaKeyInUse		bit	 	= 0,
	@pbIsPolicingBatchNoInUse		bit	 	= 0,
	@pbIsStaffKeyInUse			bit	 	= 0,
	@pbIsResponsibleNameTypeKeyInUse	bit	 	= 0,
	@pbIsFromCaseKeyInUse			bit	 	= 0,
	@pbIsStopPolicingInUse			bit		= 0
)
as
-- PROCEDURE:	csw_InsertCaseEventB
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CaseEvent.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 10 May 2006	AU	RFC3866		1	Procedure created
-- 11 Nov 2008	SF	RFC3392		2	Added Period and PeriodTypeKey parameters, enlarged CreatedByActionCode field.
-- 12 Nov 2008	SF	RFC3392		3	Back out field length change
-- 4 Dec 2008	SF	RFC3392		4	Fix incorrect RFC number
-- 5 Sep 2009	KR	RFC6950		5	Added extra columns to the insert EMPLOYEENO, DUEDATERESPNAMETYPE and FROMCASEID
-- 14 Feb 2011	AT	RFC10034	6	Add stop policing processing.
-- 01 Mar 2011	AT	RFC10034	7	Fixed bug processing stop policing flag when null.
-- 20 Sep 2011	LP	R10812		8	Inline editing of events
-- 15 Feb 2012	SF	R11943		9	Correct syntax error caused by version 8
-- 19 Feb 2012	MF	RFC11957	10	Safeguard against a duplicate key error.
-- 18 Apr 2013	LP	R13415		11	Record Event Text as EVENTLONGTEXT
-- 02 Mar 2015	MS	R43203		12	Added @pnEventTextType parameter and insert EventText into CASEEVENTTEXT and EVENTTEXT tables
-- 29 Sep 2016	MF	69013		13	Need to take into consideration if EventText is being shared with other CASEEVENT rows.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @nOccurredFlag 	decimal(1,0)
Declare @nDateDueSaved 	decimal(1,0)
Declare @bLongFlag 	bit
Declare @tEventText 	nvarchar(254)
Declare @nTypeOfRequest tinyint
Declare @nRowCount	int

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("
Set @bLongFlag = 1

If @nErrorCode = 0
-- RFC11957
and not exists(	select 1 from CASEEVENT
		where CASEID =@pnCaseKey
		and   EVENTNO=@pnEventKey
		and   CYCLE  =@pnEventCycle)
Begin
	Set @sInsertString = "Insert into CASEEVENT ("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"CASEID"

	Set @sValuesString = @sValuesString+CHAR(10)+"@pnCaseKey"

	If @pbIsEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEventKey"
	End

	If @pbIsEventCycleInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CYCLE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEventCycle"
	End

	If @pbIsEventDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EVENTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtEventDate"
	End
	
	-- If stop policing checkbox ticked then raise event as occurred.
	If (@pbIsStopPolicingInUse = 1 and @pbIsStopPolicing = 1)
	Begin	
		Set @nOccurredFlag = 1
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"OCCURREDFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@nOccurredFlag"
	End
	Else
	Begin
		Set @nOccurredFlag = case when @pbIsEventDateInUse = 1 and @pdtEventDate is not null then 1 else 0 end
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"OCCURREDFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@nOccurredFlag"
	End

	If @pbIsEventDueDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EVENTDUEDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtEventDueDate"
	End

	Set @nDateDueSaved = case when @pbIsEventDueDateInUse = 1 and @pdtEventDueDate is not null then 1 else 0 end
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DATEDUESAVED"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@nDateDueSaved"	

	If @pbIsCreatedByActionCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CREATEDBYACTION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCreatedByActionCode"
	End

	If @pbIsCreatedByCriteriaKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CREATEDBYCRITERIA"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCreatedByCriteriaKey"
	End

	If @pbIsPeriodInUse = 1
	and @pbIsPeriodTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ENTEREDDEADLINE, PERIODTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPeriod,@psPeriodTypeKey"
	End

	If @pbIsStaffKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EMPLOYEENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStaffKey"
	End

	If @pbIsResponsibleNameTypeKeyInUse = 1
	and (datalength(@psResponsibleNameTypeKey) > 0 or @psResponsibleNameTypeKey is null)
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DUEDATERESPNAMETYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psResponsibleNameTypeKey"
	End

	If @pbIsFromCaseKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FROMCASEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnFromCaseKey"
	End
	
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString
	
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey		int,
			@pnEventKey		int,
			@pnEventCycle		smallint,
			@pdtEventDate		datetime,
			@nOccurredFlag		decimal(1,0),
			@pdtEventDueDate	datetime,
			@nDateDueSaved		decimal(1,0),
			@bLongFlag		bit,			
			@pnPeriod				smallint,
			@psPeriodTypeKey		nchar(1),
			@psCreatedByActionCode	nvarchar(2),
			@pnCreatedByCriteriaKey	int,
			@pnPolicingBatchNo	int,
			@pnStaffKey			int,
			@psResponsibleNameTypeKey	nvarchar(6),
			@pnFromCaseKey		int',
			@pnCaseKey	 	= @pnCaseKey,
			@pnEventKey	 	= @pnEventKey,
			@pnEventCycle	 	= @pnEventCycle,
			@pdtEventDate		= @pdtEventDate,
			@nOccurredFlag		= @nOccurredFlag,
			@pdtEventDueDate	= @pdtEventDueDate,
			@nDateDueSaved		= @nDateDueSaved,
			@bLongFlag		= @bLongFlag,
			@pnPeriod		= @pnPeriod,
			@psPeriodTypeKey = @psPeriodTypeKey,			
			@psCreatedByActionCode	= @psCreatedByActionCode,
			@pnCreatedByCriteriaKey	= @pnCreatedByCriteriaKey,
			@pnPolicingBatchNo	= @pnPolicingBatchNo,
			@pnStaffKey			= @pnStaffKey,
			@psResponsibleNameTypeKey = @psResponsibleNameTypeKey,
			@pnFromCaseKey		= @pnFromCaseKey

	Set @nRowCount = @@RowCount

	If @nErrorCode = 0 and @pbIsEventTextInUse = 1 and @nRowCount > 0
	Begin	
		exec @nErrorCode = csw_UpdateEventText		
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnEventCycle		= @pnEventCycle,
			@pnEventTextType	= @pnEventTextType,
			@ptEventText		= @ptEventText
	End

	If @nErrorCode = 0
	Begin
		-- (3) Police Occurred Event, (2) Police Due Event
		Set @nTypeOfRequest = case when @nOccurredFlag = 1 then 3 else 2 end
		
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

Grant execute on dbo.csw_InsertCaseEventB to public
GO