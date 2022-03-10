-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure dbo.csw_InsertCaseEvent.'
	drop procedure [dbo].[csw_InsertCaseEvent]
	print '**** Creating Stored Procedure dbo.csw_InsertCaseEvent...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE procedure dbo.csw_InsertCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,  	-- the language in which output is to be expressed
	@pnCaseKey			int, 		-- Mandatory
	@pnEventKey			int,		-- Mandatory
	@pnCycle			smallint,	-- Mandatory
	@pdtEventDueDate		datetime	= null,
	@pdtEventDate			datetime	= null,
	@pbIsStopPolicing		bit		= null,
	@pnPeriod			smallint	= null,
	@psPeriodTypeKey		nchar(1)	= null,
	@ptEventText			nvarchar(max)	= null,
	@psCreatedByActionKey		nvarchar(2) 	= null,
	@pnCreatedByCriteriaKey		int 		= null,
	@pnSendMethodKey		int		= null,
	@pdtSendDate			datetime	= null,
	@pdtReceiptDate			datetime	= null,
	@psReference			nvarchar(50)	= null,
	@pnStaffKey			int		= null,
	@pnDisplayOrder			int		= null,
	@pnPolicingBatchNo		int 		= null,
	@pbIsPolicedEvent 		bit 		= 1,	-- Some events (e.g. date last changed) are not policed
	@pbOnHold			bit		= null,	-- When not null, indicates that the policing request is to be placed on hold. If null, the On Hold status is determined from the @pnPolicingBatchNo.	
	@pnEventTextType		smallint	= null
)
AS
-- PROCEDURE :	csw_InsertCaseEvent
-- VERSION :	8
-- DESCRIPTION:	Add a new CaseEvent.

-- MODIfICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 01 Nov 2004	TM	RFC1322	1	Procedure created base on the Vers 16 of the cs_InsertCaseEvent.
-- 15 JAN 2008	SF	RFC5708	2	Added SendMethod, SendMethodKey, SentDate, ReceiptDate, Reference and StaffKey, DisplayOrder Parameters.
-- 11 Nov 2008	SF	RFC3392 3	Increase field length for @psCreatedByActionKey
-- 12 Nov 2008	SF	RFC3392	4	Back out field length change
-- 4 Dec 2008	SF	RFC3392	5	Fix incorrect RFC number
-- 18 Apr 2013	LP	R13415	6	Event Text recorded as EVENTLONGTEXT
-- 5 Mar 2015	MS	R43203	7	Insert event text in EVENTTEXT table
-- 29 Sep 2016	MF	69013	8	Need to take into consideration if EventText is being shared with other CASEEVENT rows.

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF


Begin

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)

Declare @nTypeOfRequest 	int
Declare	@sCreatedByActionKey 	nvarchar(2)
Declare	@nCreatedByCriteriaKey 	int
Declare @nOccurredFlag 		decimal(1,0)
Declare @nDateDueSaved 		decimal(1,0)
Declare @bLongFlag 		bit

-- Initialise variables
Set @nErrorCode = 0
Set @bLongFlag = 1

