
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_InsertMarketing									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_InsertMarketing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_InsertMarketing.'
	Drop procedure [dbo].[crm_InsertMarketing]
End
Print '**** Creating Stored Procedure dbo.crm_InsertMarketing...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_InsertMarketing
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,	-- Mandatory.
	@pnActualCostLocal		decimal(11,2)		 = null,
	@pnActualCost			decimal(11,2)		 = null,
	@psActualCostCurrency		nvarchar(3)		 = null,
	@pnExpectedResponses		int		 = null,
	@pdtStartDate			datetime	= null,
	@pdtActualDate			datetime	= null,
	@pnStaffAttended		int		= null,
	@pnContactsAttended		int		= null,
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
-- PROCEDURE:	crm_InsertMarketing
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Marketing.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 22 Aug 2008	AT	RFC5712	1	Procedure created.
-- 03 Oct 2008	AT	RFC7118	2	Added Staff/Contacts Attended.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @nTranCountStart 	int

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into MARKETING
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			CASEID
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnCaseKey
			"

	If @pbIsActualCostInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTUALCOST"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnActualCost"
		Set @sComma = ","
	End

	If @pbIsActualCostCurrencyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTUALCOSTCURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psActualCostCurrency"
		Set @sComma = ","
	End

	If @pbIsActualCostLocalInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTUALCOSTLOCAL"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnActualCostLocal"
		Set @sComma = ","
	End

	If @pbIsExpectedResponsesInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPECTEDRESPONSES"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnExpectedResponses"
		Set @sComma = ","
	End

	If @pbIsStaffAttendedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STAFFATTENDED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStaffAttended"
		Set @sComma = ","
	End

	If @pbIsContactsAttendedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CONTACTSATTENDED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnContactsAttended"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnActualCostLocal	decimal(11,2),
			@pnActualCost		decimal(11,2),
			@psActualCostCurrency	nvarchar(3),
			@pnExpectedResponses	int,
			@pnStaffAttended	int,
			@pnContactsAttended	int',
			@pnCaseKey	 	= @pnCaseKey,
			@pnActualCostLocal	= @pnActualCostLocal,
			@pnActualCost		= @pnActualCost,
			@psActualCostCurrency	= @psActualCostCurrency,
			@pnExpectedResponses	= @pnExpectedResponses,
			@pnStaffAttended	= @pnStaffAttended,
			@pnContactsAttended	= @pnContactsAttended


	if @pbIsStartDateInUse = 1 and @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.csw_InsertCaseEvent
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey 		= -12210,
			@pnCycle		= 1,
			@pdtEventDate		= @pdtStartDate,
			@pbIsPolicedEvent 	= 0
	End


	if @pbIsActualDateInUse = 1 and @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.csw_InsertCaseEvent
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey 		= @pnCaseKey,
			@pnEventKey 		= -12211,
			@pnCycle		= 1,
			@pdtEventDate		= @pdtActualDate,
			@pdtEventDueDate	= @pdtActualDate,
			@pbIsPolicedEvent 	= 0
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

Grant execute on dbo.crm_InsertMarketing to public
GO