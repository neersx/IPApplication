-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListTaxProof
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ListTaxProof]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ListTaxProof.'
	Drop procedure [dbo].[ap_ListTaxProof]
End
Print '**** Creating Stored Procedure dbo.ap_ListTaxProof...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ap_ListTaxProof
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbDebug		bit		= 0,
	@ptXMLFilterCriteria	ntext		= null	-- The filtering to be performed on the result set	
)
as
-- PROCEDURE:	ap_ListTaxProof
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions Australia Pty Limited
-- DESCRIPTION:	Tax Proof Listing Report

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	----------------------------------------------- 
-- 17 Nov 2009	CR	SQA18252	1	Procedure created
-- 22 Mar 2010	CR	SQA17685	2	Expanded Filter Criteria to use XML
-- 24 Aug 2010	MF	SQA19001	3	Allow Country to be optionally reported.
-- 10 Nov 2011	CR	SQA20132	4	Fix TRANSACTIONHEADER join.
-- 05 June 2012	CR	SQA20653	5	Change order by to cater for multiple rates
-- 15 Apr 2013	DV	R13270		6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629		7	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

CREATE TABLE #TAXCODES (
		TAXCODE nvarchar(3)	collate database_default NOT NULL )

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sSelect		nvarchar(1000)
declare @sFrom			nvarchar(1000)
declare @sWhere			nvarchar(1000)
declare @sOrderBy		nvarchar(1000)
-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int
Declare	@nPeriodFrom		int
Declare	@nPeriodTo		int
Declare	@dtPostDateFrom		datetime
Declare	@dtPostDateTo		datetime
Declare	@dtTransDateFrom	datetime
Declare	@dtTransDateTo		datetime
Declare	@nEntityNo		int
Declare	@nCreditorNo		int
Declare @sCreditorCountryCode	nvarchar(3)
Declare @sTaxNo			nvarchar(30)
Declare @nLocalTaxFrom		decimal(13,2)
Declare	@nLocalTaxTo		decimal(13,2)
Declare	@bGroupByTaxCategory	bit
Declare	@bGroupByCreditor	bit
Declare @bGroupByNone		bit

-- Initialise variables
Set @nErrorCode = 0

