-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cb_ListBankHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cb_ListBankHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cb_ListBankHistory.'
	Drop procedure [dbo].[cb_ListBankHistory]
End
Print '**** Creating Stored Procedure dbo.cb_ListBankHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cb_ListBankHistory
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)
as
-- PROCEDURE:	cb_ListBankHistory
-- VERSION:	15
-- SCOPE:	Inprotech
-- DESCRIPTION:	List Bank History/CashItem entries by specified criteria 
--		for Bank History Report in Cash Book program
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 21/02/2004	CR	10840		1	Procedure created.
-- 01/06/2006	AT	12258		2	Modified to display reversal transactions.
-- 11/12/2008	MF	17136		3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 20/01/2009	AT	16971		4	Cater for Dishonoured Receipts.
-- 23/06/2009	MF	17809		5	Duplicate rows being returned because of join to CASHHISTORY
-- 25/06/2009	MF	17809		6	Revisit to cater for valid duplicate rows appearing in the CASHITEM table. 
-- 03/05/2012	CR	20506		7	Change Entity Filter to refer to ENTITYNO instead of REFENTITYNO
-- 10/07/2012	CR	13749		8	Fix Period Range
-- 11/07/2012	CR	11766		9	Fix Exchange Rate included for Bank only transactions
-- 18/07/2012	CR	20739		10	Ensure only the BANKHISTORY row is referred to for Bank Draft Automatic Payments
-- 17/09/2012   DL	16196		11	Consolidate System Defined Payment Methods - update references.
-- 15/04/2013	DV	R13270		12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629		13	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 13 Oct 2017	DL	R72377		14	Bank History report duplicating rows
-- 14 Nov 2018  AV  75198/DR-45358	15   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


declare @sSql 			nvarchar(4000)
declare @sSqlFrom 		nvarchar(2000)
declare @sSqlWhere		nvarchar(2000)
declare @sOr			nvarchar(5)
-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

declare
	@nEntityNo		int,
	@dtDateFrom		datetime,
	@dtDateTo		datetime,
	@nPeriodFrom		int,
	@nPeriodTo		int,
	@sBankAcctId		nvarchar(35),
	@nAccountName		int,
	@nEnteredByStaff	int,
	@sReferenceFrom		nvarchar(30),
	@sReferenceTo		nvarchar(30),
	@nLocalFrom		decimal(13,2),
	@nLocalTo		decimal(13,2),
	@nBankedFrom		decimal(13,2),
	@nBankedTo		decimal(13,2),
	@nBankingCategory	int,
	@bReportByTransDate	bit,
	@bReportByPostDate	bit,
	@bReportByPostPeriod	bit,
	@bSortTransDate 	bit,
	@bSortPostDate		bit,
	@bSortAcctName		bit,
	@bIncludeWithdrawals	bit,
	@bIncludeDeposits	bit,
	@bShowReversed		bit,
	@sIncludeCommands	nvarchar(10)

/* not able to use these with sp_executesql
declare @tbTRANSTYPEINC 		table (
	TRANTYPEID	int 		NOT NULL)

declare @tbPAYMENTMETHODINC 		table (
	METHODID	int 		NOT NULL)

*/

declare	@nErrorCode int

Set	@nErrorCode = 0


If @nErrorCode = 0
Begin
	CREATE TABLE #TRANSTYPEINC (
		TRANTYPEID	int 		NOT NULL)

	Set	@nErrorCode = @@Error

End

