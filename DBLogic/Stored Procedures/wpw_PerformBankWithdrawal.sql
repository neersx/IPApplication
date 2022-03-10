-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_PerformBankWithdrawal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wpw_PerformBankWithdrawal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.wpw_PerformBankWithdrawal.'
	drop procedure dbo.wpw_PerformBankWithdrawal
End
print '**** Creating Stored Procedure dbo.wpw_PerformBankWithdrawal...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wpw_PerformBankWithdrawal
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	@psFeeType			nvarchar(6)	= null,
	@pnCaseKey			int		= null,
	@pdtTransDate			datetime	= null,
	@pnEntityKey			int		= null,
	@pdtWhenRequested		datetime	= null
	
	
)
as		
-- PROCEDURE :	wpw_PerformBankWithdrawal
-- VERSION :	9
-- DESCRIPTION:	Make adjustment(s) Bank Account balance.
-- CALLED BY :	Inprotech Web

-- MODIFICTIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 15 Jul 2014	KR	RFC9012		1	Procedure created.
-- 19 Aug 2014	KR	RFC9012		2	Adjusted calculation updating BANKACCOUNT.ACCOUNTBALANCE
-- 29 Aug 2014	KR	RFC9012		3	Fixed issue where the @sCountryCode was set to varchar(2)
-- 28 May 2015	KR	R47797		4	Fixed the declaration for @nLocalCurrencyExchRate
-- 01 Jun 2016	KR	R47797		5	Fixed the bank local calculation
-- 02 Jun 2015	KR	R47797		6	Fixed so that the correct row is picked up form the feelistcase
--						also passing WhenRequested date from wp_PostWip to avoid concurrency issues
-- 09 Oct 2015	DL	R53867		7	Ledger Journal is swapping the local and foreign currency amount
-- 08 Aug 2017	DL	R72092		8	Record WIP is updating incorrect bank account when Entity is incorrect
-- 21 May 2018	AK	R71884		9	applied check for @bFeesListAutocreateAndFinaliseSiteControl and bankaccountno, fixed logic

SET CONCAT_NULL_YIELDS_NULL OFF

-- This must be off if the procedure does multiple inserts/updates/deletes (For concurrency checking).
SET NOCOUNT OFF

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int
Declare @sLookupCulture	nvarchar(10)
Declare @sAlertXML		nvarchar(1000)
Declare @nRowCount		int
Declare @bDebug			bit
Declare	@nBankNameNo		int
Declare @nAccountSeqNo		int
Declare	@nAccountBalance	decimal(13,2)
Declare	@nTotalFee		decimal(13,2)
Declare @sAcctTypeBankDoesNotExist nvarchar(80)
Declare @sAcctTypeFeeListDoesNotExist nvarchar(80)
Declare @sCountryCode		nvarchar(3)
Declare @nRegisteredFlag	decimal(5,1)
Declare	@sFeeCurrencyCode	nvarchar(3)
Declare @nTaxable		decimal(5,1)
Declare @nOfficeId		int
Declare @sCaseCategory		nvarchar(2)
Declare	@nFeeListNo		int
Declare @nNewFeeListNo		int
Declare @bVerifyFeeListFund	bit
Declare @sIPOfficeSiteControl	nvarchar(15)
Declare @sIPOffice		varchar(256)
Declare @sFeeListNameType	varchar(256)
Declare @nFeeListName		int
Declare @nIPOffice		int
Declare @sPropertyType		nchar(1)
Declare @nLocalTotalFee		decimal(13,2)	
Declare @nBuyRate		dec(11,4)
Declare @nSellRate		dec(11,4)
Declare @nForeignDecimalPlaces	tinyint
Declare @nBankAmountLocal	decimal(13,2)
Declare @nBankCurrencyExchRate	dec(11,4)
Declare @nBankAmountForeign	decimal(13,2)
Declare @nCABAccountId		int
Declare @sCABProfitCentre	nvarchar(6)
Declare @LocalAmount		decimal(13,2)
Declare @nCreditDefaultAccountId	int
Declare @nCreditAcountId		int
Declare @nControlAcctTypeId		int
Declare @sCreditProfitCentreCode	nvarchar(6)
Declare @nEmployeeNo			int
Declare @sLoginId			nvarchar(50)	
Declare @nPostPeriod			int
Declare @nLedgerSeqNo			int
Declare	@nNewBankHistoryLineNo		int
Declare	@nSessionId			int
Declare @nTransNo			int
Declare	@sBankCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		int
Declare @sHomeCurrency			nvarchar(3)
Declare @nGLJournalCreation		int
Declare	@nLocalCurrencyExchRate		decimal(10,4)
Declare	@nResult			int
Declare @bVerifyFeeListFunds		bit
Declare @nFeeListitem			int
Declare @nAccountOwner			int
declare @nTranCountStart	int
Declare @bFeesListAutocreateAndFinaliseSiteControl bit

-- initialise variables
Set @bDebug = 0
Set @nRowCount = 0
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

