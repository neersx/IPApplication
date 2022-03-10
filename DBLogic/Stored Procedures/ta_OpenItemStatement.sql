-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ta_OpenItemStatement
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ta_OpenItemStatement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ta_OpenItemStatement.'
	drop procedure dbo.ta_OpenItemStatement
end
print '**** Creating procedure dbo.ta_OpenItemStatement...'
print ''
go

CREATE PROCEDURE dbo.ta_OpenItemStatement
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
	@pbTrustOnly		bit = 0
AS
-- PROCEDURE :	ta_OpenItemStatement
-- VERSION :	6
-- DESCRIPTION:	A procedure to browse for all the trust/open items which meet the supplied parameters, and the associated history (if any) 
-- 		which falls within the reporting period.  The procedure calculates the opening and closing balance for each item, and
-- 		ages the closing balance.  All figures reported are in the currency in which the item was raised. Also formats and returns
-- 		the mailing address for the debtor or debtors in question. Sorted by Entity, debtor name code, currency of the items, 
-- 		Item Date, Item No, Transaction Date and TransactionNo. This is implemented using a temporary table because of limitations
-- 		on memory in SqlServer when a cursor and Case statements are used.
-- CALLED BY :	Trust Accounting - Debtors Trust Item Movement Statement
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 11/03/2008	JS	10105	1		Created based on arb_OpenItemStatement.
-- 26/03/2008	JS	10105	2		More changes.
-- 16/01/2012	DL	16758	3		Filter by TRUSTHISTORY.LOCALBALANCE <> 0 instead of by TRUSTITEM.CLOSEPOSTPERIOD > period which might exclude valid items
-- 08/08/2012  DL	20819	4		Revisit 16758 - Fixed bug fully paid invoices are not included in the report. Use max(TRUSTHISTORY.POSTPERIOD) instead of TRUSTITEM.CLOSEPERIOD for selecting data.
-- 27/02/2014	DL	S21508	5		Change variables and temp table columns that reference namecode to 20 characters
-- 18/09/2014	DL	29203	6		Trust Debtor Statement not handling Trust Transfer


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
	@dtItemDueDate		datetime,
	@bTrust			BIT,
	@nTrustPayments 	decimal(11,2),
	@nItemTransNo		int				-- rfc29203 original itemtransno (not reftransno). Use for sorting and report grouping as trustitem.itemno is the same when transfer


create table #TASTATEMENT
	(ACCTENTITYNO 		INT, 
	NAMECODE 		varchar(20)	collate database_default, 
	ACCTDEBTORNO 		INT, 
	CURRENCY 		varchar(3) 	collate database_default, 
	CURRENCYDESCRIPTION 	varchar(40) 	collate database_default, 
	ITEMDATE 		DATETIME, 
	ITEMNO 			varchar(12) 	collate database_default,
	ITEMDESCRIPTION 	varchar(254) 	collate database_default, 
	OPENINGBALANCE 		decimal(11,2),
	CLOSINGBALANCE 		decimal(11,2), 
	TRANSDATE 		DATETIME 					NULL,
	TRANSNO 		INT 						NULL, 
	TRANSDESCRIPTION 	varchar(254) 	collate database_default	NULL, 
	TRANSAMOUNT 		decimal(11,2)					NULL,
	MOVEMENTCLASS 		smallint,
	AGE0 			decimal(11,2), 
	AGE1 			decimal(11,2), 
	AGE2 			decimal(11,2), 
	AGE3 			decimal(11,2), 
	UNALLOCATEDCASH 	decimal(11,2), 
	HISTORYLINENO 		INT						NULL,
	POSTPERIOD		INT,
	NAMECATEGORY		NVARCHAR(80) 	collate database_default,
	TRADINGTERMS		INT,
	ITEMDUEDATE		DATETIME					NULL,
	TRUST			BIT,
	ITEMTRANSNO		INT		-- rfc29203 original itemtransno (not reftransno) use for sorting and report grouping as trustitem.itemno is the same when transfer
	)


-- Insert Trust items and movements

insert #TASTATEMENT

-- The first portion of the union selects all items which were opened prior
-- to, or during the reporting period, and the associated movements in the item balance

