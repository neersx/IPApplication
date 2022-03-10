-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertAdHocDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertAdHocDate.'
	Drop procedure [dbo].[ipw_InsertAdHocDate]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertAdHocDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertAdHocDate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pnCaseKey		int		= null,
	@psAdHocMessage		nvarchar(1000),	-- Mandatory
	@psAdHocReference	nvarchar(20)	= null,
	@pnNameReferenceKey     int             = null,
	@pdtDueDate		datetime	= null,	
	@pdtDateOccurred	datetime	= null,
	@pnEventKey		int		= null,
	@pnOccurredReasonKey	tinyint		= null,
	@pdtDeleteDate		datetime	= null,
	@pdtStopRemindersDate	datetime	= null,
	@pnDaysLead		smallint	= null,
	@pnRepeatIntervalDays	smallint	= null,
	@pnMonthsLead		smallint	= null,
	@pnRepeatIntervalMonths smallint	= null,
	@pbIsElectronicReminder bit		= null,
	@psEmailSubject		nvarchar(100)	= null,
	@psImportanceLevel	nvarchar(2)	= null,
	@pnDisplayOrder		int             = null,
	@pbIsEmployee		bit		= 0,
	@pbIsSignatory		bit		= 0,
	@pbIsCriticalList	bit		= 0,
	@psNameType		nvarchar(3)	= null,
	@psRelationship		nvarchar(3)	= null,
	@pnPolicingBatchNo	int		= null
)
-- PROCEDURE:	ipw_InsertAdHocDate
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create a new Alert.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07 Oct 2004  TM	RFC1327	1	Procedure created. 
-- 11 Oct 2004	TM	RFC1327	2	Only write the @pnOccurredReasonKey to the database if it is provided.
-- 23 Nov 2004	TM	RFC2025	3	Ensure any time component is stripped from the following: DueDate, 
--					DateOccurred, DeleteDate, StopRemindersDate. Do not set an @dtAlertDate
--					to the current date/time but leave it null.
-- 17 Aug 2005	TM	RFC2938	4	Cater for new ImportanceLevel column on the Alert table. 
-- 18 Jan 2008	SF	RFC5708	5 	Cater for DisplayOrder (docketing wizard)
-- 12 Feb 2009  LP      RFC6047 6       Add new NameReferenceKey parameter.
-- 18 Jul 2011	LP	RFC10992 7	Increase @psAlertMessage parameter to 1000 characters.
-- 02 Dec 2011	DV	RFC996	 8	Add logic to update additional fields in ALERT table.
-- 08 Apr 2014  MS      R31303  9      Set default values for parameters IsEmployee, IsSignaytory and IsCriticalList to 0 rather than null 

as

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @nSequenceNo 	int
Declare @dtAlertSeq 	datetime
Declare @dtAlertDate	datetime
Declare @nTypeOfRequest tinyint
Declare @nRowCount	smallint

-- Initialise variables
Set @nErrorCode 	= 0
Set @dtAlertDate 	= null

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	select 	@nSequenceNo = isnull(max(SEQUENCENO)+1, 0)
	from 	ALERT 
	where	EMPLOYEENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSequenceNo	int		output,
					  @pnNameKey	int',
					  @nSequenceNo	= @nSequenceNo	output,
					  @pnNameKey	= @pnNameKey
End

