
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_UpdateMarketing									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_UpdateMarketing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_UpdateMarketing.'
	Drop procedure [dbo].[crm_UpdateMarketing]
End
Print '**** Creating Stored Procedure dbo.crm_UpdateMarketing...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_UpdateMarketing
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,	-- Mandatory
	@pnActualCostLocal		decimal(11,2)	= null,
	@pnActualCost			decimal(11,2)	= null,
	@psActualCostCurrency		nvarchar(3)	= null,
	@pnExpectedResponses		int		= null,
	@pdtStartDate			datetime	= null,
	@pdtActualDate			datetime	= null,
	@pnStaffAttended		int		= null,
	@pnContactsAttended		int		= null,
	@pnOldActualCostLocal		decimal(11,2)	= null,
	@pnOldActualCost		decimal(11,2)	= null,
	@psOldActualCostCurrency	nvarchar(3)	= null,
	@pnOldExpectedResponses		int		= null,
	@pdtOldStartDate		datetime	= null,
	@pdtOldActualDate		datetime	= null,
	@pnOldStaffAttended		int		= null,
	@pnOldContactsAttended		int		= null,
	@pbIsActualCostLocalInUse	bit	 = 0,
	@pbIsActualCostInUse		bit	 = 0,
	@pbIsActualCostCurrencyInUse	bit	 = 0,
	@pbIsExpectedResponsesInUse	bit	 = 0,
	@pbIsStartDateInUse		bit	 = 0,
	@pbIsActualDateInUse		bit	 = 0,
	@pbIsStaffAttendedInUse		bit	 = 0,
	@pbIsContactsAttendedInUse	bit	 = 0
)
as
-- PROCEDURE:	crm_UpdateMarketing
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Marketing if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 22 Aug 2008	AT	RFC5712	1	Procedure created.
-- 03 Oct 2008	AT	RFC7118	2	Added Staff/Contacts Attended.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)
Declare @nTranCountStart 	int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION
End

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update MARKETING
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey
"

	If @pbIsActualCostInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTUALCOST = @pnActualCost"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ACTUALCOST = @pnOldActualCost"
		Set @sComma = ","
	End

	If @pbIsActualCostCurrencyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTUALCOSTCURRENCY = @psActualCostCurrency"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ACTUALCOSTCURRENCY = @psOldActualCostCurrency"
		Set @sComma = ","
	End

	If @pbIsActualCostLocalInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTUALCOSTLOCAL = @pnActualCostLocal"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ACTUALCOSTLOCAL = @pnOldActualCostLocal"
		Set @sComma = ","
	End

	If @pbIsExpectedResponsesInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXPECTEDRESPONSES = @pnExpectedResponses"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EXPECTEDRESPONSES = @pnOldExpectedResponses"
		Set @sComma = ","
	End

	If @pbIsStaffAttendedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STAFFATTENDED = @pnStaffAttended"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STAFFATTENDED = @pnOldStaffAttended"
		Set @sComma = ","
	End

	If @pbIsContactsAttendedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CONTACTSATTENDED = @pnContactsAttended"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CONTACTSATTENDED = @pnOldContactsAttended"
		Set @sComma = ","
	End		

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnActualCostLocal		decimal(11,2),
			@pnActualCost		decimal(11,2),
			@psActualCostCurrency		nvarchar(3),
			@pnExpectedResponses		int,
			@pnStaffAttended		int,
			@pnContactsAttended		int,
			@pnOldActualCostLocal		decimal(11,2),
			@pnOldActualCost		decimal(11,2),
			@psOldActualCostCurrency	nvarchar(3),
			@pnOldExpectedResponses		int,
			@pnOldStaffAttended		int,
			@pnOldContactsAttended		int',
			@pnCaseKey	 	 = @pnCaseKey,
			@pnActualCostLocal	 = @pnActualCostLocal,
			@pnActualCost	 	 = @pnActualCost,
			@psActualCostCurrency	 = @psActualCostCurrency,
			@pnExpectedResponses	 = @pnExpectedResponses,
			@pnStaffAttended	 = @pnStaffAttended,
			@pnContactsAttended	 = @pnContactsAttended,
			@pnOldActualCostLocal	 = @pnOldActualCostLocal,
			@pnOldActualCost	 = @pnOldActualCost,
			@psOldActualCostCurrency = @psOldActualCostCurrency,
			@pnOldExpectedResponses	 = @pnOldExpectedResponses,
			@pnOldStaffAttended	 = @pnOldStaffAttended,
			@pnOldContactsAttended	 = @pnOldContactsAttended

	If @nErrorCode= 0 and @pbIsStartDateInUse = 1
	Begin
		Set @sSQLString = "UPDATE CASEEVENT SET EVENTDATE = @pdtStartDate
				WHERE CASEID = @pnCaseKey
				AND EVENTNO = -12210 
				AND CYCLE = 1
				AND EVENTDATE = @pdtOldStartDate"

		exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnCaseKey		int,
				@pdtStartDate		datetime,
				@pdtOldStartDate	datetime',
				@pnCaseKey	 = @pnCaseKey,
				@pdtStartDate	 = @pdtStartDate,
				@pdtOldStartDate = @pdtOldStartDate
	End

	If @nErrorCode= 0 and @pbIsActualDateInUse = 1
	Begin
		Set @sSQLString = "UPDATE CASEEVENT SET EVENTDATE = @pdtActualDate,
				EVENTDUEDATE = @pdtActualDate
				WHERE CASEID = @pnCaseKey
				AND EVENTNO = -12211 
				AND CYCLE = 1
				AND (EVENTDUEDATE = @pdtOldActualDate or EVENTDATE = @pdtOldActualDate)"

		exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnCaseKey		int,
				@pdtActualDate		datetime,
				@pdtOldActualDate	datetime',
				@pnCaseKey	 = @pnCaseKey,
				@pdtActualDate	 = @pdtActualDate,
				@pdtOldActualDate = @pdtOldActualDate
	End

If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else
	Begin
		ROLLBACK TRANSACTION
	End
End

End

Return @nErrorCode
GO

Grant execute on dbo.crm_UpdateMarketing to public
GO