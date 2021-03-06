-----------------------------------------------------------------------------------------------------------------------------
-- Creation of arbw_OpenItemStatement
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[arbw_OpenItemStatement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.arbw_OpenItemStatement.'
	Drop procedure [dbo].[arbw_OpenItemStatement]	
End
Print '**** Creating Stored Procedure dbo.arbw_OpenItemStatement...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[arbw_OpenItemStatement] @pnUserIdentityId	INT,
                                                @psCulture		NVARCHAR(10),
                                                @pnPeriod		INT,
                                                @pnEntityNo		INT = NULL,
                                                @pnPrintZeroBalance	INT = 0,
                                                @pnDebtorNo		INT = NULL,
                                                @psFromDebtor		VARCHAR(10) = NULL,
                                                @psToDebtor		VARCHAR(10) = NULL,
                                                @pbPrintPositiveBal	BIT = 1,
                                                @pbPrintNegativeBal	BIT = 1,
                                                @pbPrintZeroBalWOAct	BIT = 0,
                                                @pnSortBy		TINYINT = 0,
                                                @pbCalledFromCentura	bit = 0,
						@psDebtorRestrictions	NVARCHAR(4000)	= null,
						@pbLocalDebtor		bit = 1,
						@pbForeignDebtor	bit = 1,
						@psDebtorNos		NVARCHAR(4000)	= null
AS

  -- PROCEDURE : arbw_OpenItemStatement        
  -- VERSION : 9       
  -- DESCRIPTION: This is a wrapper procedure coded for workbenches version of the OpenItemStatement for debtor. This procedure calls        
  --     proc: arb_OpenItemStatement to browse for all the open items which meet the supplied parameters, and the associated history (if any)         
  --   which falls within the reporting period.  The procedure calculates the opening and closing balance for each item, and        
  --   ages the closing balance.  All figures reported are in the currency in which the item was raised. Also formats and returns        
  --   the mailing address for the debtor or debtors in question. Sorted by Entity, debtor name code, currency of the items,         
  --   Item Date, Item No, Transaction Date and TransactionNo. Couple of Temporary tables have been used to cross join their results         
  --  to fetch the final dataset. In additon to above details fetched by arb_OpenItemStatement, this procedure fecthes Entity Address        
  --  details and END PERIOD DATE. Cross joins all the debtor item details with the outut to form a single dataset.        
  -- CALLED BY :         
  -- COPYRIGHT: Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited        
  -- CREATED BY : Tarun Madaan        
  -- CREATED ON : 04/08/2010        
  -- PROCEDURES USED: dbo.arb_OpenItemStatement        
  -- MODIFICTIONS :        
  -- Date         Who   SQA#	Version		Change        
  -- ------------ ---- ----	--------	-------------------------------------------         
  -- 05/08/2010	  TM   RFC9630  1		Wrote stored procedure        
  -- 14/09/2010   TM   -------  2		Modified for insert error in temp table    
  -- 19/05/2011   LP   -------	3		Corrected with use of temp tables.
  -- 28/03/2014	  MS   R31038	4		Added parameters for debtor restrictions, local and foreign debtors for filter
  -- 18/06/2014   DV   R35246	5		Added parameter to filter for multiple debtor
  -- 24/11/2015	  DL   R55498   6		Debtors item Movememt Report - Incorrect 'Total Unallocated Funds’ display after Credit allocation 
  -- 22/08/2016	  LP   R65046	7		Re-order items within the final SELECT statement.
  -- 24 Aug 2017  MF   71713	8		Ethical Walls rules applied for logged on user.
  -- 22 Mar 2019  MS   DR45695  9               Added IRN and Client's reference fields in resultset
	
 
 
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
 
DECLARE @check INT
declare @sSQLString nvarchar(max)
declare @nErrorCode int
declare @dtBaseDate datetime
declare @dtItemDateTo datetime
declare @nAge0Days int
declare @nAge1Days int
declare @nAge2Days int       
declare @nBracket0Days int
declare @nBracket1Days int
declare @nBracket2Days int                                         

CREATE TABLE #temp_ARSTATEMENT_basic
(
	MAILINGLABEL        VARCHAR(254) NULL,
	ACCTENTITYNO        INT NULL,
	NAMECODE            VARCHAR(10) COLLATE database_default NULL,
	ACCTDEBTORNO        INT NULL,
	CURRENCY            VARCHAR(3) COLLATE database_default NULL,
	CURRENCYDESCRIPTION VARCHAR(40) COLLATE database_default NULL,
	ITEMDATE            DATETIME NULL,
	ITEMNO              VARCHAR(12) COLLATE database_default NULL,
	ITEMDESCRIPTION     VARCHAR(254) COLLATE database_default,
	OPENINGBALANCE      DECIMAL(11, 2),
	CLOSINGBALANCE      DECIMAL(11, 2),
	TRANSDATE           DATETIME NULL,
	TRANSNO             INT NULL,
	TRANSDESCRIPTION    VARCHAR(254) COLLATE database_default NULL,
	TRANSAMOUNT         DECIMAL(11, 2) NULL,
	--MOVEMENTCLASS   smallint,    
	AGE0                DECIMAL(11, 2),
	AGE1                DECIMAL(11, 2),
	AGE2                DECIMAL(11, 2),
	AGE3                DECIMAL(11, 2),
	UNALLOCATEDCASH     DECIMAL(11, 2),
	--HISTORYLINENO   INT NULL,    
	TOTALPAYMENTS       DECIMAL(11, 2),
	NAMECATEGORY        NVARCHAR(80) COLLATE database_default,
	TRADINGTERMS        INT,
	ITEMDUEDATE         DATETIME
)
    
CREATE TABLE #temp_ARSTATEMENT
(
	MAILINGLABEL        VARCHAR(254) NULL,
	ACCTENTITYNO        INT NULL,
	NAMECODE            VARCHAR(10) COLLATE database_default NULL,
	ACCTDEBTORNO        INT NULL,
	CURRENCY            VARCHAR(3) COLLATE database_default NULL,
	CURRENCYDESCRIPTION VARCHAR(40) COLLATE database_default NULL,
	ITEMDATE            DATETIME NULL,
	ITEMNO              VARCHAR(12) COLLATE database_default NULL,
	ITEMDESCRIPTION     VARCHAR(254) COLLATE database_default,
	OPENINGBALANCE      DECIMAL(11, 2),
	CLOSINGBALANCE      DECIMAL(11, 2),
	TRANSDATE           DATETIME NULL,
	TRANSNO             INT NULL,
	TRANSDESCRIPTION    VARCHAR(254) COLLATE database_default NULL,
	TRANSAMOUNT         DECIMAL(11, 2) NULL,
	--MOVEMENTCLASS   smallint,    
	AGE0                DECIMAL(11, 2),
	AGE1                DECIMAL(11, 2),
	AGE2                DECIMAL(11, 2),
	AGE3                DECIMAL(11, 2),
	UNALLOCATEDCASH     DECIMAL(11, 2),
	--HISTORYLINENO   INT NULL,    
	TOTALPAYMENTS       DECIMAL(11, 2),
	NAMECATEGORY        NVARCHAR(80) COLLATE database_default,
	TRADINGTERMS        INT,
	ITEMDUEDATE         DATETIME,
	EntityName	nvarchar(254) collate database_default	null,
	EntityStreet1	nvarchar(254) collate database_default	null,
	EntityStreet2	nvarchar(254) collate database_default	null,
	EntityCity	nvarchar(30) collate database_default	null,
	EntityState	nvarchar(20) collate database_default	null,
	EntityPostCode	nvarchar(10) collate database_default	null,
	EntityCountry	nvarchar(60) collate database_default	null,
	ENDDATE		datetime				null,
        OURREF          nvarchar(30) collate database_default	null,
        YOURREF         nvarchar(30) collate database_default	null
)

create table #temp_PeriodDate
(
	ENDDATE datetime null
)

Set @nErrorCode = 0

If (@nErrorCode =0) and (@pnPeriod is not null)
Begin
	exec @nErrorCode = dbo.acw_GetAgeingBrackets         
	@pnUserIdentityId,
	@psCulture,
	@pbCalledFromCentura,
	@pnPeriod,
	@dtBaseDate output,
	@nBracket0Days output,
	@nBracket1Days output,
	@nBracket2Days output

	Set @nAge0Days = @nBracket0Days
	Set @nAge1Days = (@nBracket1Days - @nBracket0Days)
	Set @nAge2Days = (@nBracket2Days - @nBracket1Days)
	-- report based on period so both these dates will be the same (end of specified period)
	Set @dtItemDateTo = @dtBaseDate
	
	Set @nErrorCode = @@Error
End

if (@nErrorCode = 0)
Begin
	INSERT INTO #temp_ARSTATEMENT_basic
	EXEC [dbo].[arb_OpenItemStatement]
	@pnPeriod,
	@dtBaseDate,
	@dtItemDateTo,
	@nAge0Days,
	@nAge1Days,
	@nAge2Days,
	@pnEntityNo,
	@pnPrintZeroBalance,
	@pnDebtorNo,
	@psFromDebtor,
	@psToDebtor,
	@pbPrintPositiveBal,
	@pbPrintNegativeBal,
	@pbPrintZeroBalWOAct,
	@pnSortBy,
	@psDebtorRestrictions,
	@pbLocalDebtor,
	@pbForeignDebtor,
	@psDebtorNos

	Set @nErrorCode = @@Error
End

if (@nErrorCode = 0)
Begin
	insert into #temp_PeriodDate(ENDDATE)
	SELECT ENDDATE
	FROM   PERIOD
	WHERE  PERIODID = @pnPeriod

	Set @nErrorCode = @@Error
End

---------------------- Create Entity Address Details Dataset -------------------------------
if (@nErrorCode = 0)
Begin
	SELECT N_Ent.NAME     AS EntityName,
	A_Ent.STREET1  AS EntityStreet1,
	A_Ent.STREET2  AS EntityStreet2,
	A_Ent.CITY     AS EntityCity,
	A_Ent.STATE    AS EntityState,
	A_Ent.POSTCODE AS EntityPostCode,
	C.COUNTRY      AS EntityCountry
	INTO   #temp_EntityDetails
	FROM   dbo.NAME N_Ent
	JOIN dbo.ADDRESS A_Ent
	ON N_Ent.POSTALADDRESS = A_Ent.ADDRESSCODE
	JOIN dbo.COUNTRY C
	ON A_Ent.COUNTRYCODE = C.COUNTRYCODE
	WHERE  N_Ent.NAMENO = @pnEntityNo

	Set @nErrorCode = @@Error

End
  
if (@nErrorCode = 0)
Begin
	if @pnSortBy = 1
	Begin
		INSERT INTO #temp_ARSTATEMENT
		SELECT B.*, E.*, P.*, NULL, NULL
		FROM   #temp_ARSTATEMENT_basic B
		left join dbo.fn_NamesEthicalWall(@pnUserIdentityId) D on (D.NAMENO = B.ACCTDEBTORNO)
		CROSS JOIN #temp_EntityDetails E
		CROSS JOIN #temp_PeriodDate P
		where (D.NAMENO is not null OR B.ACCTDEBTORNO is null) -- Apply ethical wall rules to filter out rows
		ORDER  BY 22,2,3,4,5,6,7,8,9,10,11,12,13
	End
	Else
	Begin
		INSERT INTO #temp_ARSTATEMENT
		SELECT B.*, E.*, P.*, NULL, NULL
		FROM   #temp_ARSTATEMENT_basic B
		left join dbo.fn_NamesEthicalWall(@pnUserIdentityId) D on (D.NAMENO = B.ACCTDEBTORNO)
		CROSS JOIN #temp_EntityDetails E
		CROSS JOIN #temp_PeriodDate P
		where (D.NAMENO is not null OR B.ACCTDEBTORNO is null) -- Apply ethical wall rules to filter out rows
		ORDER  BY 2,3,4,5,6,7,8,9,10,11,12,13
	End
	set @nErrorCode = @@Error
End

if (@nErrorCode = 0)
Begin
        UPDATE #temp_ARSTATEMENT  SET OURREF  = (SELECT min( C1.IRN ) 
                                                     FROM OPENITEM O 
                                                     join WORKHISTORY WH on (O.ITEMENTITYNO = WH.REFENTITYNO and O.ITEMTRANSNO = WH.REFTRANSNO AND WH.MOVEMENTCLASS = 2)
                                                     join CASES C1	on (C1.CASEID=ISNULL(O.MAINCASEID, WH.CASEID))  		
                                                     WHERE O.OPENITEMNO   = #temp_ARSTATEMENT.ITEMNO  		
                                                     AND   O.ITEMENTITYNO = #temp_ARSTATEMENT.ACCTENTITYNO)

End

if (@nErrorCode = 0)
Begin
        UPDATE #temp_ARSTATEMENT  SET YOURREF = CN.REFERENCENO 
        FROM #temp_ARSTATEMENT T		
        join CASES C on  (C.IRN = T.OURREF) 
        join CASENAME CN on (CN.CASEID=C.CASEID and CN.EXPIRYDATE is null and CN.NAMENO = T.ACCTDEBTORNO) 
        join OPENITEM O on (O.ACCTENTITYNO = T.ACCTENTITYNO and O.OPENITEMNO = T.ITEMNO)
        where CN.NAMETYPE = CASE WHEN O.RENEWALDEBTORFLAG = 1 THEN 'Z' ELSE 'D' END
End
  
If (@nErrorCode = 0)
---------------- Alter the table to add identity field for unique records-------------------
BEGIN
	ALTER TABLE #temp_ARSTATEMENT
	ADD identity_field INT IDENTITY (1, 1);

	/* Ranking the records with same item number value transactions to update 
	closing balalnce, and all aging fields to 0 after header transaction */
	SELECT *,
	Rank() OVER (partition BY acctentityno, namecode, acctdebtorno, currency, itemno ORDER BY identity_field) rankid
	INTO   #temp_ARSTATEMENT1
	FROM   #temp_ARSTATEMENT;

	UPDATE #temp_ARSTATEMENT1
	SET    CLOSINGBALANCE = 0,
	AGE3 = 0,
	AGE2 = 0,
	AGE1 = 0,
	AGE0 = 0,
	UNALLOCATEDCASH = 0
	WHERE  rankid <> 1;        
        	
	/* Final output */
	if @pnSortBy = 1
	Begin
		SELECT *
		FROM   #temp_ARSTATEMENT1
		ORDER  BY 22,2,3,4,5,6,7,8,9,10,11,12,13
	End
	Else
	Begin
		SELECT *
		FROM   #temp_ARSTATEMENT1
		ORDER  BY 2,3,4,5,6,7,8,9,10,11,12,13
	End

	Set @nErrorCode = @@Error
END
 
DROP TABLE #temp_ARSTATEMENT
  
RETURN @nErrorCode
GO
  

GRANT EXECUTE ON [dbo].[arbw_OpenItemStatement] TO PUBLIC
go 
