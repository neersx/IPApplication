-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GenerateBillChangeAlert									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GenerateBillChangeAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GenerateBillChangeAlert.'
	Drop procedure [dbo].[biw_GenerateBillChangeAlert]
End
Print '**** Creating Stored Procedure dbo.biw_GenerateBillChangeAlert...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_GenerateBillChangeAlert
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityKey		int,	-- Mandatory.
	@pnItemTransKey		int,	-- Mandatory.
	@psChangedItem		nvarchar(20),
	@psOldValue		nvarchar(max),	-- Mandatory.
	@psNewValue		nvarchar(max),
	@pnCaseKey		int,
	@psReasonCode		nvarchar(2)		
)
as
-- PROCEDURE:	biw_GenerateBillChangeAlert
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate a reminder notice for generic changes on an invoice.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18-Oct-2010	AT	RFC7272	1	Procedure created.
-- 12-Jan-2011	AT	RFC8983	2	Clear wildcard strings if nothing has changed.
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET CONCAT_NULL_YIELDS_NULL OFF

SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sOpenItemNo nvarchar(12)
Declare @nMainCaseKey int
Declare @nStaffKey int

Declare @sReminderText nvarchar(max)
Declare @sAlertTemplate nvarchar(10)
Declare @nChangeAdmin int
Declare @sReplaceString nvarchar(500)

Declare @dtAlertSeq datetime
Declare @dtDueDate datetime
Declare @dtStopDate datetime
Declare @dtDeleteDate datetime

Declare @nPolicingBatchNo int

-- Initialise variables
Set @nErrorCode = 0

-- Get the invoice details
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @sOpenItemNo = O.OPENITEMNO,
		@nMainCaseKey = O.MAINCASEID,
		@nStaffKey = EMPLOYEENO
		from OPENITEM AS O WITH (READUNCOMMITTED)
		where ITEMENTITYNO = @pnItemEntityKey
		and ITEMTRANSNO = @pnItemTransKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sOpenItemNo nvarchar(12) OUTPUT,
				@nMainCaseKey int OUTPUT,
				@nStaffKey int OUTPUT,
				@pnItemEntityKey int,
				@pnItemTransKey int',
				@sOpenItemNo = @sOpenItemNo OUTPUT,
				@nMainCaseKey = @nMainCaseKey OUTPUT,
				@nStaffKey = @nStaffKey OUTPUT,
				@pnItemEntityKey = @pnItemEntityKey,
				@pnItemTransKey = @pnItemTransKey
End


-- Get the address change template and address administrator site controls 
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @sReminderText = AT.ALERTMESSAGE,
		@sAlertTemplate = AT.ALERTTEMPLATECODE
		FROM ALERTTEMPLATE AT
		join SITECONTROL SC ON (SC.COLCHARACTER = AT.ALERTTEMPLATECODE)
		WHERE SC.CONTROLID = 'DN Change Reminder Template'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sReminderText nvarchar(max) OUTPUT,
		@sAlertTemplate nvarchar(10) OUTPUT',
		@sReminderText = @sReminderText OUTPUT,
		@sAlertTemplate = @sAlertTemplate OUTPUT
End
	
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @nChangeAdmin = COLINTEGER
		FROM SITECONTROL SC
		join NAME N on (N.NAMENO = SC.COLINTEGER)
		WHERE CONTROLID = 'DN Change Administrator'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nChangeAdmin int OUTPUT',
		@nChangeAdmin = @nChangeAdmin OUTPUT
End

-- Generate the reminder text if all applicable details are present
if (@sReminderText is not null
	and @nChangeAdmin is not null)
