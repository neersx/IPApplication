-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_AppendUserFieldContent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_AppendUserFieldContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_AppendUserFieldContent.'
	Drop procedure [dbo].[fi_AppendUserFieldContent]
End
Print '**** Creating Stored Procedure dbo.fi_AppendUserFieldContent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.fi_AppendUserFieldContent
(	@prsSelect		nvarchar(2000)	= null output,	
	@prsFrom		nvarchar(2000)	= null output,	
	@prsWhere		nvarchar(2000)	= null output,	
	@prsJoin		nvarchar(2000)	= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@pnContentId		int,		-- Mandatory
	@pnNameData		int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbDebugFlag		tinyint		= 0	
	
)
as

-- PROCEDURE:	fi_AppendUserFieldContent
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Called by the fi_CreateAndPostJournals stored procedure

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 02 Dec 2009	CR	RFC8407		1	Procedure created
-- 17 Aug 2010	DL	SQA17990	2	Enclosed filter conditions for @sDebtorLedgerWhere in brackets.
-- 24 Mar 2011	AT	RFC10387	3	Fixed syntax error on @sDebtorLedgerWhere and @sWIPLedgerWhere
-- 09 Aug 2011	AT	RFC10241	4	Modified output of where to exclude 'where' keyword.
-- 02 Nov 2015	vql	R53910		5	Adjust formatted names logic (DR-15543).
-- 16 Oct 2018	DL	DR-43385	6	Fixed SQL syntax error in Field Content 1 & 2
-- 08 Apr 2019	MAF	DR-46167	7	Correct issue when WIP Associate is selected as Field Content
-- 11 Apr 2019	MAF	DR-46167	8	Correct error where Home currency is being referenced without quotes

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sWIPLedgerFrom		nvarchar(1000)
declare @sWIPLedgerJoin		nvarchar(1000)
declare @sDebtorWIPLedgerJoin	nvarchar(1000)	
declare @sDebtorWIPLedgerFrom	nvarchar(1000)
declare @sDebtorLedgerJoin	nvarchar(1000)
declare @sDebtorLedgerFrom	nvarchar(1000)
declare @sOpenItemJoin		nvarchar(1000)
declare @sOpenItemFrom		nvarchar(1000)
declare @sCashLedgerJoin	nvarchar(1000)
declare @sCashLedgerFrom	nvarchar(1000)
declare @sBankLedgerJoin	nvarchar(1000)
declare @sBankLedgerFrom	nvarchar(1000)
declare @sBankAccountJoin	nvarchar(1000)
declare @sBankAccountFrom	nvarchar(1000)
declare @sWIPLedgerWhere	nvarchar(1000)
declare @sDebtorLedgerWhere	nvarchar(1000)
declare @sHomeCurrency 		nvarchar(3)
declare @sNameColumn		nvarchar(254)

-- Initialise variables
Set @nErrorCode = 0
Set @sNameColumn = NULL

