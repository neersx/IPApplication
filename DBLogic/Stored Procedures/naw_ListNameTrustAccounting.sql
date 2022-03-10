-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameTrustAccounting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameTrustAccounting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameTrustAccounting.'
	Drop procedure [dbo].[naw_ListNameTrustAccounting]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameTrustAccounting...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameTrustAccounting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_ListNameTrustAccounting
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Name Trust Account information.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 30 Sep 2010	AT	R9436	1	Procedure created.
-- 11 Sep 2014	MF	R39202	2	The Trust tab is not showing the trust balance after a Trust Transfer. Find the
--					originating transaction by using TrustHistory to go up the parent tree.
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

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
	Cast(TS.TACCTNAMENO as nvarchar(12)) + '^' + CAST(TS.TACCTENTITYNO AS NVARCHAR(12)) + '^' + CAST(TS.BANKNAMENO AS NVARCHAR(12)) + '^' + CAST(TS.SEQUENCENO AS NVARCHAR(12)) AS 'RowKey',
	TS.TACCTENTITYNO AS 'EntityKey',
	dbo.fn_FormatNameUsingNameNo(ENT.NAMENO, null) as 'Entity',
	TS.BANKNAMENO 'BankAccountNameKey',
	TS.SEQUENCENO 'BankAccountSeqKey', 
	BA.DESCRIPTION AS 'BankAccount',
	round(TS.LocalBalance, @nLocalDecimalPlaces, @nLocalDecimalPlaces) as 'LocalBalance',
	TS.ForeignBalance as 'ForeignBalance',
	@sLocalCurrencyCode as 'LocalCurrency',
	TS.CURRENCY as 'Currency'
	from (select
		TI.TACCTENTITYNO,
		TI.TACCTNAMENO,
		CI.BANKNAMENO, CI.SEQUENCENO,
		SUM(TI.LOCALBALANCE) as 'LocalBalance',
		SUM(ISNULL(TI.FOREIGNBALANCE,0)) as 'ForeignBalance',
		TI.CURRENCY
		from TRUSTITEM TI
		left join TrustHistoryTree TR on (TR.ChildEntityNo=TI.TACCTENTITYNO
		                              and TR.ChildTransNo =TI.ITEMTRANSNO)
		join CASHITEM CI ON (CI.ACCTENTITYNO = isnull(TR.OrigEntityNo, TI.TACCTENTITYNO)
				 AND CI.TRANSNO      = isnull(TR.OrigTransNo,  TI.ITEMTRANSNO))
		WHERE TI.TACCTNAMENO = @pnNameKey
		GROUP BY TI.TACCTENTITYNO, TI.TACCTNAMENO, TI.CURRENCY, CI.BANKNAMENO, CI.SEQUENCENO) as TS
	join NAME ENT ON ENT.NAMENO = TS.TACCTENTITYNO
	join NAME TRADER ON TRADER.NAMENO = TS.TACCTNAMENO
	join BANKACCOUNT BA ON (BA.BANKNAMENO = TS.BANKNAMENO
				AND BA.SEQUENCENO = TS.SEQUENCENO
				AND BA.ACCOUNTOWNER = TS.TACCTENTITYNO)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	int',
					  @pnNameKey = @pnNameKey,
					  @sLocalCurrencyCode = @sLocalCurrencyCode,
					  @nLocalDecimalPlaces = @nLocalDecimalPlaces
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameTrustAccounting to public
GO
