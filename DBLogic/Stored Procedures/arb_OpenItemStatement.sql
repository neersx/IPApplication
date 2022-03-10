----------------------------------------------------------------------------------------------------------------------------
-- Creation of arb_OpenItemStatement
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[arb_OpenItemStatement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.arb_OpenItemStatement.'
	drop procedure dbo.arb_OpenItemStatement
end
print '**** Creating procedure dbo.arb_OpenItemStatement...'
print ''
go

CREATE PROCEDURE dbo.arb_OpenItemStatement
	@pnPeriod 		INT, 
	@pdtBaseDate 		DATETIME, 
	@pdtItemDateTo 		DATETIME,
	@pnAge0Days 		INT, 
	@pnAge1Days 		INT, 
	@pnAge2Days 		INT,
	@pnEntityNo 		INT = NULL, 
	@pnPrintZeroBalance 	INT = 0, 
	@pnDebtorNo 		INT = NULL,
	@psFromDebtor 		varchar(20) = NULL, 
	@psToDebtor 		varchar(20) = NULL,
	@pbPrintPositiveBal 	bit = 1,
	@pbPrintNegativeBal	bit = 1,
	@pbPrintZeroBalWOAct	bit = 0,
	@pnSortBy		TINYINT = 0,
	@psDebtorRestrictions	NVARCHAR(4000)	= null,
	@pbLocalDebtor		bit = 1,
	@pbForeignDebtor	bit = 1,
	@psDebtorNos		NVARCHAR(4000)	= null
AS
-- PROCEDURE :	arb_OpenItemStatement
-- VERSION :	12
-- DESCRIPTION:	A procedure to browse for all the open items which meet the supplied parameters, and the associated history (if any) 
-- 		which falls within the reporting period.  The procedure calculates the opening and closing balance for each item, and
-- 		ages the closing balance.  All figures reported are in the currency in which the item was raised. Also formats and returns
-- 		the mailing address for the debtor or debtors in question. Sorted by Entity, debtor name code, currency of the items, 
-- 		Item Date, Item No, Transaction Date and TransactionNo. This is implemented using a temporary table because of limitations
-- 		on memory in SqlServer when a cursor and Case statements are used.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  Change
-- ------------ ----	---- 	-------- ------------------------------------------- 
-- 24/05/99	JEK	4090		Sort by NameNo within Debtor Name Code as Name Code is not mandatory
-- 05/01/00	JEK 	4318		Show full history for debits
--					Show only credits still open without history
--					Change description for credit allocation transactions
-- 03/05/00	JEK 	5625		Drop procedure, remove Country & and order by
-- 20/06/00	CPR 	5703		Print/Don't print zero balance statements - Check the user's preference if DON'T then check 
--					the statements closing balance if zero skip to the next row (fetchnext)
-- 29/6/00	dw  	5413		Added extra logic to handle the fact that Reference Text may be stored as either a short or 
--					long string in both OPENITEM & DEBTORHISTORY tables.
-- 04/07/00	CPR 	5677		To cater for multiple debtors being selected, two more string parameters have been defined, 
--					FromDebtor and ToDebtor.
-- 21/08/00	ABELL			Add dbo. to the creation of stored procedures.
-- 24/02/02	AvdA	7363		Include openitems with 'Locked' status (2).
-- 28/02/02	JEK	7363		Adjust unallocated cash total to include prepayments by checking ITYPE.CASHITEMFLAG instead of 
--					TYPE = 520.
-- 08/04/02	MF	7525		Get the Mailing Label details on a change of currency as well as a change of debtor as
--					it is possible for a Debtor to have items with more than one currency but for the total
--					value of the first currency to be zero which means the Mailing Label details are not extracted.
-- 05/08/2004	AB	8035		Add collate database_default to temp table definitions
-- 17/02/2006	AT	12071	1	Fixed calculation of aged balances when processed out of date/period order.
-- 06/09/2006	AT	12399	2	Added new print options.
-- 27/11/2006	AT	13540	3	Added sort options and additional output columns.
-- 16/01/2012	DL	16758	4	Filter by DEBTORHISTORY.LOCALBALANCE <> 0 instead of by OPENITEM.CLOSEPOSTPERIOD > period which might exclude valid items
-- 08/08/2012	DL	20819	5	Revisit 16758 - Fixed bug fully paid invoices are not included in the report. Use max(DEBTORHISTORY.POSTPERIOD) instead of OPENITEM.CLOSEPERIOD for selecting data.
-- 30/11/2012	DL	21088	6	Revisit 20819 - use temp table with index to enhance performance
-- 27/02/2014	DL	S21508	7	Change variables and temp table columns that reference namecode to 20 characters
-- 28/03/2014	MS      R31038	8	Added parameters for debtor restrictions, local and foreign debtors for filter
-- 02/04/2014	DL	S20835	9	Show Client Payment transactions on Debtor Statement (e.g. AP client refund and AR/AP offset)
-- 18/06/2014	DV	R35246	10	Added parameter to filter for multiple debtor
-- 18 Sep 2014	MF	R39588	11	Tidy up code and improve performance on #TEMPCLOSEBAL by including any filters on its load.
-- 24 Nov 2015	DL	R55494	12	Debtors Item Movement report - Description not displayed for Inter Entity transactions 


--SQA21088 - use temp table with index to enhance performance
create table #TEMPCLOSEBAL (
	ACCTENTITYNO 		INT		NOT NULL, 
	ACCTDEBTORNO 		INT		NOT NULL, 
	ITEMENTITYNO		INT		NOT NULL,
	ITEMTRANSNO 		INT		NOT NULL,
	LOCALBALANCE		decimal(11,2)	NOT NULL,	 							
	FOREIGNBALANCE		decimal(11,2)	NULL,	 
	NUMROWS			INT		NOT NULL,	
	MAXPERIOD		INT		NOT NULL
	)