select TRUSTITEM.TACCTENTITYNO, 
	DEBTOR.NAMECODE, 
	TRUSTITEM.TACCTNAMENO, 
	-- If the trust item currency is null, use the home currency for the system
	case	when TRUSTITEM.CURRENCY IS NULL
		then convert(varchar(3),HOMECURR.COLCHARACTER)
		else TRUSTITEM.CURRENCY
	end,
	CURRENCY.DESCRIPTION,
	TRUSTITEM.ITEMDATE, TRUSTITEM.ITEMNO, 
	convert(varchar(254),
		case	when	TRUSTITEM.DESCRIPTION IS NULL
			then case	when	ORIGTRANS.DESCRIPTION IS NULL
					then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGDESCRIPTION)
					else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.DESCRIPTION
				end
			else	TRUSTITEM.DESCRIPTION
		end),
	-- If the trust item currency is null, the item is held in local currency
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRUSTITEM.LOCALVALUE*-1
		else	TRUSTITEM.FOREIGNVALUE*-1
	end,
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	CLOSEBAL.LOCALBALANCE*-1
		else	CLOSEBAL.FOREIGNBALANCE*-1
	end,
	TRANS.TRANSDATE, TRANS.REFTRANSNO,
	case	when	TRANS.DESCRIPTION IS NULL
		then	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + convert(varchar(254),TRANS.LONGDESCRIPTION))
		else	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + TRANS.DESCRIPTION)
	end,
 	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRANS.LOCALVALUE*-1
		else	TRANS.FOREIGNTRANVALUE*-1
	end,
	TRANS.MOVEMENTCLASS,
	-- Calculate the aged balances
	convert( decimal(11,2),
	  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days) )+1) )) 
		* (	case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end )) ),
	convert( decimal(11,2),
	  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - @pnAge0Days)
		/convert(float,@pnAge1Days)) ) )) 
		* (	case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end )) ),
	convert( decimal(11,2),
	  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days))
		/convert(float,@pnAge2Days)) ) )) 
		* (case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end) ) ),
	convert( decimal(11,2), 
	  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days+@pnAge2Days-1) )-1) )) 
		* (case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end) ) ),
	-- Calculate the total Unallocated Cash
	convert( decimal(11,2), 0.0 ), 
	-- HISTORYLINENO for this union should return Trans.HistoryLineNo
	TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, NULL, 1 'TRUST FLAG'
	-- rfc29203 original itemtransno use for sorting and report grouping as trustitem.itemno is the same when transfer	
	, TRUSTITEM.ITEMTRANSNO	
FROM 	TRUSTITEM, 
	(
		SELECT TACCTENTITYNO, TACCTNAMENO, ITEMENTITYNO, ITEMTRANSNO, 
		SUM(LOCALVALUE) AS LOCALBALANCE, SUM(FOREIGNTRANVALUE) AS FOREIGNBALANCE
		-- 20819  used max(TRUSTHISTORY.POSTPERIOD) instead of TRUSTITEM.CLOSEPERIOD for selecting data
		,MAX(POSTPERIOD) MAXPERIOD
		FROM TRUSTHISTORY
		WHERE POSTPERIOD <= @pnPeriod 
	  	AND STATUS <> 0
		GROUP BY ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO
	) AS CLOSEBAL, TRUSTHISTORY ORIGTRANS, TRUSTHISTORY TRANS, TABLECODES ITYPE,
	ACCT_TRANS_TYPE TTYPE, SITECONTROL HOMECURR, NAME DEBTOR
	left join IPNAME IPN on (IPN.NAMENO = DEBTOR.NAMENO)
	left join TABLECODES TC on (TC.TABLECODE = IPN.CATEGORY),
	CURRENCY

WHERE	TRUSTITEM.ITEMTYPE = ITYPE.TABLECODE
and	ITYPE.TABLETYPE = 149 
and	TRUSTITEM.TACCTNAMENO = DEBTOR.NAMENO 
and	HOMECURR.CONTROLID = 'CURRENCY' 
and	CURRENCY.CURRENCY = (case when TRUSTITEM.CURRENCY IS NULL
			then convert(varchar(3),HOMECURR.COLCHARACTER)
			else TRUSTITEM.CURRENCY
			end) 
and	TRUSTITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
-- SQA20919
and ( CLOSEBAL.MAXPERIOD >=  @pnPeriod or CLOSEBAL.LOCALBALANCE <> 0 )

and	TRUSTITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items
and	TRUSTITEM.LOCALVALUE > 0 			-- Exclude any credit items and items raised for zero value
							-- Note: credit items are reported with no history
and	TRUSTITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
and	( @pnEntityNo IS NULL or 			-- Check filter criteria
	TRUSTITEM.TACCTENTITYNO = @pnEntityNo ) 
