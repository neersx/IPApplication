-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBilledCredit									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBilledCredit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBilledCredit.'
	Drop procedure [dbo].[biw_InsertBilledCredit]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBilledCredit...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_InsertBilledCredit
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDRItemEntityNo	int,
	@pnDRItemTransNo	int,
	@pnDRAcctEntityNo	int,
	@pnDRAcctDebtorNo	int,
	@pnCRItemEntityNo	int,
	@pnCRItemTransNo	int,
	@pnCRAcctEntityNo	int,
	@pnCRAcctDebtorNo	int,
	@pnCRCaseId		int		 = null,
	@pnLocalSelected	decimal(11,2)	 = null,
	@pnForeignSelected	decimal(11,2)	 = null,
	@pbForcedPayOut		bit		 = null,
	@pnSelectedRenewal	decimal(11,2)	 = 0,
	@pnSelectedNonRenewal	decimal(11,2)	 = 0,
	@pnCRExchVariance	decimal(11,2)	 = null,
	@pbCRForcedPayOut	bit		 = null
)
as
-- PROCEDURE:	biw_InsertBilledCredit
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert BilledCredit.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Mar 2010	AT	RFC3605	1	Procedure created.
-- 20 May 2010	AT	RFC9092	2	Fixed update of OPENITEMCASE to be case specific.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)
Set @sComma = ','

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into BILLEDCREDIT ("
	Set @sInsertString = @sInsertString+CHAR(10)+"DRITEMENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+"@pnDRItemEntityNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DRITEMTRANSNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDRItemTransNo"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DRACCTENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDRAcctEntityNo"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DRACCTDEBTORNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDRAcctDebtorNo"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRITEMENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRItemEntityNo"
		
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRITEMTRANSNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRItemTransNo"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRACCTENTITYNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRAcctEntityNo"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRACCTDEBTORNO"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRAcctDebtorNo"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRCASEID"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRCaseId"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LOCALSELECTED"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLocalSelected"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FOREIGNSELECTED"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnForeignSelected"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FORCEDPAYOUT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbForcedPayOut"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SELECTEDRENEWAL"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnSelectedRenewal"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SELECTEDNONRENEWAL"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnSelectedNonRenewal"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CREXCHVARIANCE"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCRExchVariance"
	
	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRFORCEDPAYOUT"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbCRForcedPayOut"
	
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnDRItemEntityNo		int,
			@pnDRItemTransNo		int,
			@pnDRAcctEntityNo		int,
			@pnDRAcctDebtorNo		int,
			@pnCRItemEntityNo		int,
			@pnCRItemTransNo		int,
			@pnCRAcctEntityNo		int,
			@pnCRAcctDebtorNo		int,
			@pnCRCaseId		int,
			@pnLocalSelected		decimal(11,2),
			@pnForeignSelected		decimal(11,2),
			@pbForcedPayOut		bit,
			@pnSelectedRenewal		decimal(11,2),
			@pnSelectedNonRenewal		decimal(11,2),
			@pnCRExchVariance		decimal(11,2),
			@pbCRForcedPayOut		bit',
			@pnDRItemEntityNo	 = @pnDRItemEntityNo,
			@pnDRItemTransNo	 = @pnDRItemTransNo,
			@pnDRAcctEntityNo	 = @pnDRAcctEntityNo,
			@pnDRAcctDebtorNo	 = @pnDRAcctDebtorNo,
			@pnCRItemEntityNo	 = @pnCRItemEntityNo,
			@pnCRItemTransNo	 = @pnCRItemTransNo,
			@pnCRAcctEntityNo	 = @pnCRAcctEntityNo,
			@pnCRAcctDebtorNo	 = @pnCRAcctDebtorNo,
			@pnCRCaseId	 = @pnCRCaseId,
			@pnLocalSelected	 = @pnLocalSelected,
			@pnForeignSelected	 = @pnForeignSelected,
			@pbForcedPayOut	 = @pbForcedPayOut,
			@pnSelectedRenewal	 = @pnSelectedRenewal,
			@pnSelectedNonRenewal	 = @pnSelectedNonRenewal,
			@pnCRExchVariance	 = @pnCRExchVariance,
			@pbCRForcedPayOut	 = @pbCRForcedPayOut
End

If @nErrorCode = 0
Begin
	If exists  (SELECT * FROM OPENITEMCASE 
		Where ITEMENTITYNO = @pnCRItemEntityNo
		and ITEMTRANSNO = @pnCRItemTransNo
		and ACCTENTITYNO = @pnCRAcctEntityNo
		and ACCTDEBTORNO = @pnCRAcctDebtorNo
		and CASEID = @pnCRCaseId)
	Begin
		Set @sSQLString = "UPDATE OPENITEMCASE
			SET STATUS = 2
			Where ITEMENTITYNO = @pnCRItemEntityNo
			and ITEMTRANSNO = @pnCRItemTransNo
			and ACCTENTITYNO = @pnCRAcctEntityNo
			and ACCTDEBTORNO = @pnCRAcctDebtorNo
			and CASEID = @pnCRCaseId"
	End
	Else
	Begin
		Set @sSQLString = "UPDATE OPENITEM
			SET STATUS = 2
			Where ITEMENTITYNO = @pnCRItemEntityNo
			and ITEMTRANSNO = @pnCRItemTransNo
			and ACCTENTITYNO = @pnCRAcctEntityNo
			and ACCTDEBTORNO = @pnCRAcctDebtorNo"
	End

	exec @nErrorCode=sp_executesql @sSQLString,
			      		N'@pnCRItemEntityNo		int,
					@pnCRItemTransNo		int,
					@pnCRAcctEntityNo		int,
					@pnCRAcctDebtorNo		int,
					@pnCRCaseId				int',
					@pnCRItemEntityNo	 = @pnCRItemEntityNo,
					@pnCRItemTransNo	 = @pnCRItemTransNo,
					@pnCRAcctEntityNo	 = @pnCRAcctEntityNo,
					@pnCRAcctDebtorNo	 = @pnCRAcctDebtorNo,
					@pnCRCaseId			 = @pnCRCaseId
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBilledCredit to public