-- Extract the filtering details that are to be applied to the extracted columns as opposed
-- to the filtering that applies to the result set.
If @nErrorCode = 0
Begin

	If PATINDEX ('%<ap_ListTaxProof>%', @ptXMLFilterCriteria)> 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML
			
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria 	
	
		-- Retrieve the filter criteria into corresponding variables
		Set @sSQLString = 	
		"Select	@nEntityNo		= EntityNo,"+CHAR(10)+
		"	@nPeriodFrom		= PeriodFrom,"+CHAR(10)+
		"	@nPeriodTo		= PeriodTo,"+CHAR(10)+
		"	@dtPostDateFrom		= PostDateFrom,"+CHAR(10)+
		"	@dtPostDateTo		= PostDateTo,"+CHAR(10)+
		"	@dtTransDateFrom	= TransDateFrom,"+CHAR(10)+
		"	@dtTransDateTo		= TransDateTo,"+CHAR(10)+
		"	@nCreditorNo		= CreditorNo,"+CHAR(10)+
		"	@sCreditorCountryCode 	= CreditorCountryCode,"+CHAR(10)+
		"	@sTaxNo 		= TaxNo,"+CHAR(10)+
		"	@nLocalTaxFrom 		= LocalTaxFrom,"+CHAR(10)+
		"	@nLocalTaxTo 		= LocalTaxTo,"+CHAR(10)+
		"	@bGroupByTaxCategory 	= GroupByTaxCategory,"+CHAR(10)+
		"	@bGroupByCreditor 	= GroupByCreditor,"+CHAR(10)+
		"	@bGroupByNone 		= GroupByNone"+CHAR(10)+
	
		"from	OPENXML (@idoc, '/ap_ListTaxProof',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	PeriodFrom		int		'PostPeriodFrom/text()',"+CHAR(10)+
		"	PeriodTo		int		'PostPeriodTo/text()',"+CHAR(10)+
		"	PostDateFrom		datetime	'PostDateFrom/text()',"+CHAR(10)+
		"	PostDateTo		datetime	'PostDateTo/text()',"+CHAR(10)+
		"	TransDateFrom		datetime	'TransDateFrom/text()',"+CHAR(10)+
		"	TransDateTo		datetime	'TransDateTo/text()',"+CHAR(10)+
		"	EntityNo		int		'EntityNo/text()',"+CHAR(10)+
		"	CreditorNo		int		'CreditorNo/text()',"+CHAR(10)+
		"	CreditorCountryCode	nvarchar(3)	'CreditorCountryCode/text()',"+CHAR(10)+
		"	TaxNo			nvarchar(30)	'TaxNo/text()',"+CHAR(10)+
		"	LocalTaxFrom		decimal(13,2)	'LocalTaxFrom/text()',"+CHAR(10)+
		"	LocalTaxTo		decimal(13,2)	'LocalTaxTo/text()',"+CHAR(10)+
		"	GroupByTaxCategory	bit		'GroupByTaxCategory/text()',"+CHAR(10)+
		"	GroupByCreditor		bit		'GroupByCreditor/text()',"+CHAR(10)+
		"	GroupByNone		bit		'GroupByNone/text()'"+CHAR(10)+
		"	     )"
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc			int,
					@nPeriodFrom		int			output,
					@nPeriodTo		int			output,
					@dtPostDateFrom		datetime		output,
					@dtPostDateTo		datetime		output,
					@dtTransDateFrom	datetime		output,
					@dtTransDateTo		datetime		output,
					@nEntityNo		int			output,
					@nCreditorNo		int			output,
					@sCreditorCountryCode	nvarchar(3)		output,
					@sTaxNo			nvarchar(30)		output,
					@nLocalTaxFrom		decimal(13,2)		output,
					@nLocalTaxTo		decimal(13,2)		output,
					@bGroupByTaxCategory	bit			output,
					@bGroupByCreditor	bit			output,
					@bGroupByNone		bit			output',
					@idoc			= @idoc,
					@nPeriodFrom		= @nPeriodFrom		output,
					@nPeriodTo		= @nPeriodTo		output,
					@dtPostDateFrom		= @dtPostDateFrom	output,
					@dtPostDateTo		= @dtPostDateTo		output,
					@dtTransDateFrom	= @dtTransDateFrom	output,
					@dtTransDateTo		= @dtTransDateTo	output,
					@nEntityNo		= @nEntityNo		output,
					@nCreditorNo		= @nCreditorNo		output,
					@sCreditorCountryCode	= @sCreditorCountryCode	output,
					@sTaxNo			= @sTaxNo		output,
					@nLocalTaxFrom		= @nLocalTaxFrom	output,
					@nLocalTaxTo		= @nLocalTaxTo		output,
					@bGroupByTaxCategory	= @bGroupByTaxCategory	output,
					@bGroupByCreditor	= @bGroupByCreditor	output,
					@bGroupByNone		= @bGroupByNone		output
	End

	If @pbDebug = 1
	Begin
		PRINT '-- ** Extract filter criteria **'
		PRINT ''
		PRINT @sSQLString
		SELECT @nPeriodFrom		AS PeriodFrom,
			@nPeriodTo		AS PeriodTo,
			@dtPostDateFrom		AS PostDateFrom,
			@dtPostDateTo		AS PostDateTo,
			@dtTransDateFrom	AS TransDateFrom,
			@dtTransDateTo		AS TransDateTo,
			@nEntityNo		AS EntityNo,
			@nCreditorNo		AS CreditorNo,
			@sCreditorCountryCode	AS CreditorCountryCode,
			@sTaxNo			AS TaxNo,
			@nLocalTaxFrom		AS LocalTaxFrom,
			@nLocalTaxTo		AS LocalTaxTo,
			@bGroupByTaxCategory	AS GroupByTaxCategory,
			@bGroupByCreditor	AS GroupByCreditor,
			@bGroupByNone		AS GroupByNone
	End	
End


