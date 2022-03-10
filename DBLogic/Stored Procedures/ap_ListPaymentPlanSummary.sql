-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListPaymentPlanSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_ListPaymentPlanSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_ListPaymentPlanSummary.'
	Drop procedure [dbo].[ap_ListPaymentPlanSummary]
End
Print '**** Creating Stored Procedure dbo.ap_ListPaymentPlanSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_ListPaymentPlanSummary
(
	@pnRowCount			int 		output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pbDebugFlag			bit		= 0,	-- Indicates that debugging information should be used
	@ptXMLFilterCriteria		ntext		= null	-- The filtering to be performed on the result set	
)
as
-- PROCEDURE:	ap_ListPaymentPlanSummary
-- VERSION:	9
-- COPYRIGHT: 	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro
-- DESCRIPTION:	Called from Centura or the ProcessPaymentPlan stored procedure 
--		to produce payments required to process a payment plan in Accounts Payable

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Mar 2005 CR	10146	1	Procedure created
-- 01 Jun 2005 CR	10146	2	Bug Fixes to do with totals
-- 12 Oct 2006 CR	11936	3	Extended to include Payment Date
-- 10 Sep 2009	CR	SQA8819	4	Updated joins to CREDITORITEM and CREDITORHISTORY to cater for
--								Unallocated Payments recorded using the Credit Card method 
--								(i.e. two Creditor Items created with the same TransId)
-- 16 May 2012	CR	16196	5	Consolidate System Defined Payment Methods - update references.	
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	7	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 18 Sep 2014	vql	R13629	8	Return cheque number for payments by cheque
-- 14 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF



declare @sSQLString		nvarchar(4000),
 	@sSqlFrom 		nvarchar(1000),
	@sSqlWhere		nvarchar(2000)

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

Declare 
	@nErrorCode 		int,
--	@sBankCurrency		nvarchar(3),
	@sLocalCurrency		nvarchar(3),
	@nExchRateType		tinyint,
	@nPeriod		int,
	@sPeriodType		nvarchar(1),
	@dtItemDueDate		datetime,
	@nPlanId		int,
	@nTotalLocal		decimal(13,2),
	@sStatusInc		nvarchar(254),
-- Filter criteria
	@nEntityNo		int,
	@sBankAcctId		nvarchar(35),
	@sPlanName		nvarchar(50),
	@dtPaymentDateFrom	datetime,
	@dtPaymentDateTo	datetime,
	@nPaymentTerm		int,
	@nSupplierType		int,
	@dtItemDateFrom		datetime,
	@dtItemDateTo		datetime,
	@dtDueDateFrom		datetime,
	@dtDueDateTo		datetime,
	@nSupplier		int,
	@sDocumentNo		nvarchar(20),
	@nPaymentMethod		int,
	@sItemCurrency		nvarchar(3),
	@nTotalLocalBalFrom	decimal(13,2),
	@nTotalLocalBalTo	decimal(13,2),
	@nItemBalFrom		decimal(13,2),
	@nItemBalTo		decimal(13,2),
	@bIncludeActive		bit,
	@bIncludeDraft		bit,
	@bIncludeFinalised	bit,
	@nStatus		tinyint

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sLocalCurrency = SI.COLCHARACTER
	from SITECONTROL SI	
	where SI.CONTROLID = 'CURRENCY'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sLocalCurrency		nvarchar(3)	OUTPUT',
				@sLocalCurrency=@sLocalCurrency			OUTPUT
End

-- For Debugging
If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
Begin
	PRINT '*** Retrieve the Local Currency ***'
	Select @sLocalCurrency
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nExchRateType = SI.COLBOOLEAN
	from SITECONTROL SI
	where SI.CONTROLID = 'Bank Rate In Use'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nExchRateType	tinyint	OUTPUT',
				@nExchRateType=@nExchRateType	OUTPUT

	If @nExchRateType <> 1
	Begin
		-- Bank Rate is not in use so use Buy Rate
		Set @nExchRateType = 2
	End
End

--For Debugging
If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
Begin
	PRINT '*** Determine if the Bank Rate should be used ***'
	Select @nExchRateType
End

