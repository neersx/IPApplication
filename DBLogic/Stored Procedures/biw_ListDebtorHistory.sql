-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListDebtorHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListDebtorHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListDebtorHistory.'
	Drop procedure [dbo].[biw_ListDebtorHistory]
End
Print '**** Creating Stored Procedure dbo.biw_ListDebtorHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListDebtorHistory
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit 		= 0,
	@pnItemEntityNo			int		= null, -- The Item Entity No
	@pnItemTransNo			int		= null -- The Item Transaction No

)
as
-- PROCEDURE:	biw_ListDebtorHistory
-- VERSION:	2
-- DESCRIPTION:	Lists the debtor history

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 May 2010	KR	RFC8300	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(max)



Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT
	cast(ITEMENTITYNO as nvarchar(50))+'^'+cast(ITEMTRANSNO as nvarchar(30))+'^'+
	cast(ACCTENTITYNO as nvarchar(50))+'^'+cast(ACCTDEBTORNO as nvarchar(30))+'^'+
	cast(HISTORYLINENO as nvarchar(10)) as RowKey,
	OPENITEMNO as OpenItemNo, 
	TRANSDATE as TransDate, 
	POSTDATE as PostDate,   
	REFTRANSNO as RefTransNo,
	ITEMPRETAXVALUE as ItemPreTaxValue, 
	LOCALTAXAMT as LocalTaxAmount,   
	LOCALVALUE as LocalValue, 
	CURRENCY as Currency, 
	FOREIGNTRANVALUE as ForeignTranValue,  
	EXCHVARIANCE as ExchVariance, 
	REFERENCETEXT as ReferenceText,   
	ITEMENTITYNO as ItemEntityNo, 
	ITEMTRANSNO as ItemTransNo, 
	ACCTENTITYNO as AcctEntityNo,  
	ACCTDEBTORNO as AcctDebtorNo, 
	HISTORYLINENO as HistoryLineNo, 
	STATUS as StatusCode,   
	REFENTITYNO as RefEntityNo, 
	REFTRANSNO as RefTransNo1,  
	DEBTORHISTORY.MOVEMENTCLASS as MovementClass, 
	LONGREFTEXT as ReferenceTextLong, 
	dbo.fn_FormatNameUsingNameNo(D.NAMENO, null) as AcctDebtorName,
	ACCT_TRANS_TYPE.DESCRIPTION as TransType,  
	ML.LABEL as Classification,  
	REASON.DESCRIPTION as Reason,  
	S.STATUS_DESCRIPTION as Status         
	FROM  DEBTORHISTORY   
	JOIN NAME D ON (D.NAMENO = DEBTORHISTORY.ACCTDEBTORNO)  
	JOIN ACCT_TRANS_TYPE ON (ACCT_TRANS_TYPE.TRANS_TYPE_ID = TRANSTYPE)   
	JOIN MOVEMENTLABEL ML ON (ML.MOVEMENTCLASS = DEBTORHISTORY.MOVEMENTCLASS AND   ML.LEDGERID = 2)  
	LEFT JOIN REASON ON (REASON.REASONCODE = DEBTORHISTORY.REASONCODE)   
	JOIN TRANSACTION_STATUS S ON (S.STATUS_ID = STATUS)  
	WHERE ITEMENTITYNO = @pnItemEntityNo AND ITEMTRANSNO = @pnItemTransNo 
	ORDER BY dbo.fn_FormatNameUsingNameNo(D.NAMENO, null), 
	TRANSDATE DESC, POSTDATE DESC, OPENITEMNO "

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int',
			  @pnItemEntityNo	= @pnItemEntityNo,
			  @pnItemTransNo	= @pnItemTransNo

End


Return @nErrorCode
GO

Grant execute on dbo.biw_ListDebtorHistory to public
GO
