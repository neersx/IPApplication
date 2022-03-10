-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_PostTimeBatch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_PostTimeBatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_PostTimeBatch.'
	Drop procedure [dbo].[ts_PostTimeBatch]
End
Print '**** Creating Stored Procedure dbo.ts_PostTimeBatch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_PostTimeBatch
(
	@pnRowsPosted		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityKey		int,		-- Mandatory
	@psWhereClause		nvarchar(4000),	-- Mandatory
	@pnBatchSize		int		= null,	-- Maximum number of diary entries to post
	@pnDebugFlag		tinyint		= 0, --0=off,1=trace execution,2=dump data        
        @pbHasOfficeEntityError bit             = 0 output
)
as
-- PROCEDURE:	ts_PostTimeBatch
-- VERSION:	30
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create and post a batch of time entries.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 24 Jun 2005	JEK	R2556		1	Procedure created
-- 29 Jun 2005	JEK	R2556		2	Fix case sensitivity error.
-- 30 Jun 2005	TM	R2766		3	Choose action in a similar manner to client/server.
-- 04 Jul 2005	TM	R2777		4	Extract the highest best fit score for the narrative similar to the 
--						extraction of the default WIP template. 
-- 05 Jul 2005	TM	R2777		5	Correct the Narrative default logic.
-- 15 Jul 2005	JEK	R2881		6	Discount WIP rows not being inserted correctly when there is no discount WIP code.
--						Also, selecting action for language best fit was returning multiple rows.
-- 09 Mar 2006	TM	R3651		7	Cast an integer variable or column as nvarchar(20) before comparing it to
--						the TABLEATTRIBUTES.GENERICKEY column.
-- 19 Aug 2008	AT	R6859		8	Store Case Profit Centre in WIP and WorkHistory.
-- 04 Sep 2008  LP      R6904		9	Update CONTROLTOTAL to sum of LOCALTRANSVALUE from WORKHISTORY
-- 18 Nov 2008	MF	17136		10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05 Dec 2008	MF	17200		11	Correct the update of Control Totals.
-- 25 Mar 2009	MS	R7130		12	Add new parameter MarginNo and pass this parameter to 
--						WORKINPROGRESS and WORKHISTORY tables.
-- 01 Apr 2009	MF	R7835		13	Narrative for discount is not being correctly determined when posting transaction.
-- 29 Jul 2009  PS	R8173		14	In Create Account section add Distinct to Select query to avoid multiple entry with same NAMENO in the ACCOUNT table.
-- 23 Feb 2010	MS	R7268		15	Condition for ChargeOutRate added for IsComplete check.
-- 25 Mar 2010	KR	R8407		16	Added code for Financial Interface Journal Creation
-- 19 Aug 2010  MS  	R9685		17	Add DebtorNo in best fit criteria for Discount Narrative
-- 09 Aut 2011	MF	R11087		18	Site Control "GL Journal Creation" is an integer not a bit and allows for value 0,1 and 2
-- 21 Sep 2010  MS  	RFC5885 	19	Corrected Best Fit criteria for Discount Narrative
-- 27 Apr 2012	KR	R11414		20	Modified the IsComplete Logic
-- 15 Apr 2013	DV	R13270		21	Increase the length of nvarchar to 11 when casting or declaring integer
-- 25 Jun 2013	AT	RFC13593	22	Fixed error converting date/time on French database server.
-- 10 Sep 2013	KR	DR218		23	Modified the stored procedure to use DEBTORSPLITDIARY table if rows are available in there.	
-- 20 Sep 2013	AT	DR-218		24	Allocate debtor to Split WIP.
--						Fixed creating null discounts when only one debtor has a discount.
--						Fixed WORKINPROGRESS.WIPSEQNO allocation for Split WIP.
--						Write debtor split percentage to SPLITPERCENTAGE column.
--						Create ACCOUNT row for new Split WIP debtors.
-- 05 Apr 2016	LP	R58817		26	Retrieve WIP details from both DIARY and DEBTORSPLITDIARY when posting a mix of single and multi-debtor case WIP.
-- 21 Dec 2016	LP	R70149		27	Fixed bug when posting a combination of multi-debtor and debtor-only time entries.
-- 19 Feb 2018	vql	R73392		28	Timesheet discounts posted to Work History with incorrect HISTORYLINENO (DR-38470).
-- 08 Oct 2018  MS      DR40951         29      Record entries against Office Entity for case / debtor
-- 14 Nov 2018  AV  75198/DR-45358	30   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare	@nRowsInBatch		int
declare @sSQLString		nvarchar(max)
declare @sSQLString2		nvarchar(max)
declare @sSQLString3		nvarchar(max)
declare	@sTimeStamp		nvarchar(24)
declare @sAlertXML		nvarchar(400)

declare @nTranCountStart	int
declare @nFromTransNo		int
declare @nToTransNo		int
declare @dtTransDate		datetime

declare @nAccountingSystemID	int
declare @nTransactionType	int

declare @sDiscountWipCode	nvarchar(6)
declare @sDiscountRenewalWipCode nvarchar(6)
declare @nDiscountNarrativeKey	int
declare @sDiscountNarrativeKey	nvarchar(10)
declare @bIsNarrativeTranslate	bit

declare @nTransNo		int
declare @nResult		int
Declare @nGLJournalCreation	int

declare @dBillingDiscountRate	decimal(6,3)
declare @nNameKey		int
declare @nCaseKey		int
declare @bExtractDiscount	bit
declare @bDebtorSplitDiaryExists bit
declare @nEntityNo              int

-- Initialise variables
Set @nErrorCode = 0
Set @nRowsInBatch = 0
Set @pnRowsPosted = 0
Set @nAccountingSystemID = 2 	-- Time and Billing
Set @nTransactionType = 400 	-- Timesheet
Set @bDebtorSplitDiaryExists = 0 -- assume there are no split rows

-- Discounts required?
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bExtractDiscount =
		CASE	when(D.COLBOOLEAN = 1)
			then CASE WHEN isnull(B.COLBOOLEAN,0) = 0 THEN 1
			     ELSE 0
			     END	
			ELSE 0
			END
	from	SITECONTROL D
	left join SITECONTROL B	on (B.CONTROLID = 'DiscountNotInBilling')
	WHERE 	D.CONTROLID = 'Discounts'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bExtractDiscount	bit		OUTPUT',
			  @bExtractDiscount	= @bExtractDiscount	OUTPUT
End

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ts_PostTimeBatch-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End

if (@nErrorCode = 0)
Begin
-- get site control values
	
	Set @sSQLString = "
	Select @nGLJournalCreation = isnull(COLINTEGER,0)
	From SITECONTROL
	Where CONTROLID = 'GL Journal Creation'"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nGLJournalCreation	int 			OUTPUT',
				@nGLJournalCreation = @nGLJournalCreation	OUTPUT

