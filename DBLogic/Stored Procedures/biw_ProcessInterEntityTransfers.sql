-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ProcessInterEntityTransfers
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ProcessInterEntityTransfers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.biw_ProcessInterEntityTransfers.'
	drop procedure dbo.biw_ProcessInterEntityTransfers
End
print '**** Creating Stored Procedure dbo.biw_ProcessInterEntityTransfers...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ProcessInterEntityTransfers
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	
	-- Open Item Key
	@pnItemEntityKey		int,	-- the new entity
	@pnItemTransKey			int	-- the OpenItem transaction key
)		
-- PROCEDURE :	biw_ProcessInterEntityTransfers
-- VERSION :	9
-- DESCRIPTION:	Perform Inter-Entity transfer transaction against WIP Items on an open item.
--		Note: This must be called:
--		AFTER the original WIP items have been consumed and adjusted
--
-- CALLED BY :	Inprotech Web

-- MODIFICTIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	---------------	-------	----------------------------------------------- 
-- 20-Oct-2011	AT	RFC10168	1	Procedure created.
-- 04-Nov-2011	AT	RFC10168	2	Fixed cursor retrieving incorrect entity key.
-- 05-Dec-2011	AT	RFC11657	3	Changed name of temp table to avoid conflict with biw_CreditBill.
-- 16-Dec-2011	AT	RFC11657	4	Fixed where clause filtering out transfer for credit full bills
-- 31-Jan-2012	AT	RFC11862	5	Fixed HistoryLineNo bug with inter-entity write downs.
-- 04-Apr-2012	AT	RFC12146	6	Fixed updating control total for transfer to entity.
-- 16-Apr-2012	AT	RFC12171	7	Fixed Post Period for inter-entity transaction.
-- 14-Jan-2013	CR	RFC13093	8	Fixed setting of ENTRYDATE and ASSOCLINENO.
-- 20 Oct 2015  MS      R53933          9       Changed size from decimal(8,4) to decimal(11,4) for ExchRate cols

as

SET CONCAT_NULL_YIELDS_NULL OFF

-- This must be off if the procedure does multiple inserts/updates/deletes (For concurrency checking).
SET NOCOUNT on

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)
Declare @sAlertXML		nvarchar(1000)
Declare @nRowCount		int

Declare @bDebug			bit
Declare @nGLJournalCreation	int
Declare @nResult		int

-- OpenItem details
Declare @nStaffKey		int

Set @bDebug = 0

Set @nRowCount = 0
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Insert new Transaction Header
-- Adjust WORKHISTORY against new entity
-- Adjust WORKHISTORY against old entity
-- Update Control Totals

Declare @nNewTransKey int
Declare @dtTransDate datetime
Declare @dtEntryDate datetime
Declare @dtTranPostDate	datetime
Declare @nPostPeriod int

-- Check if there are transfers to process
if not exists (select * from WORKHISTORY
		WHERE REFENTITYNO = @pnItemEntityKey
		and REFTRANSNO = @pnItemTransKey
		and REFENTITYNO != ENTITYNO)
Begin		
	if (@bDebug = 1)
	Begin
		print 'Inter-Entity Transfers not required.'
	End
	
	return
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @nGLJournalCreation = COLINTEGER
		From SITECONTROL
		Where CONTROLID = 'GL Journal Creation'"

	exec	@nErrorCode = sp_executesql @sSQLString,
					N'@nGLJournalCreation	int 			OUTPUT',
					@nGLJournalCreation = @nGLJournalCreation	OUTPUT
					
	if (@bDebug = 1)
	Begin
		print 'GL Journal Creation is: ' + cast(@nGLJournalCreation as nvarchar(13))
	End
End


If @nErrorCode = 0
Begin		
	if (@bDebug = 1)
	Begin
		print 'Get details of OpenItem'
	End

	Set @sSQLString = "Select @nStaffKey = EMPLOYEENO,
			@dtTransDate = TRANSDATE,
			@dtTranPostDate = TRANPOSTDATE,
			@nPostPeriod = TRANPOSTPERIOD
			From TRANSACTIONHEADER
			Where ENTITYNO = @pnItemEntityKey
			and TRANSNO = @pnItemTransKey"

	exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nStaffKey		int OUTPUT,
				@dtTransDate		datetime OUTPUT,
				@dtTranPostDate		datetime OUTPUT,
				@nPostPeriod		int OUTPUT,
				@pnItemEntityKey	int,
				@pnItemTransKey		int',
				@nStaffKey = @nStaffKey	OUTPUT,
				@dtTransDate = @dtTransDate	OUTPUT,
				@dtTranPostDate = @dtTranPostDate OUTPUT,
				@nPostPeriod = @nPostPeriod OUTPUT,
				@pnItemEntityKey = @pnItemEntityKey,
				@pnItemTransKey = @pnItemTransKey
End

