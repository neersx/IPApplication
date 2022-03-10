-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListProtocolDisbursements
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListProtocolDisbursements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListProtocolDisbursements.'
	Drop procedure [dbo].[acw_ListProtocolDisbursements]
	Print '**** Creating Stored Procedure dbo.acw_ListProtocolDisbursements...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListProtocolDisbursements
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCreditItemTransKey	int,
	@psProtocolKey		nvarchar(20),
	@psProtocolDate		nvarchar(15)	
)
AS
-- PROCEDURE:	acw_ListProtocolDisbursements
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available actions.

-- MODIFICATIONS :
-- Date		Who	Change Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26-10-2009	AT	RFC3605	1	Procedure created.
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nEntityKey	int
Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(2000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	-- Get the EntityKey
	Set @sSQLString = 
	"Select @nEntityKey = CI.ACCTENTITYNO
	FROM CREDITORITEM CI
	WHERE CI.ITEMTRANSNO = @pnCreditItemTransKey
		AND CI.PROTOCOLNO = @psProtocolKey
		AND dbo.fn_DateOnly(CI.PROTOCOLDATE) = dbo.fn_DateOnly(cast(@psProtocolDate as datetime))"
		
	exec @nErrorCode = sp_executesql @sSQLString,
			N'
			@nEntityKey	int OUTPUT,
			@pnCreditItemTransKey	int,
			@psProtocolKey	nvarchar(20),
			@psProtocolDate	nvarchar(15)',
			@nEntityKey = @nEntityKey OUTPUT,
			@pnCreditItemTransKey = @pnCreditItemTransKey,
			@psProtocolKey = @psProtocolKey,
			@psProtocolDate = @psProtocolDate
End

	
If @nErrorCode = 0
Begin	
	Set @sSQLString = "select
		CI.ACCTCREDITORNO as 'CreditorKey',
		N.NAMECODE as 'CreditorCode',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'CreditorName',
		CI.ACCTENTITYNO as 'EntityKey',
		CI.DOCUMENTREF as 'InvoiceKey',
		CI.CURRENCY as 'Currency',
		C.DESCRIPTION as 'CurrencyDescription',
		isnull(CI.FOREIGNVALUE, CI.LOCALPRETAXVALUE) as 'PurchaseValue'
		From CREDITORITEM CI
		join NAME N on (N.NAMENO = CI.ACCTCREDITORNO)
		left join CURRENCY C on (C.CURRENCY = CI.CURRENCY)
		WHERE CI.ITEMTRANSNO = @pnCreditItemTransKey
		AND CI.PROTOCOLNO = @psProtocolKey
		AND dbo.fn_DateOnly(CI.PROTOCOLDATE) = dbo.fn_DateOnly(cast(@psProtocolDate as datetime))"
	
	PRINT @sSQLString
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCreditItemTransKey	int,
			@psProtocolKey	nvarchar(20),
			@psProtocolDate	nvarchar(15)',
			@pnCreditItemTransKey = @pnCreditItemTransKey,
			@psProtocolKey = @psProtocolKey,
			@psProtocolDate = @psProtocolDate
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		select
		W.TRANSNO as 'TransNo',
		W.WIPSEQNO as 'WIPSeqNo',
		W.TRANSDATE as 'TransDate',
		W.TRANSTYPE as 'TransType',
		W.WIPCODE as 'WIPCode',
		WT.DESCRIPTION as 'WIPDescription',
		W.CASEID as 'CaseKey',
		C.IRN as 'IRN',
		W.ACCTENTITYNO as 'EntityKey',
		N.NAMENO as 'CreditorKey',
		N.NAMECODE as 'CreditorNameCode',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'CreditorName',
		W.EMPLOYEENO as 'EmployeeKey',
		EMP.NAMECODE as 'EmployeeNameCode',
		dbo.fn_FormatNameUsingNameNo(EMP.NAMENO, null) as 'EmployeeName',
		W.LOCALTRANSVALUE as 'LocalValue',
		W.FOREIGNCURRENCY as 'ForeignCurrency',
		W.FOREIGNTRANVALUE as 'ForeignValue',
		W.NARRATIVENO as 'NarrativeKey',
		ISNULL(W.SHORTNARRATIVE, W.LONGNARRATIVE) as 'DebitNoteText',
		W.VERIFICATIONNUMBER as 'VerificationNo',
		W.LOCALCOST as 'LocalCost',
		W.FOREIGNCOST as 'ForeignCost',
		W.ENTEREDQUANTITY as 'EnteredQuantity',
		isnull(W.DISCOUNTFLAG,0) as 'DiscountFlag',
		W.MARGINNO as 'MarginNo',
		isnull(W.MARGINFLAG,0) as 'MarginFlag'
		From WORKHISTORY W
		Join WIPTEMPLATE WT on WT.WIPCODE = W.WIPCODE
		Join NAME EMP on (EMP.NAMENO = W.EMPLOYEENO)
		Left Join CASES C on (C.CASEID = W.CASEID)
		Left Join (
			SELECT CN.CASEID, CN.NAMENO 
			FROM CASENAME CN
			JOIN (SELECT MIN(SEQUENCE) as SEQUENCE, CASEID
				FROM CASENAME CN
				WHERE CN.NAMETYPE = 'D'
				group by CASEID) 
			AS CN1 ON CN1.CASEID = CN.CASEID
				AND CN1.SEQUENCE = CN.SEQUENCE
				AND CN.NAMETYPE = 'D'
		) AS CN on (CN.CASEID = C.CASEID)
		Left Join NAME N on (N.NAMENO = ISNULL(W.ACCTCLIENTNO, CN.NAMENO))
		Where ((W.REFENTITYNO = @nEntityKey
			AND W.REFTRANSNO = @pnCreditItemTransKey)
			or
			(W.PROTOCOLNO = @psProtocolKey
			AND dbo.fn_DateOnly(W.PROTOCOLDATE) = dbo.fn_DateOnly(cast(@psProtocolDate as datetime))))
		AND W.MOVEMENTCLASS = 1
		AND W.ITEMIMPACT = 1
		ORDER BY TRANSNO, WIPSEQNO
		"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@nEntityKey	int,
			@pnCreditItemTransKey	int,
			@psProtocolKey	nvarchar(20),
			@psProtocolDate	nvarchar(15)',
			@nEntityKey = @nEntityKey,
			@pnCreditItemTransKey = @pnCreditItemTransKey,
			@psProtocolKey = @psProtocolKey,
			@psProtocolDate = @psProtocolDate
End

Return @nErrorCode
GO

Grant execute on dbo.acw_ListProtocolDisbursements to public
GO