if @nErrorCode = 0
Begin
			
			Set @sSQLString = "
			Select @bFeesListAutocreateAndFinaliseSiteControl = COLBOOLEAN
			From SITECONTROL
			Where CONTROLID = 'FeesList Autocreate & Finalise'"

			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@bFeesListAutocreateAndFinaliseSiteControl	bit 	OUTPUT',				
				@bFeesListAutocreateAndFinaliseSiteControl = @bFeesListAutocreateAndFinaliseSiteControl	OUTPUT					
			
End

If @nErrorCode=0
Begin
	Set @sSQLString = "Select 
			@nAccountOwner = ACCOUNTOWNER,
			@nBankNameNo = BANKNAMENO,
			@nAccountSeqNo = ACCOUNTSEQUENCENO
			From FEETYPES
			Where FEETYPE = @psFeeType"
	exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nAccountOwner int OUTPUT,
			@nBankNameNo	int	OUTPUT,
			@nAccountSeqNo	int	OUTPUT,
			@psFeeType	nvarchar(6)',
			@nAccountOwner	=	@nAccountOwner OUTPUT,
			@nBankNameNo	=	@nBankNameNo OUTPUT,
			@nAccountSeqNo	=	@nAccountSeqNo OUTPUT,
			@psFeeType	=	@psFeeType
						
	
	if @bFeesListAutocreateAndFinaliseSiteControl = 1 and
	   (@nBankNameNo is null or
		@nAccountOwner is null )
		Begin
			If @nErrorCode = 0
					Begin						
						set @nErrorCode = 1
						Set @sAlertXML = dbo.fn_GetAlertXML('AC225', 'A bank account is currently not selected for the applicable fee list to perform a bank withdrawal. Please select an appropriate bank account against the fee list.' ,
    								null, null, null, null, null)
  						RAISERROR(@sAlertXML, 16, 1)
						return @nErrorCode
  					End
		End 

	-- The bank widthrawal is from the Bank AccountOwner, thus all transaction data is to be recorded under the same entity. 	
	set @pnEntityKey = @nAccountOwner

	if @nErrorCode = 0 and @nBankNameNo is not null
	Begin
		Set @sSQLString = "
			Select @bVerifyFeeListFunds = isnull(COLBOOLEAN,0)
			From SITECONTROL
			Where CONTROLID = 'VerifyFeeListFunds'"

		exec	@nErrorCode = sp_executesql @sSQLString,
					N'@bVerifyFeeListFunds	bit 			OUTPUT',
					@bVerifyFeeListFunds = @bVerifyFeeListFunds	OUTPUT
					
		if @nErrorCode = 0 
		Begin
			Set @sSQLString = "Select @nAccountBalance = ACCOUNTBALANCE,
						  @sBankCurrencyCode = CURRENCY
			From BANKACCOUNT
			Where ACCOUNTOWNER = @pnEntityKey
			And   BANKNAMENO = @nBankNameNo
			And   SEQUENCENO = @nAccountSeqNo"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnEntityKey		int,
				@nBankNameNo		int,
				@nAccountSeqNo		int,
				@sBankCurrencyCode	nvarchar(3) OUTPUT,
				@nAccountBalance	decimal(13,2) OUTPUT',
				@pnEntityKey		=	@pnEntityKey,
				@nBankNameNo		=	@nBankNameNo,
				@nAccountSeqNo		=	@nAccountSeqNo,
				@sBankCurrencyCode	=	@sBankCurrencyCode OUTPUT,
				@nAccountBalance	=	@nAccountBalance OUTPUT	
			
						
			if @nErrorCode = 0 
			Begin			
				Set @sSQLString = "Select top 1 @nTotalFee = TOTALFEE,
				@nFeeListitem = FEELISTITEM
				From FEELISTCASE
				Where	CASEID	= @pnCaseKey
				And	FEETYPE = @psFeeType 
				And	WHENREQUESTED = @pdtWhenRequested"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey	int,
					@psFeeType	nvarchar(6),
					@pdtWhenRequested datetime,
					@nTotalFee	decimal(13,2) OUTPUT,
					@nFeeListitem	int	OUTPUT',
					@pnCaseKey	=	@pnCaseKey,
					@psFeeType	=	@psFeeType,
					@pdtWhenRequested = @pdtWhenRequested,
					@nTotalFee	=	@nTotalFee OUTPUT,
					@nFeeListitem	= @nFeeListitem OUTPUT
			End
			
			
			If @nErrorCode = 0  and @bVerifyFeeListFund = 1 and @nAccountBalance > @nTotalFee
			Begin	
				If not exists (Select 1
				From DEFAULTACCOUNT
				Where CONTROLACCTYPEID = 8701)
				Begin
					Set @sSQLString = "Select @sAcctTypeBankDoesNotExist = DESCRIPTION
					From TABLECODES
					Where TABLECODE = 8701"
					
					exec	@nErrorCode = sp_executesql @sSQLString,
						N'@sAcctTypeBankDoesNotExist nvarchar(80) OUTPUT',
						@sAcctTypeBankDoesNotExist = @sAcctTypeBankDoesNotExist OUTPUT
					
					If @nErrorCode = 0
					Begin
						Set @sAlertXML = dbo.fn_GetAlertXML('AccountTypeBankDoesNotExist', @sAcctTypeBankDoesNotExist ,
    								null, null, null, null, null)
  						RAISERROR(@sAlertXML, 14, 1)
  					End
				End
				
				If not exists (Select 1
				From DEFAULTACCOUNT
				Where CONTROLACCTYPEID = -42846974)
				Begin
					Set @sSQLString =  "Select @sAcctTypeFeeListDoesNotExist = DESCRIPTION
					From TABLECODES
					Where TABLECODE = -42846974"
					
					exec	@nErrorCode = sp_executesql @sSQLString,
						N'@sAcctTypeFeeListDoesNotExist nvarchar(80) OUTPUT',
						@sAcctTypeFeeListDoesNotExist = @sAcctTypeFeeListDoesNotExist OUTPUT
					If @nErrorCode = 0
					Begin
						Set @sAlertXML = dbo.fn_GetAlertXML('AccountTypeBankDoesNotExist', @sAcctTypeFeeListDoesNotExist,
    							null, null, null, null, null)
  						RAISERROR(@sAlertXML, 14, 1)
  					End
				End
			    End			
				
			End
		End
		
		
		If @nErrorCode = 0
		Begin
			Set @sSQLString =  "Select 
			@sCountryCode = C.COUNTRYCODE, 
			@nRegisteredFlag = Case when FT.REPORTFORMAT = 'B' then 1 else 0 end,
			@sFeeCurrencyCode = F.CURRENCY,
			@nTaxable = Case when isnull(F.TAXAMOUNT,0) > 0 THEN 1 else 0 end,
			@sPropertyType = C.PROPERTYTYPE, 
			@nOfficeId = C.OFFICEID, 
			@sCaseCategory = C.CASECATEGORY
			From FEELISTCASE F
			Join CASES C ON	(F.CASEID = C.CASEID)
			Join FEETYPES FT ON (F.FEETYPE = FT.FEETYPE)
			Where F.FEETYPE = @psFeeType
			And   F.CASEID = @pnCaseKey
			And   F.WHENREQUESTED = @pdtWhenRequested
			And   F.FEELISTITEM = @nFeeListitem"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@sCountryCode		nvarchar(3)	OUTPUT,
			@nRegisteredFlag	decimal(5,1)	OUTPUT,
			@sFeeCurrencyCode		nvarchar(3)	OUTPUT,
			@nTaxable		decimal(5,1)	OUTPUT,
			@sPropertyType		char(1)		OUTPUT,
			@nOfficeId		int		OUTPUT,
			@sCaseCategory		nvarchar(2)	OUTPUT,
			@psFeeType		nvarchar(6),
			@pnCaseKey		int,
			@pdtWhenRequested	datetime,
			@nFeeListitem		int',
			@sCountryCode		= @sCountryCode		OUTPUT,
			@nRegisteredFlag	= @nRegisteredFlag	OUTPUT,
			@sFeeCurrencyCode		= @sFeeCurrencyCode		OUTPUT,
			@nTaxable		= @nTaxable		OUTPUT,
			@sPropertyType		= @sPropertyType		OUTPUT,
			@nOfficeId		= @nOfficeId		OUTPUT,
			@sCaseCategory		= @sCaseCategory	OUTPUT,
			@psFeeType		= @psFeeType,
			@pnCaseKey		= @pnCaseKey,
			@pdtWhenRequested	= @pdtWhenRequested,
			@nFeeListitem		= @nFeeListitem	
			
			print @sSQLString
			print @psFeeType
			print @pnCaseKey
			print @pdtWhenRequested
			print @nFeeListitem
			print @sCountryCode

			if @nErrorCode = 0
			Begin
				set @sIPOfficeSiteControl =  'IPOffice' + @sCountryCode + @sPropertyType
				
				Set @sSQLString = "
				Select @sIPOffice = COLCHARACTER
				From SITECONTROL
				Where CONTROLID = @sIPOfficeSiteControl"

				exec	@nErrorCode = sp_executesql @sSQLString,
					N'@sIPOffice	varchar(256) 	OUTPUT,
					@sIPOfficeSiteControl varchar(30)',
					@sIPOffice = @sIPOffice	OUTPUT,
					@sIPOfficeSiteControl = @sIPOfficeSiteControl
					
				Set @sSQLString = "
				Select @sFeeListNameType = COLCHARACTER
				From SITECONTROL
				Where CONTROLID = 'FeeListNameType'"

				exec	@nErrorCode = sp_executesql @sSQLString,
					N'@sFeeListNameType	varchar(256)	OUTPUT',
					@sFeeListNameType = @sFeeListNameType	OUTPUT
			End
			
			if @nErrorCode = 0 and @sFeeListNameType is not null
			Begin		
				Set @sSQLString = "Select @nFeeListName = N.NAMENO 
					From FEELISTCASE FC
					Left Join CASENAME CN on (CN.CASEID = FC.CASEID 
								and CN.NAMETYPE = @sFeeListNameType)
					Left Join NAME N on (N.NAMENO = CN.NAMENO)
					Where CN.CASEID = @pnCaseKey
					And ( not exists (SELECT	*
						FROM	CASENAME CN_1
						WHERE	CN_1.CASEID = CN.CASEID
						AND	CN_1.NAMETYPE = CN.NAMETYPE )
						or CN.SEQUENCE = (
						SELECT	MIN(SEQUENCE)
						FROM	CASENAME CN_2
						WHERE	CN_2.CASEID = CN.CASEID
						AND	CN_2.NAMETYPE = CN.NAMETYPE ))"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
					N'@nFeeListName		int	OUTPUT,
					@sFeeListNameType	nvarchar(3),
					@pnCaseKey		int'	,
					@nFeeListName		=	@nFeeListName OUTPUT,
					@sFeeListNameType	=	@sFeeListNameType,
					@pnCaseKey		=	@pnCaseKey
			End
						
			
			if (@nErrorCode = 0)
			Begin
			exec @nErrorCode = ip_GetLastInternalCode
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@psTable = 'FEELIST',
				@pnLastInternalCode	= @nNewFeeListNo OUTPUT,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pbIsInternalCodeNegative = 0
			End
			
			If @nErrorCode = 0
			Begin			
				Set @sSQLString = "Insert into FEELIST(FEELISTNO, COUNTRYCODE, REGISTEREDFLAG, CURRENCY, IPOFFICE, TAXABLE,
					PROPERTYTYPE, OFFICEID, CASECATEGORY, FEELISTNAME, DATEPRINTED)
				values (@nNewFeeListNo, @sCountryCode, @nRegisteredFlag, @sFeeCurrencyCode, @sIPOffice, @nTaxable,
					@sPropertyType, @nOfficeId, @sCaseCategory, @nFeeListName, getdate())"
					
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nNewFeeListNo	int,
				@sCountryCode		nvarchar(3),
				@nRegisteredFlag	decimal(5,1),
				@sFeeCurrencyCode	nvarchar(3),
				@sIPOffice		nvarchar(256),
				@nTaxable		decimal(5,1),
				@sPropertyType		nchar(1),
				@nOfficeId		int,	
				@sCaseCategory		nvarchar(2),	
				@nFeeListName		int',
				@nNewFeeListNo		= @nNewFeeListNo,
				@sCountryCode		= @sCountryCode,
				@nRegisteredFlag	= @nRegisteredFlag,
				@sFeeCurrencyCode	= @sFeeCurrencyCode,
				@sIPOffice		= @sIPOffice,
				@nTaxable		= @nTaxable,
				@sPropertyType		= @sPropertyType,
				@nOfficeId		= @nOfficeId,
				@sCaseCategory		= @sCaseCategory,
				@nFeeListName		= @nFeeListName
			End
						
	End
	
	-- Update FEELISTCASE with relevant details			
	If @nErrorCode = 0
	Begin				
		Set @sSQLString = "Update FEELISTCASE set FEELISTNO = @nNewFeeListNo
		Where CASEID = @pnCaseKey
		And   FEETYPE = @psFeeType
		And   WHENREQUESTED = @pdtWhenRequested
		And   FEELISTITEM = @nFeeListitem"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@nNewFeeListNo int,
		@pnCaseKey int,
		@psFeeType nvarchar(6),
		@pdtWhenRequested datetime,
		@nFeeListitem int',
		@nNewFeeListNo	 = @nNewFeeListNo,
		@pnCaseKey	= @pnCaseKey,
		@psFeeType	= @psFeeType,
		@nFeeListitem	= @nFeeListitem,
		@pdtWhenRequested = @pdtWhenRequested
	End
	

	if @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @sHomeCurrency = S.COLCHARACTER,
			@nLocalDecimalPlaces = isnull(C.DECIMALPLACES, 2)
		From SITECONTROL S
		Left join CURRENCY C on (C.CURRENCY = S.COLCHARACTER)
		Where S.CONTROLID = 'CURRENCY'"

		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@sHomeCurrency	varchar(256) 	OUTPUT,
			@nLocalDecimalPlaces int	OUTPUT',
			@sHomeCurrency = @sHomeCurrency	OUTPUT,
			@nLocalDecimalPlaces = @nLocalDecimalPlaces OUTPUT
	End
	
	-- Check if the fee currency is foreign - if so convert the fee to local currency
	if (@nErrorCode = 0 and @sFeeCurrencyCode = @sHomeCurrency)
	Begin
		Set @nLocalTotalFee = @nTotalFee
	End
	Else
	Begin
		exec @nErrorCode = dbo.ac_GetExchangeDetails
			@pnBuyRate		= @nBuyRate output,
			@pnSellRate		= @nSellRate output,
			@pnDecimalPlaces	= @nForeignDecimalPlaces output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psCurrencyCode		= @sFeeCurrencyCode,
			@pdtTransactionDate	= @pdtTransDate,
			@pbUseHistoricalRates	= 0,
			@pnCaseID		= @pnCaseKey
			
		
		Set @nLocalTotalFee = round(@nTotalFee/@nBuyRate, isnull(@nLocalDecimalPlaces, 2))
		Set @nLocalCurrencyExchRate = @nBuyRate
	End
	
	-- check if the bank currency is foreign and if so convert fee(from Local) to bank currency
	
	if (@nErrorCode = 0 and @sBankCurrencyCode = @sHomeCurrency)
	Begin
		Set @nBankAmountLocal = @nLocalTotalFee * -1
	End
	Else
	Begin
		exec @nErrorCode = dbo.ac_GetExchangeDetails
			@pnBuyRate		= @nBuyRate output,
			@pnSellRate		= @nSellRate output,
			@pnDecimalPlaces	= @nForeignDecimalPlaces output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psCurrencyCode		= @sBankCurrencyCode,
			@pdtTransactionDate	= @pdtTransDate,
			@pbUseHistoricalRates	= 0,
			@pnCaseID		= @pnCaseKey
			
		set @nBankCurrencyExchRate = @nBuyRate
		
		-- RFC53867
		-- Set @nBankAmountLocal = round(@nLocalTotalFee * @nBuyRate, isnull(@nLocalDecimalPlaces, 2)) * -1 /*Amount in the bank's currency*/
		-- Set @nBankAmountForeign = round(@nLocalTotalFee, @nForeignDecimalPlaces) * -1			 /*Amount in WIP currency*/

		Set @nBankAmountLocal = round(@nTotalFee, isnull(@nLocalDecimalPlaces, 2)) * -1				/*Amount in the bank's currency*/
		Set @nBankAmountForeign = round(@nTotalFee, isnull(@nForeignDecimalPlaces, 2)) * -1			/*Foreign amount for ledger journal line*/
	End
	
	if @nErrorCode = 0
	Begin
		Set @sSQLString = "Select	@nCABAccountId = CABACCOUNTID,
			@sCABProfitCentre = CABPROFITCENTRE,
			@LocalAmount = LOCALBALANCE				
			From	BANKACCOUNT
			Where	ACCOUNTOWNER = @pnEntityKey
			And   BANKNAMENO = @nBankNameNo
			And   SEQUENCENO = @nAccountSeqNo"
	
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nCABAccountId	int		OUTPUT,
			@sCABProfitCentre	nvarchar(6)	OUTPUT,
			@LocalAmount		decimal(13,2)	OUTPUT,			
			@pnEntityKey	int,
			@nBankNameNo	int,
			@nAccountSeqNo	int',
			@nCABAccountId  = @nCABAccountId OUTPUT,
			@sCABProfitCentre = @sCABProfitCentre OUTPUT,
			@LocalAmount	= @LocalAmount OUTPUT,
			@pnEntityKey	= @pnEntityKey,
			@nBankNameNo	= @nBankNameNo,
			@nAccountSeqNo	= @nAccountSeqNo
			
		if ( @nCABAccountId is null OR @sCABProfitCentre is null)
		Begin
			Set @sSQLString = "SELECT
			@nCABAccountId = a.ACCOUNTID,
			@sCABProfitCentre = a.PROFITCENTRECODE 
			FROM DEFAULTACCOUNT a, LEDGERACCOUNT b 
			WHERE a.ENTITYNO = @pnEntityKey AND a.CONTROLACCTYPEID = 8701 
			and b.ACCOUNTID = a.ACCOUNTID 
			and b.ISACTIVE = 1 
			and not exists (Select 1 from LEDGERACCOUNT d
			where b.ACCOUNTID = d.PARENTACCOUNTID)"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nCABAccountId	int	OUTPUT,
			@sCABProfitCentre	varchar(6) OUTPUT,
			@pnEntityKey		int',
			@nCABAccountId		= @nCABAccountId OUTPUT,
			@sCABProfitCentre	= @sCABProfitCentre OUTPUT,
			@pnEntityKey		= @pnEntityKey
		End
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "Select 
			@nCreditDefaultAccountId = a.DEFAULTACCOUNTID, 
			@nCreditAcountId = a.ACCOUNTID, 
			@nControlAcctTypeId = a.CONTROLACCTYPEID,
			@sCreditProfitCentreCode = a.PROFITCENTRECODE
			From DEFAULTACCOUNT a, LEDGERACCOUNT b
			Where
			a.ENTITYNO = @pnEntityKey
			AND a.CONTROLACCTYPEID = -42846974 
			and b.ACCOUNTID = a.ACCOUNTID 
			and b.ISACTIVE = 1 
			and not exists (Select 1 from LEDGERACCOUNT d
			where b.ACCOUNTID = d.PARENTACCOUNTID)"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nCreditDefaultAccountId int OUTPUT,
			@nCreditAcountId int OUTPUT,
			@nControlAcctTypeId int OUTPUT,
			@sCreditProfitCentreCode nvarchar(6) OUTPUT,
			@pnEntityKey	int',
			@nCreditDefaultAccountId = @nCreditDefaultAccountId OUTPUT,
			@nCreditAcountId = @nCreditAcountId OUTPUT,
			@nControlAcctTypeId = @nControlAcctTypeId OUTPUT,
			@sCreditProfitCentreCode = @sCreditProfitCentreCode OUTPUT,
			@pnEntityKey = @pnEntityKey
		End
		
		-- get the employee no and login id based the @pnUserIdentityId
		if (@nErrorCode = 0)
		Begin
			Select @nEmployeeNo = NAMENO, @sLoginId = LOGINID from USERIDENTITY where IDENTITYID = @pnUserIdentityId
		End
		
		-- get transaction post period
		if (@nErrorCode = 0)
		Begin
			Set @nPostPeriod = dbo.fn_GetPostPeriod(@pdtTransDate,2)
		End
		
	End

	if @nErrorCode = 0
	Begin			
		Select @nTranCountStart = @@TranCount
		Begin transaction
		
		if (@nErrorCode = 0)
		Begin
		exec @nErrorCode = ip_GetLastInternalCode
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psTable = 'TRANSACTIONHEADER',
			@pnLastInternalCode	= @nTransNo OUTPUT,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pbIsInternalCodeNegative = 0
		End
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "INSERT into TRANSACTIONHEADER (ENTITYNO, TRANSNO, EMPLOYEENO, ENTRYDATE, IDENTITYID, 
			SOURCE, TRANPOSTDATE,  TRANPOSTPERIOD, TRANSDATE, TRANSTATUS,  TRANSTYPE, USERID, GLSTATUS) 
			VALUES ( @pnEntityKey, @nTransNo, @nEmployeeNo, getdate(), @pnUserIdentityId, 2, @pdtTransDate, @nPostPeriod,@pdtTransDate, 1, 570,  @sLoginId, null )"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnEntityKey	int,
			@nTransNo	int,
			@nEmployeeNo	int,
			@pnUserIdentityId	int,
			@pdtTransDate	datetime,
			@nPostPeriod	int,
			@sLoginId	nvarchar(50)',
			@pnEntityKey	= @pnEntityKey,
			@nTransNo	= @nTransNo,
			@nEmployeeNo	= @nEmployeeNo,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pdtTransDate	= @pdtTransDate,
			@nPostPeriod	= @nPostPeriod,
			@sLoginId	= @sLoginId
		End
		
		-- write to ledger journal and debit and credit journal lines
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "INSERT into LEDGERJOURNAL (ENTITYNO, TRANSNO, DESCRIPTION,  IDENTITYID, REFERENCE,  STATUS, USERID) 
			VALUES(@pnEntityKey,@nTransNo, @nNewFeeListNo, @pnUserIdentityId, 'WID'+cast(@nTransNo as varchar(10)), 1, @sLoginId )"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnEntityKey	int,
			@nTransNo	int, 
			@nNewFeeListNo	int, 
			@pnUserIdentityId	int,
			@sLoginId	nvarchar(50)',
			@pnEntityKey	= @pnEntityKey,
			@nTransNo	= @nTransNo, 
			@nNewFeeListNo	= @nNewFeeListNo, 
			@pnUserIdentityId	= @pnUserIdentityId,
			@sLoginId	= @sLoginId				
		End
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "SELECT @nLedgerSeqNo = (ISNULL(Max(SEQNO),0) + 1)  FROM LEDGERJOURNALLINE WHERE TRANSNO = @nTransNo AND ENTITYNO = @pnEntityKey"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nLedgerSeqNo	int OUTPUT,
			@nTransNo	int,
			@pnEntityKey	int',
			@nLedgerSeqNo	= @nLedgerSeqNo OUTPUT,
			@nTransNo	= @nTransNo,
			@pnEntityKey	= @pnEntityKey
		End
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "INSERT into LEDGERJOURNALLINE (TRANSNO, SEQNO, ENTITYNO,  ACCOUNTID, ACCTENTITYNO, CURRENCY,  EXCHRATE, FOREIGNAMOUNT, LOCALAMOUNT,  PROFITCENTRECODE)
			VALUES (@nTransNo, @nLedgerSeqNo, @pnEntityKey, @nCABAccountId, @pnEntityKey, @sBankCurrencyCode, @nBankCurrencyExchRate,  @nBankAmountForeign, @nLocalTotalFee*-1, @sCABProfitCentre )"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nTransNo int, 
			@nLedgerSeqNo int, 
			@pnEntityKey int, 
			@nCABAccountId int, 
			@sBankCurrencyCode nvarchar(3), 
			@nBankCurrencyExchRate decimal(11,4), 
			@nBankAmountForeign decimal(13,2), 
			@nLocalTotalFee decimal(13,2), 
			@sCABProfitCentre nvarchar(6)	',
			@nTransNo	= @nTransNo, 
			@nLedgerSeqNo	= @nLedgerSeqNo, 
			@pnEntityKey	= @pnEntityKey, 
			@nCABAccountId  = @nCABAccountId,
			@sBankCurrencyCode = @sBankCurrencyCode, 
			@nBankCurrencyExchRate = @nBankCurrencyExchRate, 
			@nBankAmountForeign = @nBankAmountForeign, 
			@nLocalTotalFee = @nLocalTotalFee, 
			@sCABProfitCentre = @sCABProfitCentre
		End
		
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "SELECT @nLedgerSeqNo = (ISNULL(Max(SEQNO),0) + 1)  FROM LEDGERJOURNALLINE WHERE TRANSNO = @nTransNo AND ENTITYNO = @pnEntityKey"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nLedgerSeqNo	int OUTPUT,
			@nTransNo	int,
			@pnEntityKey	int',
			@nLedgerSeqNo	= @nLedgerSeqNo OUTPUT,
			@nTransNo	= @nTransNo,
			@pnEntityKey	= @pnEntityKey
		End
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "INSERT into LEDGERJOURNALLINE (TRANSNO, SEQNO, ENTITYNO,  ACCOUNTID, ACCTENTITYNO, CURRENCY,  EXCHRATE, FOREIGNAMOUNT, LOCALAMOUNT,  PROFITCENTRECODE)
			Values (@nTransNo, @nLedgerSeqNo, @pnEntityKey, @nCreditAcountId, @pnEntityKey, @sBankCurrencyCode, @nBankCurrencyExchRate, @nBankAmountForeign*-1, @nLocalTotalFee, @sCreditProfitCentreCode )"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nTransNo		int, 
			@nLedgerSeqNo		int, 
			@pnEntityKey		int, 
			@nCreditAcountId	int, 
			@sBankCurrencyCode	nvarchar(3), 
			@nBankCurrencyExchRate	decimal(11,4), 
			@nBankAmountForeign	decimal(11,2), 
			@nLocalTotalFee		decimal(13,2), 
			@sCreditProfitCentreCode nvarchar(6)',
			@nTransNo		= @nTransNo, 
			@nLedgerSeqNo		= @nLedgerSeqNo, 
			@pnEntityKey		= @pnEntityKey, 
			@nCreditAcountId	= @nCreditAcountId, 
			@sBankCurrencyCode	= @sBankCurrencyCode, 
			@nBankCurrencyExchRate	= @nBankCurrencyExchRate, 
			@nBankAmountForeign	= @nBankAmountForeign, 
			@nLocalTotalFee		= @nLocalTotalFee, 
			@sCreditProfitCentreCode = @sCreditProfitCentreCode
		End
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "SELECT @nNewBankHistoryLineNo = (ISNULL(Max(HISTORYLINENO),0) + 1) FROM BANKHISTORY WHERE SEQUENCENO = @nAccountSeqNo AND ENTITYNO = @pnEntityKey AND 
				BANKNAMENO = @nBankNameNo"
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nNewBankHistoryLineNo int OUTPUT,
				@nAccountSeqNo int,
				@pnEntityKey int,
				@nBankNameNo int',
				@nNewBankHistoryLineNo = @nNewBankHistoryLineNo OUTPUT,
				@nAccountSeqNo = @nAccountSeqNo,
				@pnEntityKey = @pnEntityKey,
				@nBankNameNo = @nBankNameNo

		End
		
		if (@nErrorCode = 0)
		Begin
		-- write to bank history
			Set @sSQLString = "INSERT into BANKHISTORY (SEQUENCENO, HISTORYLINENO, ENTITYNO,  BANKNAMENO, BANKAMOUNT,  
			BANKCHARGES, BANKEXCHANGERATE,  BANKNET, COMMANDID, DESCRIPTION,  ISRECONCILED, LOCALAMOUNT,  
			LOCALCHARGES, LOCALEXCHANGERATE, LOCALNET,  MOVEMENTCLASS, POSTDATE, 
			POSTPERIOD,  REFENTITYNO,  REFTRANSNO,  STATUS, TRANSDATE, TRANSTYPE, REFERENCE) 
			VALUES ( @nAccountSeqNo, @nNewBankHistoryLineNo, @pnEntityKey, @nBankNameNo, @nBankAmountLocal, 
			0, @nBankCurrencyExchRate, @nBankAmountLocal, 3, @nNewFeeListNo, 0, @nLocalTotalFee * -1, 
			0, @nLocalCurrencyExchRate, @nLocalTotalFee * -1, 2, getdate(), @nPostPeriod, @pnEntityKey, @nTransNo, 1, @pdtTransDate, 570, 'WID'+cast(@nTransNo as varchar(10))  )"
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nAccountSeqNo	int, 
				@nNewBankHistoryLineNo	int, 
				@pnEntityKey		int, 
				@nBankNameNo		int, 
				@nBankAmountLocal	decimal(13,2),
				@nBankCurrencyExchRate	decimal(10,4), 
				@nNewFeeListNo		int, 
				@nLocalTotalFee		decimal(13,2),
				@nLocalCurrencyExchRate	decimal(10,4), 
				@nPostPeriod		int, 
				@nTransNo		int, 
				@pdtTransDate		datetime',
				@nAccountSeqNo		= @nAccountSeqNo, 
				@nNewBankHistoryLineNo	= @nNewBankHistoryLineNo, 
				@pnEntityKey		= @pnEntityKey, 
				@nBankNameNo		= @nBankNameNo, 
				@nBankAmountLocal	= @nBankAmountLocal,
				@nBankCurrencyExchRate	= @nBankCurrencyExchRate, 
				@nNewFeeListNo		= @nNewFeeListNo, 
				@nLocalTotalFee		= @nLocalTotalFee,
				@nLocalCurrencyExchRate	= @nLocalCurrencyExchRate, 
				@nPostPeriod		= @nPostPeriod,
				@nTransNo		= @nTransNo, 
				@pdtTransDate		= @pdtTransDate
		End
		
		if (@nErrorCode = 0)
		Begin
			-- adjust the ledger journal line balance
			exec	@nErrorCode = dbo.gl_MaintLJLBalance
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pbDebug = 0,
				@pnEntityNo = @pnEntityKey,
				@pnTransNo = @nTransNo
		End
		
		-- Update FEELISTCASE with relevant details			
		If @nErrorCode = 0
		Begin				
			Set @sSQLString = "Update FEELISTCASE set 
			REFENTITYNO = @pnEntityKey,
			REFTRANSNO = @nTransNo
			Where CASEID = @pnCaseKey
			And   FEETYPE = @psFeeType
			And   WHENREQUESTED = @pdtWhenRequested
			And   FEELISTITEM = @nFeeListitem"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'
			@pnCaseKey int,
			@psFeeType nvarchar(6),
			@pnEntityKey int,
			@nTransNo int,
			@pdtWhenRequested datetime,
			@nFeeListitem int',
			@pnCaseKey	= @pnCaseKey,
			@psFeeType	= @psFeeType,
			@pnEntityKey	= @pnEntityKey,
			@nTransNo	= @nTransNo,
			@nFeeListitem	= @nFeeListitem,
			@pdtWhenRequested = @pdtWhenRequested
		End
		
		if (@nErrorCode = 0)
		Begin						
			--update bank account			
			Set @sSQLString = "UPDATE BANKACCOUNT SET ACCOUNTBALANCE = ACCOUNTBALANCE-@nBankAmountLocal*-1, LOCALBALANCE = LOCALBALANCE-@nLocalTotalFee 
			WHERE ACCOUNTOWNER = @pnEntityKey AND BANKNAMENO = @nBankNameNo AND SEQUENCENO = @nAccountSeqNo"
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nBankAmountLocal	decimal(13,2), 
				@nLocalTotalFee		decimal(13,2), 
				@pnEntityKey		int, 
				@nBankNameNo		int, 
				@nAccountSeqNo		int',
				@nBankAmountLocal	= @nBankAmountLocal, 
				@nLocalTotalFee		= @nLocalTotalFee, 
				@pnEntityKey		= @pnEntityKey, 
				@nBankNameNo		= @nBankNameNo, 
				@nAccountSeqNo		= @nAccountSeqNo
		End
		
		if (@nErrorCode = 0)
		Begin
		-- update control total
			Set @sSQLString = "UPDATE CONTROLTOTAL SET TOTAL = TOTAL - @nLocalTotalFee WHERE TYPE = 570 AND PERIODID = @nPostPeriod AND LEDGER = 5 
			AND ENTITYNO = @pnEntityKey AND CATEGORY = 2"
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nLocalTotalFee	decimal(13,2),
				@nPostPeriod		int,
				@pnEntityKey		int',
				@nLocalTotalFee		= @nLocalTotalFee,
				@nPostPeriod		= @nPostPeriod,
				@pnEntityKey		= @pnEntityKey
		End
		
		
		if (@nErrorCode = 0)
		Begin
			Set @sSQLString = "SELECT @nSessionId  = max(isnull(SESSIONIDENTIFIER,0)) + 1   FROM SESSION "
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nSessionId	int OUTPUT', 
				@nSessionId	= @nSessionId OUTPUT
		End
		
		if (@nErrorCode = 0)
		Begin	
			Set @sSQLString = "INSERT into SESSION (IDENTITYID, PROGRAM, SESSIONIDENTIFIER, STARTDATE) 
					VALUES(@pnUserIdentityId, 'WIP', @nSessionId, getdate() )"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnUserIdentityId		int,
			@nSessionId		int',
			@pnUserIdentityId		= @pnUserIdentityId,
			@nSessionId		= @nSessionId 
		End
		
		if (@nErrorCode = 0)
		Begin		
			Set @sSQLString = "INSERT into TRANSACTIONINFO (CASEID, SESSIONNO, TRANSACTIONDATE) 
			VALUES(@pnCaseKey, @nSessionId, getdate())"
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey	int,
			@nSessionId	int',
			@pnCaseKey	= @pnCaseKey,
			@nSessionId	= @nSessionId 
		End		
	End		
	
	If @@TranCount > @nTranCountStart
	Begin
		if @nErrorCode = 0
		commit transaction	
		else
		rollback transaction 
	End

	
End	


RETURN @nErrorCode
GO

Grant execute on dbo.wpw_PerformBankWithdrawal  to public
GO