If @nErrorCode = 0
Begin
--	Set @sSQLString = "
		CREATE TABLE #PAYMENTPLANSUMMARY (
		PLANID			int		NOT NULL,
		ENTITYNO 		int 		NOT NULL,
		BANKNAMENO 		int 		NOT NULL,
		BANKSEQUENCENO 		int 		NOT NULL,
		PAYMENTMETHOD		INT		NULL,		
		STATUS			INT		NULL,	
		PLANNAME		nvarchar(50)	collate database_default NULL,
		PAYMENTDATE		datetime	NULL,
		ENTITYNAME		nvarchar(254)	collate database_default NULL,
		BANKACCOUNT		nvarchar(80)	collate database_default NULL,
		PAYMENTMETHODDESC	nvarchar(30)	collate database_default NULL,
		TOTALLOCAL		decimal(11,2)	NULL, 
		STATUSDESC		nvarchar(10)	collate database_default NULL, 
		DATECREATED		datetime	NULL,
		CREATEDBY		nvarchar(30)	collate database_default NULL, 
		DATEPROCESSED		datetime	NULL,
		EFTFILEFORMAT		int		NULL,
		EFTPAYMENTFILE		nvarchar(254)	collate database_default NULL,
		CHEQUENO		nvarchar(30)	collate database_default NULL)
--"

--	exec @nErrorCode=sp_executesql @sSQLString

end


-- For Debugging
If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
Begin
	PRINT '*** Temporary Table Created ***'
	select * from #PAYMENTPLANSUMMARY
End