If @nErrorCode = 0
Begin
	If @pbIsStopPolicing = 1
	Begin
		Set @nOccurredFlag = 1
	End
	Else
	Begin
		Set @nOccurredFlag = case when @pdtEventDate is null then 0 else 1 end
	End

	Set @nDateDueSaved = case when @pdtEventDueDate is null then 0 else 1 end

	Set @sSQLString = "
	Insert 	CASEEVENT
		(CASEID,
		EVENTNO,
		CYCLE,
		EVENTDATE,
		EVENTDUEDATE,
		DATEDUESAVED,
		OCCURREDFLAG,
		CREATEDBYACTION,
		CREATEDBYCRITERIA,
		ENTEREDDEADLINE,
		PERIODTYPE,
		SENDMETHOD,
		SENTDATE,
		RECEIPTDATE,
		RECEIPTREFERENCE,
		EMPLOYEENO,
		DISPLAYORDER
		)
	values	(@pnCaseKey,
		@pnEventKey,
		@pnCycle,
		@pdtEventDate,
		@pdtEventDueDate,
		@nDateDueSaved,
		@nOccurredFlag,
		@psCreatedByActionKey,
		@pnCreatedByCriteriaKey,
		@pnPeriod,
		@psPeriodTypeKey,
		@pnSendMethodKey,
		@pdtSendDate,
		@pdtReceiptDate,
		@psReference,
		@pnStaffKey,
		CASE WHEN isnull(@pnDisplayOrder,9001) > 9000 THEN NULL ELSE @pnDisplayOrder END
		)"
		/* display order may be passed in as 9999, when this happens it should be set to NULL */
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnEventKey 		int,
					  @pnCycle		smallint,
					  @pdtEventDate		datetime,
					  @pdtEventDueDate	datetime,
					  @nDateDueSaved	decimal(1,0),
					  @nOccurredFlag	decimal(1,0),
					  @psCreatedByActionKey	nvarchar(2),
					  @pnCreatedByCriteriaKey int,
					  @pnPeriod		smallint,
					  @psPeriodTypeKey	nchar(1),
					  @pnSendMethodKey	int,
					  @pdtSendDate		datetime,
					  @pdtReceiptDate	datetime,
					  @psReference		nvarchar(50),
					  @pnStaffKey		int,
					  @pnDisplayOrder	int',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnEventKey 		= @pnEventKey,	
					  @pnCycle		= @pnCycle,
					  @pdtEventDate		= @pdtEventDate,
					  @pdtEventDueDate	= @pdtEventDueDate,
					  @nDateDueSaved	= @nDateDueSaved,
					  @nOccurredFlag	= @nOccurredFlag,
					  @psCreatedByActionKey	= @psCreatedByActionKey,
					  @pnCreatedByCriteriaKey=@pnCreatedByCriteriaKey,
					  @pnPeriod		= @pnPeriod,
					  @psPeriodTypeKey	= @psPeriodTypeKey,
					  @pnSendMethodKey	= @pnSendMethodKey,
					  @pdtSendDate		= @pdtSendDate,
					  @pdtReceiptDate	= @pdtReceiptDate,
					  @psReference		= @psReference,
					  @pnStaffKey		= @pnStaffKey,
					  @pnDisplayOrder	= @pnDisplayOrder

	If @nErrorCode = 0 
	Begin	
		exec @nErrorCode = csw_UpdateEventText		
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnEventCycle		= @pnCycle,
			@pnEventTextType	= @pnEventTextType,
			@ptEventText		= @ptEventText
	End
End

If @nErrorCode = 0
and @pbIsPolicedEvent = 1
Begin
	-- If both dates are provided
	-- police as an occurred event
	If 	(@nDateDueSaved = 1
		or @pnPeriod is not null
		or @psPeriodTypeKey is not null)
	and 	(@nOccurredFlag = 0)
	Begin
		Set @nTypeOfRequest = 2 -- Police Due Event
	End
	Else
	Begin
		Set @nTypeOfRequest = 3 -- Police Occurred Event
	End

	exec @nErrorCode = ipw_InsertPolicing
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture 		= @psCulture,
		@pnCaseKey 		= @pnCaseKey,
		@pnEventKey		= @pnEventKey,
		@pnCycle		= @pnCycle,
		@psAction		= @psCreatedByActionKey,
		@pnCriteriaNo		= @pnCreatedByCriteriaKey,
		@pnTypeOfRequest	= @nTypeOfRequest,
		@pnPolicingBatchNo	= @pnPolicingBatchNo,
		@pbOnHold		= @pbOnHold
End


Return @nErrorCode

End
GO

Grant execute on dbo.csw_InsertCaseEvent to public
GO
