-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.bi_ListReceivableItemWIP
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListReceivableItemWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListReceivableItemWIP...'
	Drop procedure [dbo].[bi_ListReceivableItemWIP]
End
Print '**** Creating Stored Procedure dbo.bi_ListReceivableItemWIP...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.bi_ListReceivableItemWIP
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnItemEntityNo		int,		-- Mandatory
	@pnItemTransNo 		int,		-- Mandatory
	@pnItemLineNo 		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	bi_ListReceivableItemWIP
-- VERSION:	5
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates ReceivableItemWIPData dataset.
--		Lists WIP details regarding a bill line.
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18-Mar-2009  AT	RFC769	1	Procedure created
-- 5-Dec-2012	SW	R12848	2	Fix for showing two rows when there is write down/up value
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).
-- 13 Dec 2016	MS	R69575	4	Add MovementClass in GroupBy for WHBILLED
-- 07 Jan 2019	MF	DR-46379 5	Some discount lines were not being returned because assumption was that WORKHISTORY would always
--					have a row where HISTORYLINENO=1.  Changed query to return the lowest HISTORYLINENO for transaction.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSQLString 		nvarchar(4000)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint

Declare @sLookupCulture		nvarchar(10)
Declare	@dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

Set 	@nErrorCode 		= 0
Set 	@pnRowCount		= 0

--Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End


If @nErrorCode = 0
Begin
	select '-1' as 'RowKey', @sLocalCurrencyCode as 'LocalCurrencyCode', @nLocalDecimalPlaces as 'LocalDecimalPlaces'
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	SELECT CAST(WH.REFENTITYNO as nvarchar(11))+'^'+
		CAST(WH.REFTRANSNO as nvarchar(11))+'^'+
		CAST(WH.BILLLINENO as nvarchar(11))+'^'+
		CAST(WH.TRANSNO as nvarchar(11))+'^'+
		CAST(WH.WIPSEQNO as nvarchar(5))+'^'+
		CAST(WH.HISTORYLINENO as nvarchar(5)) as 'RowKey',
	WH.REFENTITYNO as 'ItemEntityNo',
	WH.REFTRANSNO as 'ItemTransNo',
	WH.BILLLINENO as 'BillLineNo',
	WT.DESCRIPTION as 'WIPDescription', 
	WC.DESCRIPTION as 'CategoryDescription',
	WH1.TRANSDATE as 'TransDate',
	WH.EMPLOYEENO as 'StaffNameKey',
	EN.NAMECODE as 'StaffNameCode',
	RN.DESCRIPTION as 'Reason',
	dbo.fn_FormatNameUsingNameNo(EN.NAMENO, NULL) as 'StaffName',
	case when WH1.TOTALTIME IS NULL THEN NULL ELSE
	isnull(DATEPART(HOUR,WH1.TOTALTIME),0)*60 + isnull(DATEPART(MINUTE, WH1.TOTALTIME),0) END as 'TotalMinutes',
	
	CASE WHEN WH.MOVEMENTCLASS = 2 THEN WHBILLED.LOCALBILLED * -1 ELSE WH.LOCALTRANSVALUE END as 'LocalBilled',
	CASE WHEN WH.MOVEMENTCLASS = 2 THEN WHBILLED.FOREIGNBILLED * -1 ELSE WH.FOREIGNTRANVALUE END as 'ForeignBilled',
	
	WH.FOREIGNCURRENCY as 'ForeignCurrency'
	FROM WORKHISTORY WH
	JOIN (SELECT SUM(LOCALTRANSVALUE) AS LOCALBILLED, SUM(FOREIGNTRANVALUE) AS FOREIGNBILLED,
			ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO, MOVEMENTCLASS
			FROM WORKHISTORY
			GROUP BY ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO, MOVEMENTCLASS) AS WHBILLED
			ON (WHBILLED.ENTITYNO = WH.ENTITYNO
				AND WHBILLED.TRANSNO = WH.TRANSNO
				AND WHBILLED.WIPSEQNO = WH.WIPSEQNO 
				AND WHBILLED.REFENTITYNO = WH.REFENTITYNO
				AND WHBILLED.REFTRANSNO = WH.REFTRANSNO
				AND WHBILLED.MOVEMENTCLASS = WH.MOVEMENTCLASS)
	JOIN WORKHISTORY WH1 ON (WH1.TRANSNO = WH.TRANSNO
				AND WH1.ENTITYNO = WH.ENTITYNO
				AND WH1.WIPSEQNO = WH.WIPSEQNO
				AND WH1.HISTORYLINENO = (select min(WH2.HISTORYLINENO)		-- DR-46379
							 from WORKHISTORY WH2
							 where WH2.ENTITYNO=WH.ENTITYNO
							 and WH2.TRANSNO   =WH.TRANSNO
							 and WH2.WIPSEQNO  =WH.WIPSEQNO))
	JOIN BILLLINE BL ON BL.ITEMLINENO = WH.BILLLINENO
			AND BL.ITEMTRANSNO = WH.REFTRANSNO
			AND BL.ITEMENTITYNO = WH.REFENTITYNO
	JOIN WIPTEMPLATE WT ON WT.WIPCODE = WH.WIPCODE
	JOIN WIPTYPE WTP ON WT.WIPTYPEID = WTP.WIPTYPEID
	JOIN WIPCATEGORY WC ON WC.CATEGORYCODE = WTP.CATEGORYCODE
	LEFT JOIN NAME EN ON EN.NAMENO = WH.EMPLOYEENO
	LEFT JOIN REASON RN ON RN.REASONCODE = WH.REASONCODE
	WHERE BL.ITEMTRANSNO = @pnItemTransNo
	and BL.ITEMENTITYNO = @pnItemEntityNo
	and WH.BILLLINENO = @pnItemLineNo
	ORDER BY WH1.TRANSDATE, WT.DESCRIPTION, WC.DESCRIPTION"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int,
					  @pnItemLineNo		int',
					  @pnItemEntityNo	= @pnItemEntityNo,
					  @pnItemTransNo	= @pnItemTransNo,
					  @pnItemLineNo		= @pnItemLineNo

	Set @pnRowCount = @@Rowcount

End

Return @nErrorCode
GO

Grant execute on dbo.bi_ListReceivableItemWIP to public
GO