If @pbDebugFlag = 1
	Begin
		Print ''
		If (@pnContentId = 1)
		Begin
			Print '-- AppendTransNo'
		End
		Else If  (@pnContentId = 2) 
		Begin
			Print '-- AppendTransactionType'
		End
		Else If (@pnContentId = 3)
		Begin
			Print '-- AppendLiteral'
		End
		Else If (@pnContentId = 4)
		Begin
			Print '-- AppendWIPNameNo'
			Print 	'EXECUTE @nErrorCode = fi_ConvertNameData
		   '+@prsSelect+' OUTPUT
		  ,'+@prsFrom+' OUTPUT
		  ,'+@prsJoin+' OUTPUT
		  ,'+CAST(@pnUserIdentityId AS NVARCHAR(30))+'
		  ,'+CAST(@pnNameData AS NVARCHAR(30))+'
		  ,'+@sNameColumn+'
		  ,'+@psCulture+'
		  ,0
		  ,'+CAST(@pbDebugFlag AS NVARCHAR(2))

		End
		Else If (@pnContentId = 5)
		Begin
			Print '-- AppendWIPStaffNo'
		End
		Else If ( @pnContentId = 6 )
		Begin
			Print '-- AppendCaseReference'
		End
		Else If ( @pnContentId = 7 )
		Begin
			Print '-- AppendCaseNameNo'
		End
		Else If ( @pnContentId = 8 )
		Begin
			Print '-- AppendWIPDebtorNo'
		End
		Else If ( @pnContentId = 9 )
		Begin
			Print '-- AppendWIPOpenItemNo'
		End
		Else If ( @pnContentId = 10 )
		Begin
			Print '-- AppendDebtorCaseReference'
		End
		Else If ( @pnContentId = 11 )
		Begin
			Print '-- AppendDebtorCaseNameNo'
		End
		Else If ( @pnContentId = 12 )
		Begin
			Print '-- AppendDebtorNo'
		End
		Else If ( @pnContentId = 13 )
		Begin
			Print '-- AppendOpenItemNo'
		End
		Else If ( @pnContentId = 14 )
		Begin
			Print '-- AppendDebtorCurrency'
		End
		Else If ( @pnContentId = 15 )
		Begin
			Print '-- AppendDebtorForeignAmount'
		End
		Else If ( @pnContentId = 16 )
		Begin
			Print '-- AppendDebtorTransactionText'
		End
		Else If ( @pnContentId = 17 )
		Begin
			Print '-- AppendOpenItemNo'
		End
		Else If ( @pnContentId = 18 )
		Begin
			Print '-- AppendCashTransactionText'
		End
		Else If ( @pnContentId = 19 )
		Begin
			Print '-- AppendCashReferenceNo'
		End
		Else If ( @pnContentId = 20 )
		Begin
			Print '-- AppendCashDrawerName'
		End
		Else If ( @pnContentId = 21 )
		Begin
			Print '-- AppendCashPaymentCurrency'
		End
		Else If ( @pnContentId = 22 )
		Begin
			Print '-- AppendCashPaymentAmount'
		End
		Else If ( @pnContentId = 23 )
		Begin
			Print '-- AppendBankTransactionText'
		End
		Else If ( @pnContentId = 24 )
		Begin
			Print '-- AppendBankReferenceNo'
		End
		Else If ( @pnContentId = 25 )
		Begin
			Print '-- AppendBankCurrency'
		End
		Else If ( @pnContentId = 26 )
		Begin
			Print '-- AppendBankForeignAmount'
		End
		Else If ( @pnContentId = 27 )
		Begin
			Print '-- AppendBankPaymentCurrency'
		End
		Else If ( @pnContentId = 28 ) 
		Begin
			Print '-- AppendBankPaymentAmount'
		End
		Else If ( @pnContentId = 29 )
		Begin
			Print '-- AppendDebtorReference'
		End
		Else If ( @pnContentId = 30 )
		Begin
			Print '-- AppendOpenItemStatementRef'
		End
		Else If ( @pnContentId = 31 )
		Begin
			Print '-- AppendPostDate'
		End
		Else If ( @pnContentId = 32 )
		Begin
			Print '-- AppendWIPAssociateNo'
		End
		Else If ( @pnContentId = 33 )
		Begin
			Print '-- AppendSupplierInvoiceNo'
		End
		Else If ( @pnContentId = 34 )
		Begin
			Print '-- AppendWIPVerificationNo'
		End
		Else If ( @pnContentId = 35 )
		Begin
			Print '-- AppendWIPCode'
		End
		Else If ( @pnContentId = 36 )
		Begin
			Print '-- AppendWIPCurrency'
		End
		Else If ( @pnContentId = 37 )
		Begin
			Print '-- AppendWIPForeignAmount'
		End
		Else If ( @pnContentId = 38 )
		Begin
			Print '-- AppendWIPStaffProfitCentre'
		End
		Else If ( @pnContentId = 39 )
		Begin
			Print '-- AppendOIStaffProfitCentre'
		End
		Else If ( @pnContentId = 40 ) 
		Begin
			Print '-- AppendOpenItemNoCreated'
		End
		Else If ( @pnContentId = 41 )
		Begin
			Print '-- AppendOpenItemNoCreated'
		End
		Else If ( @pnContentId = 42 )
		Begin
			Print '-- AppendOIStaffProfitCentre'
		End
		Else If ( @pnContentId = 43 ) 
		Begin
			Print '-- AppendTaxCurrency'
		End
		Else If ( @pnContentId = 44 )
		Begin
			Print '-- AppendTaxForeignAmount'
		End
		Else If ( @pnContentId = 45 )
		Begin
			Print '-- AppendWIPSourceOfficeId'
		End
		Else If ( @pnContentId = 46 )
		Begin
			Print '-- AppendDebtorSourceOfficeId'
		End
		Else If ( @pnContentId = 47 )
		Begin
			Print '-- AppendTaxSourceOfficeId'
		End
		Else If ( @pnContentId = 48 )
		Begin
			Print '-- AppendWIPCaseProfitCentre'
		End
		Else If ( @pnContentId = 49 )
		Begin
			Print '-- AppendOICaseProfitCentre'
		End
		Else If ( @pnContentId = 50 )
		Begin
			Print '-- AppendOICaseProfitCentre'
		End
		
		Select @prsSelect AS SELECTSTMT,	
			@prsFrom AS FROMSTMT,	
			@prsJoin AS JOINSTMT,
			@prsWhere AS WHERESTMT
	End