If @nErrorCode = 0
Begin
	CREATE TABLE #PAYMENTMETHODINC 		(
		METHODID	int 		NOT NULL)

	Set	@nErrorCode = @@Error
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
		Set @sSql = 	
		"Select	@nEntityNo		= EntityNo,"+CHAR(10)+
		"	@dtDateFrom		= DateFrom,"+CHAR(10)+
		"	@dtDateTo		= DateTo,"+CHAR(10)+
		"	@nPeriodFrom		= PeriodFrom,"+CHAR(10)+
		"	@nPeriodTo		= PeriodTo,"+CHAR(10)+
		"	@sBankAcctId 		= BankAcctId,"+CHAR(10)+
		"	@nAccountName		= AccountName,"+CHAR(10)+
		"	@nEnteredByStaff	= EnteredByStaff,"+CHAR(10)+
		"	@sReferenceFrom 	= ReferenceFrom,"+CHAR(10)+
		"	@sReferenceTo 		= ReferenceTo,"+CHAR(10)+
		"	@nLocalFrom 		= LocalFrom,"+CHAR(10)+
		"	@nLocalTo 		= LocalTo,"+CHAR(10)+
		"	@nBankedFrom 		= BankedFrom,"+CHAR(10)+
		"	@nBankedTo 		= BankedTo,"+CHAR(10)+
		"	@nBankingCategory	= BankingCategory,"+CHAR(10)+
		"	@bReportByTransDate 	= ReportByTransDate,"+CHAR(10)+
		"	@bReportByPostDate 	= ReportByPostDate,"+CHAR(10)+
		"	@bReportByPostPeriod 	= ReportByPostPeriod,"+CHAR(10)+
		"	@bSortTransDate 	= SortTransDate,"+CHAR(10)+
		"	@bSortPostDate	 	= SortPostDate,"+CHAR(10)+
		"	@bSortAcctName	 	= SortAcctName,"+CHAR(10)+
		"	@bIncludeWithdrawals 	= IncludeWithdrawals,"+CHAR(10)+
		"	@bIncludeDeposits 	= IncludeDeposits,"+CHAR(10)+
		"	@bShowReversed 		= ShowReversed"+CHAR(10)+
	
		"from	OPENXML (@idoc, '/Filter',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	EntityNo		int		'cmbEntity/text()',"+CHAR(10)+
		"	DateFrom		datetime	'dfDateFrom/text()',"+CHAR(10)+
		"	DateTo			datetime	'dfDateTo/text()',"+CHAR(10)+
		"	PeriodFrom		int		'dfPostPeriodFrom/text()',"+CHAR(10)+
		"	PeriodTo		int		'dfPostPeriodTo/text()',"+CHAR(10)+
		"	BankAcctId		nvarchar(35)	'cmbBankAccount/text()',"+CHAR(10)+
		"	AccountName		int		'dfAcctName/text()',"+CHAR(10)+
		"	EnteredByStaff		int		'dfEnteredBy/text()',"+CHAR(10)+
		"	ReferenceFrom		nvarchar(30)	'dfReferenceFrom/text()',"+CHAR(10)+
		"	ReferenceTo		nvarchar(30)	'dfReferenceTo/text()',"+CHAR(10)+
		"	LocalFrom		decimal(13,2)	'dfLocalAmountFrom/text()',"+CHAR(10)+
		"	LocalTo			decimal(13,2)	'dfLocalAmountTo/text()',"+CHAR(10)+
		"	BankedFrom		decimal(13,2)	'dfBankAmountFrom/text()',"+CHAR(10)+
		"	BankedTo		decimal(13,2)	'dfBankAmountTo/text()',"+CHAR(10)+
		"	BankingCategory		Int		'cmbCategory/text()',"+CHAR(10)+
		"	ReportByTransDate	bit		'rbTransactionDate/text()',"+CHAR(10)+
		"	ReportByPostDate	bit		'rbPostDate/text()',"+CHAR(10)+
		"	ReportByPostPeriod	bit		'rbPostPeriod/text()',"+CHAR(10)+
		"	SortTransDate 		bit		'rbSortTransDate/text()',"+CHAR(10)+
		"	SortPostDate		bit		'rbSortPostDate/text()',"+CHAR(10)+
		"	SortAcctName		bit		'rbSortAcctName/text()',"+CHAR(10)+
		"	IncludeWithdrawals	bit		'cbWithdrawal/text()',"+CHAR(10)+
		"	IncludeDeposits		bit		'cbDeposit/text()',"+CHAR(10)+
		"	ShowReversed		bit		'cbIncludeReversed/text()'"+CHAR(10)+
		"	     )"
	
		exec @nErrorCode = sp_executesql @sSql,
					N'@idoc			int,
					@nEntityNo		int			output,
					@dtDateFrom		datetime		output,
					@dtDateTo		datetime		output,
					@nPeriodFrom		int			output,
					@nPeriodTo		int			output,
					@sBankAcctId		nvarchar(35)		output,
					@nAccountName		int			output,
					@nEnteredByStaff	int			output,
					@sReferenceFrom		nvarchar(30)		output,
					@sReferenceTo		nvarchar(30)		output,
					@nLocalFrom		decimal(13,2)		output,
					@nLocalTo		decimal(13,2)		output,
					@nBankedFrom		decimal(13,2)		output,
					@nBankedTo		decimal(13,2)		output,
					@nBankingCategory	int			output,
					@bReportByTransDate	bit			output,
					@bReportByPostDate	bit			output,
					@bReportByPostPeriod	bit			output,
					@bSortTransDate 	bit			output,
					@bSortPostDate		bit			output,
					@bSortAcctName		bit			output,
					@bIncludeWithdrawals	bit			output,
					@bIncludeDeposits	bit			output,
					@bShowReversed		bit			output',
					@idoc			= @idoc,
					@nEntityNo		= @nEntityNo		output,
					@dtDateFrom		= @dtDateFrom		output,
					@dtDateTo		= @dtDateTo		output,
					@nPeriodFrom		= @nPeriodFrom		output,
					@nPeriodTo		= @nPeriodTo		output,
					@sBankAcctId		= @sBankAcctId		output,
					@nAccountName		= @nAccountName		output,
					@nEnteredByStaff	= @nEnteredByStaff	output,
					@sReferenceFrom		= @sReferenceFrom	output,
					@sReferenceTo		= @sReferenceTo		output,
					@nLocalFrom		= @nLocalFrom		output,
					@nLocalTo		= @nLocalTo		output,
					@nBankedFrom		= @nBankedFrom		output,
					@nBankedTo		= @nBankedTo		output,
					@nBankingCategory	= @nBankingCategory	output,
					@bReportByTransDate	= @bReportByTransDate	output,
					@bReportByPostDate	= @bReportByPostDate	output,
					@bReportByPostPeriod	= @bReportByPostPeriod	output,
					@bSortTransDate 	= @bSortTransDate 	output,
					@bSortPostDate		= @bSortPostDate	output,
					@bSortAcctName		= @bSortAcctName	output,
					@bIncludeWithdrawals	= @bIncludeWithdrawals	output,
					@bIncludeDeposits	= @bIncludeDeposits	output,
					@bShowReversed		= @bShowReversed	output
	End
