-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ValidateTransactionDate									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ValidateTransactionDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ValidateTransactionDate.'
	Drop procedure [dbo].[acw_ValidateTransactionDate]
End
Print '**** Creating Stored Procedure dbo.acw_ValidateTransactionDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ValidateTransactionDate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pdtItemDate		dateTime	= null,
	@pnModule		int		= 2,
	@pbIgnoreWarnings	bit		= 0,
	@pnPeriodId		int		output
)
as
-- PROCEDURE:	acw_ValidateTransactionDate
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validate item date. Based off functionality in FCTransactionDateValidation
--		This SP is called from:
--			Bulk Finalisation date validation (Module ID = 2)
--			Billing Wizard date validation (Module ID = 2)
--			biw_FinaliseOpenItem (Module ID = 2)
--			WIP Adjustment (Module ID = 1)

-- MODIFICATIONS :
-- Date		Who	Change			Version	Description
-- -----------	-------			------	-------------------------------------------------------
-- 11 Aug 2010	KR	RFC9087		1		Procedure created.
-- 16 Aug 2011	AT	RFC10241	2		Added Bill Dates Forward validation and null check.
--										Return period for call from biw_FinaliseOpenItem.
-- 12 Oct 2011	AT	RFC100618	3		Strip out time from @pdtItemDate. Optimise use of fn_DateOnly().
-- 12 Nov 2012	AK	RFC12544	4		Prevent finalize if bill date is future date
-- 27 Mar 2013	KR	RFC13361	5		Allow finalise bill if date in the future and it is within the current open period
-- 10 Apr 2013	KR	RFC13361	6		Fix issue with the todays' period.
-- 22 Jul 2013	KR	DR394		7		Added Bill Date Only From Today site control and the required code for validation
-- 22 Jul 2013	KR	KR400		8		Added Bill Date Future Restriction site control and the required code for validation
-- 26 Dec 2016	MS	R69522		9		Remove AC209 check as its not allowing creating bill in past date which has period

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @bDebug			bit

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @nPostPeriod	int
Declare @dtPostDate		datetime
Declare @dtEndDate	datetime
Declare @dtCommencedDate datetime
Declare @dtStartDate datetime
Declare @bIsBillDateOnlyFromToday bit
Declare @nIsBillDateFutureRestriction int

Declare @dtLastFinalisedDate datetime

Declare @sAlertXML nvarchar(2000)

Set @bDebug = 0

set @dtPostDate = dbo.fn_DateOnly(getdate())
Set @pdtItemDate = dbo.fn_DateOnly(@pdtItemDate)

-- Initialise variables
Set @nErrorCode = 0