-- The following predefined joins are used by the User Fields logic near the end of this procedure.
-- __cfAppendWIPLedgerJoin
Set @sWIPLedgerFrom = "INNER JOIN WORKHISTORY H ON (
			H.ENTITYNO = GL.KEYFIELD1
			AND H.TRANSNO = GL.KEYFIELD2
			AND H.WIPSEQNO = GL.SMALLKEYFIELD1
			AND H.HISTORYLINENO = GL.SMALLKEYFIELD2 )" 
Set @sWIPLedgerJoin = "GL.LEDGER = 1"

-- __cfAppendDebtorWIPLedgerJoin
--MAF V7 - Correct Variable Name
Set @sDebtorWIPLedgerFrom = "INNER JOIN OPENITEM H ON (H.ITEMENTITYNO = GL.KEYFIELD3
		AND	H.ITEMTRANSNO = GL.KEYFIELD4
		AND	H.ACCTENTITYNO = GL.KEYFIELD5
		AND	H.ACCTDEBTORNO = GL.KEYFIELD6)"
Set @sDebtorWIPLedgerJoin = "GL.LEDGER = 1"

-- __cfAppendDebtorLedgerJoin
Set @sDebtorLedgerFrom = "INNER JOIN DEBTORHISTORY H ON (H.ITEMENTITYNO = GL.KEYFIELD3
		AND	H.ITEMTRANSNO = GL.KEYFIELD4
		AND	H.ACCTENTITYNO = GL.KEYFIELD5
		AND	H.ACCTDEBTORNO = GL.KEYFIELD6
		AND	H.HISTORYLINENO = GL.SMALLKEYFIELD1)" 
Set @sDebtorLedgerJoin = "( GL.LEDGER = 2 OR
		                  GL.LEDGER = 3 )"

-- __cfAppendOpenItemJoin
Set @sOpenItemFrom = "INNER JOIN OPENITEM OI ON (OI.ITEMENTITYNO = GL.KEYFIELD3
		AND	OI.ITEMTRANSNO = GL.KEYFIELD4
		AND	OI.ACCTENTITYNO = GL.KEYFIELD5
		AND	OI.ACCTDEBTORNO = GL.KEYFIELD6)" 
Set @sOpenItemJoin = "( GL.LEDGER = 2  OR
		                  GL.LEDGER = 3 )"

-- __cfAppendCashLedgerJoin
Set @sCashLedgerFrom = "INNER JOIN CASHHISTORY H ON (H.ENTITYNO = GL.KEYFIELD1
		AND	H.BANKNAMENO = GL.KEYFIELD2
		AND	H.SEQUENCENO = GL.KEYFIELD3
		AND	H.TRANSENTITYNO = GL.KEYFIELD4
		AND	H.TRANSNO = GL.KEYFIELD5
		AND	H.HISTORYLINENO = GL.SMALLKEYFIELD1)" 
Set @sCashLedgerJoin = "GL.LEDGER = 4"

-- __cfAppendBankLedgerJoin
Set @sBankLedgerFrom = "INNER JOIN BANKHISTORY H ON (H.ENTITYNO = GL.KEYFIELD1
		AND	H.BANKNAMENO = GL.KEYFIELD2
		AND	H.SEQUENCENO = GL.KEYFIELD3
		AND	H.HISTORYLINENO = GL.KEYFIELD4)"
Set @sBankLedgerJoin = "GL.LEDGER = 5"

-- __cfAppendBankAccountJoin
Set @sBankAccountFrom = "INNER JOIN BANKACCOUNT BA ON (BA.ACCOUNTOWNER = GL.KEYFIELD1
		AND	BA.BANKNAMENO = GL.KEYFIELD2
		AND	BA.SEQUENCENO = GL.KEYFIELD3)" 
Set @sBankAccountJoin = "GL.LEDGER = 5"

-- __cfAppendWIPLedgerWhere
Set @sWIPLedgerWhere = "GL.LEDGER = 1"

-- __cfAppendDebtorLedgerWhere
-- SQA17799 Enclosed filter conditions in brackets.
Set @sDebtorLedgerWhere = "(GL.LEDGER = 2 OR
		                  GL.LEDGER = 3 )"

if (@prsWhere is null or @prsWhere = "")
Begin
	Set @prsWhere = " 1=1 "
End

-- Determine Home Currency
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select	@sHomeCurrency = COLCHARACTER from SITECONTROL
	Where CONTROLID = 'CURRENCY'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sHomeCurrency	nvarchar(3)	OUTPUT',
				  @sHomeCurrency	OUTPUT
