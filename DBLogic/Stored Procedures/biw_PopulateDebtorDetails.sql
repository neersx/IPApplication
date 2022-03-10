-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_PopulateDebtorDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_PopulateDebtorDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_PopulateDebtorDetails].'
	drop procedure dbo.[biw_PopulateDebtorDetails]
end
print '**** Creating procedure dbo.[biw_PopulateDebtorDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_PopulateDebtorDetails]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@sTempTable		nvarchar(30), -- the name of the temp table to populate details into
				@pnEntityKey		int = null,
				@pdtTransDate		datetime=null,
				@pnCaseKey		int=null,
				@pnRaisedByStaffKey		int = null -- Used to get the actual Tax code
as
-- PROCEDURE :	biw_PopulateDebtorDetails
-- VERSION :	8
-- DESCRIPTION:	A procedure that populates a temporary table of Debtor information.
--
-- Pass in temp table with the following column structure:
--create table ##DebtorCurrencyDetails + Cast(@@SPID as nvarchar(30))
--(
--	NAMENO			INT,
--	BILLPERCENTAGE		DECIMAL(5,2) null,
--	REFERENCENO		NVARCHAR(80) COLLATE database_default NULL,
--	CORRESPONDNAME		INT null,
--	INSTRUCTIONS		nvarchar(254) COLLATE database_default NULL,
--	INSTRUCTIONSBILLING	ntext COLLATE database_default NULL,
--	TAXCODE			nvarchar(3) COLLATE database_default NULL,
--	TAXDESCRIPTION		nvarchar(30) COLLATE database_default NULL,
--	TAXRATE			DECIMAL(11,4) null,
--	ALLOWMULTICASE		bit,
--	BILLFORMATPROFILEKEY	INT null,
--	BILLMAPPROFILEKEY	INT null,
--	CURRENCY		NVARCHAR(3) COLLATE database_default NULL,
--	BANKRATE		DECIMAL(11,4) null,
--	BUYRATE			DECIMAL(11,4) null,
--	SELLRATE		DECIMAL(11,4) null,
--	DECIMALPLACES		INT null,
--	ROUNDBILLVALUES		INT null,
--	BILLINGCAP		decimal(12,2),
--	BILLEDAMOUNT		decimal(12,2),
--	BILLINGCAPSTART		DATETIME,
--	HASOFFICEINEU	bit NOT NULL default 0,
--	BILLINGCAPEND		DATETIME
--)
--
-- NOTE: CASENAME values BillPercentage, ReferenceNo and CorrespondName will not be updated.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- -----------------------------------------------------------
-- 15-Jul-2010	AT	RFC7273	1	Procedure created.
-- 02-Nov-2011	AT	RFC9451	2	Make Entity Key parameter optional.
-- 20 Oct 2015  MS  R53933  3   Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 24 Jan 2018	AK	R72409  4   Pupulate  INSTRUCTIONSBILLING
-- 26 Feb 2018  AK  R72937  5   Added logic to return effective tax code
-- 07 Mar 2018  AK  R73598  6   added HasOfficeInEu in resultset
-- 13 Mar 2018	AK	R73612	7	Applied check to validate tax code entered in TaxCodeEUBilling sitecontrol.
-- 04 Oct 2018  AK  R74005  8   passed @pnEntityKey in fn_GetDefaultTaxCodeForWIP and fn_HasDebtorSatisfyEUBilling and increased paramter 