If @nErrorCode = 0
Begin
	-- Since DateTime is part of the key it is possible to
	-- get a duplicate key.  Keep trying until a unique DateTime
	-- is extracted.
	Set @dtAlertSeq = getdate()
	
	Set @nRowCount = 1

	While @nRowCount > 0	
	Begin	
		Set @sSQLString = "
		Select @nRowCount = COUNT(*)
		from ALERT
		where	EMPLOYEENO = @pnNameKey
		and	ALERTSEQ = @dtAlertSeq"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRowCount	smallint	output,
						  @dtAlertSeq 	datetime,
						  @pnNameKey	int',
						  @nRowCount	= @nRowCount	output,
						  @dtAlertSeq 	= @dtAlertSeq,
						  @pnNameKey	= @pnNameKey	
		
		If @nRowCount > 0
		Begin
			-- millisecond are held to equivalent to 3.33, so need to add 3
			Set @dtAlertSeq = DATEADD(millisecond,3,@dtAlertSeq)
		End

	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	insert into ALERT (
		EMPLOYEENO,
		ALERTSEQ,
		CASEID,
		ALERTMESSAGE,
		REFERENCE,
		NAMENO,
		ALERTDATE,
		DUEDATE,	
		TRIGGEREVENTNO,		
		DATEOCCURRED,
		OCCURREDFLAG,
		DELETEDATE,
		STOPREMINDERSDATE,
		MONTHLYFREQUENCY,
		MONTHSLEAD,		
		DAILYFREQUENCY,
		DAYSLEAD,
		SEQUENCENO,
		SENDELECTRONICALLY,
		EMAILSUBJECT,
		IMPORTANCELEVEL,
		DISPLAYORDER,
		EMPLOYEEFLAG,
		SIGNATORYFLAG,
		CRITICALFLAG,
		NAMETYPE,
		RELATIONSHIP
		)
	values (
		@pnNameKey,
		@dtAlertSeq,
		@pnCaseKey,
		@psAdHocMessage,
		@psAdHocReference,
		@pnNameReferenceKey,
		@dtAlertDate,
		-- Ensure any time component is stripped from the following: 
		-- DueDateDate, OccurredDelete, DateStop, RemindersDate
		convert(char(10),@pdtDueDate,121),
		@pnEventKey,
		convert(char(10),@pdtDateOccurred,121),
		CASE WHEN @pnOccurredReasonKey IS NOT NULL
		     THEN @pnOccurredReasonKey 
		     WHEN @pdtDateOccurred IS NULL 
		     THEN 0 
		     WHEN @pdtDateOccurred IS NOT NULL AND @pnOccurredReasonKey IS NULL 
		     -- Event has occurred	
		     THEN 3 
		END,
		convert(char(10),@pdtDeleteDate,121),
		convert(char(10),@pdtStopRemindersDate,121),
		@pnRepeatIntervalMonths,
		@pnMonthsLead,
		@pnRepeatIntervalDays,
		@pnDaysLead,			
		isnull(@nSequenceNo,0),
		CAST(@pbIsElectronicReminder as decimal(1,0)),
		@psEmailSubject,
		@psImportanceLevel,
		CASE WHEN isnull(@pnDisplayOrder,9001) > 9000 THEN NULL ELSE @pnDisplayOrder END,
		@pbIsEmployee,
		@pbIsSignatory,
		@pbIsCriticalList,
		@psNameType,
		@psRelationship
		)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @dtAlertSeq		datetime,
					  @pnCaseKey		int,
					  @psAdHocMessage	nvarchar(1000),
					  @psAdHocReference	nvarchar(20),
					  @pnNameReferenceKey	int,
					  @dtAlertDate		datetime,
					  @pdtDueDate		datetime,
					  @pnEventKey		int,
					  @pdtDateOccurred	datetime,
					  @pnOccurredReasonKey	tinyint,
					  @pdtDeleteDate	datetime,
					  @pdtStopRemindersDate	datetime,
					  @pnRepeatIntervalMonths smallint,
					  @pnMonthsLead		smallint,
					  @pnRepeatIntervalDays smallint,
					  @pnDaysLead		smallint,
					  @nSequenceNo		int,
					  @pbIsElectronicReminder bit,
					  @psEmailSubject	nvarchar(100),
					  @psImportanceLevel	nvarchar(2),
					  @pnDisplayOrder	int,
					  @pbIsEmployee		bit,
					  @pbIsSignatory	bit,
					  @pbIsCriticalList	bit,
					  @psNameType		nvarchar(3),
					  @psRelationship	nvarchar(3)',					  
					  @pnNameKey		= @pnNameKey,
					  @dtAlertSeq		= @dtAlertSeq,
					  @pnCaseKey		= @pnCaseKey,
					  @psAdHocMessage	= @psAdHocMessage,
					  @psAdHocReference	= @psAdHocReference,
					  @pnNameReferenceKey   = @pnNameReferenceKey,
					  @dtAlertDate		= @dtAlertDate,
					  @pdtDueDate		= @pdtDueDate,
					  @pnEventKey		= @pnEventKey,
					  @pdtDateOccurred	= @pdtDateOccurred,
					  @pnOccurredReasonKey	= @pnOccurredReasonKey,
					  @pdtDeleteDate	= @pdtDeleteDate,
					  @pdtStopRemindersDate = @pdtStopRemindersDate,
					  @pnRepeatIntervalMonths = @pnRepeatIntervalMonths,
					  @pnMonthsLead		= @pnMonthsLead,
					  @pnRepeatIntervalDays	= @pnRepeatIntervalDays,
					  @pnDaysLead		= @pnDaysLead,
					  @nSequenceNo		= @nSequenceNo,
					  @pbIsElectronicReminder = @pbIsElectronicReminder,
					  @psEmailSubject	= @psEmailSubject,
					  @psImportanceLevel	= @psImportanceLevel,
					  @pnDisplayOrder	= @pnDisplayOrder,
					  @pbIsEmployee			= @pbIsEmployee,
					  @pbIsSignatory		= @pbIsSignatory,
					  @pbIsCriticalList		= @pbIsCriticalList,
					  @psNameType			= @psNameType,
					  @psRelationship		= @psRelationship

	-- Publish the generated AlertSeq
	Select @dtAlertSeq as AlertSeq
End

If @nErrorCode = 0
and @pnPolicingBatchNo is not null
Begin
	Set @nTypeOfRequest = CASE WHEN @pdtDateOccurred IS NOT NULL 
				   -- Ad Hoc Occurred
				   THEN 3
				   -- Ad Hoc Due
				   ELSE 2
			      END

	exec @nErrorCode = dbo.ipw_InsertPolicing
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnTypeOfRequest	= @nTypeOfRequest,
		@pnPolicingBatchNo	= @pnPolicingBatchNo,
		@pnAdHocNameNo		= @pnNameKey,
		@pdtAdHocDateCreated	= @dtAlertSeq
		
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertAdHocDate to public
GO