-- Extract the filtering details that are to be applied to the extracted columns as opposed
-- to the filtering that applies to the result set.
If @nErrorCode = 0
Begin

	If PATINDEX ('%<Filter>%', @ptXMLFilterCriteria)> 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML
			
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	

		-- Retrieve the filter criteria into corresponding variables
		Set @sSQLString = 	
		"Select	@nEntityNo		= EntityNo,"+CHAR(10)+
		"	@sBankAcctId 		= BankAcctId,"+CHAR(10)+
		"	@nPaymentMethod		= PaymentMethod,"+CHAR(10)+
		"	@sPlanName		= PlanName,"+CHAR(10)+
		"	@dtPaymentDateFrom	= PaymentDateFrom,"+CHAR(10)+
		"	@dtPaymentDateTo	= PaymentDateTo,"+CHAR(10)+
		"	@nTotalLocalBalFrom	= TotalLocalBalFrom,"+CHAR(10)+
		"	@nTotalLocalBalTo 	= TotalLocalBalTo,"+CHAR(10)+
		"	@nSupplier		= Supplier,"+CHAR(10)+
		"	@sDocumentNo		= DocumentNo,"+CHAR(10)+
		"	@nPaymentTerm		= PaymentTerm,"+CHAR(10)+
		"	@nSupplierType		= SupplierType,"+CHAR(10)+
		"	@dtItemDateFrom		= ItemDateFrom,"+CHAR(10)+
		"	@dtItemDateTo		= ItemDateTo,"+CHAR(10)+
		"	@dtDueDateFrom		= DueDateFrom,"+CHAR(10)+
		"	@dtDueDateTo		= DueDateTo,"+CHAR(10)+
		"	@sItemCurrency		= ItemCurrency, "+CHAR(10)+
		"	@nItemBalFrom 		= ItemBalFrom,"+CHAR(10)+
		"	@nItemBalTo 		= ItemBalTo,"+CHAR(10)+
		"	@bIncludeActive 	= IncludeActive,"+CHAR(10)+
		"	@bIncludeDraft 		= IncludeDraft,"+CHAR(10)+
		"	@bIncludeFinalised 	= IncludeFinalised"+CHAR(10)+
	
		"from	OPENXML (@idoc, '/Filter',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	EntityNo		int		'cmbEntity/text()',"+CHAR(10)+
		"	BankAcctId		nvarchar(35)	'cmbBankAccount/text()',"+CHAR(10)+
		"	PaymentMethod		int		'cmbPaymentMethod/text()',"+CHAR(10)+
		"	PlanName		nvarchar(50)	'dfsPlanName/text()',"+CHAR(10)+
		"	PaymentDateFrom		datetime	'dfPaymentDateFrom/text()',"+CHAR(10)+
		"	PaymentDateTo		datetime	'dfPaymentDateTo/text()',"+CHAR(10)+
		"	TotalLocalBalFrom	decimal(13,2)	'dfTotalLocalBalFrom/text()',"+CHAR(10)+
		"	TotalLocalBalTo		decimal(13,2)	'dfTotalLocalBalTo/text()',"+CHAR(10)+
		"	Supplier		int		'dfSupplier/text()',"+CHAR(10)+
		"	DocumentNo		nvarchar(20)	'dfsDocumentNo/text()',"+CHAR(10)+
		"	PaymentTerm		int		'cmbPaymentTerm/text()',"+CHAR(10)+
		"	SupplierType		int		'cmbSupplierType/text()',"+CHAR(10)+
		"	ItemDateFrom		datetime	'dfItemDateFrom/text()',"+CHAR(10)+
		"	ItemDateTo		datetime	'dfItemDateTo/text()',"+CHAR(10)+
		"	DueDateFrom		datetime	'dfDueDateFrom/text()',"+CHAR(10)+
		"	DueDateTo		datetime	'dfDueDateTo/text()',"+CHAR(10)+
		"	ItemCurrency		nvarchar(3)	'cmbItemCurrency/text()', "+CHAR(10)+
		"	ItemBalFrom		decimal(13,2)	'dfItemBalFrom/text()',"+CHAR(10)+
		"	ItemBalTo		decimal(13,2)	'dfItemBalTo/text()',"+CHAR(10)+
		"	IncludeActive		bit		'cbActive/text()',"+CHAR(10)+
		"	IncludeDraft		bit		'cbDraft/text()',"+CHAR(10)+
		"	IncludeFinalised	bit		'cbFinalised/text()'"+CHAR(10)+
		"	     )"


		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc			int,
					@nEntityNo		int			output,
					@sBankAcctId		nvarchar(35)		output,
					@nPaymentMethod		int			output,
					@sPlanName		nvarchar(50)		output,
					@dtPaymentDateFrom	datetime		output,
					@dtPaymentDateTo	datetime		output,
					@nTotalLocalBalFrom	decimal(13,2)		output,
					@nTotalLocalBalTo	decimal(13,2)		output,
					@nSupplier		int			output,
					@sDocumentNo		nvarchar(20)		output,
					@nPaymentTerm		int			output,
					@nSupplierType		int			output,
					@dtItemDateFrom		datetime		output,
					@dtItemDateTo		datetime		output,
					@dtDueDateFrom		datetime		output,
					@dtDueDateTo		datetime		output,
					@sItemCurrency		nvarchar(3)		output,
					@nItemBalFrom		decimal(13,2)		output,
					@nItemBalTo		decimal(13,2)		output,
					@bIncludeActive		bit			output,
					@bIncludeDraft		bit			output,
					@bIncludeFinalised	bit			output',
					@idoc			= @idoc,
					@nEntityNo		= @nEntityNo		output,
					@sBankAcctId		= @sBankAcctId		output,
					@nPaymentMethod		= @nPaymentMethod	output,
					@sPlanName		= @sPlanName		output,
					@dtPaymentDateFrom	= @dtPaymentDateFrom	output,
					@dtPaymentDateTo	= @dtPaymentDateTo	output,
					@nTotalLocalBalFrom	= @nTotalLocalBalFrom	output,
					@nTotalLocalBalTo	= @nTotalLocalBalTo	output,
					@nSupplier		= @nSupplier		output,
					@sDocumentNo		= @sDocumentNo		output,
					@nPaymentTerm		= @nPaymentTerm		output,
					@nSupplierType		= @nSupplierType	output,
					@dtItemDateFrom		= @dtItemDateFrom	output,
					@dtItemDateTo		= @dtItemDateTo		output,
					@dtDueDateFrom		= @dtDueDateFrom	output,
					@dtDueDateTo		= @dtDueDateTo		output,
					@sItemCurrency		= @sItemCurrency	output,
					@nItemBalFrom		= @nItemBalFrom		output,
					@nItemBalTo		= @nItemBalTo		output,
					@bIncludeActive		= @bIncludeActive	output,
					@bIncludeDraft		= @bIncludeDraft	output,
					@bIncludeFinalised	= @bIncludeFinalised	output

		Exec sp_xml_removedocument @idoc

	End
	
	If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
	Begin
		Print '*** Filter Criteria ***'
		Select @idoc AS XMLDoc,
			@nEntityNo AS ENTITYNO,
			@sBankAcctId AS BANKACCTID,
			@nPaymentMethod AS PAYMENTMETHOD,
			@sPlanName AS PLANNAME,
			@dtPaymentDateFrom AS PAYMENTDATEFROM,
			@dtPaymentDateTo AS PAYMENTDATETO,
			@nTotalLocalBalFrom AS TOTALLOCALBALFROM,
			@nTotalLocalBalTo AS TOTLOCALBALTO,
			@nSupplier AS SUPPLIERNO,
			@sDocumentNo AS DOCUMENTNO,
			@nPaymentTerm AS PAYMENTTERM,
			@nSupplierType AS SUPPLIERTYPE,
			@dtItemDateFrom AS ITEMDATEFROM,
			@dtItemDateTo AS ITEMDATETO,
			@dtDueDateFrom AS ITEMDUEDATEFROM,
			@dtDueDateTo AS ITEMDUEDATETO,
			@sItemCurrency AS ITEMCURRENCY,
			@nItemBalFrom AS ITEMBALFROM,
			@nItemBalTo AS ITEMBALTO,
			@bIncludeActive AS INCACTIVE,
			@bIncludeDraft AS INCDRAFT,
			@bIncludeFinalised AS INCFINALISE
	End
End