If @nErrorCode = 0
Begin
	Set @dtEntryDate = getdate()
End

If @nErrorCode = 0 and @nPostPeriod is null
Begin
	Select @nPostPeriod = dbo.fn_GetPostPeriod(@dtTransDate,2)
End

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPWORKHISTORY_IEBILLING')
Begin
	drop table #TEMPWORKHISTORY_IEBILLING
End

-- Use temp work history table so we can control the history line numbers.
CREATE table #TEMPWORKHISTORY_IEBILLING
(
	ROWKEY	int identity(1,1),
	ENTITYNO int NOT NULL,
	TRANSNO int NOT NULL,
	WIPSEQNO smallint NOT NULL,
	HISTORYLINENO int null,
	TRANSDATE datetime NULL,
	POSTDATE datetime NULL,
	TRANSTYPE smallint NULL,
	RATENO int NULL,
	WIPCODE nvarchar(6) collate database_default NULL,
	CASEID int NULL,
	ACCTENTITYNO int NULL,
	ACCTCLIENTNO int NULL,
	EMPLOYEENO int NULL,
	TOTALTIME datetime NULL,
	TOTALUNITS smallint NULL,
	UNITSPERHOUR smallint NULL,
	CHARGEOUTRATE decimal(11, 2) NULL,
	ASSOCIATENO int NULL,
	INVOICENUMBER nvarchar(20) collate database_default NULL,
	FOREIGNCURRENCY nvarchar(3) collate database_default NULL,
	FOREIGNTRANVALUE decimal(11, 2) NULL,
	EXCHRATE decimal(11, 4) NULL,
	LOCALTRANSVALUE decimal(11, 2) NULL,
	REFENTITYNO int NULL,
	REFTRANSNO int NULL,
	REFSEQNO int NULL,
	REFACCTENTITYNO int NULL,
	REFACCTDEBTORNO int NULL,
	REASONCODE nvarchar(2) collate database_default NULL,
	BILLLINENO smallint NULL,
	EMPPROFITCENTRE nvarchar(6) collate database_default NULL,
	CASEPROFITCENTRE nvarchar(6) collate database_default NULL,
	NARRATIVENO smallint NULL,
	SHORTNARRATIVE nvarchar(max) collate database_default NULL,
	ASSOCLINENO smallint NULL,
	TRANSFERDETAIL int NULL,
	STATUS smallint NULL,
	ORIGMOVEMENTCLASS smallint NULL,
	MOVEMENTCLASS smallint NULL,
	COMMANDID smallint NULL,
	ITEMIMPACT smallint NULL,
	POSTPERIOD int NULL,
	VARIABLEFEEAMT decimal(11, 2) NULL,
	VARIABLEFEETYPE smallint NULL,
	VARIABLEFEECURR nvarchar(3) collate database_default NULL,
	FEECRITERIANO int NULL,
	FEEUNIQUEID smallint NULL,
	GLMOVEMENTNO int NULL,
	QUOTATIONNO int NULL,
	EMPFAMILYNO smallint NULL,
	EMPOFFICECODE int NULL,
	VERIFICATIONNUMBER nvarchar(20) collate database_default NULL,
	LOCALCOST decimal(11, 2) NULL,
	FOREIGNCOST decimal(11, 2) NULL,
	ENTEREDQUANTITY int NULL,
	DISCOUNTFLAG decimal(1, 0) NULL,
	NARRATIVE_TID int NULL,
	COSTCALCULATION1 decimal(11, 2) NULL,
	COSTCALCULATION2 decimal(11, 2) NULL,
	PRODUCTCODE int NULL,
	GENERATEDINADVANCE decimal(1, 0) NULL,
	MATCHENTITYNO int NULL,
	MATCHTRANSNO int NULL,
	MATCHWIPSEQNO int NULL,
	MATCHEDTOOPENITEM bit NULL,
	MATCHEDFULLY bit NULL,
	MARGINNO int NULL,
	MARGINFLAG bit NULL,
	PROTOCOLNO nvarchar(20) collate database_default NULL,
	PROTOCOLDATE datetime NULL,
	MAXHISTORYLINENO	INT NULL
)