If @nErrorCode = 0
Begin
	If PATINDEX ('%<TaxCode>%', @ptXMLFilterCriteria)> 0
	Begin
		Set @sSQLString = "Insert into #TAXCODES(TAXCODE)
		Select  TaxCode   
		from	OPENXML(@idoc, '//ap_ListTaxProof/TaxCategories/TaxCode', 2)
			WITH (TaxCode		nvarchar(3)	'./text()')"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc	int',
					@idoc	= @idoc

		If @pbDebug = 1
		Begin
			PRINT '-- ** Create TaxCode Temp Table **'
			PRINT 'CREATE TABLE #TAXCODES (
			TAXCODE nvarchar(3)	collate database_default NOT NULL )'
			PRINT ''
			PRINT '-- Populate temp table '
			PRINT @sSQLString
			print ''
			PRINT '-- Selected tax codes **'
			SELECT * FROM #TAXCODES
		End
	End
End


Exec sp_xml_removedocument @idoc


If @nErrorCode = 0
Begin
	Set @sSQLString = "
	SELECT convert( nvarchar(254), E.NAME+ CASE WHEN E.FIRSTNAME IS NOT NULL THEN ', ' END +E.FIRSTNAME+SPACE(1)+ CASE WHEN E.NAMECODE IS NOT NULL THEN '{' END +E.NAMECODE+ CASE WHEN E.NAMECODE IS NOT NULL THEN '}' END ) AS ENTITYNAME, 
	E.NAMENO AS ENTITYNAMENO, E.NAMECODE AS ENTITYNAMECODE, 
	convert( nvarchar(254), C.NAME+ CASE WHEN C.FIRSTNAME IS NOT NULL THEN ', ' END +C.FIRSTNAME+SPACE(1)+ CASE WHEN C.NAMECODE IS NOT NULL THEN '{' END +C.NAMECODE+ CASE WHEN C.NAMECODE IS NOT NULL THEN '}' END ) AS CREDITORNAME, 
	C.NAMENO AS CREDITORNAMENO, C.NAMECODE AS CREDITORNAMECODE, A.COUNTRYCODE AS CREDITORCOUNTRY, C.TAXNO AS CREDITORTAXNO, "
	
	Set @sFrom = "FROM TAXPAIDHISTORY TPH
	JOIN NAME C			ON (C.NAMENO = TPH.ACCTCREDITORNO)
	LEFT JOIN ADDRESS A		on (A.ADDRESSCODE=C.POSTALADDRESS)
	JOIN NAME E			ON (E.NAMENO = TPH.ACCTENTITYNO)
	JOIN TAXRATES TR		ON (TPH.TAXCODE = TR.TAXCODE)
	JOIN TRANSACTIONHEADER TH	ON (TH.ENTITYNO = TPH.REFENTITYNO
					and TH.TRANSNO = TPH.REFTRANSNO)
	JOIN ACCT_TRANS_TYPE ATT	ON (TH.TRANSTYPE = ATT.TRANS_TYPE_ID)
	LEFT JOIN CREDITORHISTORY CH	ON (CH.ITEMENTITYNO = TPH.ITEMENTITYNO
					and CH.ITEMTRANSNO = TPH.ITEMTRANSNO
					and CH.ACCTENTITYNO = TPH.ACCTENTITYNO
					and CH. ACCTCREDITORNO = TPH.ACCTCREDITORNO
					and CH.HISTORYLINENO = TPH.HISTORYLINENO)
	LEFT JOIN CASHITEM CI		ON (CI.TRANSENTITYNO = TPH.ITEMENTITYNO
					and CI.TRANSNO = TPH.ITEMTRANSNO)"
	
	Set @sWhere = "WHERE TH.TRANSTATUS <> 0"
	
	If (@nPeriodFrom IS NOT NULL) AND 
	   (@nPeriodTo is NOT NULL) AND 
	   (@nPeriodFrom = @nPeriodTo)
	begin
		Set @sWhere = @sWhere + " AND 
		TH.TRANPOSTPERIOD = " + CAST(@nPeriodFrom as NVARCHAR(10))
	End
	Else
	Begin
		If @nPeriodFrom IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			TH.TRANPOSTPERIOD >= " + CAST(@nPeriodFrom as NVARCHAR(10))
		End
		If @nPeriodTo IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			TH.TRANPOSTPERIOD <= " + CAST(@nPeriodTo as NVARCHAR(10))	
		End
	End
	
	If (@dtPostDateFrom IS NOT NULL) AND 
	   (@dtPostDateTo is NOT NULL) AND 
	   (@dtPostDateFrom = @dtPostDateTo)
	begin
		Set @sWhere = @sWhere + " AND
		CAST(CONVERT(NVARCHAR,TH.TRANPOSTDATE,112) as DATETIME)
			 = " + CHAR(39) + convert(nvarchar,@dtPostDateFrom,112)+ CHAR(39) 
	End
	Else
	Begin
		If @dtPostDateFrom IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			CAST(CONVERT(NVARCHAR,TH.TRANPOSTDATE,112) as DATETIME)
			 >= " + CHAR(39) + convert(nvarchar,@dtPostDateFrom,112)+ CHAR(39) 
		End
		If @dtPostDateTo IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			CAST(CONVERT(NVARCHAR,TH.TRANPOSTDATE,112) as DATETIME)
			 <= " + CHAR(39) + convert(nvarchar,@dtPostDateTo,112)+ CHAR(39) 
		End
	End

	If (@dtTransDateFrom IS NOT NULL) AND 
	   (@dtTransDateTo is NOT NULL) AND 
	   (@dtTransDateFrom = @dtTransDateTo)
	begin
		Set @sWhere = @sWhere + " AND
		CAST(CONVERT(NVARCHAR,TH.TRANSDATE,112) as DATETIME)
			 = " + CHAR(39) + convert(nvarchar,@dtTransDateFrom,112)+ CHAR(39) 
	End
	Else
	Begin
		If @dtTransDateFrom IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			CAST(CONVERT(NVARCHAR,TH.TRANSDATE,112) as DATETIME)
			 >= " + CHAR(39) + convert(nvarchar,@dtTransDateFrom,112)+ CHAR(39) 
		End
		If @dtTransDateTo IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			CAST(CONVERT(NVARCHAR,TH.TRANSDATE,112) as DATETIME)
			 <= " + CHAR(39) + convert(nvarchar,@dtTransDateTo,112)+ CHAR(39) 
		End
	End
	
	If @nEntityNo IS NOT NULL
	Begin
		Set @sWhere = @sWhere + " AND 
		TPH.ITEMENTITYNO = " + CAST(@nEntityNo as NVARCHAR(11))
	End

	If @nCreditorNo is NOT NULL
	Begin
		Set @sWhere = @sWhere + " AND 
		TPH.ACCTCREDITORNO = " + CAST(@nCreditorNo as NVARCHAR(11))
	End

	If @sCreditorCountryCode is NOT NULL
	Begin
		Set @sWhere = @sWhere + " AND 
		A.COUNTRYCODE = " + CHAR(39) + @sCreditorCountryCode + CHAR(39) 
	End

	If @sTaxNo is NOT NULL
	Begin
		Set @sWhere = @sWhere + " AND 
		C.TAXNO = " + CHAR(39) + @sTaxNo + CHAR(39) 
	End

	If (@nLocalTaxFrom IS NOT NULL) AND 
	   (@nLocalTaxTo is NOT NULL) AND 
	   (@nLocalTaxFrom = @nLocalTaxTo)
	begin
		Set @sWhere = @sWhere + " AND
		isnull(TPH.TAXAMOUNT, 0) = " + CAST(@nLocalTaxFrom as NVARCHAR(10))
	End
	Else
	Begin
		If @nLocalTaxFrom IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			isnull(TPH.TAXAMOUNT, 0) >= " + CAST(@nLocalTaxFrom as NVARCHAR(10))
		End
		If @nLocalTaxTo IS NOT NULL
		Begin
			Set @sWhere = @sWhere + " AND 
			isnull(TPH.TAXAMOUNT, 0) <= " + CAST(@nLocalTaxTo as NVARCHAR(10))
		End
	End

	-- restrict to Tax Categories specified
	If exists (Select * from #TAXCODES)
	Begin
		Set @sWhere = @sWhere + "
			and TPH.TAXCODE IN (Select TAXCODE from #TAXCODES)"
	End

	If @bGroupByNone = 1
	Begin
		Set @sSQLString = @sSQLString + "TPH.TAXABLEAMOUNT, TPH.TAXAMOUNT, TR.TAXCODE, TR.DESCRIPTION AS TAXDESCRIPTION, TPH.TAXRATE, TH.TRANSDATE, TH.TRANSNO, ATT.DESCRIPTION AS TRANSACTIONTYPE, ISNULL(CH.DOCUMENTREF, CI.ITEMREFNO) AS REFERENCE "

		Set @sOrderBy = "ORDER BY convert( nvarchar(254), E.NAME+ CASE WHEN E.FIRSTNAME IS NOT NULL THEN ', ' END +E.FIRSTNAME+SPACE(1)+ CASE WHEN E.NAMECODE IS NOT NULL THEN '{' END +E.NAMECODE+ CASE WHEN E.NAMECODE IS NOT NULL THEN '}' END ), 
		E.NAMENO, TR.TAXCODE, TR.DESCRIPTION, TPH.TAXRATE, TH.TRANSDATE, TH.TRANSNO, convert( nvarchar(254), C.NAME+ CASE WHEN C.FIRSTNAME IS NOT NULL THEN ', ' END +C.FIRSTNAME+SPACE(1)+ CASE WHEN C.NAMECODE IS NOT NULL THEN '{' END +C.NAMECODE+ CASE WHEN C.NAMECODE IS NOT NULL THEN '}' END ), C.NAMENO"
	End
	Else If @bGroupByCreditor = 1
	Begin
		Set @sSQLString = @sSQLString + "SUM(isnull(TPH.TAXABLEAMOUNT, 0)) AS TAXABLEAMOUNT, SUM(isnull(TPH.TAXAMOUNT, 0)) AS TAXAMOUNT"

		Set @sOrderBy = "GROUP BY convert( nvarchar(254), E.NAME+ CASE WHEN E.FIRSTNAME IS NOT NULL THEN ', ' END +E.FIRSTNAME+SPACE(1)+ CASE WHEN E.NAMECODE IS NOT NULL THEN '{' END +E.NAMECODE+ CASE WHEN E.NAMECODE IS NOT NULL THEN '}' END ), 
		E.NAMENO, E.NAMECODE, 
		convert( nvarchar(254), C.NAME+ CASE WHEN C.FIRSTNAME IS NOT NULL THEN ', ' END +C.FIRSTNAME+SPACE(1)+ CASE WHEN C.NAMECODE IS NOT NULL THEN '{' END +C.NAMECODE+ CASE WHEN C.NAMECODE IS NOT NULL THEN '}' END ), 
		C.NAMENO, C.NAMECODE, A.COUNTRYCODE, C.TAXNO"		
	End
	Else If @bGroupByTaxCategory = 1
	Begin
		Set @sSQLString = @sSQLString + "SUM(isnull(TPH.TAXABLEAMOUNT, 0)) AS TAXABLEAMOUNT, SUM(isnull(TPH.TAXAMOUNT, 0)) AS TAXAMOUNT, TR.TAXCODE, TR.DESCRIPTION AS TAXDESCRIPTION, TPH.TAXRATE"

		Set @sOrderBy = "GROUP BY convert( nvarchar(254), E.NAME+ CASE WHEN E.FIRSTNAME IS NOT NULL THEN ', ' END +E.FIRSTNAME+SPACE(1)+ CASE WHEN E.NAMECODE IS NOT NULL THEN '{' END +E.NAMECODE+ CASE WHEN E.NAMECODE IS NOT NULL THEN '}' END ), 
		E.NAMENO, E.NAMECODE,TR.TAXCODE, TR.DESCRIPTION, TPH.TAXRATE,
		convert( nvarchar(254), C.NAME+ CASE WHEN C.FIRSTNAME IS NOT NULL THEN ', ' END +C.FIRSTNAME+SPACE(1)+ CASE WHEN C.NAMECODE IS NOT NULL THEN '{' END +C.NAMECODE+ CASE WHEN C.NAMECODE IS NOT NULL THEN '}' END ), 
		C.NAMENO, C.NAMECODE, A.COUNTRYCODE, C.TAXNO"	
	End
	Set @sSQLString = @sSQLString +char(10)+ @sFrom +char(10)+ @sWhere +char(10)+ @sOrderBy

	If @pbDebug = 1
	Begin
		PRINT '--** STATEMENT USED TO RETURN THE RESULTS **'
		PRINT @sSQLString
	End

	Exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount

End

Return @nErrorCode
GO

Grant execute on dbo.ap_ListTaxProof to public
GO