End
-- Identify candidate rows
If @nErrorCode = 0
Begin
	If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPENTRIES')
	Begin
		delete from #TEMPENTRIES

		Set @nErrorCode = @@ERROR
	End
	Else
	Begin
		-- Used to generate a unique sequence number for each row to be procesed
		CREATE TABLE #TEMPENTRIES (
			SEQUENCENO	int identity(0,1),
			EMPLOYEENO	int,
			ENTRYNO		int,
                        ENTITYNO        int)

		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
		Begin
		Set @sSQLString = "
		Insert into #TEMPENTRIES (EMPLOYEENO, ENTRYNO, ENTITYNO)
		Select"
	
		If @pnBatchSize > 0
		Begin
			Set @sSQLString = @sSQLString + " TOP " + cast(@pnBatchSize as nvarchar)
		End
	
		Set @sSQLString = @sSQLString+" D.EMPLOYEENO, D.ENTRYNO, CASE WHEN SE.COLBOOLEAN = 1 and SN.NAMENO is not null THEN SN.NAMENO ELSE @pnEntityKey END
		from DIARY D
		left join DIARY D1 on (D1.PARENTENTRYNO = D.ENTRYNO and D1.EMPLOYEENO = D.EMPLOYEENO)
		left join SITECONTROL S	on (S.CONTROLID = 'CASEONLY_TIME')
		left join SITECONTROL SR on (SR.CONTROLID = 'Rate mandatory on time items')
                left join SITECONTROL SE on (SE.CONTROLID = 'Entity Defaults from Case Office')
                left join CASES C on (C.CASEID = D.CASEID)
                left join NAME N on (N.NAMENO = D.NAMENO)
                left join TABLEATTRIBUTES TA on (TA.PARENTTABLE = 'NAME' and TA.GENERICKEY = N.NAMENO and TA.TABLETYPE = 44)
                left join OFFICE O on (O.OFFICEID = isnull(C.OFFICEID, TA.TABLECODE))
                left join SPECIALNAME SN on (O.ORGNAMENO = SN.NAMENO and SN.ENTITYFLAG = 1)
			-- Not a timer
		where 	D.ISTIMER=0
			-- Not incomplete and Not continued
		and	not((isnull(S.COLBOOLEAN, 0) = 1 OR D.NAMENO is null) and
			D.CASEID is null OR D.ACTIVITY is null or (( D.TOTALTIME is null or D.TOTALUNITS is null or D.TOTALUNITS = 0 or D.TIMEVALUE is null ) AND (D1.PARENTENTRYNO is null or D.ENTRYNO != D1.PARENTENTRYNO))
			OR (D.CHARGEOUTRATE is null and isnull(SR.COLBOOLEAN,0) = 1))
			-- Not posted
		and	D.TRANSNO is null"

		-- Not incomplete (Charge Out Rate is there)
		If @pbCalledFromCentura = 0 and
		exists (Select 1 from SITECONTROL where CONTROLID = 'Rate mandatory on time items' and COLBOOLEAN = 1)
		Begin
			Set @sSQLString = @sSQLString+" and D.CHARGEOUTRATE is not null"
		End
			
		Set @sSQLString2 =
			     +char(10)+"and exists(Select 1"
			     +char(10)+@psWhereClause
			     +char(10)+"and XD.EMPLOYEENO = D.EMPLOYEENO"
			     +char(10)+"and XD.ENTRYNO = D.ENTRYNO)"
	
		Set @sSQLString = (@sSQLString+@sSQLString2)

                Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnEntityKey		int',
				  @pnEntityKey		=@pnEntityKey
	
		Select 	@nRowsInBatch = @@ROWCOUNT

                If exists (Select 1 from #TEMPENTRIES where ENTITYNO is null)
                Begin
                        Set @pbHasOfficeEntityError = 1
                        
                        DELETE FROM #TEMPENTRIES WHERE ENTITYNO is null   
                        
                        select  @nRowsInBatch = count(*) from #TEMPENTRIES
                End
	
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Temp table created with %d entries',0,1,@sTimeStamp, @nRowsInBatch ) with NOWAIT
		End
		
		If @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents of #TEMPENTRIES:'
			Select * from #TEMPENTRIES
			order by SEQUENCENO
		End
	End
End

-- Allocate a sequential range of TransNos for the batch
If @nErrorCode = 0
and @nRowsInBatch > 0
Begin
	-- Use a separate transaction for this so that the LASTINTERNALCODE is freed
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Reserve the necessary numbers for the TRANSACTIONHEADER.TRANSNO
	If @nErrorCode=0
	Begin
		set @sSQLString="
			UPDATE LASTINTERNALCODE 
			SET INTERNALSEQUENCE 	= INTERNALSEQUENCE + @nRowsInBatch,
			    @nFromTransNo    	= INTERNALSEQUENCE + 1,
			    @nToTransNo		= INTERNALSEQUENCE + @nRowsInBatch
			WHERE  TABLENAME = 'TRANSACTIONHEADER'"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int		OUTPUT,
				  @nToTransNo		int		OUTPUT,
				  @nRowsInBatch		int',
				  @nFromTransNo		=@nFromTransNo	OUTPUT,
				  @nToTransNo		=@nToTransNo	OUTPUT,
				  @nRowsInBatch		=@nRowsInBatch
	End

	-- In case the LASTINTERNALCODE row is not present yet
	If @nErrorCode=0
	and @nFromTransNo is null
	Begin
		set @sSQLString="
			INSERT LASTINTERNALCODE (TABLENAME, INTERNALSEQUENCE)
			VALUES ('TRANSACTIONHEADER',@nRowsInBatch)"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nRowsInBatch		int',
				  @nRowsInBatch		=@nRowsInBatch

		If @nErrorCode=0
		Begin
			Set @nFromTransNo = 1
			Set @nToTransNo = @nRowsInBatch
		End
	End

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTimeBatch-@nFromTransNo=%d',0,1,@sTimeStamp,@nFromTransNo ) with NOWAIT
		RAISERROR ('%s ts_PostTimeBatch-@nToTransNo=%d',0,1,@sTimeStamp,@nToTransNo ) with NOWAIT
	End
End

If @nErrorCode = 0
and @nFromTransNo is not null
and @nToTransNo is not null
Begin
	-- Begin processing of the batch
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Create Transaction Headers
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin Transaction Header processing',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		Insert into TRANSACTIONHEADER
		(ENTITYNO, TRANSNO, 
		TRANSDATE, 
		TRANSTYPE, BATCHNO, EMPLOYEENO, 
		USERID, ENTRYDATE, SOURCE, 
		TRANSTATUS, GLSTATUS, TRANPOSTPERIOD, 
		TRANPOSTDATE, IDENTITYID)"

		set @sSQLString2="
		select 	T.ENTITYNO 			as EntityNo,
			T.SEQUENCENO+@nFromTransNo 	as TransNo, 
			cast(convert(nvarchar, D.STARTTIME, 112)as datetime) 
							as TransDate,
			@nTransactionType		as TransType, 
			null 				as Batch, 
			D.EMPLOYEENO 			as EmployeeNo,
			dbo.fn_GetUser() 		as UserID,
			getdate() 			as EntryDate,
			@nAccountingSystemID		as Source,
			1 				as TransStatus,	-- Active
			case 	when S.COLINTEGER > 0
				and  D.TIMEVALUE > 0
				then 0 			-- Awaiting interface
				else null 		-- Ignore
				end as GLStatus,
			dbo.fn_GetPostPeriod(D.STARTTIME,@nAccountingSystemID) 
							as TranPostPeriod,
			getdate() 			as TranPostDate,
			@pnUserIdentityId 		as IdentityID
		from #TEMPENTRIES T
		join DIARY D		on (D.EMPLOYEENO = T.EMPLOYEENO
					and D.ENTRYNO = T.ENTRYNO)
		left join SITECONTROL S	on (S.CONTROLID = 'GL Journal Creation')"

		Set @sSQLString=@sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @pnUserIdentityId	int,
				  @nAccountingSystemID	int,
				  @nTransactionType	int',
				  @nFromTransNo		= @nFromTransNo,
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @nAccountingSystemID	= @nAccountingSystemID,
				  @nTransactionType	= @nTransactionType

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into TRANSACTIONHEADER:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @pnUserIdentityId	int,
				  @nAccountingSystemID	int,
				  @nTransactionType	int',
				  @nFromTransNo		= @nFromTransNo,
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @nAccountingSystemID	= @nAccountingSystemID,
				  @nTransactionType	= @nTransactionType
		End

		If  @nErrorCode = 0
		and @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents of TRANSACTIONHEADER:'
			select 	* from TRANSACTIONHEADER T
			where	T.TRANSNO between @nFromTransNo and @nToTransNo
			order by T.ENTITYNO, T.TRANSNO
		End
	End

	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin post period validation',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString = "
		select 	@dtTransDate = min(TRANSDATE)
		from	TRANSACTIONHEADER T
                where	T.TRANSNO between @nFromTransNo and @nToTransNo
		and	T.TRANPOSTPERIOD is null"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtTransDate		datetime	OUTPUT,
				  @nFromTransNo		int,
				  @nToTransNo		int',
				  @dtTransDate		= @dtTransDate	OUTPUT,
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		-- Note: this validation should have been performed before now.
		-- This is included as a failsafe to prevent a SQL error.
		If @nErrorCode = 0
		and @dtTransDate is not null
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC12', 'Unable to locate accounting period for {0:d}.  Either the date is incorrect, or the period has not been defined.',
							convert(nvarchar, @dtTransDate, 112), null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End
	End

	-- Lock Diary rows as soon as possible
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin updating Diary rows',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		update	DIARY
		set	WIPENTITYNO	= T.ENTITYNO,
			TRANSNO 	= T.SEQUENCENO+@nFromTransNo
		from	#TEMPENTRIES T
		where	DIARY.EMPLOYEENO = T.EMPLOYEENO
		and	DIARY.ENTRYNO = T.ENTRYNO"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int',
				  @nFromTransNo		= @nFromTransNo

		If  @nErrorCode = 0
		and @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents of DIARY:'
			select 	* from DIARY D
			where	D.TRANSNO between @nFromTransNo and @nToTransNo
			order by D.WIPENTITYNO, D.TRANSNO
		End
	End

	--check if debtorsplitdiary exists for the diary entry
	if exists (Select * 
				from DEBTORSPLITDIARY S
				join DIARY D on (D.EMPLOYEENO = S.EMPLOYEENO and D.ENTRYNO = S.ENTRYNO)
				join TRANSACTIONHEADER T on (T.ENTITYNO = D.WIPENTITYNO and T.TRANSNO = D.TRANSNO)
				where	T.TRANSNO between @nFromTransNo and @nToTransNo)
	Begin
			set @bDebtorSplitDiaryExists = 1
	End
	
	-- Create Accounts
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin creating Accounts',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		insert	ACCOUNT (ENTITYNO, NAMENO, BALANCE, CRBALANCE)"

		if (@bDebtorSplitDiaryExists=1)
		Begin
			set @sSQLString2="
			select	DISTINCT D.WIPENTITYNO, ISNULL(DSD.NAMENO, D.NAMENO), 0, 0
			from	DIARY D
			left JOIN DEBTORSPLITDIARY DSD ON (DSD.ENTRYNO = D.ENTRYNO)
			LEFT JOIN ACCOUNT A ON (A.ENTITYNO = D.WIPENTITYNO
									AND A.NAMENO = ISNULL(DSD.NAMENO, D.NAMENO))
			where	D.TRANSNO between @nFromTransNo and @nToTransNo
			and A.ENTITYNO IS NULL
			and (DSD.NAMENO is not null or D.NAMENO is not null)"		
		End
		Else
		Begin
			set @sSQLString2="
			select	DISTINCT D.WIPENTITYNO, D.NAMENO, 0, 0
			from	DIARY D
			where	D.TRANSNO between @nFromTransNo and @nToTransNo
			and	D.NAMENO IS NOT NULL
			and	not exists
				(select 1
				from ACCOUNT A
				where A.ENTITYNO = D.WIPENTITYNO
				and A.NAMENO = D.NAMENO)"
		End

		set @sSQLString = @sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into ACCOUNT:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
		End
	End

	-- Create non-chargeable Work History
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin non-chargeable Work History processing',0,1,@sTimeStamp ) with NOWAIT
		End
		
		set @sSQLString="
			Insert into WORKHISTORY
			(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, 
			TRANSDATE, POSTDATE, TRANSTYPE, POSTPERIOD,
			RATENO, WIPCODE, CASEID, 
			ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, 
			TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
			CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNTRANVALUE, 
			EXCHRATE, LOCALTRANSVALUE, COSTCALCULATION1, 
			COSTCALCULATION2, MARGINNO, REFENTITYNO, REFTRANSNO, 
			EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
			NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
			STATUS, QUOTATIONNO, PRODUCTCODE,
			DISCOUNTFLAG, GENERATEDINADVANCE,
			MOVEMENTCLASS, COMMANDID, ITEMIMPACT, CASEPROFITCENTRE,
			SPLITPERCENTAGE)"
		
		if (@bDebtorSplitDiaryExists = 1)
		Begin
			set @sSQLString2="
			select 	T.ENTITYNO,
				T.TRANSNO, 
				ROW_NUMBER() OVER(PARTITION BY T.TRANSNO order by T.TRANSNO) as WipSeqNo,		-- We know this it the first item for the transaction
				1 			as HistoryLineNo,	-- We know this is the first history for the transaction
				T.TRANSDATE,
				T.TRANPOSTDATE,
				T.TRANSTYPE,
				T.TRANPOSTPERIOD,
				NULL 			as RateNo,
				D.ACTIVITY,
				D.CASEID,
				T.ENTITYNO as AcctEntityNo,
				ISNULL(S.NAMENO, D.NAMENO) as AcctClientNo,
				D.EMPLOYEENO,
				-- Ensure date portion is set to Centura value of 01 Jan 1899
				cast('1899-01-01T'+convert(nvarchar,
							case when D.TIMECARRIEDFORWARD is null 
							then D.TOTALTIME 
							else D.TIMECARRIEDFORWARD+D.TOTALTIME 
							end, 108) as datetime) as TotalTime,
				D.TOTALUNITS,
				D.UNITSPERHOUR,
				ISNULL(S.CHARGEOUTRATE, D.CHARGEOUTRATE),
				ISNULL(S.FOREIGNCURRENCY, D.FOREIGNCURRENCY),
				ISNULL(S.FOREIGNVALUE, D.FOREIGNVALUE),
				ISNULL(S.EXCHRATE, D.EXCHRATE),
				isnull(S.TIMEVALUE,0) 	as LocalValue,
				ISNULL(S.COSTCALCULATION1, D.COSTCALCULATION1),
				ISNULL(S.COSTCALCULATION2, D.COSTCALCULATION2),
				ISNULL(S.MARGINNO, D.MARGINNO),
				T.ENTITYNO,
				T.TRANSNO,
				E.PROFITCENTRECODE,
				N.FAMILYNO,
				(select min(T.TABLECODE)
				from TABLEATTRIBUTES T
				where T.GENERICKEY = cast(D.EMPLOYEENO as nvarchar(20))
				and T.PARENTTABLE = 'NAME'
				and T.TABLETYPE = 44) 	as EmpOffice,
				ISNULL(S.NARRATIVENO,D.NARRATIVENO),
				ISNULL(case when LEN(S.NARRATIVE)<= 508 then S.NARRATIVE else null end, D.SHORTNARRATIVE),
				ISNULL(case when LEN(S.NARRATIVE)> 508 then S.NARRATIVE else null end, D.LONGNARRATIVE),
				1 			as Status,		-- Active
				D.QUOTATIONNO,
				D.PRODUCTCODE,
				0 			as DiscountFlag,
				0 			as GeneratedInAdvance,
				1			as MovementClass,	-- Generate
				1 			as CommandID,		-- Generate Item
				1 			as ItemImpact,		-- Item Created
				C.PROFITCENTRECODE	as CaseProfitCentre,
				S.SPLITPERCENTAGE as SplitPercentage
			from 	TRANSACTIONHEADER T	
			join	DIARY D		on (D.WIPENTITYNO = T.ENTITYNO
						and D.TRANSNO = T.TRANSNO)
			left join EMPLOYEE E	on (E.EMPLOYEENO = D.EMPLOYEENO)
			left join NAME N	on (N.NAMENO = D.EMPLOYEENO)
			left join CASES C	on (C.CASEID = D.CASEID)
			left join DEBTORSPLITDIARY S on (D.EMPLOYEENO = S.EMPLOYEENO and D.ENTRYNO = S.ENTRYNO)
			where	T.TRANSNO between @nFromTransNo and @nToTransNo
			and	isnull(D.TIMEVALUE,0) = 0"
		End	
		Else
		Begin
			set @sSQLString2="
			select 	T.ENTITYNO,
				T.TRANSNO, 
				1 			as WipSeqNo,		-- We know this it the first item for the transaction
				1 			as HistoryLineNo,	-- We know this is the first history for the transaction
				T.TRANSDATE,
				T.TRANPOSTDATE,
				T.TRANSTYPE,
				T.TRANPOSTPERIOD,
				NULL 			as RateNo,
				D.ACTIVITY,
				D.CASEID,
				case when D.CASEID is null and D.NAMENO is not null then T.ENTITYNO else NULL end 
							as AcctEntityNo,
				case when D.CASEID is null then D.NAMENO end 
							as AcctClientNo,
				D.EMPLOYEENO,
				-- Ensure date portion is set to Centura value of 01 Jan 1899
				cast('1899-01-01T'+convert(nvarchar,
							case when D.TIMECARRIEDFORWARD is null 
							then D.TOTALTIME 
							else D.TIMECARRIEDFORWARD+D.TOTALTIME 
							end, 108) as datetime) as TotalTime,
				D.TOTALUNITS,
				D.UNITSPERHOUR,
				D.CHARGEOUTRATE,
				D.FOREIGNCURRENCY,
				D.FOREIGNVALUE,
				D.EXCHRATE,
				isnull(D.TIMEVALUE,0) 	as LocalValue,
				D.COSTCALCULATION1,
				D.COSTCALCULATION2,
				D.MARGINNO,
				T.ENTITYNO,
				T.TRANSNO,
				E.PROFITCENTRECODE,
				N.FAMILYNO,
				(select min(T.TABLECODE)
				from TABLEATTRIBUTES T
				where T.GENERICKEY = cast(D.EMPLOYEENO as nvarchar(20))
				and T.PARENTTABLE = 'NAME'
				and T.TABLETYPE = 44) 	as EmpOffice,
				D.NARRATIVENO,
				D.SHORTNARRATIVE,
				D.LONGNARRATIVE,
				1 			as Status,		-- Active
				D.QUOTATIONNO,
				D.PRODUCTCODE,
				0 			as DiscountFlag,
				0 			as GeneratedInAdvance,
				1			as MovementClass,	-- Generate
				1 			as CommandID,		-- Generate Item
				1 			as ItemImpact,		-- Item Created
				C.PROFITCENTRECODE	as CaseProfitCentre,
				null as SplitPercentage
			from 	TRANSACTIONHEADER T	
			join	DIARY D		on (D.WIPENTITYNO = T.ENTITYNO
						and D.TRANSNO = T.TRANSNO)
			left join EMPLOYEE E	on (E.EMPLOYEENO = D.EMPLOYEENO)
			left join NAME N	on (N.NAMENO = D.EMPLOYEENO)
			left join CASES C	on (C.CASEID = D.CASEID)
			where	T.TRANSNO between @nFromTransNo and @nToTransNo
			and	isnull(D.TIMEVALUE,0) = 0"
		End
		
		Set @sSQLString=@sSQLString+@sSQLString2
		
		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into non-chargeable WORKHISTORY:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
		End

		If  @nErrorCode = 0
		and @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents of non-chargeable WORKHISTORY:'
			select 	* from WORKHISTORY W
			where	W.TRANSNO between @nFromTransNo and @nToTransNo
			order by W.ENTITYNO, W.TRANSNO, W.WIPSEQNO, W.HISTORYLINENO
		End
	End

	-- Create chargeable Work In Progress
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin chargeable Work In Progress processing',0,1,@sTimeStamp ) with NOWAIT			
		End

		set @sSQLString="
		Insert into WORKINPROGRESS
		(ENTITYNO, TRANSNO, WIPSEQNO,
		TRANSDATE, POSTDATE,
		RATENO, WIPCODE, CASEID, 
		ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, 
		TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
		CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNVALUE, 
		EXCHRATE, LOCALVALUE, BALANCE, 
		FOREIGNBALANCE, COSTCALCULATION1, COSTCALCULATION2, MARGINNO,
		EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
		STATUS, QUOTATIONNO, PRODUCTCODE,
		DISCOUNTFLAG, GENERATEDINADVANCE, CASEPROFITCENTRE,
		SPLITPERCENTAGE)"

		if (@bDebtorSplitDiaryExists = 1)
		Begin
			set @sSQLString2="
			select 	T.ENTITYNO,
				T.TRANSNO, 
				ROW_NUMBER() OVER(PARTITION BY T.TRANSNO order by T.TRANSNO) as WipSeqNo,		-- We know this is the first WIP item
				T.TRANSDATE,
				T.TRANPOSTDATE,
				NULL 			as RateNo,
				D.ACTIVITY,
				D.CASEID,
				T.ENTITYNO as AcctEntityNo,
				ISNULL(S.NAMENO, D.NAMENO) as AcctClientNo,
				D.EMPLOYEENO,
				-- Ensure date portion is set to Centura value of 01 Jan 1899
				cast('1899-01-01T'+convert(nvarchar,
							case when D.TIMECARRIEDFORWARD is null 
							then D.TOTALTIME 
							else D.TIMECARRIEDFORWARD+D.TOTALTIME 
							end, 108) as datetime) as TotalTime,
				D.TOTALUNITS,
				D.UNITSPERHOUR,
				ISNULL(S.CHARGEOUTRATE, D.CHARGEOUTRATE),
				ISNULL(S.FOREIGNCURRENCY, D.FOREIGNCURRENCY),
				ISNULL(S.FOREIGNVALUE, D.FOREIGNVALUE),
				ISNULL(S.EXCHRATE, D.EXCHRATE),
				ISNULL(S.TIMEVALUE, D.TIMEVALUE),
				ISNULL(S.TIMEVALUE, D.TIMEVALUE),
				ISNULL(S.FOREIGNVALUE, D.FOREIGNVALUE),
				ISNULL(S.COSTCALCULATION1, D.COSTCALCULATION1),
				ISNULL(S.COSTCALCULATION2, D.COSTCALCULATION2),
				ISNULL(S.MARGINNO, D.MARGINNO),
				E.PROFITCENTRECODE,
				N.FAMILYNO,
				(select min(T.TABLECODE)
				from TABLEATTRIBUTES T
				where T.GENERICKEY = cast(D.EMPLOYEENO as nvarchar(20))
				and T.PARENTTABLE = 'NAME'
				and T.TABLETYPE = 44) 	as EmpOffice,
				ISNULL(S.NARRATIVENO, D.NARRATIVENO),
				ISNULL(case when LEN(S.NARRATIVE)<= 508 then S.NARRATIVE else null end, D.SHORTNARRATIVE),
				ISNULL(case when LEN(S.NARRATIVE)> 508 then S.NARRATIVE else null end, D.LONGNARRATIVE),
				1 			as Status,		-- Active
				D.QUOTATIONNO,
				D.PRODUCTCODE,
				0 			as DiscountFlag,
				0 			as GeneratedInAdvance,
				C.PROFITCENTRECODE	as CaseProfitCentre,
				S.SPLITPERCENTAGE as SplitPercentage
			from 	TRANSACTIONHEADER T	
			join	DIARY D		on (D.WIPENTITYNO = T.ENTITYNO
						and D.TRANSNO = T.TRANSNO)
			left join EMPLOYEE E	on (E.EMPLOYEENO = D.EMPLOYEENO)
			left join NAME N	on (N.NAMENO = D.EMPLOYEENO)
			left join CASES C	on (C.CASEID = D.CASEID)
			left join DEBTORSPLITDIARY S on (D.EMPLOYEENO = S.EMPLOYEENO and D.ENTRYNO = S.ENTRYNO)
			where	T.TRANSNO between @nFromTransNo and @nToTransNo
			and	D.TIMEVALUE <> 0"
		End
		Else
		Begin
			set @sSQLString2="
			select 	T.ENTITYNO,
				T.TRANSNO, 
				1 			as WipSeqNo,		-- We know this is the first WIP item
				T.TRANSDATE,
				T.TRANPOSTDATE,
				NULL 			as RateNo,
				D.ACTIVITY,
				D.CASEID,
				case when D.CASEID is null and D.NAMENO is not null then T.ENTITYNO else NULL end 
							as AcctEntityNo,
				case when D.CASEID is null then D.NAMENO end 
							as AcctClientNo,
				D.EMPLOYEENO,
				-- Ensure date portion is set to Centura value of 01 Jan 1899
				cast('1899-01-01T'+convert(nvarchar,
							case when D.TIMECARRIEDFORWARD is null 
							then D.TOTALTIME 
							else D.TIMECARRIEDFORWARD+D.TOTALTIME 
							end, 108) as datetime) as TotalTime,
				D.TOTALUNITS,
				D.UNITSPERHOUR,
				D.CHARGEOUTRATE,
				D.FOREIGNCURRENCY,
				D.FOREIGNVALUE,
				D.EXCHRATE,
				D.TIMEVALUE,
				D.TIMEVALUE,
				D.FOREIGNVALUE,
				D.COSTCALCULATION1,
				D.COSTCALCULATION2,
				D.MARGINNO,
				E.PROFITCENTRECODE,
				N.FAMILYNO,
				(select min(T.TABLECODE)
				from TABLEATTRIBUTES T
				where T.GENERICKEY = cast(D.EMPLOYEENO as nvarchar(20))
				and T.PARENTTABLE = 'NAME'
				and T.TABLETYPE = 44) 	as EmpOffice,
				D.NARRATIVENO,
				D.SHORTNARRATIVE,
				D.LONGNARRATIVE,
				1 			as Status,		-- Active
				D.QUOTATIONNO,
				D.PRODUCTCODE,
				0 			as DiscountFlag,
				0 			as GeneratedInAdvance,
				C.PROFITCENTRECODE	as CaseProfitCentre,
				NULL as SplitPercentage
			from 	TRANSACTIONHEADER T	
			join	DIARY D		on (D.WIPENTITYNO = T.ENTITYNO
						and D.TRANSNO = T.TRANSNO)
			left join EMPLOYEE E	on (E.EMPLOYEENO = D.EMPLOYEENO)
			left join NAME N	on (N.NAMENO = D.EMPLOYEENO)
			left join CASES C	on (C.CASEID = D.CASEID)
			where	T.TRANSNO between @nFromTransNo and @nToTransNo
			and	D.TIMEVALUE <> 0"
		End
		
		Set @sSQLString=@sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into chargeable WORKINPROGRESS:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
		End

		If  @nErrorCode = 0
		and @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents chargeable WORKINPROGRESS:'
			select 	* from WORKINPROGRESS W
			where	W.TRANSNO between @nFromTransNo and @nToTransNo
			order by W.ENTITYNO, W.TRANSNO
		End
	End

	-- Create discount Work In Progress
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin discount Work In Progress processing',0,1,@sTimeStamp ) with NOWAIT
		End

		Set @sSQLString="
		select 	@sDiscountWipCode = DW.COLCHARACTER,
			@sDiscountRenewalWipCode = RD.COLCHARACTER,
			@nDiscountNarrativeKey = N.NARRATIVENO,
			@bIsNarrativeTranslate = T.COLBOOLEAN
		from SITECONTROL DW
		cross join SITECONTROL RD	
		cross join SITECONTROL NS
		cross join SITECONTROL T
		-- Discount Narrative is ignored if either of the WIP Codes are present
		left join NARRATIVE N		on (N.NARRATIVECODE = NS.COLCHARACTER
						and DW.COLCHARACTER IS NULL
						and RD.COLCHARACTER IS NULL)
		where DW.CONTROLID = 'Discount WIP Code'
		and RD.CONTROLID = 'Discount Renewal WIP Code'
		and NS.CONTROLID = 'Discount Narrative'
		and T.CONTROLID = 'Narrative Translate'"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sDiscountWipCode		nvarchar(6)			OUTPUT,
				  @sDiscountRenewalWipCode	nvarchar(6)			OUTPUT,
				  @nDiscountNarrativeKey	int				OUTPUT,
				  @bIsNarrativeTranslate	bit				OUTPUT',
				  @sDiscountWipCode		= @sDiscountWipCode		OUTPUT,
				  @sDiscountRenewalWipCode	= @sDiscountRenewalWipCode	OUTPUT,
				  @nDiscountNarrativeKey	= @nDiscountNarrativeKey	OUTPUT,
				  @bIsNarrativeTranslate	= @bIsNarrativeTranslate	OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Discount WIP Code=%s',0,1,@sTimeStamp,  @sDiscountWipCode) with NOWAIT
			RAISERROR ('%s ts_PostTimeBatch-Discount Renewal WIP Code=%s',0,1,@sTimeStamp,  @sDiscountRenewalWipCode) with NOWAIT
			set @sDiscountNarrativeKey = cast(@nDiscountNarrativeKey as nvarchar)
			RAISERROR ('%s ts_PostTimeBatch-Discount Narrative Key=%s',0,1,@sTimeStamp, @sDiscountNarrativeKey) with NOWAIT
			if @bIsNarrativeTranslate=1
				RAISERROR ('%s ts_PostTimeBatch-Is Narrative Translated=Yes',0,1,@sTimeStamp) with NOWAIT
			else 
				RAISERROR ('%s ts_PostTimeBatch-Is Narrative Translated=No',0,1,@sTimeStamp) with NOWAIT
		End

		If @nErrorCode = 0
		Begin
			
			set @sSQLString=
			"Insert into WORKINPROGRESS"+char(10)+
			"(ENTITYNO, TRANSNO, WIPSEQNO,"+char(10)+
			"DISCOUNTFLAG, WIPCODE, NARRATIVENO,"+char(10)+
			"SHORTNARRATIVE, LONGNARRATIVE,"+char(10)+
			"TOTALTIME, TOTALUNITS, UNITSPERHOUR,"+char(10)+
			"CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNVALUE,"+char(10)+
			"EXCHRATE, LOCALVALUE, BALANCE,"+char(10)+
			"FOREIGNBALANCE, COSTCALCULATION1, COSTCALCULATION2,"+char(10)+
			"TRANSDATE, POSTDATE, RATENO, CASEID,"+char(10)+
			"ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO,"+char(10)+
			"EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE,"+char(10)+
			"STATUS, QUOTATIONNO, PRODUCTCODE,"+char(10)+
			"GENERATEDINADVANCE, CASEPROFITCENTRE,"+char(10)+
			"SPLITPERCENTAGE)"+char(10)
			
			if (@bDebtorSplitDiaryExists = 1)
			Begin
				set @sSQLString2=
				"select	W.ENTITYNO, W.TRANSNO,"+char(10)+
				"MW.MaxWipSeqNo + ROW_NUMBER() OVER(PARTITION BY W.TRANSNO order by W.TRANSNO) as WipSeqNo,"+char(10)+
				"1 as DiscountFlag,"+char(10)+
				-- Use Discount Renewal WIP Code for renewals and Discount WIP Code for the rest.  If neither, keep original WIPCODE.
				"case when T.RENEWALFLAG = 1"+char(10)+
				"	then "+case when @sDiscountRenewalWipCode is null
							then 'W.WIPCODE'
							else dbo.fn_WrapQuotes(@sDiscountRenewalWipCode,0,@pbCalledFromCentura)
							end+char(10)+
				"	else "+case when @sDiscountWipCode is null
							then 'W.WIPCODE'
							else dbo.fn_WrapQuotes(@sDiscountWipCode,0,@pbCalledFromCentura)
							end+char(10)+
				"	end as WipCode,"+char(10)
			End
			Else
			Begin
				set @sSQLString2=
				"select	W.ENTITYNO, W.TRANSNO, 2 as WipSeqNo,"+char(10)+
				"1 as DiscountFlag,"+char(10)+
				-- Use Discount Renewal WIP Code for renewals and Discount WIP Code for the rest.  If neither, keep original WIPCODE.
				"case when T.RENEWALFLAG = 1"+char(10)+
				"	then "+case when @sDiscountRenewalWipCode is null
							then 'W.WIPCODE'
							else dbo.fn_WrapQuotes(@sDiscountRenewalWipCode,0,@pbCalledFromCentura)
							end+char(10)+
				"	else "+case when @sDiscountWipCode is null
							then 'W.WIPCODE'
							else dbo.fn_WrapQuotes(@sDiscountWipCode,0,@pbCalledFromCentura)
							end+char(10)+
				"	end as WipCode,"+char(10)
			End

			-- If translated, use the translation and default to the untranslated narrative
			If @bIsNarrativeTranslate = 1
			and (@sDiscountRenewalWipCode is not null or
			     @sDiscountWipCode is not null or
			     @nDiscountNarrativeKey is not null)
			Begin
				set @sSQLString2=@sSQLString2+
				"N.NARRATIVENO as NarrativeNo,"+char(10)+
				"case when datalength(isnull(NTR.TRANSLATEDTEXT,N.NARRATIVETEXT))<=508"+char(10)+
				"	then isnull(NTR.TRANSLATEDTEXT,N.NARRATIVETEXT) else NULL end as ShortNarrative,"+char(10)+
				"case when datalength(isnull(NTR.TRANSLATEDTEXT,N.NARRATIVETEXT))<=508"+char(10)+
				"	then NULL else isnull(NTR.TRANSLATEDTEXT,N.NARRATIVETEXT) end as LongNarrative,"+char(10)
			End
			Else If (@sDiscountRenewalWipCode is not null or
				 @sDiscountWipCode is not null or
				 @nDiscountNarrativeKey is not null)
			Begin
				if (@bDebtorSplitDiaryExists = 1)
				Begin
					set @sSQLString2=@sSQLString2+
					"coalesce(N.NARRATIVENO, S.NARRATIVENO, D.NARRATIVENO) as NarrativeNo,"+char(10)+
					"case when N.NARRATIVENO is not null"+char(10)+
					"	then case when datalength(N.NARRATIVETEXT)<=508"+char(10)+
					"		then N.NARRATIVETEXT else NULL end"+char(10)+
					"	else ISNULL(case when LEN(S.NARRATIVE) <= 508 then S.NARRATIVE else null end, D.SHORTNARRATIVE) end as ShortNarrative,"+char(10)+
					"case when N.NARRATIVENO is not null"+char(10)+
					"	then case when datalength(N.NARRATIVETEXT)<=508"+char(10)+
					"		then NULL else N.NARRATIVETEXT end"+char(10)+
					"	else ISNULL(case when LEN(S.NARRATIVE) > 508 then S.NARRATIVE else null end, D.LONGNARRATIVE) end as LongNarrative,"+char(10)
				End
				Else
				Begin
					set @sSQLString2=@sSQLString2+
					"isnull(N.NARRATIVENO, D.NARRATIVENO) as NarrativeNo,"+char(10)+
					"case when N.NARRATIVENO is not null"+char(10)+
					"	then case when datalength(N.NARRATIVETEXT)<=508"+char(10)+
					"		then N.NARRATIVETEXT else NULL end"+char(10)+
					"	else D.SHORTNARRATIVE end as ShortNarrative,"+char(10)+
					"case when N.NARRATIVENO is not null"+char(10)+
					"	then case when datalength(N.NARRATIVETEXT)<=508"+char(10)+
					"		then NULL else N.NARRATIVETEXT end"+char(10)+
					"	else D.LONGNARRATIVE end as LongNarrative,"+char(10)
				End
			End
			Else
			Begin
				if (@bDebtorSplitDiaryExists = 1)
				Begin			
					set @sSQLString2=@sSQLString2+
					"ISNULL(S.NARRATIVENO, D.NARRATIVENO) as NarrativeNo,"+char(10)+
					"ISNULL(case when LEN(S.NARRATIVE) <= 508 then S.NARRATIVE else null end, D.SHORTNARRATIVE) as ShortNarrative,"+char(10)+
					"ISNULL(case when LEN(S.NARRATIVE) > 508 then S.NARRATIVE else null end, D.LONGNARRATIVE) as LongNarrative,"+char(10)
				End
				Else					
				Begin
					set @sSQLString2=@sSQLString2+
					"D.NARRATIVENO as NarrativeNo,"+char(10)+
					"D.SHORTNARRATIVE as ShortNarrative,"+char(10)+
					"D.LONGNARRATIVE as LongNarrative,"+char(10)
				End
			End
			
			if (@bDebtorSplitDiaryExists = 1)
			Begin
				set @sSQLString2=@sSQLString2+
				"NULL as TotalTime, NULL as TOTALUNITS, NULL as UNITSPERHOUR,"+char(10)+
				"NULL as CHARGEOUTRATE,"+char(10)+ 
				"ISNULL(S.FOREIGNCURRENCY, W.FOREIGNCURRENCY),"+char(10)+  
				"ISNULL(S.FOREIGNDISCOUNT, D.FOREIGNDISCOUNT) * -1 as FOREIGNVALUE,"+char(10)+
				"ISNULL(S.EXCHRATE, W.EXCHRATE),"+char(10)+  
				"ISNULL(S.DISCOUNTVALUE, D.DISCOUNTVALUE) * -1 as TIMEVALUE,"+char(10)+
				"ISNULL(S.DISCOUNTVALUE, D.DISCOUNTVALUE) * -1 as BALANCE,"+char(10)+
				"ISNULL(S.FOREIGNDISCOUNT, D.FOREIGNDISCOUNT) * -1 as FOREIGNBALANCE,"+char(10)+
				"NULL as COSTCALCULATION1, NULL as COSTCALCULATION2,"+char(10)+
				"W.TRANSDATE, W.POSTDATE, W.RATENO, W.CASEID,"+char(10)+
				"W.ACCTENTITYNO, W.ACCTCLIENTNO, W.EMPLOYEENO,"+char(10)+
				"W.EMPPROFITCENTRE, W.EMPFAMILYNO, W.EMPOFFICECODE,"+char(10)+
				-- Active
				"1 as Status,"+char(10)+		
				"W.QUOTATIONNO, W.PRODUCTCODE,"+char(10)+
				"W.GENERATEDINADVANCE,"+char(10)+
				"C.PROFITCENTRECODE,"+char(10)+
				"null"+char(10)
			End
			Else
			Begin
				set @sSQLString2=@sSQLString2+
				"NULL as TotalTime, NULL as TOTALUNITS, NULL as UNITSPERHOUR,"+char(10)+
				"NULL as CHARGEOUTRATE, W.FOREIGNCURRENCY, D.FOREIGNDISCOUNT * -1 as FOREIGNVALUE,"+char(10)+
				"W.EXCHRATE, D.DISCOUNTVALUE * -1 as TIMEVALUE,"+char(10)+
				"D.DISCOUNTVALUE * -1 as BALANCE,"+char(10)+
				"D.FOREIGNDISCOUNT * -1 as FOREIGNBALANCE,"+char(10)+
				"NULL as COSTCALCULATION1, NULL as COSTCALCULATION2,"+char(10)+
				"W.TRANSDATE, W.POSTDATE, W.RATENO, W.CASEID,"+char(10)+
				"W.ACCTENTITYNO, W.ACCTCLIENTNO, W.EMPLOYEENO,"+char(10)+
				"W.EMPPROFITCENTRE, W.EMPFAMILYNO, W.EMPOFFICECODE,"+char(10)+
				-- Active
				"1 as Status,"+char(10)+		
				"W.QUOTATIONNO, W.PRODUCTCODE,"+char(10)+
				"W.GENERATEDINADVANCE,"+char(10)+
				"C.PROFITCENTRECODE,"+char(10)+
				"null"+char(10)
			End

			if (@bDebtorSplitDiaryExists = 1)
			Begin
				Set @sSQLString3 = 			
				"From 	DIARY D"+char(10)+
				"join	WORKINPROGRESS W"+char(10)+
				"	on (W.ENTITYNO = D.WIPENTITYNO"+char(10)+
				"	and W.TRANSNO = D.TRANSNO
					and ISNULL(W.DISCOUNTFLAG,0) = 0)"+char(10)+
				"join (select max(WIPSEQNO) as MaxWipSeqNo, ENTITYNO, TRANSNO from WORKINPROGRESS group by ENTITYNO, TRANSNO) AS MW on (MW.ENTITYNO = D.WIPENTITYNO"+char(10)+
				"	and MW.TRANSNO = D.TRANSNO)"+char(10)+ 
				"left join DEBTORSPLITDIARY S on (D.EMPLOYEENO = S.EMPLOYEENO and D.ENTRYNO = S.ENTRYNO and W.ACCTCLIENTNO = S.NAMENO)"+char(10)+
				"left join WIPTEMPLATE T on (T.WIPCODE = W.WIPCODE)"+char(10)+
				"left join CASES C on (C.CASEID = W.CASEID)"+char(10)
			End
			Else
			Begin
				Set @sSQLString3 = 	
				"From 	DIARY D"+char(10)+
				"join	WORKINPROGRESS W"+char(10)+
				"	on (W.ENTITYNO = D.WIPENTITYNO"+char(10)+
				"	and W.TRANSNO = D.TRANSNO"+char(10)+
				"	and W.WIPSEQNO = 1)"+char(10)+
				"left join WIPTEMPLATE T on (T.WIPCODE = W.WIPCODE)"+char(10)+
				"left join CASES C on (C.CASEID = W.CASEID)"+char(10)
			End

			If @nErrorCode = 0
			and (@sDiscountWipCode is not null or
			    @sDiscountRenewalWipCode is not null)
			Begin
				set @sSQLString3=@sSQLString3+
				"left join CASENAME CN2"+char(10)+
				"	on (CN2.CASEID = W.CASEID"+char(10)+
				"	and CN2.NAMETYPE = 'D'"+char(10)+
				"	and (CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())"+char(10)+
				"	and CN2.SEQUENCE = (select min(SEQUENCE) from CASENAME CN3"+char(10)+
				"	    where CN3.CASEID = W.CASEID"+char(10)+
				"	    and CN3.NAMETYPE = 'D'"+char(10)+
				"	    and(CN3.EXPIRYDATE is null or CN3.EXPIRYDATE>getdate())))"+char(10)+
				-- The narrative is derived via a best fit for the WIP ocde
				"left join NARRATIVE N on (N.NARRATIVENO ="+char(10)+
				"	(Select"+char(10)+
				"	convert(int,"+char(10)+
				"	substring("+char(10)+
				"	max ("+char(10)+
				"	CASE WHEN (NRL.DEBTORNO IS NULL) THEN '0' ELSE '1' END +"+char(10)+  
				"	CASE WHEN (NRL.EMPLOYEENO IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NRL.CASETYPE IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NRL.PROPERTYTYPE IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NRL.CASECATEGORY IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NRL.SUBTYPE IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NRL.TYPEOFMARK is NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CAST(NRL.NARRATIVENO as varchar(5))), 8, 5))"+char(10)+
				"	from NARRATIVERULE NRL"+char(10)+
				"	where NRL.WIPCODE = case when T.RENEWALFLAG = 1"+char(10)+
				"				then "+case when @sDiscountRenewalWipCode is null
									then 'W.WIPCODE'
									else dbo.fn_WrapQuotes(@sDiscountRenewalWipCode,0,@pbCalledFromCentura)
									end+char(10)+
				"				else "+case when @sDiscountWipCode is null
									then 'W.WIPCODE'
									else dbo.fn_WrapQuotes(@sDiscountWipCode,0,@pbCalledFromCentura)
									end+char(10)+
				"				end"+char(10)+
				"	AND (	NRL.DEBTORNO	= isnull(CN2.NAMENO,W.ACCTCLIENTNO) OR NRL.DEBTORNO IS NULL )"+char(10)+
				"	AND (	NRL.EMPLOYEENO 	= W.EMPLOYEENO OR NRL.EMPLOYEENO IS NULL )"+char(10)+
				"	AND (	NRL.CASETYPE	= C.CASETYPE	OR NRL.CASETYPE	is NULL )"+char(10)+
				"	AND (	NRL.PROPERTYTYPE = C.PROPERTYTYPE OR NRL.PROPERTYTYPE IS NULL )"+char(10)+
				"	AND (	NRL.CASECATEGORY = C.CASECATEGORY OR NRL.CASECATEGORY IS NULL )"+char(10)+
				"	AND (	NRL.SUBTYPE 	= C.SUBTYPE 	OR NRL.SUBTYPE IS NULL )"+char(10)+
				"	AND (	NRL.TYPEOFMARK	= C.TYPEOFMARK	OR NRL.TYPEOFMARK IS NULL )"+char(10)+
				-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
				-- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
				-- a single row with the maximum best fit score.
				"and not exists (Select 1"+char(10)+
						"from NARRATIVERULE NRL2"+char(10)+
						"where  NRL2.WIPCODE = NRL.WIPCODE"+char(10)+ 
						"AND (	NRL2.DEBTORNO    	= NRL.DEBTORNO	        OR (NRL2.DEBTORNO 	IS NULL AND NRL.DEBTORNO 	IS NULL) )"+char(10)+
						"AND (	NRL2.EMPLOYEENO 	= NRL.EMPLOYEENO	OR (NRL2.EMPLOYEENO 	IS NULL AND NRL.EMPLOYEENO 	IS NULL) )"+char(10)+
						"AND (	NRL2.CASETYPE		= NRL.CASETYPE		OR (NRL2.CASETYPE 	IS NULL AND NRL.CASETYPE	IS NULL) )"+char(10)+
						"AND (	NRL2.PROPERTYTYPE 	= NRL.PROPERTYTYPE 	OR (NRL2.PROPERTYTYPE 	IS NULL AND NRL.PROPERTYTYPE 	IS NULL) )"+char(10)+
						"AND (	NRL2.CASECATEGORY 	= NRL.CASECATEGORY 	OR (NRL2.CASECATEGORY 	IS NULL AND NRL.CASECATEGORY 	IS NULL) )"+char(10)+
						"AND (	NRL2.SUBTYPE 		= NRL.SUBTYPE 		OR (NRL2.SUBTYPE 	IS NULL AND NRL.SUBTYPE	 	IS NULL) )"+char(10)+
						"AND (	NRL2.TYPEOFMARK		= NRL.TYPEOFMARK	OR (NRL2.TYPEOFMARK	IS NULL AND NRL.TYPEOFMARK	IS NULL) )"+char(10)+
						"AND NRL2.NARRATIVERULENO <> NRL.NARRATIVERULENO)"+char(10)+		
						"))"+char(10)
			End
			Else If (@nDiscountNarrativeKey is not null)
			Begin
				set @sSQLString3=@sSQLString3+
				"left join NARRATIVE N on (N.NARRATIVENO = "+CAST(@nDiscountNarrativeKey as varchar(10))+")"+char(10)
			End

			-- If translated, a best fit is required to locate the language
			If @bIsNarrativeTranslate = 1
			and (@sDiscountRenewalWipCode is not null or
			     @sDiscountWipCode is not null or
			     @nDiscountNarrativeKey is not null)
			Begin
				set @sSQLString3=@sSQLString3+
				"left join CASENAME CN"+char(10)+
				"	on (CN.CASEID = W.CASEID"+char(10)+
				"	and CN.NAMETYPE = 'D'"+char(10)+
				"	and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
				"	and CN.SEQUENCE = (select min(SEQUENCE) from CASENAME CN"+char(10)+
				"	    where CN.CASEID = W.CASEID"+char(10)+
				"	    and CN.NAMETYPE = 'D'"+char(10)+
				"	    and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))"+char(10)+
				"left join NARRATIVETRANSLATE NTR on (NTR.NARRATIVENO = N.NARRATIVENO"+char(10)+
				"				and NTR.LANGUAGE = "+char(10)+
				"	(select convert(int,"+char(10)+
				"	substring("+char(10)+
				"	max ("+char(10)+
				"	CASE WHEN (NL.NAMENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NL.PROPERTYTYPE IS NULL) THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (NL.ACTION IS NULL)	THEN '0' ELSE '1' END +"+char(10)+		
				"	convert(varchar,NL.LANGUAGE)), 4,10))"+char(10)+
				"	FROM NAMELANGUAGE NL"+char(10)+
				"	WHERE (NL.NAMENO = isnull(CN.NAMENO,W.ACCTCLIENTNO) OR NL.NAMENO IS NULL )"+char(10)+
				"	AND (NL.PROPERTYTYPE = C.PROPERTYTYPE OR NL.PROPERTYTYPE IS NULL )"+char(10)+
				"	AND (NL.ACTION = (Select TOP 1 A.ACTION"+char(10)+
				"  	    		from OPENACTION A"+char(10)+
				"	   		where A.CASEID = W.CASEID"+char(10)+
				"	    		order by A.POLICEEVENTS DESC, A.DATEUPDATED DESC)"+char(10)+
				"	    OR NL.ACTION IS NULL )))"+char(10)
			End

			set @sSQLString3=@sSQLString3+
			"where D.TRANSNO between "+CAST(@nFromTransNo as varchar(11))+" and "+CAST(@nToTransNo as varchar(11))+char(10)
			
			if (@bDebtorSplitDiaryExists = 1)
			Begin
				set @sSQLString3=@sSQLString3+char(10)+"and (ISNULL(S.DISCOUNTVALUE, 0)<>0 or
															(D.DISCOUNTVALUE <> 0 and S.EMPLOYEENO IS NULL and S.ENTRYNO IS NULL))"
			End
			Else
			Begin
				set @sSQLString3=@sSQLString3+char(10)+"and D.DISCOUNTVALUE<>0"
			End
			
			exec (@sSQLString+@sSQLString2+@sSQLString3)
						
			Select 	@nErrorCode =@@Error
		End

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Printing discount WIP SQL',0,1,@sTimeStamp) with NOWAIT
			print @sSQLString
			print @sSQLString2
			print @sSQLString3
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into discount WORKINPROGRESS:'

			-- Do not change error code while in debug
			Exec (@sSQLString2+@sSQLString3) 
		End

		If  @nErrorCode = 0
		and @pnDebugFlag>1	
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents discount WORKINPROGRESS:'
			select 	* from WORKINPROGRESS W
			where	W.TRANSNO between @nFromTransNo and @nToTransNo
			and	W.WIPSEQNO = 2
			order by W.ENTITYNO, W.TRANSNO, W.WIPSEQNO
		End		
	End

	-- Create chargeable Work History
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin chargeable Work History processing',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		Insert into WORKHISTORY
		(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, 
		TRANSDATE, POSTDATE, TRANSTYPE, POSTPERIOD,
		RATENO, WIPCODE, CASEID, 
		ACCTENTITYNO, ACCTCLIENTNO, EMPLOYEENO, 
		TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
		CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNTRANVALUE, 
		EXCHRATE, LOCALTRANSVALUE, COSTCALCULATION1,  
		COSTCALCULATION2, MARGINNO, REFENTITYNO, REFTRANSNO, 
		EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
		STATUS, QUOTATIONNO, PRODUCTCODE,
		DISCOUNTFLAG, GENERATEDINADVANCE,
		MOVEMENTCLASS, COMMANDID, ITEMIMPACT, CASEPROFITCENTRE,
		SPLITPERCENTAGE )"
		
		set @sSQLString2="
		select 	W.ENTITYNO,
			W.TRANSNO, 
			W.WIPSEQNO,
			1,	-- We know this is the first history
			W.TRANSDATE,
			T.TRANPOSTDATE,
			T.TRANSTYPE,
			T.TRANPOSTPERIOD,
			W.RATENO,
			W.WIPCODE,
			W.CASEID,
			W.ACCTENTITYNO,
			W.ACCTCLIENTNO,
			W.EMPLOYEENO,
			W.TOTALTIME,
			W.TOTALUNITS,
			W.UNITSPERHOUR,
			W.CHARGEOUTRATE,
			W.FOREIGNCURRENCY,
			W.FOREIGNVALUE,
			W.EXCHRATE,
			W.LOCALVALUE,
			W.COSTCALCULATION1,
			W.COSTCALCULATION2,
			W.MARGINNO,
			T.ENTITYNO,
			T.TRANSNO,
			W.EMPPROFITCENTRE,
			W.EMPFAMILYNO,
			W.EMPOFFICECODE, 
			W.NARRATIVENO,
			W.SHORTNARRATIVE,
			W.LONGNARRATIVE,
			1 			as Status,		-- Active
			W.QUOTATIONNO,
			W.PRODUCTCODE,
			W.DISCOUNTFLAG,
			W.GENERATEDINADVANCE,
			1			as MovementClass,	-- Generate
			1 			as CommandID,		-- Generate Item
			1 			as ItemImpact,		-- Item Created
			W.CASEPROFITCENTRE	as CaseProfitCentre,
			W.SPLITPERCENTAGE as SplitPercentage
		from 	TRANSACTIONHEADER T	
		join	WORKINPROGRESS W	on (W.ENTITYNO = T.ENTITYNO
						and W.TRANSNO = T.TRANSNO)
		where	T.TRANSNO between @nFromTransNo and @nToTransNo"

		Set @sSQLString=@sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into chargeable WORKHISTORY:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
		End

		If  @nErrorCode = 0
		and @pnDebugFlag>1
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Contents of chargeable WORKHISTORY:'
			select 	* from WORKHISTORY W
			where	W.TRANSNO between @nFromTransNo and @nToTransNo
			and	W.LOCALTRANSVALUE <> 0
			order by W.ENTITYNO, W.TRANSNO, W.WIPSEQNO, W.HISTORYLINENO
		End
	End

	-- Create Control Totals
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin creating Control Totals',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		insert	CONTROLTOTAL (LEDGER, CATEGORY, TYPE, 
				     PERIODID, ENTITYNO, TOTAL)"

		set @sSQLString2="
		select	distinct 
			1 		as Ledger, 	-- Work In Progress
			W.MOVEMENTCLASS, 
			W.TRANSTYPE, 
			W.POSTPERIOD, 
			W.REFENTITYNO, 
			0		as Total
		from	WORKHISTORY W
                join    TRANSACTIONHEADER T on (T.ENTITYNO = W.REFENTITYNO and T.TRANSNO = W.REFTRANSNO)
		where	W.REFTRANSNO between @nFromTransNo and @nToTransNo
		and	W.LOCALTRANSVALUE <> 0
		and	not exists
			(select 1
			from CONTROLTOTAL C
			where C.LEDGER = 1	-- Work In Progress
			and C.CATEGORY = W.MOVEMENTCLASS
			and C.TYPE = W.TRANSTYPE
			and C.PERIODID = W.POSTPERIOD
			and C.ENTITYNO = W.REFENTITYNO)"

		set @sSQLString = @sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo

		If  @nErrorCode <> 0
		and @pnDebugFlag > 0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Dumping data',0,1,@sTimeStamp ) with NOWAIT
			select	@sTimeStamp+' ts_PostTimeBatch-'+'Selected into CONTROLTOTAL:'

			-- Do not change error code while in debug
			Exec sp_executesql @sSQLString2, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
		End
	End

	-- Update Control Totals
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ts_PostTimeBatch-Begin updating Control Totals',0,1,@sTimeStamp ) with NOWAIT
		End

		set @sSQLString="
		update C
		set TOTAL = C.TOTAL + W.TOTALTRANSVALUE"

		set @sSQLString2="
		from	CONTROLTOTAL C
		join (select WH.REFENTITYNO, WH.MOVEMENTCLASS, WH.TRANSTYPE, WH.POSTPERIOD, sum(WH.LOCALTRANSVALUE) as TOTALTRANSVALUE
			from WORKHISTORY WH
                        join TRANSACTIONHEADER T on (T.ENTITYNO = WH.REFENTITYNO and T.TRANSNO = WH.REFTRANSNO)
			where WH.REFTRANSNO between @nFromTransNo and @nToTransNo
			and WH.LOCALTRANSVALUE <> 0
			group by WH.REFENTITYNO, WH.MOVEMENTCLASS, WH.TRANSTYPE, WH.POSTPERIOD) W
					on (W.MOVEMENTCLASS= C.CATEGORY
					and W.TRANSTYPE    = C.TYPE
					and W.POSTPERIOD   = C.PERIODID
                                        and W.REFENTITYNO     = C.ENTITYNO)
		where	C.LEDGER = 1	-- Work In Progress"

		set @sSQLString = @sSQLString+@sSQLString2

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nFromTransNo		int,
				  @nToTransNo		int',
				  @nFromTransNo		= @nFromTransNo,
				  @nToTransNo		= @nToTransNo
	End
	
	-- financial interface create and post journals.
	
	if (@nErrorCode = 0 and @nGLJournalCreation = 1)
	Begin
		Declare cWorkHistory cursor for
		Select distinct ENTITYNO, TRANSNO
		From WORKHISTORY
		Where TRANSNO	between @nFromTransNo and @nToTransNo
		and (DISCOUNTFLAG is null or DISCOUNTFLAG = 0)
		
		Open cWorkHistory
		Fetch Next From cWorkHistory Into @nEntityNo, @nTransNo
		
		While @@FETCH_STATUS = 0
		Begin
			exec @nErrorCode = dbo.fi_CreateAndPostJournals
				   @pnResult = @nResult OUTPUT,
				  @pnUserIdentityId = @pnUserIdentityId,
				  @psCulture = @psCulture,
				  @pbCalledFromCentura = @pbCalledFromCentura,
				  @pbDebugFlag = @pnDebugFlag,
				  @pnEntityNo = @nEntityNo,
				  @pnTransNo = @nTransNo,
				  @pnDesignation = 1,
				  @pbIncProcessedNoJournal = 1
				  
			Fetch Next From cWorkHistory Into @nEntityNo, @nTransNo
				  
		End
		Close cWorkHistory
		Deallocate cWorkHistory		

	End

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
		Begin
			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s ts_PostTimeBatch-Committing %d entries',0,1,@sTimeStamp, @nRowsInBatch ) with NOWAIT
			End

			Set @pnRowsPosted = @nRowsInBatch
			COMMIT TRANSACTION
		End
		Else
		Begin
			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s ts_PostTimeBatch-Rolling back %d entries',0,1,@sTimeStamp, @nRowsInBatch ) with NOWAIT
			End
			ROLLBACK TRANSACTION
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ts_PostTimeBatch to public
GO
