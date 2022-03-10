-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_DeleteMarketing									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_DeleteMarketing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_DeleteMarketing.'
	Drop procedure [dbo].[crm_DeleteMarketing]
End
Print '**** Creating Stored Procedure dbo.crm_DeleteMarketing...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_DeleteMarketing
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,	-- Mandatory
	@pnOldActualCostLocal		decimal(11,2)	= null,
	@pnOldActualCost		decimal(11,2)	= null,
	@psOldActualCostCurrency	nvarchar(3) 	= null,
	@pnOldExpectedResponses		int		= null,
	@pnOldStaffAttended		int		= null,
	@pnOldContactsAttended		int		= null,
	@pbIsActualCostLocalInUse	bit	 = 0,
	@pbIsActualCostInUse		bit	 = 0,
	@pbIsActualCostCurrencyInUse	bit	 = 0,
	@pbIsExpectedResponsesInUse	bit	 = 0,
	@pbIsStaffAttendedInUse		bit	 = 0,
	@pbIsContactsAttendedInUse	bit	 = 0
)
as
-- PROCEDURE:	crm_DeleteMarketing
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Marketing if the underlying values are as expected.

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
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from MARKETING
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		CASEID = @pnCaseKey
"

	If @pbIsActualCostInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ACTUALCOST = @pnOldActualCost"
	End

	If @pbIsActualCostCurrencyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ACTUALCOSTCURRENCY = @psOldActualCostCurrency"
	End

	If @pbIsActualCostLocalInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ACTUALCOSTLOCAL = @pnOldActualCostLocal"
	End

	If @pbIsExpectedResponsesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"EXPECTEDRESPONSES = @pnOldExpectedResponses"
	End

	If @pbIsStaffAttendedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STAFFATTENDED = @pnOldStaffAttended"
	End

	If @pbIsContactsAttendedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CONTACTSATTENDED = @pnOldContactsAttended"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnCaseKey		int,
			@pnOldActualCostLocal		decimal(11,2),
			@pnOldActualCost		decimal(11,2),
			@psOldActualCostCurrency	nvarchar(3),
			@pnOldExpectedResponses		int,
			@pnOldStaffAttended		int,
			@pnOldContactsAttended		int',
			@pnCaseKey	 = @pnCaseKey,
			@pnOldActualCostLocal	 = @pnOldActualCostLocal,
			@pnOldActualCost	 = @pnOldActualCost,
			@psOldActualCostCurrency = @psOldActualCostCurrency,
			@pnOldExpectedResponses	 = @pnOldExpectedResponses,
			@pnOldStaffAttended	 = @pnOldStaffAttended,
			@pnOldContactsAttended	 = @pnOldContactsAttended

End

Return @nErrorCode
GO

Grant execute on dbo.crm_DeleteMarketing to public
GO