and	(((TRUSTITEM.TACCTNAMENO = @pnDebtorNo)) 	-- If the user has specified a single debtor find records that match 
		OR					-- that debtor's debtorno
	((@pnDebtorNo IS NULL) AND 			-- If the user has specified a range include all records that have 
	(DEBTOR.NAMECODE IS NOT NULL) AND 		-- debtor namecodes that fall into that range and are not null
	((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- If the user has specified a from debtor namecode include all 
	(DEBTOR.NAMECODE <= @psToDebtor))) OR		-- records with debtor namecodes that are equal or greater than 
	((@pnDebtorNo IS NULL) AND			-- that debtor namecode
	((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- If the user has specified a to debtor namecode include all records with
	(@psToDebtor IS NULL))) OR 			-- debtor namecodes that are equal or less than that debtor namecode
	((@pnDebtorNo IS NULL) AND
	((@psFromDebtor IS NULL) AND 
	(DEBTOR.NAMECODE <= @psToDebtor))) OR 		-- If all options are left blank return all results
	((@pnDebtorNo IS NULL) AND 
	(@psFromDebtor IS NULL) AND 
	(@psToDebtor IS NULL))) 
and	TRUSTITEM.ITEMENTITYNO = ORIGTRANS.ITEMENTITYNO 	-- Locate the history row which created the item
and	TRUSTITEM.ITEMTRANSNO = ORIGTRANS.ITEMTRANSNO 
and	TRUSTITEM.TACCTENTITYNO = ORIGTRANS.TACCTENTITYNO 
and	TRUSTITEM.TACCTNAMENO = ORIGTRANS.TACCTNAMENO 
and	ORIGTRANS.ITEMIMPACT = 1 
and	TRUSTITEM.ITEMENTITYNO = CLOSEBAL.ITEMENTITYNO 		-- The closing balance is on the most recent history processed on or before
and	TRUSTITEM.ITEMTRANSNO = CLOSEBAL.ITEMTRANSNO 		-- the reporting period
and	TRUSTITEM.TACCTENTITYNO = CLOSEBAL.TACCTENTITYNO 
and	TRUSTITEM.TACCTNAMENO = CLOSEBAL.TACCTNAMENO
and	(TRUSTITEM.ITEMENTITYNO = TRANS.ITEMENTITYNO and	-- Select all of the history posted for the item on or before 
	TRUSTITEM.ITEMTRANSNO = TRANS.ITEMTRANSNO and 		-- the reporting period.  Exclude the original history 
	TRUSTITEM.TACCTENTITYNO = TRANS.TACCTENTITYNO and 	-- because this is already covered by the Item itself.
	TRUSTITEM.TACCTNAMENO = TRANS.TACCTNAMENO and 
	TRANS.POSTPERIOD <= @pnPeriod and 
	TRANS.STATUS <> 0 and 
	( TRANS.ITEMIMPACT <> 1 or  TRANS.ITEMIMPACT IS NULL ) and 
	TRANS.TRANSTYPE = TTYPE.TRANS_TYPE_ID )

group by TRUSTITEM.TACCTENTITYNO, 
	DEBTOR.NAMECODE, TRUSTITEM.TACCTNAMENO, 
	case	when TRUSTITEM.CURRENCY IS NULL
		then convert(varchar(3),HOMECURR.COLCHARACTER)
		else TRUSTITEM.CURRENCY
	end,
	CURRENCY.DESCRIPTION,
	TRUSTITEM.ITEMDATE, TRUSTITEM.ITEMNO, TRANS.TRANSDATE, TRANS.REFTRANSNO, 
	convert(varchar(254),
		case	when	TRUSTITEM.DESCRIPTION IS NULL
			then case	when	ORIGTRANS.DESCRIPTION IS NULL
					then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGDESCRIPTION)
					else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.DESCRIPTION
				end
			else	TRUSTITEM.DESCRIPTION
		end),
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRUSTITEM.LOCALVALUE*-1
		else	TRUSTITEM.FOREIGNVALUE*-1
	end,
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	CLOSEBAL.LOCALBALANCE*-1
		else	CLOSEBAL.FOREIGNBALANCE*-1
	end,
	TRANS.TRANSDATE, TRANS.REFTRANSNO, 
	case	when	TRANS.DESCRIPTION IS NULL
		then	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + convert(varchar(254),TRANS.LONGDESCRIPTION))
		else	convert(varchar(254), rtrim(TTYPE.DESCRIPTION) + ' ' + TRANS.DESCRIPTION)
	end,

	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRANS.LOCALVALUE*-1
		else	TRANS.FOREIGNTRANVALUE*-1
	end,
	TRANS.MOVEMENTCLASS, TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS
	-- rfc29203 original itemtransno use for sorting and report grouping as trustitem.itemno is the same when transfer	
	, TRUSTITEM.ITEMTRANSNO	

UNION

-- select any items opened on or before the reporting period which have not changed
-- or are to be reported without history