Begin
	If (charindex('%CHANGEDITEM', @sReminderText) > 0)
	Begin			
		select @sReminderText = replace(@sReminderText collate database_default,
		'%CHANGEDITEM', isnull(@psChangedItem, ''))
			
		Set @sReplaceString = null
	End

	If (charindex('%OLDVALUE', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%OLDVALUE', isnull(@psOldValue, ''))
	End
	
	If (charindex('%NEWVALUE', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%NEWVALUE', isnull(@psNewValue, ''))
	End
	
	If (charindex('%NEWVALUE', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%NEWVALUE', isnull(@psNewValue, ''))
	End
	
	If (charindex('%INVOICENO', @sReminderText) > 0)
	Begin		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%INVOICENO', isnull(@sOpenItemNo,''))
	End
	
	If (charindex('%CASE', @sReminderText) > 0)
	Begin
		Set @sSQLString = "
		Select @sReplaceString = IRN
		FROM CASES WHERE CASEID = isnull(@pnCaseKey, @nMainCaseKey)"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@nMainCaseKey int,
		@pnCaseKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@nMainCaseKey = @nMainCaseKey,
		@pnCaseKey = @pnCaseKey
		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%CASE', isnull(@sReplaceString,''))
		
		Set @sReplaceString = null
	End
	
	
	If (charindex('%REASON', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%REASON', isnull(@psReasonCode,''))
	End
	
	If (charindex('%STAFF', @sReminderText) > 0)
	Begin
		Set @sSQLString = "
		Select @sReplaceString = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		FROM NAME N WHERE NAMENO = @nStaffKey"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@nStaffKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@nStaffKey = @nStaffKey
		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%STAFF', isnull(@sReplaceString,''))
		
		Set @sReplaceString = null
	End	
	

	-- Generate the actual Reminder request	
	If @nErrorCode = 0
	Begin
		-- Since DateTime is part of the key it is possible to
		-- get a duplicate key.  Keep trying until a unique DateTime
		-- is extracted.
		Set @dtAlertSeq = getdate()
		
		While exists (select * from ALERT WHERE EMPLOYEENO = @nChangeAdmin
					and ALERTSEQ = @dtAlertSeq)
		Begin	
			select @dtAlertSeq = dateadd(ms,3,@dtAlertSeq)
		End
	End
	
	If (@nErrorCode = 0)
	Begin

		Select @dtDueDate = DATEADD(mm, isnull(AT.MONTHSLEAD, 0), DATEADD(dd, isnull(AT.DAYSLEAD, 0), dbo.fn_DateOnly(GETDATE())))
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate
		
		SELECT @dtStopDate = DATEADD(dd, AT.STOPALERT, @dtDueDate)
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate
		
		SELECT @dtDeleteDate = DATEADD(dd, AT.DELETEALERT, @dtDueDate)
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate	
		
		if (len(@sReminderText) > 1000)
		Begin
			Select @sReminderText = left(@sReminderText, 1000)
		End
		
		declare @nSequenceNo int
		
		select @nSequenceNo = max(SEQUENCENO) + 1 FROM ALERT
		
		--print @sReminderText
		
		insert into ALERT (EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE,
		ALERTDATE, DUEDATE, DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE,
		MONTHLYFREQUENCY, MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY,
		EMAILSUBJECT, FROMCASEID, EVENTNO, CYCLE, LETTERNO, OVERRIDERULE, TRIGGEREVENTNO,
		SENDMETHOD, SENTDATE, RECEIPTDATE, RECEIPTREFERENCE, DISPLAYORDER, IMPORTANCELEVEL, NAMENO)
		SELECT 
		@nChangeAdmin, @dtAlertSeq, @nMainCaseKey, @sReminderText, NULL,
		dbo.fn_DateOnly(@dtAlertSeq), @dtDueDate, NULL, NULL, @dtDeleteDate, @dtStopDate,
		AT.MONTHLYFREQUENCY, AT.MONTHSLEAD, AT.DAILYFREQUENCY, AT.DAYSLEAD, @nSequenceNo, AT.SENDELECTRONICALLY,
		AT.EMAILSUBJECT, null, null, null, null, null, null,
		null, null, null, null, null, AT.IMPORTANCELEVEL, @nStaffKey
		FROM ALERTTEMPLATE AT
		WHERE ALERTTEMPLATECODE = @sAlertTemplate

	End
		
	if (@nErrorCode = 0)
	Begin
		exec @nErrorCode = ip_GetLastInternalCode
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psTable = 'POLICING',
			@pnLastInternalCode	= @nPolicingBatchNo OUTPUT,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pbIsInternalCodeNegative = 0
	End

	if (@nErrorCode = 0)
	Begin
		exec @nErrorCode = dbo.ipw_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey = @nMainCaseKey,
			@pnTypeOfRequest	= 3, -- Event occurred
			@pnPolicingBatchNo	= @nPolicingBatchNo,
			@pnAdHocNameNo		= @nChangeAdmin,
			@pdtAdHocDateCreated = @dtAlertSeq
	End
End
	
Return @nErrorCode
GO

Grant execute on dbo.biw_GenerateBillChangeAlert to public
GO