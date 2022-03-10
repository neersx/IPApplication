-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListApplyItems
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ListApplyItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ListApplyItems.'
	Drop procedure [dbo].[ap_ListApplyItems]
End
Print '**** Creating Stored Procedure dbo.ap_ListApplyItems...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_ListApplyItems
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)
as
-- PROCEDURE:	ap_ListApplyItems
-- VERSION:	9
-- SCOPE:	InPro
-- DESCRIPTION:	Returns Apply Items details based on an XML Filter Document
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 27 Apr 2005	AT	SQA9716		1	Procedure created.
-- 08 Jun 2005	AT	SQA9716		2	Fixed bugs.
-- 11 Oct 2005	AT	SQA11915	3	Fixed return of Currency to currency of Credit Item.
--						Added Currency of Receivable as return column.
-- 12 Sep 2006	Dev	SQA12884	4	Moved the "where" clause which filters Debtor No into
--						the inline select statement
-- 17 Mar 2008	AT	SQA14523	5	Return negative amounts for supplier receipts.
-- 07 Apr 2009	DL	SQA17551	6	Extract debtor instead of creditor number for display on Offset SUMMARY window.
-- 05 Jul 2013	vql	R13629		7	Remove string length restriction on datetime conversions using 106 format and use nvarchar.
-- 17 Jul 2018	DL	R56452		8	Duplicate entries in Apply Item Summary window
-- 14 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Initialise variables
declare @sSql 			nvarchar(4000)
declare @sSqlFrom 		nvarchar(2000)
declare @sSqlWhere		nvarchar(1500)
Declare @bApplyItemsMode	bit
Declare @nEntityNo		int
Declare @nSupplierNo		int
Declare @nDebtorNo		int
Declare @nEntryNo		int
Declare @nEnteredBy		int
Declare @dtTransDateFrom	datetime
Declare @dtTransDateTo		datetime
Declare @bDraft			bit
Declare @bFinalised		bit
Declare @dtDatePostedFrom	datetime
Declare @dtDatePostedTo		datetime
Declare @nLocalValueFrom	decimal(13,2)
Declare @nLocalValueTo		decimal(13,2)
Declare @sForeignCurrency	nVarChar(3)
Declare @nForeignValueFrom	decimal(13,2)
Declare @nForeignValueTo	decimal(13,2)

declare	@nErrorCode int
Set	@nErrorCode = 0

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int

If @nErrorCode = 0
Begin