-- Insert Adjustment for new entity
If @nErrorCode = 0
Begin
	Insert into #TEMPWORKHISTORY_IEBILLING (
	ENTITYNO,
	TRANSNO,
	WIPSEQNO,
	HISTORYLINENO,
	TRANSDATE,
	POSTDATE,
	TRANSTYPE,
	RATENO,
	WIPCODE,
	CASEID,
	ACCTENTITYNO,
	ACCTCLIENTNO,
	EMPLOYEENO,
	TOTALTIME,
	TOTALUNITS,
	UNITSPERHOUR,
	CHARGEOUTRATE,
	ASSOCIATENO,
	INVOICENUMBER,
	FOREIGNCURRENCY,
	FOREIGNTRANVALUE,
	EXCHRATE,
	LOCALTRANSVALUE,
	REFENTITYNO,
	REFTRANSNO,
	REFSEQNO,
	REFACCTENTITYNO,
	REFACCTDEBTORNO,
	REASONCODE,
	BILLLINENO,
	EMPPROFITCENTRE,
	CASEPROFITCENTRE,
	NARRATIVENO,
	SHORTNARRATIVE,
	ASSOCLINENO,
	TRANSFERDETAIL,
	STATUS,
	ORIGMOVEMENTCLASS,
	MOVEMENTCLASS,
	COMMANDID,
	ITEMIMPACT,
	POSTPERIOD,
	VARIABLEFEEAMT,
	VARIABLEFEETYPE,
	VARIABLEFEECURR,
	FEECRITERIANO,
	FEEUNIQUEID,
	--GLMOVEMENTNO,
	QUOTATIONNO,
	EMPFAMILYNO,
	EMPOFFICECODE,
	VERIFICATIONNUMBER,
	LOCALCOST,
	FOREIGNCOST,
	ENTEREDQUANTITY,
	DISCOUNTFLAG,
	--NARRATIVE_TID,
	COSTCALCULATION1,
	COSTCALCULATION2,
	PRODUCTCODE,
	GENERATEDINADVANCE,
	--MATCHENTITYNO,
	--MATCHTRANSNO,
	--MATCHWIPSEQNO,
	--MATCHEDTOOPENITEM,
	--MATCHEDFULLY,
	MARGINNO,
	MARGINFLAG,
	PROTOCOLNO,
	PROTOCOLDATE)
	
	SELECT 
	ENTITYNO,
	TRANSNO,
	WIPSEQNO,
	1,--HISTORYLINENO,
	@dtTransDate,
	@dtTranPostDate,
	600,
	RATENO,
	WIPCODE,
	CASEID,
	ACCTENTITYNO,
	ACCTCLIENTNO,
	EMPLOYEENO,
	TOTALTIME,
	TOTALUNITS,
	UNITSPERHOUR,
	CHARGEOUTRATE,
	ASSOCIATENO,
	INVOICENUMBER,
	FOREIGNCURRENCY,
	FOREIGNTRANVALUE * -1,
	EXCHRATE,
	LOCALTRANSVALUE * -1,
	REFENTITYNO,
	REFTRANSNO,
	REFSEQNO,
	REFACCTENTITYNO,
	REFACCTDEBTORNO,
	'_E',
	NULL,
	EMPPROFITCENTRE,
	CASEPROFITCENTRE,
	NARRATIVENO,
	SHORTNARRATIVE,
	null, --ASSOCLINENO, UPDATE THIS LATER
	null, --TRANSFERDETAIL,
	1, --STATUS,
	MOVEMENTCLASS, -- MOVMENTCLASS of row in the bill, will be either 2(Consume) or 4 or 5 (Adjustment for variations)
	CASE WHEN (LOCALTRANSVALUE * -1) > 0 THEN 4 ELSE 5 END,	-- this needs to be 4 or 5
	CASE WHEN (LOCALTRANSVALUE * -1) > 0 THEN 5 ELSE 6 END,	-- this needs to be 5 or 6
	null, --ITEMIMPACT,
	@nPostPeriod,
	VARIABLEFEEAMT,
	VARIABLEFEETYPE,
	VARIABLEFEECURR,
	FEECRITERIANO,
	FEEUNIQUEID,
	--GLMOVEMENTNO,
	QUOTATIONNO,
	EMPFAMILYNO,
	EMPOFFICECODE,
	VERIFICATIONNUMBER,
	LOCALCOST * -1,
	FOREIGNCOST * -1,
	ENTEREDQUANTITY,
	DISCOUNTFLAG,
	--NARRATIVE_TID,
	COSTCALCULATION1 * -1,
	COSTCALCULATION2 * -1,
	PRODUCTCODE,
	GENERATEDINADVANCE,
	--MATCHENTITYNO,
	--MATCHTRANSNO,
	--MATCHWIPSEQNO,
	--MATCHEDTOOPENITEM,
	--MATCHEDFULLY,
	MARGINNO,
	MARGINFLAG,
	PROTOCOLNO,
	PROTOCOLDATE
	FROM WORKHISTORY WH
	-- Insert a row for all WIP modified by this transaction
	WHERE WH.REFENTITYNO = @pnItemEntityKey
	AND WH.REFTRANSNO = @pnItemTransKey
	AND WH.ENTITYNO != WH.REFENTITYNO
	-- (xfIsSuppressInterEntity) 
	-- Don't transfer if:
	-- Credit full bill
	-- and write down wip
	-- and NOT consuming a reversal item) 
	AND NOT (WH.TRANSTYPE = 511
		AND WH.REASONCODE IS NOT NULL
		AND NOT	(WH.MOVEMENTCLASS = 2 AND WH.ITEMIMPACT = 9))