-- If payment term specified determine due date.
If @nErrorCode = 0 and (@nPaymentTerm IS NOT NULL)
Begin
	Set @sSQLString = "Select @nPeriod = FREQUENCY, @sPeriodType = PERIODTYPE
	from FREQUENCY	
	where FREQUENCYTYPE = 1 
	and FREQUENCYNO = @nPaymentTerm"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nPeriod	int		OUTPUT,
				@sPeriodType	nvarchar(1)	OUTPUT,
				@nPaymentTerm	int',
				@nPeriod 	= @nPeriod	OUTPUT,
				@sPeriodType 	= @sPeriodType	OUTPUT,
				@nPaymentTerm	= @nPaymentTerm


	-- determine what the ItemDueDate should be based on the Payment Term specified
	If @nErrorCode = 0
	Begin
		If @sPeriodType = 'D'
		Begin
			Set @dtItemDueDate = DATEADD(day, @nPeriod, GETDATE())
		End
		If @sPeriodType = 'W'
		Begin
			Set @dtItemDueDate = DATEADD(Week, @nPeriod, GETDATE())
		End
		Else If @sPeriodType = 'M'
		Begin
			Set @dtItemDueDate = DATEADD(Month, @nPeriod, GETDATE())
		End
		Else If @sPeriodType = 'Y'
		Begin
			Set @dtItemDueDate = DATEADD(Year, @nPeriod, GETDATE())
		End
	End

	-- For Debugging
	If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
	Begin
		PRINT '*** Details of Payment Term Specified ***'
		select @nPeriod AS FREQUENCY, @sPeriodType AS PERIODTYPE, @dtItemDueDate AS ITEMDUEDATE
	End

End