-- Extract the filtering details that are to be applied to the extracted columns as opposed
-- to the filtering that applies to the result set.
If @nErrorCode = 0
Begin
	If PATINDEX ('%<Filter>%', @ptXMLFilterCriteria)> 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML
		Exec sp_xml_preparedocument @idoc OUTPUT, @ptXMLFilterCriteria 	
		-- Retrieve the filter criteria into corresponding variables
		Set @sSql = 	
		"Select	@bApplyItemsMode	= ApplyItemsMode,"+CHAR(10)+
		"	@nEntityNo		= EntityNo,"+CHAR(10)+
		"	@nSupplierNo		= SupplierNo,"+CHAR(10)+
		"	@nDebtorNo		= DebtorNo,"+CHAR(10)+
		"	@nEntryNo		= EntryNo,"+CHAR(10)+
		"	@nEnteredBy		= EnteredBy,"+CHAR(10)+
		"	@dtTransDateFrom	= TransDateFrom,"+CHAR(10)+
		"	@dtTransDateTo		= TransDateTo,"+CHAR(10)+
		"	@bDraft			= Draft,"+CHAR(10)+
		"	@bFinalised		= Finalised,"+CHAR(10)+
		"	@dtDatePostedFrom	= DatePostedFrom,"+CHAR(10)+
		"	@dtDatePostedTo		= DatePostedTo,"+CHAR(10)+
		"	@nLocalValueFrom	= LocalValueFrom,"+CHAR(10)+
		"	@nLocalValueTo		= LocalValueTo,"+CHAR(10)+
		"	@sForeignCurrency	= ForeignCurrency,"+CHAR(10)+
		"	@nForeignValueFrom	= ForeignValueFrom,"+CHAR(10)+
		"	@nForeignValueTo	= ForeignValueTo"+CHAR(10)+
		"from	OPENXML (@idoc, '/Filter',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	ApplyItemsMode		bit		'rbApplyItems/text()',"+CHAR(10)+
		"	EntityNo		int		'cmbEntity/text()',"+CHAR(10)+
		"	SupplierNo		int		'dfSupplier/text()',"+CHAR(10)+
		"	DebtorNo		int		'dfDebtor/text()',"+CHAR(10)+
		"	EntryNo			int		'dfEntryNo/text()',"+CHAR(10)+
		"	EnteredBy		int		'dfEnteredBy/text()',"+CHAR(10)+
		"	TransDateFrom		datetime	'dfTransDateFrom/text()',"+CHAR(10)+
		"	TransDateTo		datetime	'dfTransDateTo/text()',"+CHAR(10)+
		"	Draft			bit		'cbDraft/text()',"+CHAR(10)+
		"	Finalised		bit		'cbFinalised/text()',"+CHAR(10)+
		"	DatePostedFrom		datetime	'dfDatePostedFrom/text()',"+CHAR(10)+
		"	DatePostedTo		datetime	'dfDatePostedTo/text()',"+CHAR(10)+
		"	LocalValueFrom		decimal(13,2)	'dfLocalValueFrom/text()',"+CHAR(10)+
		"	LocalValueTo		decimal(13,2)	'dfLocalValueTo/text()',"+CHAR(10)+
		"	ForeignCurrency		nVarChar(3)	'cmbForeignValueCurr/text()',"+CHAR(10)+
		"	ForeignValueFrom	decimal(13,2)	'dfForeignValueFrom/text()',"+CHAR(10)+
		"	ForeignValueTo		decimal(13,2)	'dfForeignValueTo/text()'"+CHAR(10)+
		"	     )"

		Exec @nErrorCode = sp_executesql @sSql,
				N'@idoc			int,
				@bApplyItemsMode	bit		output,
				@nEntityNo		int		output,
				@nSupplierNo		int		output,
				@nDebtorNo		int		output,
				@nEntryNo		int		output,
				@nEnteredBy		int		output,
				@dtTransDateFrom	datetime	output,
				@dtTransDateTo		datetime	output,
				@bDraft			bit		output,
				@bFinalised		bit		output,
				@dtDatePostedFrom	datetime	output,
				@dtDatePostedTo		datetime	output,
				@nLocalValueFrom	decimal(13,2)	output,
				@nLocalValueTo		decimal(13,2)	output,
				@sForeignCurrency	nVarChar(3)	output,
				@nForeignValueFrom	decimal(13,2)	output,
				@nForeignValueTo	decimal(13,2)	output',
				@idoc			= @idoc,
				@bApplyItemsMode	= @bApplyItemsMode	output,
				@nEntityNo		= @nEntityNo		output,
				@nSupplierNo		= @nSupplierNo		output,
				@nDebtorNo		= @nDebtorNo		output,
				@nEntryNo		= @nEntryNo		output,
				@nEnteredBy		= @nEnteredBy		output,
				@dtTransDateFrom	= @dtTransDateFrom	output,
				@dtTransDateTo		= @dtTransDateTo	output,
				@bDraft			= @bDraft		output,
				@bFinalised		= @bFinalised		output,
				@dtDatePostedFrom	= @dtDatePostedFrom	output,
				@dtDatePostedTo		= @dtDatePostedTo	output,
				@nLocalValueFrom	= @nLocalValueFrom	output,
				@nLocalValueTo		= @nLocalValueTo	output,
				@sForeignCurrency	= @sForeignCurrency	output,
				@nForeignValueFrom	= @nForeignValueFrom	output,
				@nForeignValueTo	= @nForeignValueTo	output
	
		Exec sp_xml_removedocument @idoc
	End


End