End


If @nErrorCode = 0
Begin

	Insert into #TRANSTYPEINC(TRANTYPEID)
	Select  colCode   
	from	OPENXML(@idoc, '/Filter/tblTransactionTypes/Row', 2)
		WITH (colCode		int	'colCode/text()')

	Set	@nErrorCode = @@Error

End

If @nErrorCode = 0
Begin
	Insert into #PAYMENTMETHODINC(METHODID)
	Select  colnMethodId   
	from	OPENXML(@idoc, '/Filter/tblPaymentMethod/Row', 2)
		WITH (colnMethodId		int	'colnMethodId/text()')

		Set	@nErrorCode = @@Error
End


Exec sp_xml_removedocument @idoc

If @nErrorCode = 0
Begin

	-- Set the base SQL table joins first.
	Set @sSql = "
		Select	BN.NAME, 
			Case	when BA.IBAN is null then BA.ACCOUNTNO
				else BA.IBAN
				end + CHAR(32) + BA.DESCRIPTION as BADESCRIPTION,
			BA.CURRENCY, SC.COLCHARACTER,
	
			CAST(AN.NAME + Case	when AN.NAMECODE is NULL then NULL
						else ' {' + AN.NAMECODE + '}' 
					end as NVARCHAR(254)) as ACCOUNTNAME, 
	
			CAST(EN.NAME + (Case	when EN.FIRSTNAME is not NULL
						then ', ' + EN.FIRSTNAME
					end) as NVARCHAR(254)) as ENTEREDBY,
	
			B.TRANSDATE,B.POSTDATE, P.LABEL, TT.DESCRIPTION, PM.PAYMENTDESCRIPTION, 
			ISNULL(CI.ITEMREFNO, B.REFERENCE) AS REFERENCE, 
			Case when CI.PAYMENTCURRENCY is not null then CI.PAYMENTCURRENCY
			     when B.PAYMENTCURRENCY is not null then B.PAYMENTCURRENCY
			     else BA.CURRENCY
			end AS PAYMENTCURRENCY,
			ISNULL(	ISNULL(CI.PAYMENTAMOUNT, B.PAYMENTAMOUNT ), 
				ISNULL(CI.BANKAMOUNT, B.BANKAMOUNT)) AS PAYMENTAMOUNT, 
			ISNULL(CI.LOCALAMOUNT, B.LOCALAMOUNT) AS LOCALAMOUNT, 
			ISNULL(ISNULL(ISNULL(CI.DISSECTIONEXCHANGE, B.BANKEXCHANGERATE), B.LOCALEXCHANGERATE), 1) AS EXCHANGERATE, 
			ISNULL(CI.BANKAMOUNT, B.BANKAMOUNT) AS BANKAMOUNT, 
			ISNULL(CI.BANKCHARGES, B.BANKCHARGES) AS BANKCHARGES, 
			ISNULL(CI.BANKNET, B.BANKNET) AS BANKNET,
			B.REFENTITYNO"
	
	Set @sSqlFrom = "
		FROM  BANKHISTORY B"

	If (@bShowReversed = 1)
	Begin
		Set @sSqlFrom = @sSqlFrom + "
		LEFT JOIN BANKHISTORY B1 		on (B1.SEQUENCENO = B.SEQUENCENO
							and B1.ASSOCLINENO = B.HISTORYLINENO
							and B1.BANKNAMENO = B.BANKNAMENO
							and B1.ENTITYNO = B.ENTITYNO
							and B1.SEQUENCENO = B.SEQUENCENO)"
	End

	Set @sSqlFrom = @sSqlFrom + "
		LEFT JOIN CASHITEM CI	 		on (CI.BANKEDBYENTITYNO = B.REFENTITYNO 
							and CI.BANKEDBYTRANSNO = B.REFTRANSNO
							AND NOT (B.TRANSTYPE IN (704, 705) AND B.PAYMENTMETHOD = -2))
		JOIN BANKACCOUNT BA 			on (BA.ACCOUNTOWNER = B.ENTITYNO 
							and BA.BANKNAMENO = B.BANKNAMENO 
							and BA.SEQUENCENO = B.SEQUENCENO )
		LEFT JOIN (select distinct REFENTITYNO, REFTRANSNO, ACCTNAMENO
			   from CASHHISTORY) CH		on (CH.REFENTITYNO = B.REFENTITYNO
							and CH.REFTRANSNO = B.REFTRANSNO 
							AND NOT (B.TRANSTYPE IN (704, 705) AND B.PAYMENTMETHOD = -2))
		LEFT JOIN BANKINGCATEGORY BC		on (BC.BANKCATEGORY = B.BANKCATEGORY )   
		LEFT JOIN PAYMENTMETHODS PM	 	on (PM.PAYMENTMETHOD = B.PAYMENTMETHOD )   
		JOIN ACCT_TRANS_TYPE TT 		on (TT.TRANS_TYPE_ID = B.TRANSTYPE )  
		LEFT JOIN PERIOD P			on (P.PERIODID = B.POSTPERIOD)
		JOIN TRANSACTIONHEADER T 		on (T.ENTITYNO = B.REFENTITYNO
							and T.TRANSNO = B.REFTRANSNO)
		JOIN NAME N 				on (N.NAMENO = B.REFENTITYNO)
		JOIN NAME BN 				on (BN.NAMENO = B.BANKNAMENO)
		LEFT JOIN NAME AN 			on (AN.NAMENO = ISNULL(CI.ACCTNAMENO,CH.ACCTNAMENO))
		LEFT JOIN NAME EN 			on (EN.NAMENO = T.EMPLOYEENO)
		JOIN SITECONTROL SC 			on (SC.CONTROLID = 'CURRENCY')"
	
	--Set the basic Where
	Set @sSqlWhere = '
		Where B.ENTITYNO = ' + CAST(@nEntityNo as NVARCHAR(11))
	
	--Set the additional filter criteria
	-- Date Range
	--CHAR(39) returns single quote (')
	If (@dtDateFrom is not NULL)
	Begin
		if (@bReportByTransDate = 1)
		Begin
			Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(NVARCHAR,B.TRANSDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtDateFrom,112) + CHAR(39)
		end	
		else If (@bReportByPostDate = 1)
		Begin
			Set @sSqlWhere = @sSqlWhere + '
			and CAST(CONVERT(NVARCHAR,B.POSTDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@dtDateFrom,112) + CHAR(39)
		End
	End
	
	If (@dtDateTo is not NULL)
	Begin
		 
		if (@bReportByTransDate = 1)
			Set @sSqlWhere = @sSqlWhere +'
			and CAST(CONVERT(NVARCHAR,B.TRANSDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtDateTo,112)+ CHAR(39)
		Else if (@bReportByPostDate = 1) 
			Set @sSqlWhere = @sSqlWhere +'
			and CAST(CONVERT(NVARCHAR,B.POSTDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@dtDateTo,112) + CHAR(39)
	End
	
	-- Period Range
	If (@bReportByPostPeriod = 1)
	Begin
	
		If (@nPeriodFrom is not NULL) 
		Begin
		
			Set @sSqlWhere = @sSqlWhere + '
			and B.POSTPERIOD >= @nPeriodFrom'
		End
		
		If (@nPeriodTo is not NULL) 
		Begin
			Set @sSqlWhere = @sSqlWhere + '
			and B.POSTPERIOD <= @nPeriodTo'
		End
	End
	
	-- Bank Account
	--CHAR(39) returns single quote (')
	If (@sBankAcctId is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and CAST(BA.ACCOUNTOWNER as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) +
			' + CAST(BA.BANKNAMENO as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) + 
			' + CAST(BA.SEQUENCENO as NVARCHAR(11)) = ' + CHAR(39) + @sBankAcctId + CHAR(39)
	End
		
	-- AccountName
	If (@nAccountName is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and isnull(CI.ACCTNAMENO,CH.ACCTNAMENO) = ' + CAST(@nAccountName as NVARCHAR(11))
			
	End
	
	-- Entered by Staff
	If (@nEnteredByStaff is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and T.EMPLOYEENO = ' + CAST(@nEnteredByStaff as NVARCHAR(11))
	End
	
	-- Reference Range
	If (@sReferenceFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ISNULL(CI.ITEMREFNO, B.REFERENCE) >= ' + CHAR(39) + @sReferenceFrom + CHAR(39) + ')'
	End
	
	If (@sReferenceTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ISNULL(CI.ITEMREFNO, B.REFERENCE) <= ' + CHAR(39) + @sReferenceTo + CHAR(39) + ')'
	End

	-- Local Amount Range
	If (@nLocalFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ABS(ISNULL( CI.LOCALAMOUNT, B.LOCALAMOUNT )) >= ABS(' + CAST(@nLocalFrom as NVARCHAR(20)) + '))'
	End
	
	If (@nLocalTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ABS(ISNULL( CI.LOCALAMOUNT, B.LOCALAMOUNT )) <= ABS(' + CAST(@nLocalTo as NVARCHAR(20)) + '))' 
	End
	
	
	-- Bank Amount range
	If (@nBankedFrom is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ABS(ISNULL( CI.BANKAMOUNT, B.BANKAMOUNT )) >= ABS(' + CAST(@nBankedFrom as NVARCHAR(20)) + '))'
	End
	
	If (@nBankedTo is not NULL)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (ABS(ISNULL( CI.BANKAMOUNT, B.BANKAMOUNT )) <= ABS(' + CAST(@nBankedTo as NVARCHAR(20)) + '))' 
	End
	
	-- Banking Category
	If (@nBankingCategory is not NULL)	
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (B.BANKCATEGORY = ' + CAST(@nBankingCategory as NVARCHAR(10)) + ')' 
	End


	-- Set the command ids to include
	If (@bIncludeWithdrawals = 1 and @bIncludeDeposits = 1)
	Begin
		Set @sIncludeCommands = '8,11,3'
	End
	Else If (@bIncludeWithdrawals = 1 and @bIncludeDeposits != 1)
	Begin
		Set @sIncludeCommands = '3'
	End
	Else If (@bIncludeDeposits = 1 and @bIncludeWithdrawals != 1)
	Begin
		Set @sIncludeCommands = '8,11'
	End

	--Entry Type
	Set @sSqlWhere = @sSqlWhere + '
	and (B.COMMANDID IN (' + @sIncludeCommands + ')'

	If @bShowReversed = 1
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			OR (B.COMMANDID = 99 AND B1.COMMANDID IN (' + @sIncludeCommands + ')))
			and (B.STATUS in (1,9))'
	End
	Else
	Begin
		Set @sSqlWhere = @sSqlWhere + ')
			and (B.STATUS = 1)'
	End

/*

	--Entry Type
	If (@bIncludeWithdrawals = 1 AND @bIncludeDeposits = 1)
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and (B.COMMANDID = 8 OR B.COMMANDID = 3)'
	End
	Else If @bIncludeWithdrawals = 1 
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and B.COMMANDID = 3'
	End
	Else If @bIncludeDeposits = 1
	Begin
		Set @sSqlWhere = @sSqlWhere + '
			and B.COMMANDID = 8'
	
	End
	
	-- Set Show Reversals Option
	If @bShowReversed = 1
		Set @sSqlWhere = @sSqlWhere + '
			and (B.STATUS = 1 OR B.STATUS = 9)'
	Else
	-- Still exclude draft transactions
		Set @sSqlWhere = @sSqlWhere + '
			and (B.STATUS = 1)'
	
*/
	if @pbCalledFromCentura = 0
	Begin
		Select * from #TRANSTYPEINC
		Select * from #PAYMENTMETHODINC
	End

	-- restrict to transaction types specified
	If exists (Select * from #TRANSTYPEINC) 
		Set @sSqlWhere = @sSqlWhere + '
			and B.TRANSTYPE IN (Select TRANTYPEID from #TRANSTYPEINC)'

	-- restrict to payment methods specified
	If exists (Select * from #PAYMENTMETHODINC)
		Set @sSqlWhere = @sSqlWhere + '
			and B.PAYMENTMETHOD IN (Select METHODID from #PAYMENTMETHODINC)' 


	-- Sort order by
	Set @sSqlWhere = @sSqlWhere + '
		order by B.ENTITYNO, BN.NAME, BADESCRIPTION, PAYMENTCURRENCY'
	
	If @bSortTransDate = 1
		Set @sSqlWhere = @sSqlWhere + ', B.TRANSDATE'
	Else If @bSortPostDate = 1
		Set @sSqlWhere = @sSqlWhere + ', B.POSTDATE'
	Else If @bSortAcctName = 1
		Set @sSqlWhere = @sSqlWhere + ', ACCOUNTNAME'


	Set @sSql = @sSql + @sSqlFrom + @sSqlWhere

	If @pbCalledFromCentura = 0
		Select @sSql

	Exec @nErrorCode=sp_executesql @sSql, 
			N'@nEntityNo		int,
			@dtDateFrom		datetime,
			@dtDateTo		datetime,
			@nPeriodFrom		int,
			@nPeriodTo		int,
			@sBankAcctId		nvarchar(35),
			@nAccountName		int,
			@nEnteredByStaff	int,
			@sReferenceFrom		nvarchar(30),
			@sReferenceTo		nvarchar(30),
			@nLocalFrom		decimal(13,2),
			@nLocalTo		decimal(13,2),
			@nBankedFrom		decimal(13,2),
			@nBankedTo		decimal(13,2)',
			@nEntityNo		= @nEntityNo,
			@dtDateFrom		= @dtDateFrom,
			@dtDateTo		= @dtDateTo,
			@nPeriodFrom		= @nPeriodFrom,
			@nPeriodTo		= @nPeriodTo,
			@sBankAcctId		= @sBankAcctId,
			@nAccountName		= @nAccountName,
			@nEnteredByStaff	= @nEnteredByStaff,
			@sReferenceFrom		= @sReferenceFrom,
			@sReferenceTo		= @sReferenceTo,
			@nLocalFrom		= @nLocalFrom,
			@nLocalTo		= @nLocalTo,
			@nBankedFrom		= @nBankedFrom,
			@nBankedTo		= @nBankedTo
End

DROP TABLE #TRANSTYPEINC
DROP TABLE #PAYMENTMETHODINC

Return @nErrorCode
GO

Grant execute on dbo.cb_ListBankHistory to public
GO