-- Check if item date is null
if @pdtItemDate is null
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('BI1', 'Item Date is required.',
				null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End 

-- Get today's period
If @nErrorCode = 0
Begin

	Set @sSQLString = "Select 
			@dtStartDate = dbo.fn_DateOnly(STARTDATE),
			@dtEndDate = dbo.fn_DateOnly(ENDDATE),
			@dtCommencedDate = dbo.fn_DateOnly(POSTINGCOMMENCED)
			FROM PERIOD WHERE @dtPostDate BETWEEN STARTDATE AND ENDDATE
			and (CLOSEDFOR & @pnModule != @pnModule OR CLOSEDFOR is null)"
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnModule int,
				  @dtPostDate datetime,
				  @dtStartDate datetime OUTPUT,
				  @dtEndDate		datetime OUTPUT,
				  @dtCommencedDate datetime OUTPUT',
				  @pnModule = @pnModule,
				  @dtPostDate = @dtPostDate,
				  @dtStartDate = @dtStartDate OUTPUT,
				  @dtEndDate = @dtEndDate OUTPUT,
				  @dtCommencedDate = @dtCommencedDate OUTPUT

End

If @nErrorCode = 0
Begin
	Set @sSQLString =
	"Select 
		@bIsBillDateOnlyFromToday = isnull(SC.COLBOOLEAN,0),
		@nIsBillDateFutureRestriction = isnull(SC1.COLINTEGER,0)
		From SITECONTROL SC 
		Join SITECONTROL SC1 on (SC1.CONTROLID = 'Bill Date Future Restriction')
		Where SC.CONTROLID = 'Bill Date Only From Today'"
		
		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@bIsBillDateOnlyFromToday bit output,
				  @nIsBillDateFutureRestriction int output',
				  @bIsBillDateOnlyFromToday = @bIsBillDateOnlyFromToday output,
				  @nIsBillDateFutureRestriction = @nIsBillDateFutureRestriction output
		
End


-- if the site control 'Bill Date Only From Today' is set to true, do not allow transaction date to be in the past
If @nErrorCode = 0 and 
	@pnModule = 2 and 
	@bIsBillDateOnlyFromToday = 1 and
	@pdtItemDate < dateadd(day, datediff(day, 0, getdate()), 0)
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('AC215', 'Bill dates in the past are not allowed.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End


-- Transaction date must be earlier than today or within the current period and 
-- site control 'Bill Date Future Restriction' is set to 0.
If (@nErrorCode = 0 
	and @pdtItemDate > @dtEndDate or (@pdtItemDate > @dtPostDate and @dtCommencedDate is null))
	and @nIsBillDateFutureRestriction = 0
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC208', 'The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

-- Transaction date can be in the future if it is in the period in which today's date falls
-- site control 'Bill Date Future Restriction' is set to 1.
If @nErrorCode = 0 
	and @pdtItemDate > @dtEndDate
	and @nIsBillDateFutureRestriction = 1
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC216', 'Future bill dates are only allowed if the date is in the same period as the current date. ',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

-- Transaction date can be in the future if the period is open
-- site control 'Bill Date Future Restriction' is set to 2.
If @nErrorCode = 0 
	and @nIsBillDateFutureRestriction = 2
	and @pdtItemDate > dateadd(day, datediff(day, 0, getdate()), 0)
	and exists (select 1 from PERIOD
				where @pdtItemDate between STARTDATE and ENDDATE
				and CLOSEDFOR & @pnModule = @pnModule)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC217', 'The item date cannot be in the future period that is closed for the module.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

--Use the period that is currently open period 
	-- the entered item date must be earlier than the period close date 
	-- and the period must not be closed for the accounting subsystem
If (@nErrorCode = 0)
Begin
	-- Set the period to the currently open period
	Set @sSQLString = "Select @nPostPeriod = OP.PERIODID
		From (Select TOP 1 PERIODID, ENDDATE, CLOSEDFOR
			From PERIOD 
			Where @dtPostDate > POSTINGCOMMENCED -- Currently open period
			and POSTINGCOMMENCED IS NOT NULL
			Order by POSTINGCOMMENCED DESC) AS OP
		WHERE @pdtItemDate <= OP.ENDDATE -- item date is within the period
		and (OP.CLOSEDFOR & @pnModule != @pnModule OR OP.CLOSEDFOR is null) -- and the period is not closed for Time/Billing"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @dtPostDate datetime,
				  @pnModule int,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @dtPostDate = @dtPostDate,
				  @pnModule = @pnModule,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

If (@nErrorCode = 0 and @nPostPeriod is null)
Begin
	-- if the current period could not be used, use the transaction period instead.
	Set @sSQLString = "Select @nPostPeriod = PERIODID
		FROM PERIOD
		WHERE @pdtItemDate between STARTDATE AND ENDDATE
		and (CLOSEDFOR & @pnModule != @pnModule or CLOSEDFOR is null) -- Not closed for the period"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @pnModule	int,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @pnModule = @pnModule,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

If (@nErrorCode = 0 and @nPostPeriod is null)
Begin
	-- if the period of the transaction could not be used, use the next open period.
	Set @sSQLString = "Select @nPostPeriod = PERIODID
		FROM (SELECT MIN(P.PERIODID) AS PERIODID
			FROM (SELECT PERIODID FROM PERIOD
				WHERE @pdtItemDate between STARTDATE AND ENDDATE) AS TRANSPERIOD
			JOIN PERIOD P ON (P.PERIODID > TRANSPERIOD.PERIODID)
			WHERE (P.CLOSEDFOR & @pnModule != @pnModule or P.CLOSEDFOR is null)
			) AS MINPERIOD"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @pnModule int,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @pnModule = @pnModule,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

Set @pnPeriodId = @nPostPeriod

If (@bDebug = 1)
Begin
	Print 'Post Period = ' + cast(@nPostPeriod as nvarchar(12))
End

If (@nErrorCode=0 and @nPostPeriod is null)
Begin
	-- Could not determine the post period
	Set @sAlertXML = dbo.fn_GetAlertXML('AC126', 'An open accounting period for the entered date could not be found. Check the period definitions and contact administrator to set up the appropriate accounting period.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End
Else
Begin
	If (@nErrorCode = 0 and @pbIgnoreWarnings = 0)
	Begin
		If not exists(Select 1 from PERIOD where PERIODID = @nPostPeriod and @pdtItemDate between STARTDATE and ENDDATE)
		Begin
			Select 'AC124' as WarningCode, 'The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly.' as WarningMessage
		End
	End
End

If @nErrorCode = 0 and 
	@pnModule = 2 and
	exists (select * from SITECONTROL WHERE CONTROLID = 'BillDatesForwardOnly' and COLBOOLEAN = 1)
Begin
	-- Note the same code exists in biw_GetValidateItemDate and 
	Set @sSQLString = "select @dtLastFinalisedDate = MAX(dbo.fn_DateOnly(ITEMDATE))
			from OPENITEM
			WHERE STATUS = 1
			AND ITEMTYPE IN (510, 511, 513, 514)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtLastFinalisedDate datetime output',
				@dtLastFinalisedDate = @dtLastFinalisedDate output

	if (@dtLastFinalisedDate > @pdtItemDate)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC207', 'The item date cannot be earlier than the last finalised item date.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End


Return @nErrorCode
GO

Grant execute on dbo.acw_ValidateTransactionDate to public
GO