set concat_null_yields_null off

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sAlertXML	nvarchar(2000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

Declare @pnDebtorKey		int

-- Currency
Declare @sCurrency nvarchar(3)
Declare	@nBankRate		decimal(11,4)
Declare @nBuyRate		decimal(11,4)
Declare @nSellRate		decimal(11,4)
Declare @nDecimalPlaces	tinyint
Declare @nRoundBilledValues tinyint
Declare @sHomeCurrency nvarchar(3)

-- IPName
Declare @sInstructions		nvarchar(254)
Declare @sInstructionsBilling		nvarchar(MAX)
Declare @sTaxCode		nvarchar(3)
Declare @sTaxDescription	nvarchar(30)
Declare @nTaxRate		decimal(11,4)
Declare @bAllowMultiCase	bit
Declare @nBillFormatProfileKey	int
Declare @nBillMapProfileKey	int
Declare @nBillingCap		decimal(12,2)
Declare @nBilledAmount		decimal(12,2)
Declare @bHasOfficeInEu bit

		
Declare @bIsEuTaxTreatmentSatisfied bit = 0
Declare @sEUTaxCode nvarchar(3)

if (@ErrorCode = 0)
Begin
	Set @sSQLString = "select @sHomeCurrency = COLCHARACTER
					FROM SITECONTROL WHERE CONTROLID = 'CURRENCY'"
					
	exec @ErrorCode=sp_executesql @sSQLString,
				N'	@sHomeCurrency nvarchar(3) OUTPUT',
					@sHomeCurrency = @sHomeCurrency OUTPUT
End

If (@ErrorCode = 0)
Begin
	SET @sSQLString = "Select @pnDebtorKey = min(NAMENO) FROM " + @sTempTable
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnDebtorKey int OUTPUT',
				@pnDebtorKey = @pnDebtorKey OUTPUT

	WHILE (@pnDebtorKey is not null and @ErrorCode = 0)
	Begin
		Set @sCurrency		= null
		Set @nBankRate		= null
		Set @nBuyRate		= null
		Set @nSellRate		= null
		Set @nDecimalPlaces	= null
		Set @nRoundBilledValues = null

		Set @sInstructions	= null
		Set @sInstructionsBilling = null
		Set @sTaxCode		= null
		Set @sTaxDescription	= null
		Set @nTaxRate		= null
		Set @bAllowMultiCase	= null
		Set @nBillFormatProfileKey	= null
		Set @nBillMapProfileKey	= null
		Set @nBillingCap = null
		Set @nBilledAmount = null
		
		If (@ErrorCode = 0 and @pnDebtorKey is not null and @pnRaisedByStaffKey is not null)
		Begin
	
			Set @sSQLString = 'Select @bIsEuTaxTreatmentSatisfied = dbo.fn_HasDebtorSatisfyEUBilling(@pnDebtorKey, @pnRaisedByStaffKey, @pnEntityKey)'
	
			exec @ErrorCode=sp_executesql @sSQLString,
				N'@bIsEuTaxTreatmentSatisfied	bit output,
				  @pnDebtorKey	int,
				  @pnEntityKey int,
				  @pnRaisedByStaffKey int',
				  @bIsEuTaxTreatmentSatisfied	= @bIsEuTaxTreatmentSatisfied output,
				  @pnDebtorKey	=	@pnDebtorKey,
				  @pnEntityKey = @pnEntityKey,
				  @pnRaisedByStaffKey = @pnRaisedByStaffKey

			If (@ErrorCode = 0 and @bIsEuTaxTreatmentSatisfied = 1)
			Begin
					Select @sEUTaxCode=COLCHARACTER
					from	SITECONTROL
					where	CONTROLID = 'Tax Code for EU billing'
					Set @ErrorCode = @@ERROR

					If @ErrorCode = 0 and Not Exists (SELECT TAXCODE FROM TAXRATES WHERE TAXCODE = @sEUTaxCode)
					Begin
						Set @sAlertXML = dbo.fn_GetAlertXML('AC154', 'The Tax Code specified in the ''Tax Code for EU billing'' site control is invalid. Contact your System Administrator to get the site control updated.',
														null, null, null, null, null)
						RAISERROR(@sAlertXML, 14, 1)
						Set @ErrorCode = @@ERROR
						BREAK;
					End
			End
		End

		-- Collect debtor details for each debtor.
		Set @sCurrency = null

		If (@ErrorCode = 0)
		Begin
			Set @sSQLString = "Select @sCurrency = Case when CURRENCY = @sHomeCurrency then null else CURRENCY end,
					@sInstructions = " + dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,NULL,@sLookupCulture,@pbCalledFromCentura) + ",
					@sInstructionsBilling = " + dbo.fn_SqlTranslatedColumn('NT','TEXT',null,NULL,@sLookupCulture,@pbCalledFromCentura) + ",
					@sTaxCode = TR.TAXCODE,
					@sTaxDescription = " + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + ",
					@nTaxRate = dbo.fn_GetEffectiveTaxRate(TR.TAXCODE, null, null, null),
					@bHasOfficeInEu = dbo.fn_HasDebtorSatisfyEUBilling(@pnDebtorKey, @pnRaisedByStaffKey, @pnEntityKey),
					@bAllowMultiCase = CASE WHEN CAST(IPNAME.CONSOLIDATION AS INT) & 1 = 1 THEN 1 ELSE 0 END,
					@nBillFormatProfileKey = IPNAME.BILLFORMATID,
					@nBillMapProfileKey = IPNAME.BILLMAPPROFILEID,
					@nBillingCap = IPNAME.BILLINGCAP
					from IPNAME
					Left Join TAXRATES TR on (TR.TAXCODE = dbo.fn_GetDefaultTaxCodeForWIP(@pnCaseKey, null, @pnDebtorKey, @pnRaisedByStaffKey, @pnEntityKey))
					Left Join NAMETEXT NT on (IPNAME.NAMENO = NT.NAMENO AND NT.TEXTTYPE = 'CB')
					Left Join TAXRATESCOUNTRY TRC on (TRC.TAXCODE = IPNAME.TAXCODE
							and TRC.COUNTRYCODE = ISNULL(NULL,'ZZZ'))
					Where IPNAME.NAMENO = @pnDebtorKey"

			exec @ErrorCode=sp_executesql @sSQLString,
					N'@sCurrency		nvarchar(3) OUTPUT,
					  @sInstructions	nvarchar(254) OUTPUT,
					  @sInstructionsBilling nvarchar(MAX) OUTPUT,
					  @sTaxCode		nvarchar(3) OUTPUT,
					  @sTaxDescription	nvarchar(30) OUTPUT,
					  @bHasOfficeInEu bit OUTPUT,
					  @nTaxRate		decimal(11,4) OUTPUT,
					  @bAllowMultiCase	bit OUTPUT,
					  @nBillFormatProfileKey int OUTPUT,
					  @nBillMapProfileKey	int OUTPUT,
					  @nBillingCap		int OUTPUT,
					  @pnDebtorKey int,
					  @pnCaseKey   int,					 
					  @pnRaisedByStaffKey int,
					  @pnEntityKey	int,
					  @sHomeCurrency nvarchar(3)',
					  @sCurrency = @sCurrency OUTPUT,
					  @sInstructions = @sInstructions OUTPUT,
					  @sInstructionsBilling = @sInstructionsBilling OUTPUT,
					  @sTaxCode = @sTaxCode OUTPUT,
					  @bHasOfficeInEu = @bHasOfficeInEu OUTPUT,
					  @sTaxDescription = @sTaxDescription OUTPUT,
					  @nTaxRate = @nTaxRate OUTPUT,
					  @bAllowMultiCase = @bAllowMultiCase OUTPUT,
					  @nBillFormatProfileKey = @nBillFormatProfileKey OUTPUT,
					  @nBillMapProfileKey = @nBillMapProfileKey OUTPUT,
					  @nBillingCap = @nBillingCap OUTPUT,
					  @pnDebtorKey = @pnDebtorKey,
					  @pnCaseKey   = @pnCaseKey,
					  @pnEntityKey = @pnEntityKey,
					  @pnRaisedByStaffKey = @pnRaisedByStaffKey,
					  @sHomeCurrency = @sHomeCurrency
		End

		If (@ErrorCode = 0 and @sCurrency is not null)
		Begin
			Set @pdtTransDate=isnull(@pdtTransDate,getdate())

			Exec dbo.ac_DoExchangeDetails
				@pnBankRate=@nBankRate output,
				@pnBuyRate=@nBuyRate output,
				@pnSellRate=@nSellRate output,
				@pnDecimalPlaces=@nDecimalPlaces output,
				@pnUserIdentityId=@pnUserIdentityId,
				@pbCalledFromCentura=@pbCalledFromCentura,
				@psCurrencyCode=@sCurrency, -- The currency the information is required for
				@pdtTransactionDate=@pdtTransDate, -- Required for historical exchange rates.
				@pbUseHistoricalRates=null, -- Indicates historical exchange rate to be used or not
				@psWIPCategory=null, -- WIP Category used to determine whether to use historical exchange rate.
				@pnCaseID=@pnCaseKey, -- CaseID used to obtain the correct exchange rate variation
				@pnNameNo=@pnDebtorKey, -- NameNo used to obtain the correct exchange rate variation
				@pbIsSupplier=0,     -- Determines whether to get exchange rate variation from CREDITOR/IPNAME when NameNo is supplied
				@pnRoundBilledValues=@nRoundBilledValues output,
				@pnAccountingSystemID=2,
				@psWIPTypeId=null
		End

		If (@ErrorCode = 0)
		Begin
			Set @sSQLString = "update " + @sTempTable + "
				set INSTRUCTIONS = @sInstructions,
				INSTRUCTIONSBILLING= @sInstructionsBilling,
				TAXCODE = @sTaxCode,
				TAXDESCRIPTION = @sTaxDescription,
				TAXRATE = @nTaxRate,
				HASOFFICEINEU = @bHasOfficeInEu,
				ALLOWMULTICASE = @bAllowMultiCase,
				BILLFORMATPROFILEKEY = @nBillFormatProfileKey,
				BILLMAPPROFILEKEY = @nBillMapProfileKey,
				CURRENCY = @sCurrency,
				BANKRATE = @nBankRate,
				BUYRATE = @nBuyRate,
				SELLRATE = @nSellRate,
				DECIMALPLACES = @nDecimalPlaces,
				ROUNDBILLVALUES = @nRoundBilledValues,
				BILLINGCAP = @nBillingCap,
				BILLEDAMOUNT = 0
				where NAMENO = @pnDebtorKey"
				
				exec @ErrorCode=sp_executesql @sSQLString,
					N'@sInstructions	nvarchar(254),
					  @sInstructionsBilling nvarchar(MAX),
					  @sTaxCode		nvarchar(3),
					  @sTaxDescription	nvarchar(30),
					  @nTaxRate		decimal(11,4),
					  @bAllowMultiCase	bit,
					  @nBillFormatProfileKey int,
					  @nBillMapProfileKey	int,
					  @sCurrency		nvarchar(3),
					  @nBankRate		decimal(11,4),
					  @nBuyRate		decimal(11,4),
					  @nSellRate		decimal(11,4),
					  @nDecimalPlaces	int,
					  @nRoundBilledValues	int,
					  @nBillingCap		int,
					  @bHasOfficeInEu bit,
					  @pnDebtorKey int',
					  @sInstructions = @sInstructions,
					  @sInstructionsBilling = @sInstructionsBilling,
					  @sTaxCode = @sTaxCode,
					  @sTaxDescription = @sTaxDescription,
					  @nTaxRate = @nTaxRate,
					  @bAllowMultiCase = @bAllowMultiCase,
					  @nBillFormatProfileKey = @nBillFormatProfileKey,
					  @nBillMapProfileKey = @nBillMapProfileKey,
					  @sCurrency = @sCurrency,
					  @nBankRate=@nBankRate,
					  @nBuyRate=@nBuyRate,
					  @nSellRate=@nSellRate,
					  @nDecimalPlaces=@nDecimalPlaces,
					  @nRoundBilledValues = @nRoundBilledValues,
					  @nBillingCap = @nBillingCap,
					  @bHasOfficeInEu = @bHasOfficeInEu,
					  @pnDebtorKey = @pnDebtorKey
		End
		
		If (@ErrorCode = 0 and @nBillingCap IS NOT NULL AND @nBillingCap > 0)
		Begin	
			Set @sSQLString = "UPDATE D SET 
			BILLINGCAPSTART =
				CASE WHEN I.BILLINGCAPRESETFLAG = 1 THEN
					case when BILLINGCAPPERIODTYPE = 'D' THEN
						DATEADD(dd, ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
					when BILLINGCAPPERIODTYPE = 'W' THEN
						DATEADD(ww, ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
					when BILLINGCAPPERIODTYPE = 'M' THEN
						DATEADD(mm, ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
					when BILLINGCAPPERIODTYPE = 'Y' THEN
						DATEADD(yy, ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
					End
				ELSE
					I.BILLINGCAPSTARTDATE
				END,
			BILLINGCAPEND =
				CASE WHEN I.BILLINGCAPRESETFLAG = 1 THEN
					case when BILLINGCAPPERIODTYPE = 'D' THEN
						DATEADD(dd, BILLINGCAPPERIOD, DATEADD(dd, ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
					when BILLINGCAPPERIODTYPE = 'W' THEN
						DATEADD(ww, BILLINGCAPPERIOD, DATEADD(ww, ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
					when BILLINGCAPPERIODTYPE = 'M' THEN
						DATEADD(mm, BILLINGCAPPERIOD, DATEADD(mm, ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
					when BILLINGCAPPERIODTYPE = 'Y' THEN
						DATEADD(yy, BILLINGCAPPERIOD, DATEADD(yy, ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
					End
				ELSE
					case when BILLINGCAPPERIODTYPE = 'D' THEN
						DATEADD(dd, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
					when BILLINGCAPPERIODTYPE = 'W' THEN
						DATEADD(ww, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
					when BILLINGCAPPERIODTYPE = 'M' THEN
						DATEADD(mm, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
					when BILLINGCAPPERIODTYPE = 'Y' THEN
						DATEADD(yy, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
					End
				END
			FROM " + @sTempTable + " D 
			JOIN IPNAME I on (I.NAMENO = D.NAMENO)"

			exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtTransDate datetime',
				@pdtTransDate = @pdtTransDate
		End
					
		If @ErrorCode = 0
		Begin
			Set @sSQLString = "Update D
			set BILLEDAMOUNT = AGG.DebtorTotal
			from
			(
				SELECT D.NAMENO, sum(CASE WHEN OIC.CASEID IS NULL THEN OI.LOCALVALUE ELSE OIC.LOCALVALUE END) AS 'DebtorTotal'
				FROM " + @sTempTable + " D 
				JOIN OPENITEM OI on OI.ACCTDEBTORNO = D.NAMENO"
				
				if @pnEntityKey is not null
				Begin
					Set @sSQLString = @sSQLString + char(10) + "and OI.ACCTENTITYNO = @pnEntityKey"
				End
				
				Set @sSQLString = @sSQLString + char(10) + "LEFT JOIN OPENITEMCASE OIC ON
					( OI.ITEMENTITYNO = OIC.ITEMENTITYNO 
					AND OI.ITEMTRANSNO = OIC.ITEMTRANSNO 
					AND OI.ACCTENTITYNO = OIC.ACCTENTITYNO 
					AND OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
				WHERE  OI.STATUS = 1
				AND  OI.ITEMTYPE = 510
				AND (OIC.CASEID IS NULL OR (OIC.STATUS IN (0,1,2,9)))
				AND OI.POSTDATE between D.BILLINGCAPSTART and D.BILLINGCAPEND
				GROUP BY D.NAMENO
			) AS AGG
			JOIN " + @sTempTable + " D ON (D.NAMENO = AGG.NAMENO)"
			
			
			exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnEntityKey	int',
				@pnEntityKey = @pnEntityKey
		End



		Declare @nOldDebtorNameKey int
		
		Set @nOldDebtorNameKey = @pnDebtorKey

		SET @sSQLString = "Select @pnDebtorKey = min(NAMENO) FROM "+ @sTempTable +
				" Where NAMENO > " + cast(@pnDebtorKey as nvarchar(12))

		exec @ErrorCode=sp_executesql @sSQLString,
				N'	@pnDebtorKey int OUTPUT',
					@pnDebtorKey = @pnDebtorKey OUTPUT
					
		if (@pnDebtorKey = @nOldDebtorNameKey)
		Begin
			Set @pnDebtorKey = null
		End
	End
End

return @ErrorCode
go

grant execute on dbo.[biw_PopulateDebtorDetails]  to public
go