-- populate table with main information
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		INSERT INTO #PAYMENTPLANSUMMARY
		(PLANID, ENTITYNO, BANKNAMENO, BANKSEQUENCENO, PLANNAME, PAYMENTDATE, ENTITYNAME, BANKACCOUNT, 
		DATECREATED, CREATEDBY, DATEPROCESSED, PAYMENTMETHODDESC, PAYMENTMETHOD, STATUS, STATUSDESC)
		SELECT DISTINCT PP.PLANID, PP.ENTITYNO, PP.BANKNAMENO, PP.BANKSEQUENCENO, PP.PLANNAME, PP.PAYMENTDATE, N.NAME, 
		BA.DESCRIPTION, PP.DATECREATED, PP.CREATEDBY, PP.DATEPROCESSED, PM.PAYMENTDESCRIPTION, 
		PP.PAYMENTMETHOD, 
		CASE WHEN (PP.DATEPROCESSED IS NOT NULL) THEN 2 
		ELSE 
			CASE WHEN (select top 1 (PPD2.REFTRANSNO)
				from PAYMENTPLANDETAIL PPD2
				WHERE PPD2.PLANID = PP.PLANID 
				AND PPD2.REFTRANSNO IS NOT NULL) IS NOT NULL THEN 0
			ELSE 1 
			END 
		END AS STATUS,
		CASE WHEN (PP.DATEPROCESSED IS NOT NULL) THEN 'Finalised' 
		ELSE 
			CASE WHEN (PP.DATEPROCESSED IS NULL)AND (select top 1 (PPD2.REFTRANSNO)
				from PAYMENTPLANDETAIL PPD2
				WHERE PPD2.PLANID = PP.PLANID AND PPD2.REFTRANSNO IS NOT NULL) IS NOT NULL THEN 'Draft' 
				ELSE 'Active' 
			END 		
		END AS STATUSDESC"


	Set @sSqlFrom = "
		FROM PAYMENTPLAN PP
		LEFT JOIN NAME N 		ON (N.NAMENO = PP.ENTITYNO)
		LEFT JOIN BANKACCOUNT BA 	ON (BA.ACCOUNTOWNER = PP.ENTITYNO 
						AND BA.BANKNAMENO = PP.BANKNAMENO 
						AND BA.SEQUENCENO = PP.BANKSEQUENCENO)
		LEFT JOIN PAYMENTMETHODS PM 	ON (PM.PAYMENTMETHOD = PP.PAYMENTMETHOD)
		LEFT JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
		LEFT JOIN CREDITORITEM CI 	ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO 
						AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO
						AND CI.ACCTENTITYNO = PPD.ACCTENTITYNO 
						AND	CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
		LEFT JOIN CREDITOR S		ON (S.NAMENO = CI.ACCTCREDITORNO)"
			

	-- Set the additional filter criteria
	-- CHAR(39) returns single quote (')
	-- Entity 
	If (@nEntityNo is not NULL)
	Begin 
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '
		Set @sSqlWhere = @sSqlWhere + 
			'PP.ENTITYNO = ' + CAST(@nEntityNo as NVARCHAR(11))
	End
	
	-- Bank Account
	If (@sBankAcctId is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CAST(BA.ACCOUNTOWNER as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) +
			' + CAST(BA.BANKNAMENO as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) + 
			' + CAST(BA.SEQUENCENO as NVARCHAR(11)) = ' + CHAR(39) + @sBankAcctId + CHAR(39)
	End
	
	-- Payment Date Range
	If (@dtPaymentDateFrom is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CAST(CONVERT(NVARCHAR,PP.PAYMENTDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtPaymentDateFrom,112) + CHAR(39)
		
	End
	
	If (@dtPaymentDateTo is not NULL)
	Begin 
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere +
			'CAST(CONVERT(NVARCHAR,PP.PAYMENTDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtPaymentDateTo,112) + CHAR(39)
	End
	
	-- PaymentMethod
	If (@nPaymentMethod is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'PP.PAYMENTMETHOD = ' + CAST(@nPaymentMethod as NVARCHAR(11))
	End

	If (@sPlanName is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'PP.PLANNAME '+dbo.fn_ConstructOperator(4,'S',@sPlanName, null,0)
	End

	-- SupplierName
	If (@nSupplier is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CI.ACCTCREDITORNO = ' + CAST(@nSupplier as NVARCHAR(11))
	End

	-- DocumentNo
	If (@sDocumentNo is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CI.DOCUMENTREF = ' + CHAR(39) + @sDocumentNo + CHAR(39)
	End

	-- PaymentTerm
	If (@nPaymentTerm is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CAST(CONVERT(NVARCHAR,CI.ITEMDUEDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtItemDueDate,112)+ CHAR(39)
	End


	-- SupplierType
	If (@nSupplierType is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'S.SUPPLIERTYPE = ' + CAST(@nSupplierType as NVARCHAR(11))
	End


	-- Item Date Range
	If (@dtItemDateFrom is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CAST(CONVERT(NVARCHAR,CI.ITEMDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtItemDateFrom,112) + CHAR(39)
		
	End
	
	If (@dtItemDateTo is not NULL)
	Begin 
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere +
			'CAST(CONVERT(NVARCHAR,CI.ITEMDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtItemDateTo,112) + CHAR(39)
	End

	-- Due Date Range
	If (@dtDueDateFrom is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere + 
			'CAST(CONVERT(NVARCHAR,CI.ITEMDUEDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtDueDateFrom,112) + CHAR(39)
		
	End
	
	If (@dtDueDateTo is not NULL)
	Begin 
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		Set @sSqlWhere = @sSqlWhere +
			'CAST(CONVERT(NVARCHAR,CI.ITEMDUEDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtDueDateTo,112) + CHAR(39)
	End

	If (@sItemCurrency is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		if (@sItemCurrency = @sLocalCurrency)
		begin
			Set @sSqlWhere = @sSqlWhere + 
				'CI.CURRENCY is NULL '
		End
		Else
		Begin
			Set @sSqlWhere = @sSqlWhere + 
				'CI.CURRENCY = ' + CHAR(39) + @sItemCurrency + CHAR(39)
		End
	End


	-- Item Balance range
	If (@nItemBalFrom is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		if (@sItemCurrency = @sLocalCurrency) OR (@sItemCurrency is NULL)
		Begin
			Set @sSqlWhere = @sSqlWhere + 
			'(CI.LOCALBALANCE >= ' + CAST(@nItemBalFrom as NVARCHAR(20)) + ')'
		End
		Else
		Begin
			Set @sSqlWhere = @sSqlWhere + 
			'(CI.FOREIGNBALANCE >= ' + CAST(@nItemBalFrom as NVARCHAR(20)) + ')'
		End

	End
	
	If (@nItemBalTo is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			and '

		if (@sItemCurrency = @sLocalCurrency) OR (@sItemCurrency is NULL)
		Begin
			Set @sSqlWhere = @sSqlWhere + 
			'(CI.LOCALBALANCE <= ' + CAST(@nItemBalTo as NVARCHAR(20)) + ')'
		End
		Else
		Begin
			Set @sSqlWhere = @sSqlWhere + 
			'(CI.FOREIGNBALANCE <= ' + CAST(@nItemBalTo as NVARCHAR(20)) + ')'
		End
	End



	If (@sSqlWhere is not NULL)
	Begin
		Set @sSqlWhere = '
		Where ' + @sSqlWhere
	End


	Set @sSQLString = @sSQLString + @sSqlFrom + @sSqlWhere

	If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
	Begin
		print '*** SQL for Main Select ***'
		Select @sSQLString
	End


	Exec @nErrorCode=sp_executesql @sSQLString, 
			N'@nEntityNo		int,
			@sBankAcctId		nvarchar(35),
			@dtPaymentDateFrom	datetime,
			@dtPaymentDateTo	datetime,
			@nPaymentMethod		int,
			@sPlanName		nvarchar(50),
			@nSupplier		int,
			@sDocumentNo		nvarchar(20),
			@dtItemDueDate		datetime,
			@nSupplierType		int,
			@dtItemDateFrom		datetime,
			@dtItemDateTo		datetime,
			@dtDueDateFrom		datetime,
			@dtDueDateTo		datetime,
			@sItemCurrency		nvarchar(3),
			@nItemBalFrom		decimal(13,2),
			@nItemBalTo		decimal(13,2)',
			@nEntityNo		= @nEntityNo,
			@sBankAcctId		= @sBankAcctId,
			@dtPaymentDateFrom	= @dtPaymentDateFrom,
			@dtPaymentDateTo	= @dtPaymentDateTo,
			@nPaymentMethod		= @nPaymentMethod,
			@sPlanName		= @sPlanName,
			@nSupplier		= @nSupplier,
			@sDocumentNo		= @sDocumentNo,
			@dtItemDueDate		= @dtItemDueDate,
			@nSupplierType		= @nSupplierType,
			@dtItemDateFrom		= @dtItemDateFrom,
			@dtItemDateTo		= @dtItemDateTo,
			@dtDueDateFrom		= @dtDueDateFrom,
			@dtDueDateTo		= @dtDueDateTo,
			@sItemCurrency		= @sItemCurrency,
			@nItemBalFrom		= @nItemBalFrom,
			@nItemBalTo		= @nItemBalTo

	If @nErrorCode = 0 AND (@pbDebugFlag = 1)
	Begin
		print '*** List of Plans Initially selected ***'
		Set @sSQLString = "SELECT * FROM #PAYMENTPLANSUMMARY"
		exec @nErrorCode=sp_executesql @sSQLString
	End


End

-- for EFT Payments retrieve the EFTFormat and File Path and Name used
If @nErrorCode = 0
Begin
	Set @sSQLString = "Update #PAYMENTPLANSUMMARY
			set EFTFILEFORMAT = C.EFTFILEFORMAT,
			EFTPAYMENTFILE = C.EFTPAYMENTFILE
			FROM #PAYMENTPLANSUMMARY PP
			JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
			JOIN CASHITEM C 		ON (C.TRANSENTITYNO = PPD.REFENTITYNO 
							AND C.TRANSNO = PPD.REFTRANSNO)
			WHERE PP.PAYMENTMETHOD = -5"


	exec @nErrorCode=sp_executesql @sSQLString
End

-- for cheque Payments retrieve the cheque number
If @nErrorCode = 0
Begin
	Set @sSQLString = "Update #PAYMENTPLANSUMMARY
			set CHEQUENO = C.ITEMREFNO
			FROM #PAYMENTPLANSUMMARY PP
			JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
			JOIN CASHITEM C 		ON (C.TRANSENTITYNO = PPD.REFENTITYNO 
							AND C.TRANSNO = PPD.REFTRANSNO)
			WHERE PP.PAYMENTMETHOD = -1"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- remove plans where one or more payments have been reversed individually
If @nErrorCode = 0
Begin
	Set @sSQLString = "Delete 	
			From #PAYMENTPLANSUMMARY
			Where PLANID IN (SELECT DISTINCT(PP.PLANID)
					From #PAYMENTPLANSUMMARY PP
					Join PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
					Join CASHITEM C 		ON (C.TRANSENTITYNO = PPD.REFENTITYNO 
									AND C.TRANSNO = PPD.REFTRANSNO)
					Where C.STATUS = 9)"

	exec @nErrorCode=sp_executesql @sSQLString

	If @nErrorCode = 0 AND (@pbDebugFlag = 1)
	Begin
		print '*** Plans where one or more payments have been reversed individually removed ***'
		Set @sSQLString = "SELECT * FROM #PAYMENTPLANSUMMARY"
		exec @nErrorCode=sp_executesql @sSQLString
	End
End

-- remove plans that are not of the status specified
If @nErrorCode = 0 AND 
((@bIncludeActive = 1) OR (@bIncludeDraft = 1) OR (@bIncludeFinalised = 1))
Begin

	Set @sSqlWhere = NULL

	If @bIncludeActive = 1
	Begin
		Set @sStatusInc = @sStatusInc + '1'
	End
	If @bIncludeDraft = 1
	Begin
		If @sStatusInc is not NULL
			Set @sStatusInc = @sStatusInc + ', '
		Set @sStatusInc = @sStatusInc + '0'
	End
	If @bIncludeFinalised = 1
	Begin
		If @sStatusInc is not NULL
			Set @sStatusInc = @sStatusInc + ', '
		Set @sStatusInc = @sStatusInc + '2'
	End

	If @sStatusInc is not NULL
	Begin
		Set @sStatusInc = '(' + @sStatusInc + ')'

		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			or '

		Set @sSqlWhere = @sSqlWhere + 'STATUS NOT IN ' + @sStatusInc
	End 
	

	If (@sSqlWhere is not NULL)
	Begin
		Set @sSqlWhere = 'Where ' + @sSqlWhere

	
		Set @sSQLString="Delete 
		from #PAYMENTPLANSUMMARY
		" +  @sSqlWhere
	

		If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
		Begin
			print '*** SQL to apply additional filtering ***'
			Select @sSQLString
		End


		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nPlanId		int',
				@nPlanId		= @nPlanId
	End

	If @nErrorCode = 0 AND (@pbDebugFlag = 1)
	Begin
		print '*** After plans that are not of the status specified have been removed ***'
		Set @sSQLString = "SELECT * FROM #PAYMENTPLANSUMMARY"
		exec @nErrorCode=sp_executesql @sSQLString
	End
End


-- populate local total outstanding balance for each row in the table
If @nErrorCode = 0
Begin

	-- ensure the total initialised to 0
	Set @nTotalLocal = 0	

	Set @sSQLString=" 
	Select @nPlanId=min(PLANID)
	from #PAYMENTPLANSUMMARY
	where PLANID is not null"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPlanId	int		OUTPUT',
					@nPlanId	= @nPlanId	OUTPUT

End

While @nPlanId is not null
and   @nErrorCode = 0
Begin

	If @nErrorCode = 0
	Begin

		Set @sSQLString="SELECT @nStatus = STATUS
		FROM #PAYMENTPLANSUMMARY PP
		Where PP.PLANID = @nPlanId"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nStatus	tinyint		OUTPUT,
						@nPlanId	int',
						@nStatus	= @nStatus	OUTPUT,
						@nPlanId	= @nPlanId	
	end

	If @nErrorCode = 0
	Begin
		If @nStatus = 2
		Begin
			SET @nTotalLocal = 0
		End
		Else If @nStatus = 0
		Begin
			Set @sSQLString="SELECT @nTotalLocal = 
			ISNULL(ABS(SUM(C.LOCALAMOUNT)) , 0)
			FROM CASHITEM C
			WHERE TRANSENTITYNO IN (SELECT DISTINCT(PPD.REFENTITYNO)
						FROM PAYMENTPLANDETAIL PPD
						JOIN #PAYMENTPLANSUMMARY PP ON (PPD.PLANID = PP.PLANID)
						Where PP.PLANID = @nPlanId)
			AND TRANSNO IN 		(SELECT DISTINCT(PPD.REFTRANSNO)
						FROM PAYMENTPLANDETAIL PPD
						JOIN #PAYMENTPLANSUMMARY PP ON (PPD.PLANID = PP.PLANID)
						Where PP.PLANID = @nPlanId)"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalLocal	decimal(13,2)	OUTPUT,
						@nPlanId	int',
						@nTotalLocal	= @nTotalLocal	OUTPUT,
						@nPlanId	= @nPlanId	
		End
		Else If @nStatus = 1
		Begin
			Set @sSQLString="SELECT @nTotalLocal = 
			ISNULL(ABS(SUM(Case when ((CI.CURRENCY = @sLocalCurrency) OR (CI.CURRENCY is NULL)) then
					PPD.PAYMENTAMOUNT
				else
					convert( decimal(11,2), dbo.fn_ConvertCurrency(CI.CURRENCY, NULL, PPD.PAYMENTAMOUNT, @nExchRateType)) 
				End)), 0)
			FROM #PAYMENTPLANSUMMARY PP
			LEFT JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
			JOIN CREDITORITEM CI 		ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO 
							AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO
							AND CI.ACCTENTITYNO = PPD.ACCTENTITYNO 
							AND CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
			Where PP.PLANID = @nPlanId
			group by PP.PLANID, PP.STATUS"


			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTotalLocal	decimal(13,2)	OUTPUT,
						@sLocalCurrency	nvarchar(3),
						@nExchRateType	tinyint,
						@nPlanId	int',
						@nTotalLocal	= @nTotalLocal	OUTPUT,
						@sLocalCurrency	= @sLocalCurrency,
						@nExchRateType	= @nExchRateType,
						@nPlanId	= @nPlanId	
		End

		If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
		Begin
			print '*** SQL to select Total Local Value ***'
			Select @sSQLString

			print '*** Individual Local Equivalent Values ***'
			Select PP.PLANID, PP.STATUS, C.LOCALAMOUNT, CI.CURRENCY, PPD.PAYMENTAMOUNT, PP.STATUS,
			Case when PP.STATUS = 2 then 0 else
				Case when PP.STATUS = 0 then 
					C.LOCALAMOUNT
				else
					Case when PP.STATUS = 1 then
						Case when ((CI.CURRENCY = @sLocalCurrency) OR (CI.CURRENCY is NULL)) then
								PPD.PAYMENTAMOUNT
							else
								convert( decimal(11,2), dbo.fn_ConvertCurrency(CI.CURRENCY, NULL, PPD.PAYMENTAMOUNT, @nExchRateType)) 
							End
					end
				end
			End as CALCLOCALAMT
			FROM #PAYMENTPLANSUMMARY PP
			LEFT JOIN PAYMENTPLANDETAIL PPD	ON (PPD.PLANID = PP.PLANID)
			JOIN CREDITORITEM CI 		ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO 
							AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO
							AND CI.ACCTENTITYNO = PPD.ACCTENTITYNO 
							AND CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)
			LEFT JOIN CASHITEM C 		ON (C.TRANSENTITYNO = PPD.REFENTITYNO 
							AND C.TRANSNO = PPD.REFTRANSNO)
			Where PP.PLANID = @nPlanId

			print '*** Total Local Value, and Plan just processed ***'
			Select @nTotalLocal as PLANTOTAL, @nPlanId AS PLANID, @nExchRateType AS EXCHRATETYPE, @nStatus AS STATUS

			
			print '*** Summary details ***'
			SELECT *
			FROM #PAYMENTPLANSUMMARY PP
			Where PP.PLANID = @nPlanId
		End

	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString="Update #PAYMENTPLANSUMMARY
		Set TOTALLOCAL = @nTotalLocal
		Where PLANID = @nPlanId"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTotalLocal	decimal(13,2),
				@nPlanId	int',
				@nTotalLocal	= @nTotalLocal,
				@nPlanId	= @nPlanId
	End

	-- Now get the next row
	If @nErrorCode = 0
	Begin
		-- ensure the total is reset before processing the next plan
		Set @nTotalLocal = 0
		
		Set @sSQLString=" 
		Select @nPlanIdOUT = min(PLANID)
		from #PAYMENTPLANSUMMARY
		where PLANID > @nPlanId"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nPlanIdOUT	int		OUTPUT,
				@nPlanId	int',
				@nPlanIdOUT	= @nPlanId	OUTPUT,
				@nPlanId	= @nPlanId	
	End

End

-- If a Total Local Balance filter range has been specified remove the rows that are not in that range
If @nErrorCode = 0 and ((@nTotalLocalBalFrom IS NOT NULL) or (@nTotalLocalBalTo IS NOT NULL))
Begin

	Set @sSqlWhere = NULL	
	
	-- Total Local range
	If (@nTotalLocalBalFrom is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			or '

		Set @sSqlWhere = @sSqlWhere + 
		'(TOTALLOCAL < ' + CAST(@nTotalLocalBalFrom as NVARCHAR(20)) + ')'

	End
	
	If (@nTotalLocalBalTo is not NULL)
	Begin
		If (@sSqlWhere is not NULL)
			Set @sSqlWhere = @sSqlWhere + '
			or '

		Set @sSqlWhere = @sSqlWhere + 
		'(TOTALLOCAL > ' + CAST(@nTotalLocalBalTo as NVARCHAR(20)) + ')'
	End

	If (@sSqlWhere is not NULL)
	Begin
		Set @sSqlWhere = 'Where ' + @sSqlWhere

	
		Set @sSQLString="Delete 
		from #PAYMENTPLANSUMMARY
		" +  @sSqlWhere

		If (@nErrorCode = 0) AND (@pbDebugFlag = 1)
		Begin
			print '*** SQL to apply additional filtering ***'
			Select @sSQLString
		End

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nPlanId		int,
				@nTotalLocalBalFrom	decimal(13,2),
				@nTotalLocalBalTo	decimal(13,2)',
				@nPlanId		= @nPlanId,
				@nTotalLocalBalFrom	= @nTotalLocalBalFrom,
				@nTotalLocalBalTo	= @nTotalLocalBalTo

	End
End



If @nErrorCode = 0
Begin
	Set @sSQLString = "Select * 
			From #PAYMENTPLANSUMMARY
			Order By STATUS, PAYMENTDATE, DATEPROCESSED, DATECREATED"
	exec @nErrorCode=sp_executesql @sSQLString
End

Set @pnRowCount = @@Rowcount

Drop Table #PAYMENTPLANSUMMARY


Return @nErrorCode

GO

Grant execute on dbo.ap_ListPaymentPlanSummary to public
GO