If @nErrorCode = 0
Begin
	-- Set the base SQL table joins first.
	If @bApplyItemsMode = 1
	Begin
		-- Offset Payables Mode
		Set @sSql = '
			Select DISTINCT C.REFTRANSNO, C.TRANSDATE, C.POSTDATE, C.ACCTCREDITORNO, SN.NAME, NULL, NULL, TOTALS.CURRENCY,
			TOTALS.LOCALVALUE, TOTALS.FOREIGNTRANVALUE,
			NULL, NULL, NULL, NULL,
			V.EXCHVARIANCE AS TOTALVARIANCE, C.STATUS, ISNULL(C.DESCRIPTION, C.LONGDESCRIPTION) AS DESCRIPTION'

		Set @sSqlFrom = '
			From CREDITORHISTORY C
			Join (SELECT REFTRANSNO, REFENTITYNO, SUM(LOCALVALUE) AS LOCALVALUE, 
				CASE WHEN COUNT(CURRENCY) <= 2 THEN SUM(FOREIGNTRANVALUE) ELSE NULL END AS FOREIGNTRANVALUE, CURRENCY
				From CREDITORHISTORY
				Where TRANSTYPE = 708
				and MOVEMENTCLASS = 4
				GROUP BY REFTRANSNO, REFENTITYNO, CURRENCY
				) as TOTALS on (TOTALS.REFTRANSNO = C.REFTRANSNO
						AND TOTALS.REFENTITYNO = C.REFENTITYNO)
			Left Join (SELECT REFENTITYNO, REFTRANSNO, SUM(C.EXCHVARIANCE) AS EXCHVARIANCE FROM CREDITORHISTORY C
				WHERE C.MOVEMENTCLASS = 5
				GROUP BY C.REFENTITYNO, C.REFTRANSNO) as V ON (V.REFENTITYNO = C.REFENTITYNO AND V.REFTRANSNO = C.REFTRANSNO)
			Left Join NAME SN on (SN.NAMENO = C.ACCTCREDITORNO)
			'

		Set @sSqlWhere = '
			Where C.TRANSTYPE = 708
			and C.MOVEMENTCLASS = 5'


	End
	If @bApplyItemsMode = 0
	Begin
		-- AR/AP Offset Mode
		-- RFC56452 Replace foreign currency with NULL as it is causing duplicate result when exist multiple items with difference currency.
			--CASE WHEN(DEBTORVALUES.RECFOREIGNTRANVALUE != 0) THEN DEBTORVALUES.CURRENCY ELSE NULL END,
			--CASE WHEN(CREDITORVALUES.PAYFOREIGNTRANVALUE != 0) THEN C.CURRENCY ELSE NULL END, NULL, NULL,
		Set @sSql = 'SELECT DISTINCT C.REFTRANSNO, C.TRANSDATE, C.POSTDATE, C.ACCTCREDITORNO, NULL, SN.NAME, 
			NULL, NULL, NULL, NULL,
			DEBTORVALUES.RECLOCALVALUE, DEBTORVALUES.RECFOREIGNTRANVALUE,
			CREDITORVALUES.PAYLOCALVALUE, CREDITORVALUES.PAYFOREIGNTRANVALUE,
			(CREDITORVALUES.PAYLOCALVALUE - DEBTORVALUES.RECLOCALVALUE + CREDITORVALUES.EXCHVARIANCE) AS TOTALVARIANCE, 
			C.STATUS, ISNULL(C.DESCRIPTION, C.LONGDESCRIPTION) AS DESCRIPTION'
		-- We have to cater for a situation where creditor items of different currencies have been offset.
		-- Sum all the values up in CREDITORHISTORY and DEBTORHISTORY in a sub-select then return them.
		-- This way we avoid a large GROUP BY statement since we need to SUM multiple CREDITOR/DEBTOR HISTORY rows.
		set @sSqlFrom ='
			From 
			(SELECT D.REFTRANSNO, D.REFENTITYNO, D.CURRENCY,
			(SUM(D.LOCALVALUE)*-1) AS RECLOCALVALUE, 
			CASE 	WHEN D.REFTRANSNO IN ( SELECT REFTRANSNO FROM 
								(
								SELECT REFENTITYNO, REFTRANSNO, CURRENCY FROM DEBTORHISTORY
								GROUP BY REFENTITYNO, REFTRANSNO, CURRENCY
								) AS TABLE1 
							GROUP BY REFENTITYNO, REFTRANSNO, CURRENCY
							HAVING COUNT(CURRENCY) > 1 ) 
				THEN null
				ELSE (SUM(D.FOREIGNTRANVALUE)*-1) END AS RECFOREIGNTRANVALUE, 
			SUM(D.EXCHVARIANCE) AS EXCHVARIANCE
			From DEBTORHISTORY D'
			-- SQA12884 Dev
			If (@nDebtorNo is not NULL) AND (@bApplyItemsMode = 0)
			Begin
				Set @sSqlFrom = @sSqlFrom + '
					WHERE D.ACCTDEBTORNO = ' + Cast(@nDebtorNo as nVarChar(11))
			End

			Set @sSqlFrom = @sSqlFrom + '
			GROUP BY D.REFTRANSNO, D.REFENTITYNO, D.CURRENCY) AS DEBTORVALUES
			JOIN
			(SELECT C.REFTRANSNO, C.REFENTITYNO,
			(SUM(C.LOCALVALUE)*-1) AS PAYLOCALVALUE,
			CASE 	WHEN C.REFTRANSNO IN 	(SELECT REFTRANSNO FROM 
								(
								SELECT REFENTITYNO, REFTRANSNO, CURRENCY FROM CREDITORHISTORY
								GROUP BY REFENTITYNO, REFTRANSNO, CURRENCY
								) AS TABLE1 
							GROUP BY REFENTITYNO, REFTRANSNO, CURRENCY
							HAVING COUNT(CURRENCY) > 1 
							) 
				THEN null
				ELSE (SUM(C.FOREIGNTRANVALUE)*-1) END AS PAYFOREIGNTRANVALUE,
			SUM(CASE WHEN (C.FORCEDPAYOUT = 1) THEN 0 ELSE C.EXCHVARIANCE END) AS EXCHVARIANCE
			From CREDITORHISTORY C
			GROUP BY C.REFTRANSNO, C.REFENTITYNO) AS CREDITORVALUES
			ON (DEBTORVALUES.REFTRANSNO = CREDITORVALUES.REFTRANSNO
				AND DEBTORVALUES.REFENTITYNO = CREDITORVALUES.REFENTITYNO)
			Left Join CREDITORHISTORY C ON (C.REFENTITYNO = CREDITORVALUES.REFENTITYNO 
							AND C.REFTRANSNO = CREDITORVALUES.REFTRANSNO)

			-- SQA17551 extract debtor name instead of creditor name 
			Left Join DEBTORHISTORY D ON (D.REFENTITYNO = CREDITORVALUES.REFENTITYNO 
							AND D.REFTRANSNO = CREDITORVALUES.REFTRANSNO)
			Left Join NAME SN on (SN.NAMENO = D.ACCTDEBTORNO)'

		Set @sSqlWhere = '
			Where C.TRANSTYPE = 710'
	End

	Set @sSqlWhere = @sSqlWhere + '
			and C.REFENTITYNO = ' + Cast(@nEntityNo as nVarChar(11))

	--Set the additional filter criteria
	--CHAR(39) returns single quote (')

	-- Filter Supplier No
	If (@nSupplierNo is not NULL) AND (@bApplyItemsMode = 1)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and C.ACCTCREDITORNO = ' + Cast(@nSupplierNo as nVarChar(11))
	End
	
	-- SQA12884 Dev
	-- Filter Debtor No
--	If (@nDebtorNo is not NULL) AND (@bApplyItemsMode = 0)
--	Begin
--		Set @sSqlWhere = @sSqlWhere + '
--			and D.ACCTDEBTORNO = ' + Cast(@nDebtorNo as nVarChar(11))
--	End

	-- Filter by Entry No
	If (@nEntryNo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and C.REFTRANSNO = ' + Cast(@nEntryNo as nVarChar(11))
	End

	-- Filter by Entered By staff
	If (@nEnteredBy is not NULL)
	Begin
		Set @sSqlFrom = @sSqlFrom + '
			Left Join TRANSACTIONHEADER T on (T.TRANSNO = C.REFTRANSNO)'
	
		Set @sSqlWhere = @sSqlWhere + '
			and T.EMPLOYEENO = ' + Cast(@nEnteredBy as nVarChar(11))
	End

	-- Filter by Transaction Date range
	If (@dtTransDateFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(nvarchar,C.TRANSDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtTransDateFrom,112) + CHAR(39)
	End

	If (@dtTransDateTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(nvarchar,C.TRANSDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtTransDateTo,112) + CHAR(39)
	End

	Set @sSqlWhere = @sSqlWhere + '
			and C.STATUS IN ('

	-- Filter by Transaction Status
	If (@bDraft = 1)
	Begin
		Set @sSqlWhere = @sSqlWhere + '0'
		If (@bFinalised = 1)
		Begin
			Set @sSqlWhere = @sSqlWhere + ', '
		End
	End

	If (@bFinalised = 1)
	Begin
		Set @sSqlWhere = @sSqlWhere + '1'
	End

	Set @sSqlWhere = @sSqlWhere + ')'

	-- Filter by Post Date range
	If (@dtDatePostedFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(nvarchar,C.POSTDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtDatePostedFrom,112) + CHAR(39)
	End

	If (@dtDatePostedTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(nvarchar,C.POSTDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtDatePostedTo,112) + CHAR(39)
	End

	-- Filter by Local Amount Range
	If (@nLocalValueFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and ABS(C.LOCALVALUE) >= ABS(' + CAST(@nLocalValueFrom as NVARCHAR(20)) + ')'
	End
	
	If (@nLocalValueTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and ABS(C.LOCALVALUE) <= ABS(' + CAST(@nLocalValueTo as NVARCHAR(20)) + ')'
	End

	-- Filter by Foreign Curency range
	If (@sForeignCurrency is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and C.CURRENCY = ' + CHAR(39) + @sForeignCurrency + CHAR(39) 
	End

	If (@nForeignValueFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and ABS(C.FOREIGNTRANVALUE) >= ABS(' + CAST(@nForeignValueFrom as NVARCHAR(20)) + ')'
	End
	
	If (@nForeignValueTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and ABS(C.FOREIGNTRANVALUE) <= ABS(' + CAST(@nForeignValueTo as NVARCHAR(20)) + ')'
	End

	-- Sort order by
	Set @sSqlWhere = @sSqlWhere + '
			ORDER BY C.REFTRANSNO'

End

Set @sSql = @sSql + @sSqlFrom + @sSqlWhere

If @nErrorCode = 0
Begin	

	Exec @nErrorCode = sp_executesql @sSql

End
End
Return @nErrorCode
GO

Grant execute on dbo.ap_ListApplyItems to public
GO
