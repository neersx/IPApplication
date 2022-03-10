-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameTrustAccountingDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameTrustAccountingDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameTrustAccountingDetail.'
	Drop procedure [dbo].[naw_ListNameTrustAccountingDetail]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameTrustAccountingDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameTrustAccountingDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int, 		-- Mandatory
	@pnBankKey		int,		-- Mandatory
	@pnBankSeqNo		int,		-- Mandatory
	@pnEntityKey		int		-- Mandatory
)
as
-- PROCEDURE:	naw_ListNameTrustAccountingDetail
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists detailed Name Trust Account information. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 30 Sep 2010	AT	R9436	1	Procedure created.
-- 10 Nov 2010	AT	R9436	2	Fixed return of Transaction Type.
-- 11 Sep 2014	MF	R39202	3	The Trust tab is not showing the trust balance after a Trust Transfer. Find the
--					originating transaction by using TrustHistory to go up the parent tree.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @sSQLString 			nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode=0
Begin

	Set @sSQLString = "
	-----------------------------------------------------------------
	-- RFC39202
	-- This CTE is designed to trace the TRUSTHISTORY transactions up
	-- the parent tree in order to find the originating transaction.
	-----------------------------------------------------------------
	With TrustHistoryTree (ParentEntityNo, ParentTransNo,  ChildEntityNo, ChildTransNo, Level, OrigEntityNo, OrigTransNo)
	as
	(	Select Distinct null, null, C.ITEMENTITYNO, C.ITEMTRANSNO, 0, C.ITEMENTITYNO, C.ITEMTRANSNO
		from TRUSTHISTORY C
		-- Look for top parent row that is not a child
		left join TRUSTHISTORY P on (P.REFENTITYNO=C.ITEMENTITYNO
					 and P.REFTRANSNO =C.ITEMTRANSNO
					 -- Ignore rows pointing to itself
					 and(P.ITEMENTITYNO<>C.ITEMENTITYNO OR P.ITEMTRANSNO<>C.ITEMTRANSNO))
		where P.REFTRANSNO is null
		and C.MOVEMENTCLASS in (4,5)
		and C.TACCTNAMENO = @pnNameKey
		-- Recursive member definition
		UNION ALL
		Select P.ChildEntityNo, P.ChildTransNo, C.REFENTITYNO, C.REFTRANSNO, P.Level+1, P.OrigEntityNo, P.OrigTransNo
		from TrustHistoryTree P
		join TRUSTHISTORY C	on (C.ITEMENTITYNO =P.ChildEntityNo
					and C.ITEMTRANSNO  =P.ChildTransNo
					and C.MOVEMENTCLASS in (4,5)
					and(C.ITEMENTITYNO<>C.REFENTITYNO OR C.ITEMTRANSNO <>C.REFTRANSNO))
	)
	select 
	CAST(TI.TACCTNAMENO AS NVARCHAR(12)) + '^' + CAST(TI.ITEMTRANSNO AS NVARCHAR(12)) AS 'RowKey',
	cast(@pnNameKey as nvarchar(12)) + 
		'^' + cast(@pnEntityKey as nvarchar(12)) + 
		'^' + cast(@pnBankKey as nvarchar(12)) + 
		'^' + cast(@pnBankSeqNo as nvarchar(12)) as 'ParentRowKey',
	TI.TACCTNAMENO AS 'TraderKey',
	CI.TRADER as 'Trader',
	TI.ITEMDATE as 'Date',
	TI.ITEMNO as 'ItemRefNo',
	TI.ITEMTRANSNO as 'ReferenceNo',
	round(TI.LOCALVALUE, @nLocalDecimalPlaces) as 'LocalValue',
	round(TI.LOCALBALANCE, @nLocalDecimalPlaces) as 'LocalBalance',
	TI.FOREIGNVALUE as 'ForeignValue',
	TI.FOREIGNBALANCE as 'ForeignBalance',
	TI.EXCHVARIANCE as 'ExchVariance',
	@sLocalCurrencyCode as 'LocalCurrency',
	TI.CURRENCY as 'Currency',
	ATT.DESCRIPTION AS 'TransType',
	ISNULL(TI.DESCRIPTION, TI.LONGDESCRIPTION) AS 'Description'

	from TRUSTITEM TI
	join NAME ENT ON ENT.NAMENO = TI.TACCTENTITYNO
	join NAME TRADER ON TRADER.NAMENO = TI.TACCTNAMENO
	
	left join TrustHistoryTree TR on (TR.ChildEntityNo=TI.TACCTENTITYNO
	                              and TR.ChildTransNo =TI.ITEMTRANSNO)
	join CASHITEM CI ON (CI.ACCTENTITYNO = isnull(TR.OrigEntityNo, TI.TACCTENTITYNO)
			 AND CI.TRANSNO      = isnull(TR.OrigTransNo, TI.ITEMTRANSNO))
			 
	join BANKACCOUNT BA ON (BA.BANKNAMENO = CI.BANKNAMENO
				AND BA.ACCOUNTOWNER = CI.ACCTENTITYNO
				AND BA.SEQUENCENO = CI.SEQUENCENO)
	join TRANSACTIONHEADER TH ON (TH.ENTITYNO = TI.ITEMENTITYNO
				AND TH.TRANSNO = TI.ITEMTRANSNO)
	join ACCT_TRANS_TYPE ATT ON (ATT.TRANS_TYPE_ID = TH.TRANSTYPE)

	WHERE TI.LOCALBALANCE != 0
	and TI.TACCTNAMENO = @pnNameKey
	and TI.TACCTENTITYNO = @pnEntityKey
	and CI.BANKNAMENO = @pnBankKey
	and CI.SEQUENCENO = @pnBankSeqNo
	"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnEntityKey		int,
					  @pnBankKey		int,
					  @pnBankSeqNo		int,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	int',
					  @pnNameKey		= @pnNameKey,
					  @pnEntityKey		= @pnEntityKey,
					  @pnBankKey		= @pnBankKey,
					  @pnBankSeqNo		= @pnBankSeqNo,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameTrustAccountingDetail to public
GO