End

-- Insert Adjustment for original entity
If @nErrorCode = 0
Begin
	Insert into #TEMPWORKHISTORY_IEBILLING (
	ENTITYNO,
	TRANSNO,
	WIPSEQNO,
	HISTORYLINENO,
	TRANSDATE,
	POSTDATE,
	TRANSTYPE,
	RATENO,
	WIPCODE,
	CASEID,
	ACCTENTITYNO,
	ACCTCLIENTNO,
	EMPLOYEENO,
	TOTALTIME,
	TOTALUNITS,
	UNITSPERHOUR,
	CHARGEOUTRATE,
	ASSOCIATENO,
	INVOICENUMBER,
	FOREIGNCURRENCY,
	FOREIGNTRANVALUE,
	EXCHRATE,
	LOCALTRANSVALUE,
	REFENTITYNO,
	REFTRANSNO,
	REFSEQNO,
	REFACCTENTITYNO,
	REFACCTDEBTORNO,
	REASONCODE,
	BILLLINENO,
	EMPPROFITCENTRE,
	CASEPROFITCENTRE,
	NARRATIVENO,
	SHORTNARRATIVE,
	ASSOCLINENO,
	TRANSFERDETAIL,
	STATUS,
	ORIGMOVEMENTCLASS,
	MOVEMENTCLASS,
	COMMANDID,
	ITEMIMPACT,
	POSTPERIOD,
	VARIABLEFEEAMT,
	VARIABLEFEETYPE,
	VARIABLEFEECURR,
	FEECRITERIANO,
	FEEUNIQUEID,
	--GLMOVEMENTNO,
	QUOTATIONNO,
	EMPFAMILYNO,
	EMPOFFICECODE,
	VERIFICATIONNUMBER,
	LOCALCOST,
	FOREIGNCOST,
	ENTEREDQUANTITY,
	DISCOUNTFLAG,
	--NARRATIVE_TID,
	COSTCALCULATION1,
	COSTCALCULATION2,
	PRODUCTCODE,
	GENERATEDINADVANCE,
	--MATCHENTITYNO,
	--MATCHTRANSNO,
	--MATCHWIPSEQNO,
	--MATCHEDTOOPENITEM,
	--MATCHEDFULLY,
	MARGINNO,
	MARGINFLAG,
	PROTOCOLNO,
	PROTOCOLDATE)
	
	SELECT 
	ENTITYNO,
	TRANSNO,
	WIPSEQNO,
	2,--HISTORYLINENO,
	@dtTransDate,
	@dtTranPostDate,
	600,
	RATENO,
	WIPCODE,
	CASEID,
	ACCTENTITYNO,
	ACCTCLIENTNO,
	EMPLOYEENO,
	TOTALTIME,
	TOTALUNITS,
	UNITSPERHOUR,
	CHARGEOUTRATE,
	ASSOCIATENO,
	INVOICENUMBER,
	FOREIGNCURRENCY,
	FOREIGNTRANVALUE,
	EXCHRATE,
	LOCALTRANSVALUE,
	ENTITYNO, -- THE ORIGINAL ENTITY
	null, -- THE NEW TRANSACTION NO
	REFSEQNO,
	REFACCTENTITYNO,
	REFACCTDEBTORNO,
	'_E',
	NULL,
	EMPPROFITCENTRE,
	CASEPROFITCENTRE,
	NARRATIVENO,
	SHORTNARRATIVE,
	null, --ASSOCLINENO, UPDATE THIS LATER
	null, --TRANSFERDETAIL,
	1, --STATUS,
	MOVEMENTCLASS, -- MOVMENTCLASS of row in the bill, will be either 2(Consume) or 4 or 5 (Adjustment for variations)
	CASE WHEN (LOCALTRANSVALUE) > 0 THEN 4 ELSE 5 END,
	CASE WHEN (LOCALTRANSVALUE) > 0 THEN 5 ELSE 6 END,
	null, --ITEMIMPACT,
	@nPostPeriod,
	VARIABLEFEEAMT,
	VARIABLEFEETYPE,
	VARIABLEFEECURR,
	FEECRITERIANO,
	FEEUNIQUEID,
	--GLMOVEMENTNO,
	QUOTATIONNO,
	EMPFAMILYNO,
	EMPOFFICECODE,
	VERIFICATIONNUMBER,
	LOCALCOST,
	FOREIGNCOST,
	ENTEREDQUANTITY,
	DISCOUNTFLAG,
	--NARRATIVE_TID,
	COSTCALCULATION1,
	COSTCALCULATION2,
	PRODUCTCODE,
	GENERATEDINADVANCE,
	--MATCHENTITYNO,
	--MATCHTRANSNO,
	--MATCHWIPSEQNO,
	--MATCHEDTOOPENITEM,
	--MATCHEDFULLY,
	MARGINNO,
	MARGINFLAG,
	PROTOCOLNO,
	PROTOCOLDATE
	FROM WORKHISTORY WH
	-- Insert a row for all WIP modified by this transaction
	WHERE WH.REFENTITYNO = @pnItemEntityKey
	AND WH.REFTRANSNO = @pnItemTransKey
	AND WH.ENTITYNO != WH.REFENTITYNO
	AND NOT (WH.TRANSTYPE = 511
		AND WH.REASONCODE IS NOT NULL
		AND NOT	(WH.MOVEMENTCLASS = 2 AND WH.ITEMIMPACT = 9))