create table #TEMPARSTATEMENT(
	ACCTENTITYNO 		INT						NOT NULL, 
	NAMECODE 		varchar(20)	collate database_default	NOT NULL, 
	ACCTDEBTORNO 		INT						NOT NULL, 
	CURRENCY 		varchar(3) 	collate database_default	NULL, 
	CURRENCYDESCRIPTION 	varchar(40) 	collate database_default	NULL, 
	ITEMDATE 		DATETIME					NOT NULL, 
	ITEMNO 			varchar(12) 	collate database_default	NOT NULL,
	ITEMDESCRIPTION 	varchar(254) 	collate database_default	NULL, 
	OPENINGBALANCE 		decimal(11,2)					NOT NULL,
	CLOSINGBALANCE 		decimal(11,2)					NOT NULL, 
	TRANSDATE 		DATETIME 					NULL,
	TRANSNO 		INT 						NULL, 
	TRANSDESCRIPTION 	varchar(254) 	collate database_default	NULL, 
	TRANSAMOUNT 		decimal(11,2)					NULL,
	MOVEMENTCLASS 		smallint					NOT NULL,
	AGE0 			decimal(11,2)					NULL, 
	AGE1 			decimal(11,2)					NULL, 
	AGE2 			decimal(11,2)					NULL, 
	AGE3 			decimal(11,2)					NULL, 
	UNALLOCATEDCASH 	decimal(11,2)					NULL, 
	HISTORYLINENO 		INT						NULL,
	POSTPERIOD		INT						NOT NULL,
	NAMECATEGORY		NVARCHAR(80) 	collate database_default	NULL,
	TRADINGTERMS		INT						NULL,
	ITEMDUEDATE		DATETIME					NULL,
	TRANSTYPE		INT
	)	
	
DECLARE	@nAcctEntityNo 		INT, 
	@sNameCode 		varchar(20), 
	@nAcctDebtorNo 		INT, 
	@sCurrency 		varchar(3), 
	@sCurrencyDescription 	varchar(40), 
	@dtItemDate 		DATETIME, 
	@sItemNo 		varchar(12),
	@sItemDescription 	varchar(254), 
	@nOpeningBalance 	decimal(11,2),
	@nClosingBalance 	decimal(11,2), 
	@dtTransDate 		DATETIME,
	@nTransNo 		INT, 
	@sTransDescription 	varchar(254), 
	@nTransAmount 		decimal(11,2),
	@nMovementClass 	smallint,
	@nAge0 			decimal(11,2), 
	@nAge1 			decimal(11,2), 
	@nAge2 			decimal(11,2), 
	@nAge3 			decimal(11,2), 
	@nUnallocatedCash 	decimal(11,2), 
	@nTotalPayments 	decimal(11,2),
	@nLastEntityNo		INT, 
	@nLastDebtorNo 		INT, 
	@sLastCurrency 		varchar(3), 
	@sLocalCurrency 	varchar(3), 
	@sMailingLabel 		varchar(254), 
	@nStatementClosingBalance decimal(11, 2),
	@PrintStatement 	INT, 
	@HistoryLineNo 		INT,
	@nPostPeriod		INT,
	@bActivityInPeriod 	BIT,
	@sDebtorCategory	nvarchar(80), 
	@nTradingTerms		int,
	@nRowCount		int,
	@nErrorCode		int,	
	@dtItemDueDate		datetime,
	@nTransType		int
	
