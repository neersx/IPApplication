-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_CopyDraftWIP									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_CopyDraftWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_CopyDraftWIP.'
	Drop procedure [dbo].[biw_CopyDraftWIP]
End
Print '**** Creating Stored Procedure dbo.biw_CopyDraftWIP...'
Print ''
GO

SET QUOTED_IDENTIFIER on
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS on
GO


CREATE PROCEDURE dbo.biw_CopyDraftWIP
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psMergeXMLKeys			nvarchar(max) = null,
	@pnMergeIntoEntityNo		int	= null,
	@pnMergeIntoTransNo		int	= null
)
as
-- PROCEDURE:	biw_CopyDraftWIP
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Copy/merge draft WIP from 1 bill to another.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 29 Apr 2011	AT	RFC7956		1	Procedure created.
-- 15 Jun 2012	AT	RFC12395	2	Exclude Stamp fee WIP as this will be regenerated on merged bills.
-- 29 Jun 2012	KR	RFC12430	3	In order to cater for multi debtor merge, made distinct select from xml keys
-- 28 DEC 2016	AK	RFC55838	4	Removed logic to update status of wip item.

SET CONCAT_NULL_YIELDS_NULL on
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
declare	@sAlertXML              nvarchar(400)
Declare @nMaxWIPSeqNo		int

Declare	@XMLKeys	XML

-- Initialise variables
Set @nErrorCode = 0

if (@psMergeXMLKeys is not null)
Begin		
	Set @XMLKeys = cast(@psMergeXMLKeys as XML)
End

if exists (select O.OPENITEMNO FROM OPENITEM O 
			JOIN (SELECT distinct K.value(N'ItemEntityNo[1]',N'int') as ItemEntityNo,
						K.value(N'ItemTransNo[1]',N'int') as ItemTransNo
					from @XMLKeys.nodes(N'/Keys/Key') KEYS(K)) AS XM
					on (XM.ItemEntityNo = O.ITEMENTITYNO
					and XM.ItemTransNo = O.ITEMTRANSNO)
			WHERE O.STATUS != 0)
