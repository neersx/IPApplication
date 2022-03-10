-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_SnoozeReminder ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_SnoozeReminder .'
	Drop procedure [dbo].[rmw_SnoozeReminder ]
End
Print '**** Creating Stored Procedure dbo.rmw_SnoozeReminder ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.rmw_SnoozeReminder 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtReminderDateCreated	datetime,
	@pdtLogDateTimeStamp	datetime output,
	@pdtHoldUntilDate 	datetime = null
)
-- PROCEDURE:	rmw_SnoozeReminder 
-- VERSION:	3
-- SCOPE:	WorkBench
-- DESCRIPTION:	Snooze a reminder if 
--				- @pdtHoldUntilDate is less than Due date or
--				- @pdtHoldUntilDate is greater than Due date but only if @pdtHoldUntilDate is tomorrow and Due date is today

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 1 Oct 2009	SF	RFC5803 1	Procedure created
-- 11 Feb 2010	SF	RFC9284	2	Return LogDateTimeStamp rather than checksum
-- 23 Sep 2015	DV	R52835  3	Make @pdtHoldUntilDate nullable and if null then calculate from DATEREMIND or ALERTDATE

as

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode 				int
Declare @sSQLString  				nvarchar(4000)
Declare @dtLogDateTimeStampValue	datetime

Set @nErrorCode = 0

If @nErrorCode = 0 and @pdtHoldUntilDate is null
Begin
	Set @sSQLString = 'SELECT @pdtHoldUntilDate = CASE WHEN Isnull(ER.SOURCE,0) = 0 Then CE.DATEREMIND ELSE A.ALERTDATE END
				FROM EMPLOYEEREMINDER ER
				left join CASEEVENT CE on (CE.CASEID = ER.CASEID and CE.EVENTNO = ER.EVENTNO and CE.CYCLE = ER.CYCLENO)
				left join ALERT A on (A.EMPLOYEENO = ER.ALERTNAMENO and A.SEQUENCENO = ER.SEQUENCENO
							and ER.SOURCE = 1 and ER.EVENTNO IS NULL 
							and (A.CASEID = ER.CASEID 
								or (A.REFERENCE = ER.REFERENCE and A.CASEID is null and ER.CASEID is null) 
								or (A.NAMENO = ER.NAMENO)))
				where  ER.EMPLOYEENO 	= @pnEmployeeKey
				and    ER.MESSAGESEQ 	= @pdtReminderDateCreated
				and    ER.LOGDATETIMESTAMP = @pdtLogDateTimeStamp'
				
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pdtHoldUntilDate		datetime output,
				  @pnEmployeeKey		int,
				  @pdtReminderDateCreated	datetime,
				  @pdtLogDateTimeStamp		datetime',
				  @pdtHoldUntilDate		= @pdtHoldUntilDate output,
				  @pnEmployeeKey		= @pnEmployeeKey,
				  @pdtReminderDateCreated	= @pdtReminderDateCreated,
				  @pdtLogDateTimeStamp		= @pdtLogDateTimeStamp
	
End
	
If @nErrorCode = 0 and @pdtHoldUntilDate is not null
Begin
	Set @sSQLString = '
	Update EMPLOYEEREMINDER 
	set    HOLDUNTILDATE	= @pdtHoldUntilDate,
		   REMINDERDATE		= @pdtHoldUntilDate
	where  EMPLOYEENO 	= @pnEmployeeKey
	and    MESSAGESEQ 	= @pdtReminderDateCreated
	and    LOGDATETIMESTAMP = @pdtLogDateTimeStamp
	and	   (		DUEDATE >= @pdtHoldUntilDate
			or 
			(		@pdtHoldUntilDate > DUEDATE 
				and DUEDATE = dbo.fn_DateOnly(getdate()) 
				and @pdtHoldUntilDate = DATEADD(Day, 1, DUEDATE))
			)'
print @sSQLString
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEmployeeKey			int,
				  @pdtReminderDateCreated	datetime,
				  @pdtLogDateTimeStamp		datetime,
				  @pdtHoldUntilDate			datetime',
				  @pnEmployeeKey			= @pnEmployeeKey,
				  @pdtReminderDateCreated	= @pdtReminderDateCreated,
				  @pdtLogDateTimeStamp		= @pdtLogDateTimeStamp,
				  @pdtHoldUntilDate			= @pdtHoldUntilDate
				  
	If @nErrorCode = 0
	and @@ROWCOUNT > 0
	Begin
		Set @sSQLString = '
			Select	@dtLogDateTimeStampValue = LOGDATETIMESTAMP 
			from	EMPLOYEEREMINDER
			where	EMPLOYEENO 	= @pnEmployeeKey
			and		MESSAGESEQ 	= @pdtReminderDateCreated
			'
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtLogDateTimeStampValue datetime output,
				  @pnEmployeeKey	  int,
				  @pdtReminderDateCreated datetime',
				  @dtLogDateTimeStampValue = @dtLogDateTimeStampValue output,
				  @pnEmployeeKey	  = @pnEmployeeKey,
				  @pdtReminderDateCreated = @pdtReminderDateCreated
	End			  

	If @nErrorCode = 0
	and @dtLogDateTimeStampValue is not null
	Begin
		Select @pdtLogDateTimeStamp = @dtLogDateTimeStampValue
	End
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_SnoozeReminder  to public
GO