End

If @nErrorCode = 0
Begin
	-- __cfAppendContent
	If (@pnContentId = 1)
	Begin
		-- __cfAppendTransNo()
		Set @prsSelect = @prsSelect + ", convert( nvarchar(254), GL.TRANSNO)"
	End
	Else If  (@pnContentId = 2) 
	Begin
		-- __cfAppendTransactionType
		Set @prsSelect = @prsSelect + ", TT.DESCRIPTION" 
		Set @prsFrom = @prsFrom +
					"INNER JOIN TRANSACTIONHEADER TH	ON (TH.ENTITYNO = GL.ENTITY 
			AND TH.TRANSNO = GL.TRANSNO)"
		Set @prsFrom = @prsFrom +
					"INNER JOIN ACCT_TRANS_TYPE TT ON (TT.TRANS_TYPE_ID = TH.TRANSTYPE)" 
	End
	Else If (@pnContentId = 3)
	Begin
		-- __cfAppendLiteral
		Set @prsSelect = @prsSelect + ", CONT.LITERAL"
	End
	Else If (@pnContentId = 4)
	Begin
		-- __cfAppendWIPNameNo
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin 
		Set @sNameColumn = "H.ACCTCLIENTNO"
		Set @prsJoin = @prsJoin + " AND H.ACCTCLIENTNO IS NOT NULL" 

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  --,@pnContentId
		  ,@pnNameData
		  --,@pnSegNo
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag

	End
	Else If (@pnContentId = 5)
	Begin
		-- __cfAppendWIPStaffNo
		Set @sNameColumn = "GL.WIPEMPLOYEENO"
		Set @prsJoin = @prsJoin + " AND GL.WIPEMPLOYEENO IS NOT NULL" 

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 6 )
	Begin
		 -- __cfAppendCaseReference
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sWIPLedgerWhere
		Set @prsSelect = @prsSelect + ", C.IRN" 
		Set @prsFrom = @prsFrom + "
		INNER JOIN CASES C ON (C.CASEID = GL.CASEID)" 
	End
	Else If ( @pnContentId = 7 )
	Begin
		-- __cfAppendCaseNameNo
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sWIPLedgerWhere
		Set @sNameColumn = "CN.NAMENO"
		Set @prsFrom = @prsFrom + "
		INNER JOIN CASENAME CN ON (CN.CASEID = GL.CASEID AND CN.NAMETYPE = CONT.NAMETYPE)"
		Set @prsJoin = @prsJoin + " AND  CN.EXPIRYDATE IS NULL
				AND	CN.SEQUENCE =
					( SELECT MIN(CN2.SEQUENCE)
		  			  FROM CASENAME CN2
					  WHERE CN2.CASEID = CN.CASEID
					  AND	CN2.NAMETYPE = CN.NAMETYPE
					  AND	CN2.EXPIRYDATE IS NULL )"

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 8 )
	Begin
		-- __cfAppendWIPDebtorNo
		-- MAF V7 Use correct variable
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorWIPLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorWIPLedgerJoin			

		Set @sNameColumn = "H.ACCTDEBTORNO"

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 9 )
	Begin
		-- __cfAppendWIPOpenItemNo
		-- MAF V7 Use correct variable
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorWIPLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorWIPLedgerJoin			
		Set @prsSelect = @prsSelect + ", H.OPENITEMNO" 
	End
	Else If ( @pnContentId = 10 )
	Begin
		-- __cfAppendDebtorCaseReference
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sDebtorLedgerWhere
		Set @prsSelect = @prsSelect + ", C.IRN" 
		Set @prsFrom = @prsFrom + "
		INNER JOIN CASES C ON (C.CASEID = GL.CASEID)" 
	End
	Else If ( @pnContentId = 11 )
	Begin
		-- __cfAppendDebtorCaseNameNo
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sDebtorLedgerWhere
		Set @sNameColumn = "CN.NAMENO"
		Set @prsFrom = @prsFrom + "
		INNER JOIN CASENAME CN ON (CN.CASEID = GL.CASEID AND CN.NAMETYPE = CONT.NAMETYPE)"
		Set @prsJoin = @prsJoin + " AND  CN.EXPIRYDATE IS NULL
				AND	CN.SEQUENCE =
					( SELECT MIN(CN2.SEQUENCE)
		  			  FROM CASENAME CN2
					  WHERE CN2.CASEID = CN.CASEID
					  AND	CN2.NAMETYPE = CN.NAMETYPE
					  AND	CN2.EXPIRYDATE IS NULL )"

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 12 )
	Begin
		-- __cfAppendDebtorNo
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sDebtorLedgerWhere
		Set @sNameColumn = "GL.KEYFIELD6"

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 13 )
	Begin
		-- __cfAppendOpenItemNo
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", H.OPENITEMNO"
	End
	Else If ( @pnContentId = 14 )
	Begin
		-- __cfAppendDebtorCurrency
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", H.CURRENCY"
		Set @prsJoin = @prsJoin + " AND  H.CURRENCY IS NOT NULL
				AND	GL.AMOUNTTYPE <> 6629"
	End
	Else If ( @pnContentId = 15 )
	Begin
		-- __cfAppendDebtorForeignAmount
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
			Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
						ABS( CASE WHEN GL.AMOUNTTYPE = 6612
							THEN H.FOREIGNTRANVALUE - H.FOREIGNTAXAMT
							ELSE CASE 	WHEN GL.AMOUNTTYPE = 6631
									THEN H.FOREIGNTAXAMT
									ELSE H.FOREIGNTRANVALUE
									END
							END )
						* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		-- Foreign value not available for exchange gain/loss
		Set @prsJoin = @prsJoin + " AND  H.CURRENCY IS NOT NULL
				AND	GL.AMOUNTTYPE <> 6629"
	End
	Else If ( @pnContentId = 16 )
	Begin
		-- __cfAppendDebtorTransactionText
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
			Set @prsSelect = @prsSelect + ", CASE WHEN H.REFERENCETEXT IS NULL THEN convert( nvarchar(254), H.LONGREFTEXT ) ELSE H.REFERENCETEXT END"
		Set @prsJoin = @prsJoin + " AND  ( H.REFERENCETEXT IS NOT NULL OR
				( H.LONGREFTEXT NOT LIKE '' AND H.LONGREFTEXT NOT LIKE ' ' ) )"
	End
	Else If ( @pnContentId = 17 )
	Begin
		-- __cfAppendOpenItemNo
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", H.OPENITEMNO"
	End
	Else If ( @pnContentId = 18 )
	Begin
		-- __cfAppendCashTransactionText
		Set @prsFrom = @prsFrom +char(10)+ @sCashLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sCashLedgerJoin
		Set @prsSelect = @prsSelect + ", H.DESCRIPTION"
		Set @prsJoin = @prsJoin + " AND  H.DESCRIPTION IS NOT NULL"
	End
	Else If ( @pnContentId = 19 )
	Begin
		-- __cfAppendCashReferenceNo
		Set @prsFrom = @prsFrom +char(10)+ @sCashLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sCashLedgerJoin
		Set @prsSelect = @prsSelect + ", H.ITEMREFNO"
		Set @prsJoin = @prsJoin + " AND  H.ITEMREFNO IS NOT NULL"
	End
	Else If ( @pnContentId = 20 )
	Begin
		-- __cfAppendCashDrawerName
		Set @prsFrom = @prsFrom +char(10)+ "INNER JOIN CASHITEM CI ON ( CI.ENTITYNO = GL.KEYFIELD1
			AND	CI.BANKNAMENO = GL.KEYFIELD2
			AND	CI.SEQUENCENO = GL.KEYFIELD3
			AND	CI.TRANSENTITYNO = GL.KEYFIELD4
			AND	CI.TRANSNO = GL.KEYFIELD5)"
		Set @prsJoin = @prsJoin + " AND GL.LEDGER = 4"

		Set @prsSelect = @prsSelect + ", CASE 	WHEN CI.ACCTNAMENO IS NULL
						THEN CI.TRADER
						ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
						END"
		Set @prsFrom = @prsFrom + "
		LEFT OUTER JOIN NAME N ON (N.NAMENO = CI.ACCTNAMENO)"
	End
	Else If ( @pnContentId = 21 )
	Begin
		-- __cfAppendCashPaymentCurrency
		Set @prsFrom = @prsFrom +char(10)+ @sCashLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sCashLedgerJoin
		Set @prsSelect = @prsSelect + ", H.DISSECTIONCURRENCY"
		-- Foreign value not available for Charges
		Set @prsJoin = @prsJoin + " AND  H.DISSECTIONCURRENCY  IS NOT NULL
				AND	H.DISSECTIONCURRENCY <> '" + @sHomeCurrency + "'
				AND	GL.AMOUNTTYPE <> 6649"
	End
	Else If ( @pnContentId = 22 )
	Begin
		-- __cfAppendCashPaymentAmount
		Set @prsFrom = @prsFrom +char(10)+ @sCashLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sCashLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
			Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
						ABS( H.FOREIGNAMOUNT )
						* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		-- Foreign value not available for Charges
		Set @prsJoin = @prsJoin + " AND  H.DISSECTIONCURRENCY  IS NOT NULL
				AND	H.DISSECTIONCURRENCY <> '" + @sHomeCurrency + "'
				AND	GL.AMOUNTTYPE <> 6649"
	End
	Else If ( @pnContentId = 23 )
	Begin
		-- __cfAppendBankTransactionText
		Set @prsFrom = @prsFrom +char(10)+ @sBankLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankLedgerJoin
		Set @prsSelect = @prsSelect + ", H.DESCRIPTION"
		Set @prsJoin = @prsJoin + " AND H.DESCRIPTION IS NOT NULL"
	End
	Else If ( @pnContentId = 24 )
	Begin
		-- __cfAppendBankReferenceNo
		Set @prsFrom = @prsFrom +char(10)+ @sBankLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankLedgerJoin
		Set @prsSelect = @prsSelect + ", H.REFERENCE"
		Set @prsJoin = @prsJoin + " AND  H.REFERENCE IS NOT NULL"
	End
	Else If ( @pnContentId = 25 )
	Begin
		-- __cfAppendBankCurrency
		Set @prsFrom = @prsFrom +char(10)+ @sBankAccountFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankAccountJoin
		Set @prsSelect = @prsSelect + ", BA.CURRENCY"
		Set @prsJoin = @prsJoin + " AND  BA.CURRENCY IS NOT NULL
				AND	BA.CURRENCY <> '" + @sHomeCurrency + "'"
	End
	Else If ( @pnContentId = 26 )
	Begin
		-- __cfAppendBankForeignAmount
		Set @prsFrom = @prsFrom +char(10)+ @sBankLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
		-- Determine whether foreign or not by checking Bank Account currency
		Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
					ABS( CASE 	WHEN GL.AMOUNTTYPE = 6651
						THEN H.BANKAMOUNT
						ELSE CASE	WHEN GL.AMOUNTTYPE = 6652
								THEN H.BANKNET
								ELSE H.BANKCHARGES
							 END
						END )
					* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		Set @prsFrom = @prsFrom + "
		INNER JOIN BANKACCOUNT ACCT ON (ACCT.ACCOUNTOWNER = H.ENTITYNO
						AND ACCT.BANKNAMENO = H.BANKNAMENO
						AND  ACCT.SEQUENCENO = H.SEQUENCENO)"
		Set @prsJoin = @prsJoin + " AND  ACCT.CURRENCY IS NOT NULL
				AND	ACCT.CURRENCY <> '" + @sHomeCurrency + "'"
	End
	Else If ( @pnContentId = 27 )
	Begin
		-- __cfAppendBankPaymentCurrency
		Set @prsFrom = @prsFrom +char(10)+ @sBankLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankLedgerJoin
		Set @prsSelect = @prsSelect + ", H.PAYMENTCURRENCY"
		-- Foreign value not available for charges
		Set @prsJoin = @prsJoin + " AND  H.PAYMENTCURRENCY  IS NOT NULL
				AND	H.PAYMENTCURRENCY <> '" + @sHomeCurrency + "'
				AND	GL.AMOUNTTYPE <> 6649"
	End
	Else If ( @pnContentId = 28 ) 
	Begin
		-- __cfAppendBankPaymentAmount
		Set @prsFrom = @prsFrom +char(10)+ @sBankLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sBankLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
			Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
						ABS( H.PAYMENTAMOUNT )
						* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		-- Foreign value not available for charges
		Set @prsJoin = @prsJoin + " AND  H.PAYMENTCURRENCY  IS NOT NULL
				AND	H.PAYMENTCURRENCY <> '" + @sHomeCurrency + "'
				AND	GL.AMOUNTTYPE <> 6649"
	End
	Else If ( @pnContentId = 29 )
	Begin
		-- __cfAppendDebtorReference
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sDebtorLedgerWhere
		Set @prsSelect = @prsSelect + ", CN.REFERENCENO"
		Set @prsFrom = @prsFrom + "
		INNER JOIN CASENAME CN ON (CN.CASEID = GL.CASEID AND CN.NAMENO = GL.KEYFIELD6)"
		-- GL.KEYFIELD4 contains the Debtor History key element ACCTDEBTORNO
		Set @prsJoin = @prsJoin + " AND  CN.NAMETYPE = 'D'
				AND	CN.EXPIRYDATE IS NULL
				AND	CN.REFERENCENO IS NOT NULL"
	End
	Else If ( @pnContentId = 30 )
	Begin
		-- __cfAppendOpenItemStatementRef
		Set @prsFrom = @prsFrom +char(10)+ @sOpenItemFrom
		Set @prsJoin = @prsJoin + " AND " + @sOpenItemJoin
		Set @prsSelect = @prsSelect + ", OI.STATEMENTREF"
		Set @prsJoin = @prsJoin + " AND  OI.STATEMENTREF IS NOT NULL"
	End
	Else If ( @pnContentId = 31 )
	Begin
		-- __cfAppendPostDate
		Set @prsSelect = @prsSelect + ", convert( nvarchar(254), TH.TRANPOSTDATE, 112)"
		Set @prsFrom = @prsFrom + "
		INNER JOIN TRANSACTIONHEADER TH ON (TH.ENTITYNO = GL.ENTITY AND TH.TRANSNO = GL.TRANSNO )"
	End
	Else If ( @pnContentId = 32 )
	Begin
		-- __cfAppendWIPAssociateNo
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		Set @sNameColumn = "H.ASSOCIATENO"
		Set @prsJoin = @prsJoin + " AND  H.ASSOCIATENO IS NOT NULL"

		EXECUTE @nErrorCode = fi_ConvertNameData
		   @prsSelect OUTPUT
		  ,@prsFrom OUTPUT
		  ,@prsJoin OUTPUT
		  ,@pnUserIdentityId
		  ,@pnNameData
		  ,@sNameColumn
		  ,@psCulture
		  ,0
		  ,@pbDebugFlag
	End
	Else If ( @pnContentId = 33 )
	Begin
		-- __cfAppendSupplierInvoiceNo
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		Set @prsSelect = @prsSelect + ", H.INVOICENUMBER"
		Set @prsJoin = @prsJoin + " AND  H.INVOICENUMBER IS NOT NULL"
	End
	Else If ( @pnContentId = 34 )
	Begin
		-- __cfAppendWIPVerificationNo
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		Set @prsSelect = @prsSelect + ", H.VERIFICATIONNUMBER"
		Set @prsJoin = @prsJoin + " AND  H.VERIFICATIONNUMBER IS NOT NULL"
	End
	Else If ( @pnContentId = 35 )
	Begin
		-- __cfAppendWIPCode
		Set @prsSelect = @prsSelect + ", GL.WIPCODE"
		Set @prsJoin = @prsJoin + " AND  GL.WIPCODE IS NOT NULL"
	End
	Else If ( @pnContentId = 36 )
	Begin
		-- __cfAppendWIPCurrency
		-- The currency is on the originating record, not each history row
		Set @prsFrom = @prsFrom +char(10)+ "INNER JOIN WORKHISTORY H ON (
				H.ENTITYNO = GL.KEYFIELD1
				AND H.TRANSNO = GL.KEYFIELD2
				AND H.WIPSEQNO = GL.SMALLKEYFIELD1)" 
		Set @prsJoin = @prsJoin + " AND H.ITEMIMPACT = 1
			AND	GL.LEDGER = 1"

		Set @prsSelect = @prsSelect + ", H.FOREIGNCURRENCY"
		-- The foreign currency is only on the originating row
		Set @prsJoin = @prsJoin + " AND  H.FOREIGNCURRENCY IS NOT NULL"
	End
	Else If ( @pnContentId = 37 )
	Begin
		-- __cfAppendWIPForeignAmount
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
		Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
					ABS( GL.FOREIGNAMOUNT )
					* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		Set @prsJoin = @prsJoin + " AND  GL.FOREIGNAMOUNT IS NOT NULL"
	End
	Else If ( @pnContentId = 38 )
	Begin
		-- __cfAppendWIPStaffProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		Set @prsSelect = @prsSelect + ", H.EMPPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  H.EMPPROFITCENTRE IS NOT NULL"
	End
	Else If ( @pnContentId = 39 )
	Begin
		-- __cfAppendOIStaffProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sOpenItemFrom
		Set @prsJoin = @prsJoin + " AND " + @sOpenItemJoin
		Set @prsSelect = @prsSelect + ", OI.EMPPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  OI.EMPPROFITCENTRE IS NOT NULL"
	End
	Else If ( @pnContentId = 40 ) 
	Begin
		-- __cfAppendOpenItemNoCreated
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", OI.OPENITEMNO"
		Set @prsFrom = @prsFrom + "
		INNER JOIN OPENITEM OI ON ("
		Set @prsFrom = @prsFrom + "
		OI.ITEMENTITYNO = H.REFENTITYNO
				AND OI.ITEMTRANSNO = H.REFTRANSNO
				AND OI.ACCTENTITYNO = H.ACCTENTITYNO
				AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO)"
	End
	Else If ( @pnContentId = 41 )
	Begin
		-- __cfAppendOpenItemNoCreated
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", OI.OPENITEMNO"
		Set @prsFrom = @prsFrom + "
		INNER JOIN OPENITEM OI ON ("
		Set @prsFrom = @prsFrom + "
		OI.ITEMENTITYNO = H.REFENTITYNO
				AND OI.ITEMTRANSNO = H.REFTRANSNO
				AND OI.ACCTENTITYNO = H.ACCTENTITYNO
				AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO)"
	End
	Else If ( @pnContentId = 42 )
	Begin
		-- __cfAppendOIStaffProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sOpenItemFrom
		Set @prsJoin = @prsJoin + " AND " + @sOpenItemJoin
		Set @prsSelect = @prsSelect + ", OI.EMPPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  OI.EMPPROFITCENTRE IS NOT NULL"
	End
	Else If ( @pnContentId = 43 ) 
	Begin
		-- __cfAppendTaxCurrency
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", H.CURRENCY"
		-- Foreign value not available for exchange gain/loss
		Set @prsJoin = @prsJoin + " AND  H.CURRENCY IS NOT NULL
				AND	GL.AMOUNTTYPE <> 6629"
	End
	Else If ( @pnContentId = 44 )
	Begin
		-- __cfAppendTaxForeignAmount
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		-- Obtain sign of amount from GLJournalLine, and the type of amount from GLAccounting
		Set @prsSelect = @prsSelect + ", convert( nvarchar(254),
					ABS( H.FOREIGNTAXAMT )
					* CASE WHEN GL.LOCALAMOUNT < 0 THEN -1 ELSE 1 END )"
		-- Foreign value not available for exchange gain/loss
		Set @prsJoin = @prsJoin + " AND  H.CURRENCY IS NOT NULL
				AND	GL.AMOUNTTYPE <> 6629"
	End
	Else If ( @pnContentId = 45 )
	Begin
		-- __cfAppendWIPSourceOfficeId
		Set @prsWhere = @prsWhere + char(10) + " AND " + @sWIPLedgerWhere
		Set @prsSelect = @prsSelect + ", GL.SOURCEOFFICEID"
		Set @prsJoin = @prsJoin + " AND  GL.SOURCEOFFICEID IS NOT NULL"
	End
	Else If ( @pnContentId = 46 )
	Begin
		-- __cfAppendDebtorSourceOfficeId
		Set @prsFrom = @prsFrom +char(10)+ @sDebtorLedgerFrom 
		Set @prsJoin = @prsJoin + " AND " + @sDebtorLedgerJoin
		Set @prsSelect = @prsSelect + ", GL.SOURCEOFFICEID"
		Set @prsJoin = @prsJoin + " AND  GL.SOURCEOFFICEID IS NOT NULL"
	End
	Else If ( @pnContentId = 47 )
	Begin
		-- __cfAppendTaxSourceOfficeId
		Set @prsSelect = @prsSelect + ", GL.SOURCEOFFICEID"
		Set @prsJoin = @prsJoin + " AND  GL.SOURCEOFFICEID IS NOT NULL"
	End
	Else If ( @pnContentId = 48 )
	Begin
		-- __cfAppendWIPCaseProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sWIPLedgerFrom
		Set @prsJoin = @prsJoin + " AND " + @sWIPLedgerJoin
		Set @prsSelect = @prsSelect + ", H.CASEPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  H.CASEPROFITCENTRE IS NOT NULL"
	End
	Else If ( @pnContentId = 49 )
	Begin
		-- __cfAppendOICaseProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sOpenItemFrom
		Set @prsJoin = @prsJoin + " AND " + @sOpenItemJoin
		Set @prsSelect = @prsSelect + ", OI.CASEPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  OI.CASEPROFITCENTRE IS NOT NULL"
	End
	Else If ( @pnContentId = 50 )
	Begin
		-- __cfAppendOICaseProfitCentre
		Set @prsFrom = @prsFrom +char(10)+ @sOpenItemFrom
		Set @prsJoin = @prsJoin + " AND " + @sOpenItemJoin
		Set @prsSelect = @prsSelect + ", OI.CASEPROFITCENTRE"
		Set @prsJoin = @prsJoin + " AND  OI.CASEPROFITCENTRE IS NOT NULL"
	End

	If @pbDebugFlag = 1
	Begin
		Select @prsSelect AS SELECTSTMT,	
			@prsFrom AS FROMSTMT,	
			@prsJoin AS JOINSTMT,
			@prsWhere AS WHERESTMT
	End
End

Return @nErrorCode
GO

Grant execute on dbo.fi_AppendUserFieldContent to public
GO