Begin
	-- Draft OpenItem not found
	Set @sAlertXML = dbo.fn_GetAlertXML('AC136', 'Open Item could not be found. Item has been modified or is already finalised.',
									null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

-- get the max WIPSeqNo in case there is already draft wip against the bill
If @nErrorCode = 0
Begin
	Set @sSQLString = 'Select @nMaxWIPSeqNo = max(WIPSEQNO)
	FROM WORKINPROGRESS WHERE ENTITYNO = @pnMergeIntoEntityNo
	AND TRANSNO = @pnMergeIntoTransNo'

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nMaxWIPSeqNo	int OUTPUT,
		        @pnMergeIntoEntityNo		int,
			@pnMergeIntoTransNo		int',
			@nMaxWIPSeqNo			= @nMaxWIPSeqNo	OUTPUT,
			@pnMergeIntoEntityNo		= @pnMergeIntoEntityNo,
			@pnMergeIntoTransNo		= @pnMergeIntoTransNo
End

if @nMaxWIPSeqNo is null
Begin
	Set @nMaxWIPSeqNo = 0
End

-- re-map ALL the draft wip to the new trans no
create table #REMAPPEDWIPKEYS
(
	ORIGINALENTITYNO	INT,
	ORIGINALTRANSNO		INT,
	ORIGINALWIPSEQNO	INT,
	NEWWIPSEQNO		int IDENTITY(1,1)
)

if @nErrorCode = 0 and @XMLKeys is not null
Begin
	Set @sSQLString = 'INSERT INTO #REMAPPEDWIPKEYS(ORIGINALENTITYNO, ORIGINALTRANSNO, ORIGINALWIPSEQNO)
				SELECT W.ENTITYNO, W.TRANSNO, W.WIPSEQNO
				FROM WORKINPROGRESS W
				JOIN (select distinct K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
						K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
					from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)) AS XM
					on (XM.ItemEntityNo = W.ENTITYNO
					and XM.ItemTransNo = W.TRANSNO)
				JOIN BILLEDITEM BI ON BI.WIPENTITYNO = W.ENTITYNO
							AND BI.WIPTRANSNO = W.TRANSNO
							AND BI.WIPSEQNO = W.WIPSEQNO
							AND BI.ITEMENTITYNO = XM.ItemEntityNo
							and BI.ITEMTRANSNO = XM.ItemTransNo
				WHERE BI.GENERATEDFROMTAXCODE IS NULL'

	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@XMLKeys	xml',
				@XMLKeys	= @XMLKeys
	
	If @nErrorCode = 0
	Begin
	
		SET @sSQLString = 'INSERT INTO WORKINPROGRESS(ENTITYNO, TRANSNO, WIPSEQNO, TRANSDATE, POSTDATE, RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, ASSOCIATENO, INVOICENUMBER, FOREIGNCURRENCY, FOREIGNVALUE, EXCHRATE, LOCALVALUE, BALANCE, EMPPROFITCENTRE, CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, STATUS, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, FEECRITERIANO, FEEUNIQUEID, QUOTATIONNO, EMPFAMILYNO, EMPOFFICECODE, VERIFICATIONNUMBER, LOCALCOST, FOREIGNCOST, ENTEREDQUANTITY, DISCOUNTFLAG, FOREIGNBALANCE, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, GENERATEDINADVANCE, MARGINNO, MARGINFLAG, BILLINGDISCOUNTFLAG)
		SELECT @pnMergeIntoEntityNo, @pnMergeIntoTransNo, RWK.NEWWIPSEQNO + @nMaxWIPSeqNo, TRANSDATE, POSTDATE, RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, ASSOCIATENO, INVOICENUMBER, FOREIGNCURRENCY, FOREIGNVALUE, EXCHRATE, LOCALVALUE, BALANCE, EMPPROFITCENTRE, CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, STATUS, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, FEECRITERIANO, FEEUNIQUEID, QUOTATIONNO, EMPFAMILYNO, EMPOFFICECODE, VERIFICATIONNUMBER, LOCALCOST, FOREIGNCOST, ENTEREDQUANTITY, DISCOUNTFLAG, FOREIGNBALANCE, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, GENERATEDINADVANCE, MARGINNO, MARGINFLAG, BILLINGDISCOUNTFLAG
		from WORKINPROGRESS WIP
			JOIN #REMAPPEDWIPKEYS RWK ON RWK.ORIGINALENTITYNO = WIP.ENTITYNO
						AND RWK.ORIGINALTRANSNO = WIP.TRANSNO
						AND RWK.ORIGINALWIPSEQNO = WIP.WIPSEQNO'
							
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nMaxWIPSeqNo			int,
			        @pnMergeIntoEntityNo		int,
				@pnMergeIntoTransNo		int',
				@nMaxWIPSeqNo			= @nMaxWIPSeqNo,
				@pnMergeIntoEntityNo		= @pnMergeIntoEntityNo,
				@pnMergeIntoTransNo		= @pnMergeIntoTransNo
	End
	
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'INSERT INTO WORKHISTORY(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, TRANSDATE, POSTDATE, TRANSTYPE, RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, ASSOCIATENO, INVOICENUMBER, FOREIGNCURRENCY, FOREIGNTRANVALUE, EXCHRATE, LOCALTRANSVALUE, REFENTITYNO, REFTRANSNO, REFSEQNO, REFACCTENTITYNO, REFACCTDEBTORNO, REASONCODE, BILLLINENO, EMPPROFITCENTRE, CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, ASSOCLINENO, TRANSFERDETAIL, STATUS, MOVEMENTCLASS, COMMANDID, ITEMIMPACT, POSTPERIOD, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, FEECRITERIANO, FEEUNIQUEID, GLMOVEMENTNO, QUOTATIONNO, EMPFAMILYNO, EMPOFFICECODE, VERIFICATIONNUMBER, LOCALCOST, FOREIGNCOST, ENTEREDQUANTITY, DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, GENERATEDINADVANCE, MATCHENTITYNO, MATCHTRANSNO, MATCHWIPSEQNO, MATCHEDTOOPENITEM, MATCHEDFULLY, MARGINNO, MARGINFLAG, PROTOCOLNO, PROTOCOLDATE)
		SELECT @pnMergeIntoEntityNo, @pnMergeIntoTransNo, RWK.NEWWIPSEQNO + @nMaxWIPSeqNo, HISTORYLINENO, TRANSDATE, POSTDATE, TRANSTYPE, RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, CHARGEOUTRATE, ASSOCIATENO, INVOICENUMBER, FOREIGNCURRENCY, FOREIGNTRANVALUE, EXCHRATE, LOCALTRANSVALUE, @pnMergeIntoEntityNo, @pnMergeIntoTransNo, REFSEQNO, @pnMergeIntoEntityNo, REFACCTDEBTORNO, REASONCODE, BILLLINENO, EMPPROFITCENTRE, CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, ASSOCLINENO, TRANSFERDETAIL, STATUS, MOVEMENTCLASS, COMMANDID, ITEMIMPACT, POSTPERIOD, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR, FEECRITERIANO, FEEUNIQUEID, GLMOVEMENTNO, QUOTATIONNO, EMPFAMILYNO, EMPOFFICECODE, VERIFICATIONNUMBER, LOCALCOST, FOREIGNCOST, ENTEREDQUANTITY, DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, PRODUCTCODE, GENERATEDINADVANCE, MATCHENTITYNO, MATCHTRANSNO, MATCHWIPSEQNO, MATCHEDTOOPENITEM, MATCHEDFULLY, MARGINNO, MARGINFLAG, PROTOCOLNO, PROTOCOLDATE
		from WORKHISTORY WIP
			JOIN #REMAPPEDWIPKEYS RWK ON RWK.ORIGINALENTITYNO = WIP.ENTITYNO
						AND RWK.ORIGINALTRANSNO = WIP.TRANSNO
						AND RWK.ORIGINALWIPSEQNO = WIP.WIPSEQNO'
								
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nMaxWIPSeqNo			int,
			        @pnMergeIntoEntityNo		int,
				@pnMergeIntoTransNo		int',
				@nMaxWIPSeqNo			= @nMaxWIPSeqNo,
				@pnMergeIntoEntityNo		= @pnMergeIntoEntityNo,
				@pnMergeIntoTransNo		= @pnMergeIntoTransNo
	End
				
End
		
			
if (@nErrorCode = 0)
Begin
	-- return all the re-mapped sequence nos to update in the code
	select ORIGINALENTITYNO as 'OriginalEntityNo', ORIGINALTRANSNO as 'OriginalTransNo', ORIGINALWIPSEQNO as 'OriginalWIPSeqNo', NEWWIPSEQNO as 'NewWIPSeqNo'
	from #REMAPPEDWIPKEYS
End

drop table #REMAPPEDWIPKEYS

Return @nErrorCode
GO

Grant execute on dbo.biw_CopyDraftWIP to public
GO