select TRUSTITEM.TACCTENTITYNO,
	DEBTOR.NAMECODE, TRUSTITEM.TACCTNAMENO, 
	-- If the trust item currency is null, use the home currency for the system
	case	when TRUSTITEM.CURRENCY IS NULL
		then convert(varchar(3),HOMECURR.COLCHARACTER)
		else TRUSTITEM.CURRENCY
	end,
	CURRENCY.DESCRIPTION,
	TRUSTITEM.ITEMDATE, TRUSTITEM.ITEMNO, 
	convert(varchar(254),
		case	when	TRUSTITEM.DESCRIPTION IS NULL
			then case	when	ORIGTRANS.DESCRIPTION IS NULL
					then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGDESCRIPTION)
					else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.DESCRIPTION
				end
			else	TRUSTITEM.DESCRIPTION
		end),
	-- If the trust item currency is null, the item is held in local currency
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRUSTITEM.LOCALVALUE*-1
		else	TRUSTITEM.FOREIGNVALUE*-1
	end,
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	CLOSEBAL.LOCALBALANCE*-1
		else	CLOSEBAL.FOREIGNBALANCE*-1
	end,
	'1/1/1999', -1, NULL, 0, 0,
	-- Calculate the aged balances
	convert( decimal(11,2),
	  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days) )+1) )) 
		* (	case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end )) ),
	convert( decimal(11,2),
	  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - @pnAge0Days)
		/convert(float,@pnAge1Days)) ) )) 
		* (	case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end )) ),
	convert( decimal(11,2),
	  sum( (1 - convert( bit, floor( ((datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days))
		/convert(float,@pnAge2Days)) ) )) 
		* (case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end) ) ),
	convert( decimal(11,2), 
	  sum( (1 - convert( bit, (sign( datediff(dd,ITEMDATE,@pdtBaseDate) - (@pnAge0Days+@pnAge1Days+@pnAge2Days-1) )-1) )) 
		* (case	when	TRUSTITEM.CURRENCY IS NULL
				then	CLOSEBAL.LOCALBALANCE*-1
				else	CLOSEBAL.FOREIGNBALANCE*-1
			end) )  ),
	-- Calculate the total Unallocated Cash
	convert( decimal(11,2), 0.0 ),
	-- HISTORYLINENO for this union return -1
	-1, TRUSTITEM.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, NULL, 1 'TRUST FLAG'
	-- rfc29203 original itemtransno use for sorting and report grouping as trustitem.itemno is the same when transfer	
	, TRUSTITEM.ITEMTRANSNO	

from 	TRUSTITEM,
	(
		SELECT TACCTENTITYNO, TACCTNAMENO, ITEMENTITYNO, ITEMTRANSNO,
		SUM(LOCALVALUE) AS LOCALBALANCE, SUM(FOREIGNTRANVALUE) AS FOREIGNBALANCE, COUNT(HISTORYLINENO) AS NUMROWS
		-- 20819  used max(TRUSTHISTORY.POSTPERIOD) instead of TRUSTITEM.CLOSEPERIOD for selecting data
		,MAX(POSTPERIOD) MAXPERIOD
		FROM TRUSTHISTORY
		WHERE POSTPERIOD <= @pnPeriod
	  	AND STATUS <> 0
		GROUP BY ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO
	) AS CLOSEBAL, TRUSTHISTORY ORIGTRANS,
	TABLECODES ITYPE, SITECONTROL HOMECURR, NAME DEBTOR
	left join IPNAME IPN on (IPN.NAMENO = DEBTOR.NAMENO)
	left join TABLECODES TC on (TC.TABLECODE = IPN.CATEGORY),
	CURRENCY

WHERE 	TRUSTITEM.ITEMTYPE = ITYPE.TABLECODE
and	ITYPE.TABLETYPE = 149 
and	TRUSTITEM.TACCTNAMENO = DEBTOR.NAMENO 
and	HOMECURR.CONTROLID = 'CURRENCY' 
and	CURRENCY.CURRENCY = (case when TRUSTITEM.CURRENCY IS NULL
			then convert(varchar(3),HOMECURR.COLCHARACTER)
			else TRUSTITEM.CURRENCY
			end) 
and	TRUSTITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
-- SQA20919
and ( CLOSEBAL.MAXPERIOD >=  @pnPeriod or CLOSEBAL.LOCALBALANCE <> 0 )