Set @nErrorCode=0

If @nErrorCode=0
Begin
	INSERT INTO #TEMPCLOSEBAL( ACCTENTITYNO, ACCTDEBTORNO, ITEMENTITYNO, ITEMTRANSNO, LOCALBALANCE, FOREIGNBALANCE, NUMROWS, MAXPERIOD)
	SELECT DH.ACCTENTITYNO,
	       DH.ACCTDEBTORNO,
	       DH.ITEMENTITYNO,
	       DH.ITEMTRANSNO,
	       Sum(DH.LOCALVALUE)       AS LOCALBALANCE,
	       Sum(DH.FOREIGNTRANVALUE) AS FOREIGNBALANCE,
	       Count(DH.HISTORYLINENO)  AS NUMROWS,
	       -- 20819  used max(DEBTORHISTORY.POSTPERIOD) instead of OPENITEM.CLOSEPERIOD for selecting data
	       Max(DH.POSTPERIOD)       AS MAXPERIOD
	FROM   DEBTORHISTORY DH
	       JOIN NAME D ON ( D.NAMENO = DH.ACCTDEBTORNO )
	WHERE  DH.POSTPERIOD <= @pnPeriod               
	       AND DH.STATUS <> 0
	       AND ( @pnEntityNo IS NULL OR DH.ACCTENTITYNO = @pnEntityNo )
	       AND ( DH.ACCTDEBTORNO = @pnDebtorNo 
	       
		      OR ( @pnDebtorNo IS NULL 
			   AND  D.NAMECODE IS NOT NULL 
			   AND  D.NAMECODE >= @psFromDebtor 
			   AND  D.NAMECODE <= @psToDebtor   )
	                   
		      OR ( @pnDebtorNo IS NULL
			   AND D.NAMECODE >= @psFromDebtor
			   AND @psToDebtor IS NULL )
	                   
		      OR ( @pnDebtorNo IS NULL
			   AND @psFromDebtor IS NULL
			   AND D.NAMECODE <= @psToDebtor )
	                   
		      OR ( @pnDebtorNo IS NULL
			   AND @psFromDebtor IS NULL
			   AND @psToDebtor IS NULL ) )
	GROUP  BY DH.ITEMENTITYNO,
		  DH.ITEMTRANSNO,
		  DH.ACCTENTITYNO,
		  DH.ACCTDEBTORNO

	Select	@nRowCount=@@ROWCOUNT,
		@nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin 
	CREATE INDEX CLOSEBALINDEX1 ON #TEMPCLOSEBAL
	(
		ACCTENTITYNO  ASC,
		ACCTDEBTORNO  ASC,
		ITEMENTITYNO  ASC,
		ITEMTRANSNO ASC
	)
	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin

	insert #TEMPARSTATEMENT

	-- The first portion of the union selects all items which were opened prior
	-- to, or during the reporting period, and the associated movements in the item balance

	select OPENITEM.ACCTENTITYNO, 
		DEBTOR.NAMECODE, 
		OPENITEM.ACCTDEBTORNO, 
		-- If the openitem currency is null, use the home currency for the system
		isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))),
		CURRENCY.DESCRIPTION,
		OPENITEM.ITEMDATE, OPENITEM.OPENITEMNO, 
		convert(varchar(254),
			case	when	OPENITEM.STATEMENTREF IS NULL
				then case	when	ORIGTRANS.REFERENCETEXT IS NULL
						then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGREFTEXT)
						else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.REFERENCETEXT
					end
				else	OPENITEM.STATEMENTREF
			end),


		-- If the open item currency is null, the item is held in local currency
		case	when	OPENITEM.CURRENCY IS NULL
			then	OPENITEM.LOCALVALUE
			else	OPENITEM.FOREIGNVALUE
		end,
		case	when	OPENITEM.CURRENCY IS NULL
			then	CLOSEBAL.LOCALBALANCE
			else	CLOSEBAL.FOREIGNBALANCE
		end,
		TRANS.TRANSDATE, TRANS.REFTRANSNO,
		case	when	TRANS.REFERENCETEXT IS NULL
			then	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + convert(varchar(254),TRANS.LONGREFTEXT))
			else	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + TRANS.REFERENCETEXT)
		end,
 		case	when	OPENITEM.CURRENCY IS NULL
			then	TRANS.LOCALVALUE
			else	TRANS.FOREIGNTRANVALUE
		end,
		TRANS.MOVEMENTCLASS,
		-- Calculate the aged balances
		convert( decimal(11,2),
		  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days) )+1) )) 
			* (	case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end )) ),
		convert( decimal(11,2),
		  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - @pnAge0Days)
			/convert(float,@pnAge1Days)) ) )) 
			* (	case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end )) ),
		convert( decimal(11,2),
		  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days))
			/convert(float,@pnAge2Days)) ) )) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) ) ),
		convert( decimal(11,2), 
		  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days+@pnAge2Days-1) )-1) )) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) ) ),
		-- Calculate the total Unallocated Cash
		convert( decimal(11,2), 
		  sum( (case when	ITYPE.CASHITEMFLAG = 1
					then	1
					else	0
				end) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) ) ),
	--	HISTORYLINENO for this union should return Trans.HistoryLineNo
		TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE, TRANS.TRANSTYPE
	FROM 	OPENITEM
		--SQA21088 - use temp table with index to enhance performance
		join #TEMPCLOSEBAL CLOSEBAL	on (CLOSEBAL.ITEMENTITYNO = OPENITEM.ITEMENTITYNO 	-- The closing balance is on the most recent history processed on or before
						and CLOSEBAL.ITEMTRANSNO  = OPENITEM.ITEMTRANSNO 	-- the reporting period
						and CLOSEBAL.ACCTENTITYNO = OPENITEM.ACCTENTITYNO 
						and CLOSEBAL.ACCTDEBTORNO = OPENITEM.ACCTDEBTORNO)
						
		join DEBTORHISTORY ORIGTRANS	on (ORIGTRANS.ITEMENTITYNO = OPENITEM.ITEMENTITYNO 	-- Locate the history row which created the item
						and ORIGTRANS.ITEMTRANSNO =  OPENITEM.ITEMTRANSNO 
						and ORIGTRANS.ACCTENTITYNO = OPENITEM.ACCTENTITYNO 
						and ORIGTRANS.ACCTDEBTORNO = OPENITEM.ACCTDEBTORNO )
						
		join DEBTORHISTORY TRANS	on (TRANS.ITEMENTITYNO = OPENITEM.ITEMENTITYNO 	-- Select all of the history posted for the item on or before 
						and TRANS.ITEMTRANSNO  = OPENITEM.ITEMTRANSNO  	-- the reporting period.  Exclude the original history 
						and TRANS.ACCTENTITYNO = OPENITEM.ACCTENTITYNO 	-- because this is already covered by the Item itself.
						and TRANS.ACCTDEBTORNO = OPENITEM.ACCTDEBTORNO )
		
		join DEBTOR_ITEM_TYPE ITYPE	on (ITYPE.ITEM_TYPE_ID = OPENITEM.ITEMTYPE)
		join ACCT_TRANS_TYPE TTYPE	on (TTYPE.TRANS_TYPE_ID= TRANS.TRANSTYPE)
		join SITECONTROL HOMECURR	on (HOMECURR.CONTROLID = 'CURRENCY')
		join NAME DEBTOR		on (DEBTOR.NAMENO      = OPENITEM.ACCTDEBTORNO)
		join CURRENCY			on (CURRENCY.CURRENCY  = isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))) )
		left join IPNAME IPN		on (IPN.NAMENO = DEBTOR.NAMENO)
		left join TABLECODES TC		on (TC.TABLECODE = IPN.CATEGORY)

	WHERE	OPENITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
	-- SQA20919
	and ( CLOSEBAL.MAXPERIOD >=  @pnPeriod or CLOSEBAL.LOCALBALANCE <> 0 )

	and	OPENITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items

	-- SQA20835 Remove filter to include AP client refund and AR/AP offset
	-- and	OPENITEM.LOCALVALUE > 0 			-- Exclude any credit items and items raised for zero value
								-- Note: credit items are reported with no history
	and	OPENITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
	and	( @pnEntityNo IS NULL or 			-- Check filter criteria
		OPENITEM.ACCTENTITYNO = @pnEntityNo ) 
		
       AND ( OPENITEM.ACCTDEBTORNO = @pnDebtorNo 
       
	      OR ( @pnDebtorNo IS NULL 
		   AND  DEBTOR.NAMECODE IS NOT NULL 
		   AND  DEBTOR.NAMECODE >= @psFromDebtor 
		   AND  DEBTOR.NAMECODE <= @psToDebtor   )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND DEBTOR.NAMECODE >= @psFromDebtor
		   AND @psToDebtor IS NULL )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND @psFromDebtor IS NULL
		   AND DEBTOR.NAMECODE <= @psToDebtor )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND @psFromDebtor IS NULL
		   AND @psToDebtor IS NULL ) )
		   

	and	ORIGTRANS.ITEMIMPACT = 1 

	and	TRANS.POSTPERIOD <= @pnPeriod  
	and	TRANS.STATUS <> 0 
	and   ( TRANS.ITEMIMPACT <> 1 OR  TRANS.ITEMIMPACT IS NULL ) 
	
	and	(@psDebtorRestrictions is null or IPN.BADDEBTOR is null or IPN.BADDEBTOR not in (Select Parameter from dbo.fn_Tokenise(@psDebtorRestrictions,',')))
	and	(ISNULL(IPN.LOCALCLIENTFLAG,0) = @pbLocalDebtor or ISNULL(IPN.LOCALCLIENTFLAG,0) <> @pbForeignDebtor)
	and	(@psDebtorNos is null or OPENITEM.ACCTDEBTORNO in (Select Parameter from dbo.fn_Tokenise(@psDebtorNos,',')))   
	group by OPENITEM.ACCTENTITYNO, 
		DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
		isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))),
		CURRENCY.DESCRIPTION,
		OPENITEM.ITEMDATE, OPENITEM.OPENITEMNO, TRANS.TRANSDATE, TRANS.REFTRANSNO, 
		convert(varchar(254),
			case	when	OPENITEM.STATEMENTREF IS NULL
				then case	when	ORIGTRANS.REFERENCETEXT IS NULL
						then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGREFTEXT)
						else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.REFERENCETEXT
					end
				else	OPENITEM.STATEMENTREF
			end),
		case	when	OPENITEM.CURRENCY IS NULL
			then	OPENITEM.LOCALVALUE
			else	OPENITEM.FOREIGNVALUE
		end,
		case	when	OPENITEM.CURRENCY IS NULL
			then	CLOSEBAL.LOCALBALANCE
			else	CLOSEBAL.FOREIGNBALANCE
		end,
		TRANS.TRANSDATE, TRANS.REFTRANSNO, 
		case	when	TRANS.REFERENCETEXT IS NULL
			then	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + convert(varchar(254),TRANS.LONGREFTEXT))
			else	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + TRANS.REFERENCETEXT)
		end,

		case	when	OPENITEM.CURRENCY IS NULL
			then	TRANS.LOCALVALUE
			else	TRANS.FOREIGNTRANVALUE
		end,
		TRANS.MOVEMENTCLASS, TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE, TRANS.TRANSTYPE

	UNION

	-- select any items opened on or before the reporting period which have not changed
	-- or are to be reported without history

	select OPENITEM.ACCTENTITYNO,
		DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
		-- If the openitem currency is null, use the home currency for the system
		isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))),
		CURRENCY.DESCRIPTION,
		OPENITEM.ITEMDATE, OPENITEM.OPENITEMNO, 
		convert(varchar(254),
			case	when	OPENITEM.STATEMENTREF IS NULL
				then case	when	ORIGTRANS.REFERENCETEXT IS NULL
						then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGREFTEXT)
						else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.REFERENCETEXT
					end
				else	OPENITEM.STATEMENTREF
			end),

		-- If the open item currency is null, the item is held in local currency
		case	when	OPENITEM.CURRENCY IS NULL
			then	OPENITEM.LOCALVALUE
			else	OPENITEM.FOREIGNVALUE
		end,
		case	when	OPENITEM.CURRENCY IS NULL
			then	CLOSEBAL.LOCALBALANCE
			else	CLOSEBAL.FOREIGNBALANCE
		end,
		'1/1/1999', -1, NULL, 0, 0,
		-- Calculate the aged balances
		convert( decimal(11,2),
		  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days) )+1) )) 
			* (	case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end )) ),
		convert( decimal(11,2),
		  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - @pnAge0Days)
			/convert(float,@pnAge1Days)) ) )) 
			* (	case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end )) ),
		convert( decimal(11,2),
		  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days))
			/convert(float,@pnAge2Days)) ) )) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) ) ),
		convert( decimal(11,2), 
		  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days+@pnAge2Days-1) )-1) )) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) )  ),
		-- Calculate the total Unallocated Cash
		convert( decimal(11,2), 
		  sum( (case when	ITYPE.CASHITEMFLAG = 1
					then	1
					else	0
				end) 
			* (case	when	OPENITEM.CURRENCY IS NULL
					then	CLOSEBAL.LOCALBALANCE
					else	CLOSEBAL.FOREIGNBALANCE
				end) ) ),
		-- HISTORYLINENO for this union return -1
		-1, OPENITEM.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE, -1 DUMMY_TRANSTYPE
	from 	OPENITEM
		--SQA21088 - use temp table with index to enhance performance
		join #TEMPCLOSEBAL CLOSEBAL	on (CLOSEBAL.ITEMENTITYNO = OPENITEM.ITEMENTITYNO 	-- The closing balance is on the most recent history processed on or before
						and CLOSEBAL.ITEMTRANSNO  = OPENITEM.ITEMTRANSNO 	-- the reporting period
						and CLOSEBAL.ACCTENTITYNO = OPENITEM.ACCTENTITYNO 
						and CLOSEBAL.ACCTDEBTORNO = OPENITEM.ACCTDEBTORNO)
												
		join DEBTORHISTORY ORIGTRANS	on (ORIGTRANS.ITEMENTITYNO = OPENITEM.ITEMENTITYNO 	-- Locate the history row which created the item
						and ORIGTRANS.ITEMTRANSNO =  OPENITEM.ITEMTRANSNO 
						and ORIGTRANS.ACCTENTITYNO = OPENITEM.ACCTENTITYNO 
						and ORIGTRANS.ACCTDEBTORNO = OPENITEM.ACCTDEBTORNO )
						
		join DEBTOR_ITEM_TYPE ITYPE	on (ITYPE.ITEM_TYPE_ID = OPENITEM.ITEMTYPE)
		
		join SITECONTROL HOMECURR	on (HOMECURR.CONTROLID = 'CURRENCY')
		
		join CURRENCY			on (CURRENCY.CURRENCY  = isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))) )
		
		join NAME DEBTOR		on (DEBTOR.NAMENO      = OPENITEM.ACCTDEBTORNO)
		
		left join IPNAME IPN		on (IPN.NAMENO = DEBTOR.NAMENO)
		left join TABLECODES TC		on (TC.TABLECODE = IPN.CATEGORY)
	

	WHERE 	OPENITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
	-- SQA20919
	and ( CLOSEBAL.MAXPERIOD >=  @pnPeriod or CLOSEBAL.LOCALBALANCE <> 0 )

	and	OPENITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items
	and	OPENITEM.LOCALVALUE <> 0 			-- Exclude any items raised for zero value
	and	OPENITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
	and	(@pnEntityNo IS NULL or OPENITEM.ACCTENTITYNO = @pnEntityNo) -- Check filter criteria
		
        and ( OPENITEM.ACCTDEBTORNO = @pnDebtorNo 
       
	      OR ( @pnDebtorNo IS NULL 
		   AND  DEBTOR.NAMECODE IS NOT NULL 
		   AND  DEBTOR.NAMECODE >= @psFromDebtor 
		   AND  DEBTOR.NAMECODE <= @psToDebtor   )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND DEBTOR.NAMECODE >= @psFromDebtor
		   AND @psToDebtor IS NULL )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND @psFromDebtor IS NULL
		   AND DEBTOR.NAMECODE <= @psToDebtor )
                   
	      OR ( @pnDebtorNo IS NULL
		   AND @psFromDebtor IS NULL
		   AND @psToDebtor IS NULL ) )
		   
	--and	( (	OPENITEM.LOCALVALUE > 0 AND		-- Select only debit items which have had no movement on or before 
	--	CLOSEBAL.NUMROWS = 1 )				-- the period ie. the most recent history is the one that created the
	--	or (	OPENITEM.LOCALVALUE < 0 AND		-- item or credit items which are still open (to be reported without 
	--		CLOSEBAL.LOCALBALANCE <> 0 )	) 	-- history).
			

	and	ORIGTRANS.ITEMIMPACT = 1 

	and	(@psDebtorRestrictions is null or IPN.BADDEBTOR is null or IPN.BADDEBTOR not in (Select Parameter from dbo.fn_Tokenise(@psDebtorRestrictions,',')))
	and	(ISNULL(IPN.LOCALCLIENTFLAG,0) = @pbLocalDebtor or ISNULL(IPN.LOCALCLIENTFLAG,0) <> @pbForeignDebtor)
	and	(@psDebtorNos is null or OPENITEM.ACCTDEBTORNO in (Select Parameter from dbo.fn_Tokenise(@psDebtorNos,',')))     
	GROUP BY OPENITEM.ACCTENTITYNO, 
		DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
		isnull(OPENITEM.CURRENCY, CAST(HOMECURR.COLCHARACTER as nvarchar(3))),
		CURRENCY.DESCRIPTION,
		OPENITEM.ITEMDATE, OPENITEM.OPENITEMNO, 
		convert(varchar(254),
			case	when	OPENITEM.STATEMENTREF IS NULL
				then case	when	ORIGTRANS.REFERENCETEXT IS NULL
						then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGREFTEXT)
						else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.REFERENCETEXT
					end
				else	OPENITEM.STATEMENTREF
			end),
		case	when	OPENITEM.CURRENCY IS NULL
			then	OPENITEM.LOCALVALUE
			else	OPENITEM.FOREIGNVALUE
		end,
		case	when	OPENITEM.CURRENCY IS NULL
			then	CLOSEBAL.LOCALBALANCE
			else	CLOSEBAL.FOREIGNBALANCE
		end, OPENITEM.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE

	ORDER BY 1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,23
	
	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin
	Select 	@sLocalCurrency = convert(varchar(3),COLCHARACTER)
	from	SITECONTROL
	where	CONTROLID = 'CURRENCY' 
	
	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin

	If @pnSortBy = 1
	Begin
		-- Sort by Debtor Category
		DECLARE stmtcursor CURSOR FOR
		
		select * from #TEMPARSTATEMENT
		ORDER BY 23,1,2,3,4,5,6,7,8,9,10,11,12,13

		OPEN stmtcursor 
	End
	Else Begin
		DECLARE stmtcursor CURSOR FOR
		
		select * from #TEMPARSTATEMENT
		ORDER BY 1,2,3,4,5,6,7,8,9,10,11,12,13

		OPEN stmtcursor 
	End

	fetch stmtcursor into
		@nAcctEntityNo, 
		@sNameCode, @nAcctDebtorNo, @sCurrency,
		@sCurrencyDescription, @dtItemDate, @sItemNo ,
		@sItemDescription, @nOpeningBalance,
		@nClosingBalance, @dtTransDate,
		@nTransNo, @sTransDescription, @nTransAmount,
		@nMovementClass,
		@nAge0, @nAge1, @nAge2, @nAge3, @nUnallocatedCash, @HistoryLineNo, @nPostPeriod, 
		@sDebtorCategory, @nTradingTerms, @dtItemDueDate, @nTransType

	Set @nLastDebtorNo = @nAcctDebtorNo - 1
	Set @nLastEntityNo = @nAcctEntityNo - 1
	Set @sLastCurrency = NULL

	WHILE (@@fetch_status = 0)
	BEGIN
		If ( ( @nLastEntityNo <> @nAcctEntityNo ) or
		     ( @nLastDebtorNo <> @nAcctDebtorNo ) or
		     ( @sLastCurrency <> @sCurrency ) )
		BEGIN

			If (@pnPrintZeroBalance = 1 OR @pbPrintZeroBalWOAct = 1) and NOT (@pnPrintZeroBalance = 1 and @pbPrintZeroBalWOAct = 1)
			Begin
				-- If either of the zero balance options are selected we need to check if 
				-- activity exists for the period.
				-- If both are selected, then we don't care if there's activity or not.
				If exists ( SELECT 1 FROM #TEMPARSTATEMENT ARS 
						WHERE ARS.POSTPERIOD = @pnPeriod 
						and ARS.ACCTENTITYNO = @nAcctEntityNo 
						AND ARS.ACCTDEBTORNO= @nAcctDebtorNo 
						AND ARS.CURRENCY = @sCurrency )
				Begin
					Set @bActivityInPeriod = 1
				End
				Else
				Begin
					Set @bActivityInPeriod = 0
				End
			End

			-- If not all the options are selected, then filter out the ones that we shouldn't print.
			If NOT (@pbPrintPositiveBal = 1 and @pbPrintNegativeBal = 1 and @pnPrintZeroBalance = 1 and @pbPrintZeroBalWOAct = 1)
			Begin
				SELECT @nStatementClosingBalance=SUM(CLOSINGBALANCE) FROM #TEMPARSTATEMENT ARS
				WHERE ARS.ACCTENTITYNO = @nAcctEntityNo AND ARS.ACCTDEBTORNO= @nAcctDebtorNo AND
				ARS.CURRENCY = @sCurrency AND 
				HISTORYLINENO = (SELECT MIN ( HISTORYLINENO )
							FROM #TEMPARSTATEMENT ARH
							WHERE ARH.ACCTENTITYNO = ARS.ACCTENTITYNO 
							AND ARH.ACCTDEBTORNO = ARS.ACCTDEBTORNO
			  				AND ARH.ITEMNO = ARS.ITEMNO
							AND ARH.TRANSNO = ARS.TRANSNO
							AND ARH.CURRENCY = ARS.CURRENCY)
		
				-- Decide if we should print the debtor's report
				If @nStatementClosingBalance > 0 and @pbPrintPositiveBal = 1
					Set @PrintStatement = 1
				Else If @nStatementClosingBalance < 0 and @pbPrintNegativeBal = 1
					Set @PrintStatement = 1
				Else If @nStatementClosingBalance = 0 and (@pnPrintZeroBalance = 1 and @bActivityInPeriod = 1)
					Set @PrintStatement = 1
				Else If @nStatementClosingBalance = 0 and (@pbPrintZeroBalWOAct = 1 and @bActivityInPeriod = 0)
					Set @PrintStatement = 1
				ELSE
					Set @PrintStatement = 0
			End
			Else
			Begin
				-- User has selected all options.
				Set @PrintStatement = 1
			End

			-- If the print Statement variable is one (TRUE) then continue with the printing 
			-- of the statement
			If @PrintStatement = 1
			BEGIN
				If ( @sCurrency = @sLocalCurrency )
					EXEC aro_TotalPayments
						@pnPeriod = @pnPeriod,
						@pnEntityNo = @nAcctEntityNo, 
						@pnDebtorNo = @nAcctDebtorNo,
						@prnTotalPayments = @nTotalPayments OUTPUT
				Else
					EXEC aro_TotalPayments
						@pnPeriod = @pnPeriod,
						@psCurrency = @sCurrency,
						@pnEntityNo = @nAcctEntityNo, 
						@pnDebtorNo = @nAcctDebtorNo,
						@prnTotalPayments = @nTotalPayments OUTPUT
						
				If @nLastDebtorNo <> @nAcctDebtorNo
				OR @sLastCurrency <> @sCurrency			-- SQA7525
				BEGIN
					EXEC ipo_MailingLabel
						@pnNameNo = @nAcctDebtorNo, 
						@psOverridingRelationship = 'STM',
						@prsLabel = @sMailingLabel OUTPUT
				-- Different debtor		
				END
			-- Print statement
			END
		-- Next debtor
		END
			
		Select @sLastCurrency = @sCurrency
		Select @nLastEntityNo = @nAcctEntityNo
		Select @nLastDebtorNo = @nAcctDebtorNo 

		-- If the print Statement variable is one (TRUE) then continue with the printing 
		-- of the statement
		If @PrintStatement = 1
		BEGIN
			-- If the transaction is a transfer to a Debit Item,
			-- get a more explanatory description
			-- SQA20835 include movement 4 and pass it to the SP aro_TransferredFromDesc to build the description for Adjust Up movement, (eg. Applied To...), against credit items like Credit Notes
			If @nMovementClass in (4, 5 ) and @nTransType <> 600
			BEGIN
				select @sTransDescription = NULL
					EXEC aro_TransferredFromDesc
						@pnRefEntityNo = @nAcctEntityNo, 
						@pnRefTransNo = @nTransNo,
						@prsDescription = @sTransDescription OUTPUT,
						@pnMovementClass = @nMovementClass
			-- movement class
			END
			-- Publish the database variables
			Select
				@sMailingLabel, @nAcctEntityNo, 
				@sNameCode, @nAcctDebtorNo, @sCurrency,
				@sCurrencyDescription,@dtItemDate, @sItemNo ,
				@sItemDescription, @nOpeningBalance,
				@nClosingBalance, @dtTransDate,
				@nTransNo, @sTransDescription, @nTransAmount,
				@nAge0, @nAge1, @nAge2, @nAge3, @nUnallocatedCash,
				@nTotalPayments, @sDebtorCategory, @nTradingTerms, @dtItemDueDate

		END
					
		fetch next from stmtcursor into
			@nAcctEntityNo, 
			@sNameCode, @nAcctDebtorNo, @sCurrency,
			@sCurrencyDescription,@dtItemDate, @sItemNo ,
			@sItemDescription, @nOpeningBalance,
			@nClosingBalance, @dtTransDate,
			@nTransNo, @sTransDescription, @nTransAmount,
			@nMovementClass,
			@nAge0, @nAge1, @nAge2, @nAge3,@nUnallocatedCash, @HistoryLineNo, @nPostPeriod,
			@sDebtorCategory, @nTradingTerms, @dtItemDueDate, @nTransType

	-- while
	END

	close stmtcursor
	deallocate stmtcursor
End

return @nErrorCode
go

grant execute on [dbo].[arb_OpenItemStatement] to public
go