End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Update history line numbers'
		-- in case there's a WIP variation, (we might have more than 1 row per movement).
	End

	Set @sSQLString = 'UPDATE TWH
		SET TWH.HISTORYLINENO = TWH_ORDERED.HISTLINENO
		FROM #TEMPWORKHISTORY_IEBILLING TWH
		JOIN (SELECT ROW_NUMBER() OVER(PARTITION BY ENTITYNO, TRANSNO, WIPSEQNO ORDER BY ROWKEY) AS HISTLINENO,
			ROWKEY
			FROM #TEMPWORKHISTORY_IEBILLING) TWH_ORDERED ON (TWH_ORDERED.ROWKEY = TWH.ROWKEY)'
	
	exec @nErrorCode=sp_executesql @sSQLString

End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
		print 'Get next history line numbers'
	End
	
	Set @sSQLString = 'UPDATE TWH
		SET MAXHISTORYLINENO = MAXHLN.MAXHISTLINENO
		FROM #TEMPWORKHISTORY_IEBILLING TWH
		JOIN (SELECT WHX.TRANSNO, MAX(WHX.HISTORYLINENO) AS MAXHISTLINENO
			FROM WORKHISTORY WHX
			JOIN #TEMPWORKHISTORY_IEBILLING TWHX ON TWHX.TRANSNO = WHX.TRANSNO
			GROUP BY WHX.TRANSNO) MAXHLN ON MAXHLN.TRANSNO = TWH.TRANSNO'
	
	exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	if (@bDebug = 1)
	Begin
	
		SELECT TWH1.MAXHISTORYLINENO + TWH1.HISTORYLINENO AS CALCASSOCLINENO, TWH.MAXHISTORYLINENO + TWH.HISTORYLINENO AS CALCHISTORYLINENO, 
		TWH.MAXHISTORYLINENO, TWH.ROWKEY, TWH.ENTITYNO, TWH.TRANSNO, TWH.WIPSEQNO, TWH.HISTORYLINENO, TWH.WIPCODE, TWH.CASEID, TWH.LOCALTRANSVALUE, TWH.REFENTITYNO, TWH.REFTRANSNO, TWH.MOVEMENTCLASS
		FROM #TEMPWORKHISTORY_IEBILLING TWH
		JOIN #TEMPWORKHISTORY_IEBILLING TWH1	ON (TWH1.ENTITYNO = TWH.ENTITYNO
							AND TWH1.TRANSNO = TWH.TRANSNO
							AND TWH1.WIPSEQNO = TWH.WIPSEQNO
							AND TWH1.ORIGMOVEMENTCLASS = TWH.ORIGMOVEMENTCLASS
							AND TWH1.REFENTITYNO <> TWH.REFENTITYNO
							AND TWH1.MOVEMENTCLASS <> TWH.MOVEMENTCLASS)
 
		PRINT ''
		print 'update ASSOCLINENO'
	End
	
	Set @sSQLString = 'UPDATE TWH
	SET ASSOCLINENO = TWH1.MAXHISTORYLINENO + TWH1.HISTORYLINENO
	FROM #TEMPWORKHISTORY_IEBILLING TWH
	JOIN #TEMPWORKHISTORY_IEBILLING TWH1	ON (TWH1.ENTITYNO = TWH.ENTITYNO
						AND TWH1.TRANSNO = TWH.TRANSNO
						AND TWH1.WIPSEQNO = TWH.WIPSEQNO
						AND TWH1.ORIGMOVEMENTCLASS = TWH.ORIGMOVEMENTCLASS
						AND TWH1.REFENTITYNO <> TWH.REFENTITYNO
						AND TWH1.MOVEMENTCLASS <> TWH.MOVEMENTCLASS)'

	if (@bDebug = 1)
	Begin
		print @sSQLString
		PRINT ''
	End

	exec @nErrorCode=sp_executesql @sSQLString
	
	if (@bDebug = 1)
	Begin
		PRINT 'After Update'
		SELECT ASSOCLINENO, MAXHISTORYLINENO, REFENTITYNO, REFTRANSNO, ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, TRANSTYPE, MOVEMENTCLASS, WIPCODE, CASEID, LOCALTRANSVALUE
		FROM #TEMPWORKHISTORY_IEBILLING
		ORDER BY REFTRANSNO, TRANSNO, WIPSEQNO, HISTORYLINENO, TRANSTYPE, POSTDATE 
		PRINT ''
	End