and	TRUSTITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items
and	TRUSTITEM.LOCALVALUE <> 0 			-- Exclude any items raised for zero value
and	TRUSTITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
and	(@pnEntityNo IS NULL or TRUSTITEM.TACCTENTITYNO = @pnEntityNo) -- Check filter criteria
and	(((TRUSTITEM.TACCTNAMENO = @pnDebtorNo)) OR	-- If the user has specified a single debtor find records that 
	((@pnDebtorNo IS NULL) AND			-- match that debtor's debtorno.
	(DEBTOR.NAMECODE IS NOT NULL) AND		-- If the user has specified a range include all records that 
	((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- have debtor namecodes that fall into that range and are not null
	(DEBTOR.NAMECODE <= @psToDebtor))) OR		-- If the user has specified a from debtor namecode include all 
	((@pnDebtorNo IS NULL) AND			-- records with debtor namecodes that are equal or greater than 
	((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- that debtor namecode
	(@psToDebtor IS NULL))) OR			-- If the user has specified a to debtor namecode include all 
	((@pnDebtorNo IS NULL) AND			-- records with debtor namecodes that are equal or less than that 
	((@psFromDebtor IS NULL) AND 			-- debtor namecode
	(DEBTOR.NAMECODE <= @psToDebtor))) OR		-- If all options are left blank return all results
	((@pnDebtorNo IS NULL) AND 
	(@psFromDebtor IS NULL) AND 
	(@psToDebtor IS NULL))) 
and	( (	TRUSTITEM.LOCALVALUE > 0 AND		-- Select only debit items which have had no movement on or before 
	CLOSEBAL.NUMROWS = 1 )				-- the period ie. the most recent history is the one that created the
	or (	TRUSTITEM.LOCALVALUE < 0 AND		-- item or credit items which are still open (to be reported without 
		CLOSEBAL.LOCALBALANCE <> 0 )	) 	-- history).
and	TRUSTITEM.ITEMENTITYNO = ORIGTRANS.ITEMENTITYNO -- Locate the history row which created the item
and	TRUSTITEM.ITEMTRANSNO = ORIGTRANS.ITEMTRANSNO 
and	TRUSTITEM.TACCTENTITYNO = ORIGTRANS.TACCTENTITYNO 
and	TRUSTITEM.TACCTNAMENO = ORIGTRANS.TACCTNAMENO 
and	ORIGTRANS.ITEMIMPACT = 1 
and	TRUSTITEM.ITEMENTITYNO = CLOSEBAL.ITEMENTITYNO 	-- The closing balance is on the most recent history processed 
and	TRUSTITEM.ITEMTRANSNO = CLOSEBAL.ITEMTRANSNO 	-- on or before the reporting period
and	TRUSTITEM.TACCTENTITYNO = CLOSEBAL.TACCTENTITYNO 
and	TRUSTITEM.TACCTNAMENO = CLOSEBAL.TACCTNAMENO
GROUP BY TRUSTITEM.TACCTENTITYNO, 
	DEBTOR.NAMECODE, TRUSTITEM.TACCTNAMENO, 
	case	when TRUSTITEM.CURRENCY IS NULL
		then convert(varchar(3),HOMECURR.COLCHARACTER)
		else TRUSTITEM.CURRENCY
	end,
	CURRENCY.DESCRIPTION,
	TRUSTITEM.ITEMDATE, TRUSTITEM.ITEMNO, 
	convert(varchar(254),
		case	when	TRUSTITEM.DESCRIPTION IS NULL
			then case	when	ORIGTRANS.DESCRIPTION IS NULL
					then	rtrim(ITYPE.DESCRIPTION) + ' ' + convert(varchar(254),ORIGTRANS.LONGDESCRIPTION)
					else	rtrim(ITYPE.DESCRIPTION) + ' ' + ORIGTRANS.DESCRIPTION
				end
			else	TRUSTITEM.DESCRIPTION
		end),
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	TRUSTITEM.LOCALVALUE*-1
		else	TRUSTITEM.FOREIGNVALUE*-1
	end,
	case	when	TRUSTITEM.CURRENCY IS NULL
		then	CLOSEBAL.LOCALBALANCE*-1
		else	CLOSEBAL.FOREIGNBALANCE*-1
	end, TRUSTITEM.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS
	-- rfc29203 original itemtransno use for sorting and report grouping as trustitem.itemno is the same when transfer	
	, TRUSTITEM.ITEMTRANSNO	
	


-- Insert Debtor items and movements

if @pbTrustOnly != 1
Begin

    insert #TASTATEMENT

    -- The first portion of the union selects all items which were opened prior
    -- to, or during the reporting period, and the associated movements in the item balance

    select OPENITEM.ACCTENTITYNO, 
	    DEBTOR.NAMECODE, 
	    OPENITEM.ACCTDEBTORNO, 
	    -- If the open item currency is null, use the home currency for the system
	    case	when OPENITEM.CURRENCY IS NULL
		    then convert(varchar(3),HOMECURR.COLCHARACTER)
		    else OPENITEM.CURRENCY
	    end,
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
	    -- HISTORYLINENO for this union should return Trans.HistoryLineNo
	    TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE, 0 'TRUST FLAG',
	    1 'OPENITEM.ITEMTRANSNO'

    FROM 	OPENITEM, 
	    (
		    SELECT ACCTENTITYNO, ACCTDEBTORNO, ITEMENTITYNO, ITEMTRANSNO, 
		    SUM(LOCALVALUE) AS LOCALBALANCE, SUM(FOREIGNTRANVALUE) AS FOREIGNBALANCE
		    FROM DEBTORHISTORY
		    WHERE POSTPERIOD <= @pnPeriod 
	  	    AND STATUS <> 0
		    GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
	    ) AS CLOSEBAL, DEBTORHISTORY ORIGTRANS, DEBTORHISTORY TRANS, DEBTOR_ITEM_TYPE ITYPE,
	    ACCT_TRANS_TYPE TTYPE, SITECONTROL HOMECURR, NAME DEBTOR
	    left join IPNAME IPN on (IPN.NAMENO = DEBTOR.NAMENO)
	    left join TABLECODES TC on (TC.TABLECODE = IPN.CATEGORY),
	    CURRENCY

    WHERE	OPENITEM.ITEMTYPE = ITYPE.ITEM_TYPE_ID 
    and	OPENITEM.ACCTDEBTORNO = DEBTOR.NAMENO 
    and	HOMECURR.CONTROLID = 'CURRENCY' 
    and	CURRENCY.CURRENCY = (case when OPENITEM.CURRENCY IS NULL
			    then convert(varchar(3),HOMECURR.COLCHARACTER)
			    else OPENITEM.CURRENCY
			    end) 
    and	OPENITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
    and	CLOSEBAL.LOCALBALANCE <> 0
    and	OPENITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items
    and	OPENITEM.LOCALVALUE > 0 			-- Exclude any credit items and items raised for zero value
							    -- Note: credit items are reported with no history
    and	OPENITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
    and	( @pnEntityNo IS NULL or 			-- Check filter criteria
	    OPENITEM.ACCTENTITYNO = @pnEntityNo ) 
    and	(((OPENITEM.ACCTDEBTORNO = @pnDebtorNo)) 	-- If the user has specified a single debtor find records that match 
		    OR					-- that debtor's debtorno
	    ((@pnDebtorNo IS NULL) AND 			-- If the user has specified a range include all records that have 
	    (DEBTOR.NAMECODE IS NOT NULL) AND 		-- debtor namecodes that fall into that range and are not null
	    ((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- If the user has specified a from debtor namecode include all 
	    (DEBTOR.NAMECODE <= @psToDebtor))) OR		-- records with debtor namecodes that are equal or greater than 
	    ((@pnDebtorNo IS NULL) AND			-- that debtor namecode
	    ((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- If the user has specified a to debtor namecode include all records with
	    (@psToDebtor IS NULL))) OR 			-- debtor namecodes that are equal or less than that debtor namecode
	    ((@pnDebtorNo IS NULL) AND
	    ((@psFromDebtor IS NULL) AND 
	    (DEBTOR.NAMECODE <= @psToDebtor))) OR 	-- If all options are left blank return all results
	    ((@pnDebtorNo IS NULL) AND 
	    (@psFromDebtor IS NULL) AND 
	    (@psToDebtor IS NULL))) 
    and	OPENITEM.ITEMENTITYNO = ORIGTRANS.ITEMENTITYNO 	-- Locate the history row which created the item
    and	OPENITEM.ITEMTRANSNO = ORIGTRANS.ITEMTRANSNO 
    and	OPENITEM.ACCTENTITYNO = ORIGTRANS.ACCTENTITYNO 
    and	OPENITEM.ACCTDEBTORNO = ORIGTRANS.ACCTDEBTORNO 
    and	ORIGTRANS.ITEMIMPACT = 1 
    and	OPENITEM.ITEMENTITYNO = CLOSEBAL.ITEMENTITYNO 	-- The closing balance is on the most recent history processed on or before
    and	OPENITEM.ITEMTRANSNO = CLOSEBAL.ITEMTRANSNO 	-- the reporting period
    and	OPENITEM.ACCTENTITYNO = CLOSEBAL.ACCTENTITYNO 
    and	OPENITEM.ACCTDEBTORNO = CLOSEBAL.ACCTDEBTORNO
    and	(OPENITEM.ITEMENTITYNO = TRANS.ITEMENTITYNO and	-- Select all of the history posted for the item on or before 
	    OPENITEM.ITEMTRANSNO = TRANS.ITEMTRANSNO and 	-- the reporting period.  Exclude the original history 
	    OPENITEM.ACCTENTITYNO = TRANS.ACCTENTITYNO and 	-- because this is already covered by the Item itself.
	    OPENITEM.ACCTDEBTORNO = TRANS.ACCTDEBTORNO and 
	    TRANS.POSTPERIOD <= @pnPeriod and 
	    TRANS.STATUS <> 0 and 
	    ( TRANS.ITEMIMPACT <> 1 or  TRANS.ITEMIMPACT IS NULL ) and 
	    TRANS.TRANSTYPE = TTYPE.TRANS_TYPE_ID )

    group by OPENITEM.ACCTENTITYNO, 
	    DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
	    case	when OPENITEM.CURRENCY IS NULL
		    then convert(varchar(3),HOMECURR.COLCHARACTER)
		    else OPENITEM.CURRENCY
	    end,
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
	    TRANS.MOVEMENTCLASS, TRANS.HISTORYLINENO, TRANS.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE

    UNION

    -- select any items opened on or before the reporting period which have not changed
    -- or are to be reported without history

    select OPENITEM.ACCTENTITYNO,
	    DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
	    -- If the open item currency is null, use the home currency for the system
	    case	when OPENITEM.CURRENCY IS NULL
		    then convert(varchar(3),HOMECURR.COLCHARACTER)
		    else OPENITEM.CURRENCY
	    end,
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
	    -1, OPENITEM.POSTPERIOD, TC.DESCRIPTION, IPN.TRADINGTERMS, OPENITEM.ITEMDUEDATE, 0 'TRUST FLAG',
	    1 'OPENITEM.ITEMTRANSNO'
	    
    from 	OPENITEM,
	    (
		    SELECT ACCTENTITYNO, ACCTDEBTORNO, ITEMENTITYNO, ITEMTRANSNO,
		    SUM(LOCALVALUE) AS LOCALBALANCE, SUM(FOREIGNTRANVALUE) AS FOREIGNBALANCE, COUNT(HISTORYLINENO) AS NUMROWS
		    FROM DEBTORHISTORY
		    WHERE POSTPERIOD <= @pnPeriod
	  	    AND STATUS <> 0
		    GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
	    ) AS CLOSEBAL, DEBTORHISTORY ORIGTRANS,
	    DEBTOR_ITEM_TYPE ITYPE, SITECONTROL HOMECURR, NAME DEBTOR
	    left join IPNAME IPN on (IPN.NAMENO = DEBTOR.NAMENO)
	    left join TABLECODES TC on (TC.TABLECODE = IPN.CATEGORY),
	    CURRENCY

    WHERE 	OPENITEM.ITEMTYPE = ITYPE.ITEM_TYPE_ID 
    and	OPENITEM.ACCTDEBTORNO = DEBTOR.NAMENO 
    and	HOMECURR.CONTROLID = 'CURRENCY' 
    and	CURRENCY.CURRENCY = (case when OPENITEM.CURRENCY IS NULL
			    then convert(varchar(3),HOMECURR.COLCHARACTER)
			    else OPENITEM.CURRENCY
			    end) 
    and	OPENITEM.POSTPERIOD <= @pnPeriod 		-- Select all items open during the reporting period
    and CLOSEBAL.LOCALBALANCE <> 0    
    and	OPENITEM.STATUS IN (1,2) 			-- Include active and locked. Exclude draft and reversed items
    and	OPENITEM.LOCALVALUE <> 0 			-- Exclude any items raised for zero value
    and	OPENITEM.ITEMDATE <= @pdtItemDateTo 		-- Ensure no future ageing brackets
    and	(@pnEntityNo IS NULL or OPENITEM.ACCTENTITYNO = @pnEntityNo) -- Check filter criteria
    and	(((OPENITEM.ACCTDEBTORNO = @pnDebtorNo)) OR	-- If the user has specified a single debtor find records that 
	    ((@pnDebtorNo IS NULL) AND			-- match that debtor's debtorno.
	    (DEBTOR.NAMECODE IS NOT NULL) AND		-- If the user has specified a range include all records that 
	    ((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- have debtor namecodes that fall into that range and are not null
	    (DEBTOR.NAMECODE <= @psToDebtor))) OR	-- If the user has specified a from debtor namecode include all 
	    ((@pnDebtorNo IS NULL) AND			-- records with debtor namecodes that are equal or greater than 
	    ((DEBTOR.NAMECODE >= @psFromDebtor) AND 	-- that debtor namecode
	    (@psToDebtor IS NULL))) OR			-- If the user has specified a to debtor namecode include all 
	    ((@pnDebtorNo IS NULL) AND			-- records with debtor namecodes that are equal or less than that 
	    ((@psFromDebtor IS NULL) AND 		-- debtor namecode
	    (DEBTOR.NAMECODE <= @psToDebtor))) OR	-- If all options are left blank return all results
	    ((@pnDebtorNo IS NULL) AND 
	    (@psFromDebtor IS NULL) AND 
	    (@psToDebtor IS NULL))) 
    and	( (	OPENITEM.LOCALVALUE > 0 AND		-- Select only debit items which have had no movement on or before 
	    CLOSEBAL.NUMROWS = 1 )			-- the period ie. the most recent history is the one that created the
	    or (	OPENITEM.LOCALVALUE < 0 AND	-- item or credit items which are still open (to be reported without 
			CLOSEBAL.LOCALBALANCE <> 0 ) ) 	-- history).
    and	OPENITEM.ITEMENTITYNO = ORIGTRANS.ITEMENTITYNO 	-- Locate the history row which created the item
    and	OPENITEM.ITEMTRANSNO = ORIGTRANS.ITEMTRANSNO 
    and	OPENITEM.ACCTENTITYNO = ORIGTRANS.ACCTENTITYNO 
    and	OPENITEM.ACCTDEBTORNO = ORIGTRANS.ACCTDEBTORNO 
    and	ORIGTRANS.ITEMIMPACT = 1 
    and	OPENITEM.ITEMENTITYNO = CLOSEBAL.ITEMENTITYNO 	-- The closing balance is on the most recent history processed 
    and	OPENITEM.ITEMTRANSNO = CLOSEBAL.ITEMTRANSNO 	-- on or before the reporting period
    and	OPENITEM.ACCTENTITYNO = CLOSEBAL.ACCTENTITYNO 
    and	OPENITEM.ACCTDEBTORNO = CLOSEBAL.ACCTDEBTORNO
    GROUP BY OPENITEM.ACCTENTITYNO, 
	    DEBTOR.NAMECODE, OPENITEM.ACCTDEBTORNO, 
	    case	when OPENITEM.CURRENCY IS NULL
		    then convert(varchar(3),HOMECURR.COLCHARACTER)
		    else OPENITEM.CURRENCY
	    end,
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
	    

	-- rfc39203 populate the openitem.itemtransno which is unique for debtor and openitem number
	-- Note: can't get the itemtransno in the previous sql because the aggregation is at the openitem level not itemtranno level (e.g. multip debtor bill has different openitem but same itemtransno).
	Update T
	set ITEMTRANSNO = O.ITEMTRANSNO
	from #TASTATEMENT T
	left join OPENITEM O on O.OPENITEMNO = T.ITEMNO
				and O.ACCTENTITYNO = T.ACCTENTITYNO
				and O.ACCTDEBTORNO = T.ACCTDEBTORNO
	WHERE T.TRUST <> 1				

End


Select 	@sLocalCurrency = convert(varchar(3),COLCHARACTER)
from	SITECONTROL
where	CONTROLID = 'CURRENCY' 

If @pnSortBy = 1
Begin
	-- Sort by Debtor Category
	DECLARE stmtcursor CURSOR FOR

	-- rfc39203 sort by 23 (itemtransno) after 7 (itemno) 	
	select * from #TASTATEMENT
	ORDER BY 23,1,2,3,4,5,6,7,27,8,9,10,11,12,13

	OPEN stmtcursor 
End
Else
Begin
	DECLARE stmtcursor CURSOR FOR
	
	select * from #TASTATEMENT
	ORDER BY 1,2,3,4,5,6,7,27,8,9,10,11,12,13

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
	@sDebtorCategory, @nTradingTerms, @dtItemDueDate, @bTrust, @nItemTransNo

Select @nLastDebtorNo = @nAcctDebtorNo - 1
Select @nLastEntityNo = @nAcctEntityNo - 1
Select @sLastCurrency = NULL

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
			If exists ( SELECT 1 FROM #TASTATEMENT ARS 
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
			SELECT @nStatementClosingBalance=SUM(CLOSINGBALANCE) FROM #TASTATEMENT ARS
			WHERE ARS.ACCTENTITYNO = @nAcctEntityNo AND ARS.ACCTDEBTORNO= @nAcctDebtorNo AND
			ARS.CURRENCY = @sCurrency AND 
			HISTORYLINENO = (SELECT MIN ( HISTORYLINENO )
						FROM #TASTATEMENT ARH
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
			Select @nTotalPayments = 0
			
			If ( @sCurrency = @sLocalCurrency )
				EXEC ta_TotalPayments
					@pnPeriod = @pnPeriod,
					@pnEntityNo = @nAcctEntityNo, 
					@pnDebtorNo = @nAcctDebtorNo,
					@prnTotalPayments = @nTrustPayments OUTPUT
			Else
				EXEC ta_TotalPayments
					@pnPeriod = @pnPeriod,
					@psCurrency = @sCurrency,
					@pnEntityNo = @nAcctEntityNo, 
					@pnDebtorNo = @nAcctDebtorNo,
					@prnTotalPayments = @nTrustPayments OUTPUT
					
			If @pbTrustOnly != 1
			Begin
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
			End		
			
			Select @nTotalPayments = isnull( @nTotalPayments, 0 ) + isnull( @nTrustPayments, 0 )
					
			If @nLastDebtorNo <> @nAcctDebtorNo
			OR @sLastCurrency <> @sCurrency		
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
		If @nMovementClass = 5 
		BEGIN
			Select @sTransDescription = NULL
			
			If @bTrust = 1
				EXEC ta_TransferredFromDesc
					@pnRefEntityNo = @nAcctEntityNo, 
					@pnRefTransNo = @nTransNo,
					@prsDescription = @sTransDescription OUTPUT		
			else
				EXEC aro_TransferredFromDesc
					@pnRefEntityNo = @nAcctEntityNo, 
					@pnRefTransNo = @nTransNo,
					@prsDescription = @sTransDescription OUTPUT							
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
			@nTotalPayments, @sDebtorCategory, @nTradingTerms, @dtItemDueDate, @nItemTransNo

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
		@sDebtorCategory, @nTradingTerms, @dtItemDueDate, @bTrust, @nItemTransNo

-- while
END

close stmtcursor
deallocate stmtcursor

return 0
go

grant execute on [dbo].[ta_OpenItemStatement] to public
go