End


-- Start inserting the data:

declare @nFirstTransKey	int
DECLARE @nNewEntityKey	int

If @nErrorCode = 0 and exists (select * from #TEMPWORKHISTORY_IEBILLING)
Begin
	-- Insert a transaction header for each affected entity
	DECLARE TransactionHeader_Cursor CURSOR FOR 
		SELECT DISTINCT ENTITYNO FROM #TEMPWORKHISTORY_IEBILLING
		WHERE  ENTITYNO != REFENTITYNO

	OPEN TransactionHeader_Cursor

	FETCH NEXT FROM TransactionHeader_Cursor 
	INTO @nNewEntityKey

	WHILE (@nErrorCode = 0 and @@FETCH_STATUS = 0)
	Begin
		-- Get a new Transaction Key
		Exec @nErrorCode = dbo.ip_GetLastInternalCode
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psTable		= N'TRANSACTIONHEADER',
				@pnLastInternalCode	= @nNewTransKey OUTPUT
								
		if (@bDebug = 1)
		Begin
			print 'New Trans Key is: ' + cast(@nNewTransKey as nvarchar(13))
		End
		
		if @nFirstTransKey is null
		Begin
			Set @nFirstTransKey = @nNewTransKey
		End
		
		If @nErrorCode = 0
		Begin
			if (@bDebug = 1)
			Begin
				print 'Inserting Transaction Header for entity: ' +  + cast(@nNewEntityKey as nvarchar(13))
			End
			-- Source = 2 (Time and Billing)
			-- TransStatus = 1 (active)

			Set @sSQLString = "
			INSERT INTO TRANSACTIONHEADER (ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE,
			BATCHNO, EMPLOYEENO, USERID, ENTRYDATE, 
			SOURCE, TRANSTATUS, GLSTATUS, TRANPOSTPERIOD, TRANPOSTDATE, IDENTITYID)

			SELECT @nNewEntityKey, @nNewTransKey, @dtTransDate, 600,
			null, @nStaffKey, system_user, @dtEntryDate,
			2, 1, case when @nGLJournalCreation is not null then 0 ELSE NULL end, @nPostPeriod, @dtTranPostDate, @pnUserIdentityId"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNewEntityKey	int,
						@nNewTransKey		int,
						@nStaffKey		int,
						@nGLJournalCreation	int,
						@nPostPeriod		int,
						@dtTransDate		datetime,
						@pnUserIdentityId	int,
						@dtEntryDate		datetime,
						@dtTranPostDate		datetime',
						@nNewEntityKey = @nNewEntityKey,
						@nNewTransKey = @nNewTransKey,
						@nStaffKey = @nStaffKey,
						@nGLJournalCreation = @nGLJournalCreation,
						@nPostPeriod = @nPostPeriod,
						@dtTransDate = @dtTransDate,
						@pnUserIdentityId = @pnUserIdentityId,
						@dtEntryDate = @dtEntryDate,
						@dtTranPostDate = @dtTranPostDate						
		End

		FETCH NEXT FROM TransactionHeader_Cursor 
		INTO @nNewEntityKey
	End

	CLOSE TransactionHeader_Cursor
	DEALLOCATE TransactionHeader_Cursor

	-- update temp table with trans keys:
	If @nErrorCode = 0
	Begin
	
	Set @sSQLString = 'UPDATE TWH
			SET REFTRANSNO = TH.TRANSNO
			from TRANSACTIONHEADER TH
			JOIN #TEMPWORKHISTORY_IEBILLING TWH ON TWH.REFENTITYNO = TH.ENTITYNO
			and TH.TRANSNO between @nFirstTransKey and @nNewTransKey
			AND TWH.REFTRANSNO IS NULL'
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nFirstTransKey	int,
						@nNewTransKey		int',
						@nFirstTransKey = @nFirstTransKey,
						@nNewTransKey = @nNewTransKey
	End
	

	If @nErrorCode = 0 and exists (select * from #TEMPWORKHISTORY_IEBILLING)
	Begin
		if (@bDebug = 1)
		Begin
			print 'Inserting rows into WorkHistory'
			--select * from #TEMPWORKHISTORY_IEBILLING
		End
		
		Insert into WORKHISTORY (
		ENTITYNO,
		TRANSNO,
		WIPSEQNO,
		HISTORYLINENO,
		TRANSDATE,
		POSTDATE,
		TRANSTYPE,
		RATENO,
		WIPCODE,
		CASEID,
		ACCTENTITYNO,
		ACCTCLIENTNO,
		EMPLOYEENO,
		TOTALTIME,
		TOTALUNITS,
		UNITSPERHOUR,
		CHARGEOUTRATE,
		ASSOCIATENO,
		INVOICENUMBER,
		FOREIGNCURRENCY,
		FOREIGNTRANVALUE,
		EXCHRATE,
		LOCALTRANSVALUE,
		REFENTITYNO,
		REFTRANSNO,
		REFSEQNO,
		REFACCTENTITYNO,
		REFACCTDEBTORNO,
		REASONCODE,
		BILLLINENO,
		EMPPROFITCENTRE,
		CASEPROFITCENTRE,
		NARRATIVENO,
		SHORTNARRATIVE,
		ASSOCLINENO,
		TRANSFERDETAIL,
		STATUS,
		MOVEMENTCLASS,
		COMMANDID,
		ITEMIMPACT,
		POSTPERIOD,
		VARIABLEFEEAMT,
		VARIABLEFEETYPE,
		VARIABLEFEECURR,
		FEECRITERIANO,
		FEEUNIQUEID,
		--GLMOVEMENTNO,
		QUOTATIONNO,
		EMPFAMILYNO,
		EMPOFFICECODE,
		VERIFICATIONNUMBER,
		LOCALCOST,
		FOREIGNCOST,
		ENTEREDQUANTITY,
		DISCOUNTFLAG,
		--NARRATIVE_TID,
		COSTCALCULATION1,
		COSTCALCULATION2,
		PRODUCTCODE,
		GENERATEDINADVANCE,
		--MATCHENTITYNO,
		--MATCHTRANSNO,
		--MATCHWIPSEQNO,
		--MATCHEDTOOPENITEM,
		--MATCHEDFULLY,
		MARGINNO,
		MARGINFLAG,
		PROTOCOLNO,
		PROTOCOLDATE)
		SELECT
		ENTITYNO,
		TRANSNO,
		WIPSEQNO,
		HISTORYLINENO + MAXHISTORYLINENO,
		TRANSDATE,
		POSTDATE,
		TRANSTYPE,
		RATENO,
		WIPCODE,
		CASEID,
		ACCTENTITYNO,
		ACCTCLIENTNO,
		EMPLOYEENO,
		TOTALTIME,
		TOTALUNITS,
		UNITSPERHOUR,
		CHARGEOUTRATE,
		ASSOCIATENO,
		INVOICENUMBER,
		FOREIGNCURRENCY,
		FOREIGNTRANVALUE,
		EXCHRATE,
		LOCALTRANSVALUE,
		REFENTITYNO,
		REFTRANSNO,
		REFSEQNO,
		REFACCTENTITYNO,
		REFACCTDEBTORNO,
		REASONCODE,
		BILLLINENO,
		EMPPROFITCENTRE,
		CASEPROFITCENTRE,
		NARRATIVENO,
		SHORTNARRATIVE,
		ASSOCLINENO,
		TRANSFERDETAIL,
		STATUS,
		MOVEMENTCLASS,
		COMMANDID,
		ITEMIMPACT,
		POSTPERIOD,
		VARIABLEFEEAMT,
		VARIABLEFEETYPE,
		VARIABLEFEECURR,
		FEECRITERIANO,
		FEEUNIQUEID,
		--GLMOVEMENTNO,
		QUOTATIONNO,
		EMPFAMILYNO,
		EMPOFFICECODE,
		VERIFICATIONNUMBER,
		LOCALCOST,
		FOREIGNCOST,
		ENTEREDQUANTITY,
		DISCOUNTFLAG,
		--NARRATIVE_TID,
		COSTCALCULATION1,
		COSTCALCULATION2,
		PRODUCTCODE,
		GENERATEDINADVANCE,
		--MATCHENTITYNO,
		--MATCHTRANSNO,
		--MATCHWIPSEQNO,
		--MATCHEDTOOPENITEM,
		--MATCHEDFULLY,
		MARGINNO,
		MARGINFLAG,
		PROTOCOLNO,
		PROTOCOLDATE
		FROM #TEMPWORKHISTORY_IEBILLING
	End


	-- Update control totals

	declare @nControlTotal decimal(13,2)
	declare @nControlEntity	int

	-- for the new bill entity
	If @nErrorCode = 0
	Begin
		Set @sSQLString ='select @nControlTotal = sum(LOCALTRANSVALUE),
					@nControlEntity = REFENTITYNO
					FROM #TEMPWORKHISTORY_IEBILLING
					where REFENTITYNO = @pnItemEntityKey
					GROUP BY REFENTITYNO'
			
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nControlTotal	decimal(13,2) output,
					@nControlEntity		int output,
					@pnItemEntityKey	int',
					@nControlTotal = @nControlTotal output,
					@nControlEntity = @nControlEntity output,
					@pnItemEntityKey = @pnItemEntityKey
	End

	-- Update control totals for each entity
	If @nErrorCode = 0
	Begin
		Set @sSQLString ='select @nControlEntity = min(REFENTITYNO)
			FROM #TEMPWORKHISTORY_IEBILLING'

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nControlEntity	int output',
					@nControlEntity = @nControlEntity output
	End

	If @nErrorCode = 0
	Begin
		if (@bDebug = 1)
		Begin
			print 'Update Adjust Up Control Totals'
		End
		
		While (@nErrorCode = 0 and @nControlEntity is not null)
		Begin
			if (@bDebug = 1)
			Begin
				print 'Update Adjust UP Control Totals for entity' + cast(@nControlEntity as nvarchar(13))
			End
			
			Set @sSQLString = 'Select @nControlTotal = sum(LOCALTRANSVALUE)
					FROM #TEMPWORKHISTORY_IEBILLING
					where REFENTITYNO = @nControlEntity
					and MOVEMENTCLASS = 4'

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@nControlTotal	decimal(13,2) output,
						@nControlEntity		int',
						@nControlTotal = @nControlTotal output,
						@nControlEntity = @nControlEntity
						
			if (@nErrorCode = 0 and @nControlTotal != 0 and @nControlTotal is not null)
			Begin
				exec @nErrorCode = dbo.acw_UpdateControlTotal
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnLedger = 1, -- WIP Ledger
					@pnCategory	= 4,
					@pnType		= 600,
					@pnPeriodId	= @nPostPeriod,
					@pnEntityNo	= @nControlEntity,
					@pnAmountToAdd	= @nControlTotal
			End
			
			-- Reset the control total
			Set @nControlTotal = null
			
			if (@bDebug = 1)
			Begin
				print 'Update Adjust DOWN Control Totals for entity' + cast(@nControlEntity as nvarchar(13))
			End
			
			If @nErrorCode = 0
			Begin
				Set @sSQLString = 'Select @nControlTotal = sum(LOCALTRANSVALUE)
						FROM #TEMPWORKHISTORY_IEBILLING
						where REFENTITYNO = @nControlEntity
						and MOVEMENTCLASS = 5'

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nControlTotal	decimal(13,2) output,
							@nControlEntity		int',
							@nControlTotal = @nControlTotal output,
							@nControlEntity = @nControlEntity
			End
						
			if (@nErrorCode = 0 and @nControlTotal != 0 and @nControlTotal is not null)
			Begin
				exec @nErrorCode = dbo.acw_UpdateControlTotal
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnLedger = 1, -- WIP Ledger
					@pnCategory	= 5,
					@pnType		= 600,
					@pnPeriodId	= @nPostPeriod,
					@pnEntityNo	= @nControlEntity,
					@pnAmountToAdd	= @nControlTotal
			End
			
			Set @nControlTotal = null
			
			Declare @nOldEntity int
			set @nOldEntity = @nControlEntity
			
			Set @nControlEntity = null
			
			-- Try and get the next Entity
			If @nErrorCode = 0
			Begin
				Set @sSQLString ='select @nControlEntity = min(REFENTITYNO)
					FROM #TEMPWORKHISTORY_IEBILLING
					where REFENTITYNO > @nOldEntity'

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nControlEntity	int output,
							@nOldEntity int',
							@nControlEntity = @nControlEntity output,
							@nOldEntity = @nOldEntity
			End		
		End -- while
	End

	if @nErrorCode = 0
	Begin
		-- Otherwise, transaction completed. Post to GL if necessary.
		If (@bDebug = 1)
		Begin
			Print 'Process GL Interface'
		End
			
		exec @nErrorCode = dbo.fi_CreateAndPostJournals
		  @pnResult = @nResult OUTPUT,
		  @pnUserIdentityId = @pnUserIdentityId,
		  @psCulture = @psCulture,
		  @pbCalledFromCentura = @pbCalledFromCentura,
		  @pnEntityNo = @pnItemEntityKey,
		  @pnTransNo = @nNewTransKey,
		  @pnDesignation = 1,
		  @pbIncProcessedNoJournal = 0
	End
End


If @bDebug = 1
Begin
	SELECT 'TRANSACTIONHEADER'
	SELECT * FROM TRANSACTIONHEADER WHERE TRANSNO = @nNewTransKey
	SELECT 'WORKHISTORY'
	Select * from WORKHISTORY WHERE REFTRANSNO = @nNewTransKey
	SELECT 'FINAL CONTROL TOTALS'
	SELECT * FROM CONTROLTOTAL WHERE LEDGER = 1 AND TYPE = 600 and PERIODID = @nPostPeriod
	select 'GLJOURNAL ROWS'
	SELECT * FROM GLJOURNAL WHERE TRANSNO = @nNewTransKey
	select 'GLJOURNALLINE ROWS'
	SELECT * FROM GLJOURNALLINE WHERE TRANSNO = @nNewTransKey
End


If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPWORKHISTORY_IEBILLING')
Begin
	drop table #TEMPWORKHISTORY_IEBILLING
End




RETURN @nErrorCode
GO

Grant execute on dbo.biw_ProcessInterEntityTransfers  to public
GO