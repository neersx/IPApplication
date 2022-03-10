-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_DoCalculation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_DoCalculation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_DoCalculation.'
	drop procedure dbo.pt_DoCalculation
end
print '**** Creating procedure dbo.pt_DoCalculation...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.pt_DoCalculation
	@pnCriteria		int, 
	@pnAgentNo		int, 
	@pnBillToNo		int, 		-- this is the debtor (or renewals debtor)
	@pnDebtorType		int, 
	@pnOwner		int, 
	@pnInstructor		int,
	@pnEmployee		int,
	@pnEntity		int,
	@pnAgeOfCase		int, 
	@pdtLetterDate		datetime, 
	@pnProductCode	 	int,
	@psIPTaxCode		nvarchar(3),	-- Debtor's Federal Tax Code  
	@psCaseTaxCode		nvarchar(3), 	-- Case's Federal Tax Code
	@pnEnteredQuantity	int, 
	@pnEnteredAmount	decimal(11,2), 
	@pnCaseId		int, 
	@psPropertyType		nchar(1),
	@psAction		nvarchar(2),
	@pnNoInSeries		smallint, 
	@pnNoOfClasses		smallint, 
	@pnCycle		smallint, 
	@pnEventNo		int, 
	@pnARQuantity		smallint, 
	@pnARAmount		decimal(11,2),
	@pnDebtorPercentage	decimal(5,2),
	@prsDisbCurrency 	nvarchar(3) 	output, @prnDisbExchRate	decimal(11,4) 	output, 
	@prsServCurrency 	nvarchar(3) 	output, @prnServExchRate	decimal(11,4) 	output, 
	@prsBillCurrency 	nvarchar(3) 	output, @prnBillExchRate 	decimal(11,4) 	output, 
	@prsDisbTaxCode 	nvarchar(3) 	output, @prsServTaxCode 	nvarchar(3) 	output, 
	@prnDisbNarrative 	int 		output, @prnServNarrative 	int 		output, 
	@prsDisbWIPCode 	nvarchar(6) 	output, @prsServWIPCode 	nvarchar(6) 	output, 
	@prnDisbAmount 		decimal(11,2) 	output, @prnDisbHomeAmount 	decimal(11,2) 	output, @prnDisbBillAmount decimal(11,2) output, 
	@prnServAmount 		decimal(11,2) 	output, @prnServHomeAmount 	decimal(11,2) 	output, @prnServBillAmount decimal(11,2) output, 
	@prnTotHomeDiscount 	decimal(11,2) 	output, @prnTotBillDiscount 	decimal(11,2) 	output, 
	@prnDisbTaxAmt 		decimal(11,2) 	output, @prnDisbTaxHomeAmt 	decimal(11,2) 	output, @prnDisbTaxBillAmt decimal(11,2) output, 
	@prnServTaxAmt 		decimal(11,2) 	output, @prnServTaxHomeAmt 	decimal(11,2) 	output, @prnServTaxBillAmt decimal(11,2) output, 

	-- MF 27/02/2002 Add new output parameters to return the new components of the calculation

	@prnDisbDiscOriginal	decimal(11,2)	output,
	@prnDisbHomeDiscount 	decimal(11,2) 	output,
	@prnDisbBillDiscount 	decimal(11,2) 	output, 
	@prnServDiscOriginal	decimal(11,2)	output,
	@prnServHomeDiscount 	decimal(11,2) 	output,
	@prnServBillDiscount 	decimal(11,2) 	output,
	@prnDisbCostHome	decimal(11,2)	output,
	@prnDisbCostOriginal	decimal(11,2)	output,

	-- MF 02/11/2000 The following are new output parameters to allow and extended version
	--		 of FEESCALC to be used that will return more details about the calculation
	@prnParameterSource 	smallint	output,
	@prnDisbMaxUnits 	smallint	output,
	@prnDisbBaseUnits 	smallint	output,
	@prbDisbMinFeeFlag 	decimal(1,0)	output,
	@prnServMaxUnits 	smallint	output,
	@prnServBaseUnits 	smallint	output,
	@prbServMinFeeFlag 	decimal(1,0)	output,
	@prnDisbUnitSize 	smallint 	output,
	@prnServUnitSize 	smallint 	output,
	@prdDisbBaseFee 	decimal(11,2) 	output,
	@prdDisbAddPercentage 	decimal(5,4) 	output,
	@prdDisbVariableFee 	decimal(11,2) 	output,
	@prdServBaseFee 	decimal(11,2) 	output,
	@prdServAddPercentage	decimal(5,4) 	output,
	@prdServVariableFee	decimal(11,2) 	output,
	@prdServDisbPercent	decimal(5,4) 	output,
	@prsFeeType		nvarchar(6)	output,		-- RCT 07/03/2002	New output variable added

	-- SQA12379 Add new output parameters required by Charge Generation
	@prnDisbBasicAmount		decimal(11,2)	= NULL	output,
	@prnDisbExtendedAmount 		decimal(11,2)	= NULL	output,
	@prnDisbCostCalculation1	decimal(11,2)	= NULL	output,
	@prnDisbCostCalculation2	decimal(11,2)	= NULL	output,
	@prnServBasicAmount		decimal(11,2)	= NULL	output,
	@prnServExtendedAmount 		decimal(11,2)	= NULL	output,
	@prnServCostCalculation1	decimal(11,2)	= NULL	output,
	@prnServCostCalculation2	decimal(11,2)	= NULL	output,
	@prnVarBasicAmount		decimal(11,2)	= NULL	output,
	@prnVarExtendedAmount 		decimal(11,2)	= NULL	output,
	@prnVariableFeeAmt		decimal(11,2)	= NULL	output,
	@prnVarHomeFeeAmt		decimal(11,2)	= NULL	output,
	@prnVarBillFeeAmt		decimal(11,2)	= NULL	output,
	@prnVarTaxAmt			decimal(11,2)	= NULL	output,
	@prnVarTaxHomeAmt		decimal(11,2)	= NULL	output,
	@prnVarTaxBillAmt		decimal(11,2)	= NULL	output,
	@prsVarWIPCode			nvarchar(6)	= NULL	output,
	@prsVarTaxCode 			nvarchar(3) 	= NULL	output,
	@prnDisbMargin			decimal(11,2)	= NULL	output,
	@prnDisbHomeMargin		decimal(11,2)	= NULL	output,
	@prnDisbBillMargin		decimal(11,2)	= NULL	output,
	@prnServMargin			decimal(11,2)	= NULL	output,
	@prnServHomeMargin		decimal(11,2)	= NULL	output,
	@prnServBillMargin		decimal(11,2)	= NULL	output,
	@prnServCostOriginal		decimal(11,2)	= NULL	output,
	@prnServCostHome		decimal(11,2)	= NULL	output,
	@prnFeeUniqueId			int		= NULL	output, -- If a value is passed as an input parameter then it will be used for the calculation
	@pbIsChargeGeneration		bit		= 1,	-- SQA12379 New INPUT parameter
	@pdtTransactionDate		datetime	= NULL,
	@pdtFromEventDate		datetime	= NULL, -- SQA15276 New INPUT parameter
	@psCaseType			nchar(1)	= null,	-- SQA12361 User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- SQA12361 User entered Country
	@psCaseCategory			nvarchar(2)	= null, -- SQA12361 User entered Category
	@psSubType			nvarchar(2)	= null, -- SQA12361 User entered Sub Type
	@pnExchScheduleId		int		= NULL,	-- SQA12361 User entered Exchange Rate Schedule
	@pdtFromDateDisb		datetime	= NULL,	-- SQA12361 Simulated From date for Disbursements
	@pdtFromDateServ		datetime	= NULL,	-- SQA12361 Simulated From date for Service Charges
	@pdtUntilDate			datetime	= NULL,	-- SQA12361 Simulated Until date
	@pdtBillDate			datetime	= NULL,
	-- Return quantity values used in calculations
	@pnDisbQuantity 		int		= NULL	output,
	@psDisbPeriodType		nchar(1)	= NULL	output,
	@pnDisbPeriodCount		int		= NULL	output,
	@pnServQuantity 		int		= NULL	output,
	@psServPeriodType		nchar(1)	= NULL	output,
	@pnServPeriodCount		int		= NULL	output,
	-- Return the calculated amounts before margins, discounts and rounding
	@pnDisbSourceAmt		decimal(11,2)	= NULL	output,
	@pnServSourceAmt		decimal(11,2)	= NULL	output,
	-- Additional user entered parameters for simulated Case
	@pnEntitySize			int		= null, -- SQA15384 User entered Entity Size
	@psCurrency			nvarchar(3)	= null,  -- SQA15384 User entered Currency
	@pbAgentItem			bit		= 0,
	@pbUseTodaysExchangeRate	bit		= 0,
	-- 14649 Multi-tier Tax
	@prsDisbStateTaxCode 	nvarchar(3) 	= NULL	output, @prsServStateTaxCode 	nvarchar(3) 	= NULL	output, @prsVarStateTaxCode 	nvarchar(3) 	= NULL	output,
	@prnDisbStateTaxAmt 	decimal(11,2) 	= NULL	output, @prnDisbStateTaxHomeAmt decimal(11,2) 	= NULL	output, @prnDisbStateTaxBillAmt decimal(11,2)	= NULL	output, 
	@prnServStateTaxAmt 	decimal(11,2) 	= NULL	output, @prnServStateTaxHomeAmt decimal(11,2) 	= NULL	output, @prnServStateTaxBillAmt decimal(11,2)	= NULL	output, 
	@prnVarStateTaxAmt	decimal(11,2)	= NULL	output, @prnVarStateTaxHomeAmt	decimal(11,2)	= NULL	output, @prnVarStateTaxBillAmt	decimal(11,2)	= NULL	output,
	-- SQA16376
	@prnParameterSource2 	smallint	= NULL output,
	@prnDisbMarginNo		int		= null output,
	@prnServMarginNo	int		= null output,
	-- RFC6478
	@prsFeeType2		nvarchar(6)	= null output,	
	-- RFC7269
	@pnDisbDiscountForMargin	decimal(11,2)	= null	output,
	@pnDisbHomeDiscountForMargin	decimal(11,2)	= null	output,
	@pnDisbBillDiscountForMargin	decimal(11,2)	= null	output,
	@pnServDiscountForMargin	decimal(11,2)	= null	output,
	@pnServHomeDiscountForMargin	decimal(11,2)	= null	output,
	@pnServBillDiscountForMargin	decimal(11,2)	= null	output,
	@pnFeesCalcId		        smallint	= null,	-- Key to explicit FEESCALCULATION to use in calculation
        -- RFC56172
        @pnDisbPreMarginDiscount	decimal(11,2)	= null	output,
	@pnDisbHomePreMarginDiscount	decimal(11,2)	= null	output,
	@pnDisbBillPreMarginDiscount	decimal(11,2)	= null	output,
	@pnServPreMarginDiscount	decimal(11,2)	= null	output,
	@pnServHomePreMarginDiscount	decimal(11,2)	= null	output,
	@pnServBillPreMarginDiscount	decimal(11,2)	= null	output	
as

-- PROCEDURE :	pt_DoCalculation
-- VERSION :	82
-- DESCRIPTION:	Performs fee calculations based on the details passed.
-- 		Sets the results of these calculations back into OUTPUT parameters
--		to be used by the calling stored procedures
-- CALLED BY :	FEESCALC, FEESCALCEXTENDED
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 02/11/2000 	MF			Variable required to determine if Tax calculation is required
-- 18/04/2002	IB	7375		If discounts are nulls set them to 0.
-- 29/04/2002	IB	7375		When @sServCurrency=@sDisbCurrency then set the disbursement exchange rate 
--					into the service fee exchange rate.
-- 11/09/2002	CR	6638		Added calls to alternate stored procedures for Disbursements, Service Charges and Variable Fees
-- 25/11/2002	SS	7276		Modified logic to determine tax rate.
-- 07/03/2003	MF	8521		The calculation of Cost for the Home and Original currency is in reverse.
-- 14/03/2003	CR	8071		Updated the logic when calculating Discounts and Margins so that 
--					these are not dependant on each other
-- 19/03/2003	JB	8116		Added some new parameters to pt_GetTaxRate to allow it to calculate
--					the tax rate for a country
-- 21/03/2003	JB	8116		Using default country (ZZZ) if staff responsible on case not found
-- 23/04/2003	dw	8680		Updated logic that determines whether to use buy rate or sell rate.
-- 24/06/2003	MF	8926		Revisit 6638.  A new parameter is required to be passed to alternate stored procedure
--					to indicate that results should not be returned using a SELECT which is the method
--					required by Charge Generation when calling the alternate stored procedure.
-- 13/05/2004	DW	9917		Added @pbSeparateDebtorFlag as a new input parameter.
-- 07/06/2004	DW	9917		Modified above parameter (@pnDebtorPercentage replaces @pbSeparateDebtorFlag).
-- 30/11/2004	DW	10491		Adjusted the logic to set @nServAddPercentage & @nDisbAddPercentage to 0 if null.
--					They were being set instead to 1.
-- 28/02/2005	DW	11071		added new parameter Product Code to pass to pt_GetDiscountRate.
-- 26/10/2005	DW	9931		passed debtor currency as new parameter to margin calculation.
-- 08 Mar 2006	MF	12379	10	New parameters added that are required by Charge Generation
-- 14 Mar 2006	MF	12432	11	Allow margins to be applied even if the base calculated amount is zero
-- 17 Mar 2006	JB	12378	12	Bug in parameter definition of decimals was decimal(11,0) now (11,2)
-- 21 Mar 2006	JB	12379	13	Bug calculating cost rates + now calculating cost rates outside chgen
-- 24 Mar 2006	JB	12379	14	Passing @sDisbCurrency (not @prsDisbCurrency) to pt_DoCalculation (same for Serv)
-- 					Also implemented new version of pt_DoCalculation that now returns local or foreign
-- 08 Jun 2006	DW	12351	15	Passed owner as new parameter to pt_GetDiscountRate
-- 14 Jun 2006	KR	11702	16	Changed call to pt_GetExchangeRate to ac_GetExchangeDetails
-- 20 Jun 2006	AT	12840	17	Fixed OUTPUT params on sp_executesql calls.
-- 27 Jun 2006	KR	12108	18	Fixed a problem with getting service and disbursements rates
-- 30 Jun 2006	MF	12915	19	Variable fee amount returned should be the minimum amount required.  Procedure
--					was incorrectly calculating the difference between the minimum required and 
--					the calculated service fee.
-- 25 Jul 2006	MF	13076	20	Allow additional Quantity Source that calculates a period of time between
--					event dates.  Also if the Quantity of Source used is for a period of time
--					and it calculates as a number less than 1 then do not calculate the "service"
--					amount as a percentage of disburesment.  This will allow for fines that are
--					calculated as a percentage of the Offical Fee to only occur when a specified
--					Event is later than another Event.
-- 25 Jul 2006	MF	12361	21	Additional parameters required to allow "what if" calculations for
--					a profiled case rather than a specific CaseId.
-- 26 Jul 2006	MF	13128	21	There is a bug that causes the pre-margin amount to be returned as NULL 
--					when the associated margin is NULL.
-- 25 Sep 2006	MF	13472 	22	Add Case Type, Category and Sub Type as selection characteristics for
--					determining the Margin. Change required to call of pt_GetMargin.
-- 28 Sep 2006	MF	13523	23	Where a fee is being calculated against a quantity that is a period of time
--					(e.g. X - Months) and some other value (e.g. Y - No of Classes), then any incremental 
--					increase in the fee is assumed to be against the number of periods.
--					E.g. Say a TM is 3 months late and has 7 classes.
--						X = 3
--						Y = 7
--					     A charge exists of $100 for the first month (times the number of classes) 
--					     and then $80 for each month late thereafter (times number of classes) 
--					     Therefore  1    x 7 x $100 = $700 for the first month
--						  plus (3-1) x 7 x $80 = $1,120
-- 20 Oct 2006	AT	13305	24	Added retrieval of Use Historical Exch rate flag for Fees/Charges calculations.
-- 08 Nov 2006	MF	13782	25	If the Minimum Fee flag is set on then normally this means the Basic Fee will
--					still receive a value even if the quantity used in the calculation is zero.
--					When the source of quantity involves getting a period of time between two dates 
--					then the Basic Fee will be set to zero if the period of time is zero.
-- 14 Nov 2006	MF	13782	26	Revisit. pt_Quantity must always be called if there quantity involves a period 
--					calculation
-- 20 Nov 2006 	IB	13656	27	Defaulted @pbIsChargeGeneration parameter to 1.
-- 01 Dec 2006	MF	12361	28	Add extra input parameters to handle simulation of date that influence
--					the period of time used in calculations
-- 08 Dec 2006	KR	13982	29	Modify call to ac_GetExchangeParameter so that ROUNDBILLEDVALUE is returned correctly.
-- 03 Jan 2007	MF	13280	30	Allow a specific Event to be used to get the date to be used to determine
--					which fee calculation to use.
-- 15 Jan 2007	CR	13955	31	Consolidated margin calculation logic into pt_CalculateMargin so that this and
--					wp_GetWIPCosting may use the same logic.
--			12400		Pass Time & Billing SystemID (2) to ac_GetExchangeParameters.
-- 13 Feb 2007	CR	12400	32	Fixed the logic to set @nDisbExchRate.
-- 14 Feb 2007	CR	12400	33	Added new Bill Date parameter for use when deriving exchange rate for
--					Foreign Currency Bills.
-- 21 Feb 2007	CR	12400	34 Ensure the excahange rate is retrieved for DisbCurrency and ServCurrency 
--								if it is the same as the bill currency but Historical Exch Rates apply.
-- 22 Feb 2007	CR	12400	35	Fix typo with Buy vs Sell rate for Service Charges.
-- 23 Feb 2007	CR	12400	36 Remove logic that sets the Disbursement ExchRate to BillExch rate 
--								if the same currency. Similarly for Service Charges.
-- 27 Feb 2007	CR	12400	37	Fixed the Calles to pt_GetMargin. Pass trans date as effective date.
-- 16 Mar 2007	MF	14585	38	Discount not being calculated on Service charge when it the option to calculate
--					after the Margin has been calculated is on.
-- 29 Mar 2007	MF	14645	39	If no EventDate is available to determine the FEESCALCULATION to use then use
--					the date of the transaction passed as a parameter.
-- 07 May 2007	CR	14311	40	Updated @sAction parameter to be @psAction.
-- 14 May 2007	MF	14726	41	Return the quantities used in the calculation
-- 06 Aug 2007	MF	15103	42	The simulated "from date" used for calculating the period of time between two
--					dates may in fact be different for the Disbursement and the Service components
--					of the calculation.
-- 24 Aug 2007	CR	15234	43	Fixed check of Disb before rounding Serv.
-- 28 Aug 2007	MF	15276	43	Provide a new parameter to for a simulated "from event date" to be passed
--					to be used to determine the appropriate Fees Calculation.  If passed this
--					date will take precedence over any Event already held as a CaseEvent.
-- 31 Aug 2007	CR	15276	44	Added Case Detail parameters to pt_DoCalculation
-- 24 Sep 2007	MF	15384	45	Alternate stored procedures used in fee calculations should also receive the 
--					parameters that indicate a simulated Case is being used in the calculation along
--					with the relevant dates used in the simulation.
-- 28 Sep 2007	CR	14901	45	Changed Exchange Rate field sizes to (8,4)
-- 16 Oct 2007	CR	15383	46	Added new Agent Item parameter to indicate when an Agent Item is being processed.
-- 11 Feb 2008	MF	15943	47	Provide a parameter to indicate that the current exchange rate
--					is to be used instead of one matching the transaciton date.
-- 29 Nov 2007	CR	14649	47	Extended to cater for Multi-tier Tax

-- 10 Jan 2008	MF	15820	48	If Variable Fee is higher than calculated Service Fee then discount should
--					be calculated against the Variable Fee
-- 29 Jan 2008	CR	14649	49	Changed logic in relation to setting the Tax Rate for Tax Exemption 
-- 29 Apr 2008	CR	16322	50	Ensure @nParameterSource(2) is considered when deciding if quantity should be derived
-- 13 May 2008	Dw	16376	51	Return @nParameterSource(2) as receive parameter
-- 15 Aug 2008	MF	16836	52	When the base amount (Serv or Disb) is zero but the margin is non zero then switch the 
--					currency (Serv or Disb) to be the same as the Billing currency.  This approach can result
--					in the Margin amount not being converted to the base currency and then converted back into
--					the billing currency. The double conversion can cause small rounding differences.
-- 03 Oct 2008	Dw	16917	53	Added 2 new parameters to return margin identifiers for fee1 and fee2.
-- 20 Nov 2008  Dw	16374	54	Fixed bug which was causing extended amount calculations to be automatically rounded.
-- 15 Dec 2008	MF	17136	55	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 05 Feb 2009  Dw	17331	56	Fixed bug where @nRoundBilledValue was being set incorrectly.
-- 19 Feb 2009	Dw	13940	57	Pass transaction date to pt_GetTaxRate
-- 02 Mar 2009	MF	17452	58	When called for Fee Enquiry (@pbUseTodaysExchangeRate=1) then do not use historical date
--					in determination of Margin values. Use current date or if @pdtTransactionDate is a future
--					date then it can be used.
-- 23 Mar 2009	MF	RFC6478	59	Return FEETYPE2 from FeesCalculation table as it is required to allow Fee List to be generated
-- 15 Feb 2010	Dw	15969	60	Default the product Code from the Fee Calculation row if not set
-- 24 Feb 2010	Dw	18298	61	Pass Margin Cap to pt_CalculateMargin
-- 16 Mar 2010	MS	RFC7270	62	Added check before calculating discount to restrict Double Discount
-- 23 Jun 2010	MS	RFC7269	63	Added output parameters for Discount For Margin
-- 06 Jul 2010	Dw	SQA11749 64	Passed new parameter WIP Code to pt_GetMargin
-- 01 Oct 2010	Dw	18457	65 	Adjusted Fee Calculation best fit to set cycle number from @pnCycle if set
-- 10 Jan 2011	MF	19314	66	Reversal of code change introduced for SQA18457. AgeOfCase should be used for determining the fee and
--					not the Cycle. The AgeOfCase should have previously been determined for the Cycle.
-- 10 Feb 2011	Dw	19145	67	Fixed rounding error when calculating WIP from a foreign charge
-- 27 Jul 2011	MF	19824	68	If a fee is to be determined based on a specific CaseEvent date then we should use that date 
--					in preference to the simulated @pdtFromEventDate passed to this procedure.
-- 22 Dec 2011	AT	R9160	69	Added WIP Type in get exch rate logic
-- 24 Apr 2012	MF	R12213	70	If the exact fee for a specific annuity is not found then use the next lower annuity number that has a fee.
-- 14 May 2012	MF	R12281	71	Found that the quantity being determined for the variable part of the charge was incorrectly
--					being set to an integer which resulted in it being rounded down when code already existed for
--					it to be rounded up. 
-- 19 Jun 2012	KR	R12005	72	Add WIPCODE and CASETYPE to the Discount calculation
-- 09 Jan 2013	MF	R20199	73	Event if a Quantity is passed in as a parameter the pt_GetQuantity procedure should still be called.
-- 15 Mar 2013	MF	R13050	74	The Alternate Stored Procedures that may be defined by users is to optionally allow for the 
--					@pnCycle to be passed through to it.  This is to provide a mechanism for those calculations 
--					that need to know a specific Cycle in order to correctly calculate a fee. The existence or not
--					of the @pnCycle can be determined from the stored procedure itself.
-- 01 Oct 2013	AT	DR-217	75	Fix issue with floats causing truncation on calculations.
-- 01 Jun 2015	MS	R35907	76	Added CountryCode to the Discount calculation
-- 20 Oct 2015  MS      R53933  77      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 04 Jan 2016  MS      R56172  78      Added premargin discounts for service fees and disbursments
-- 24 Oct 2017	AK	R72645	79	Make compatible with case sensitive server with case insensitive database.
-- 25 Sep 2018	MF	R75022	80	If @pnEnteredQuantity was supplied AND the calculation is based on a Quantity, the supplied @pnEnteredQuantity
--					is beiung ignored if both PARAMETERSOURCE and PARAMETERSOURCE2 are not null in FEESCALCULATION.  We should use
--					the provided @pnEnteredQuantity value. NOTE: Correction provided by ALK from Novagraaf.
-- 18 Apr 2019	DL	DR-47444 81	Service Charge component of Renewal Fee not including amount for additional classes
-- 08 Jul 2019  MS      DR49444  82     Use bank rate for conversions to local currency if site control 'Bank Rate In Use for Service Charges' is true

Set nocount on

declare @bTaxRequired 		bit

declare @sInstructorCountry	nvarchar(3)
declare	@sDebtorCountry		nvarchar(3)
declare @bIPOfficeFeeFlag	decimal(1,0)
declare @nParameterSource	smallint
declare @nParameterSource2	smallint
declare @sDisbTaxCode		nvarchar(3) -- Tax Code. Intially set using WIP Template
declare @nDisbMaxUnits		smallint
declare @nDisbBaseUnits		smallint
declare @bDisbMinFeeFlag 	decimal(1,0)
declare @sDisbWIPCode 		nvarchar(6)
declare @sDisbWIPType		nvarchar(6)
declare	@sDisbCategory		nvarchar(3)
declare @sDisbCurrency		nvarchar(3)
declare @nDisbNarrative		int
declare @nDisbBaseOnAmount	decimal(1,0)
declare @nDisbDiscountRate	decimal(6,3)
declare @nDisbMarginRate	decimal(6,3)
declare @nDisbEmployeeNo	int
declare @sServTaxCode		nvarchar(3) -- Tax Code. Intially set using WIP Template
declare @nServMaxUnits		smallint
declare @nServBaseUnits		smallint
declare @bServMinFeeFlag	decimal(1,0)
declare @sServWIPCode		nvarchar(6)
declare @sServWIPType		nvarchar(6)
declare	@sServCategory		nvarchar(3)
declare @sServCurrency		nvarchar(3)
declare @nServNarrative		int
declare @nServBaseOnAmount	decimal(1,0)
declare @nServDiscountRate	decimal(6,3)
declare @nServMarginRate	decimal(6,3)
declare @nServEmployeeNo	int

declare @sVarWIPCode 		nvarchar(6)
declare @sVarTaxCode		nvarchar(3) -- Tax Code. Intially set using WIP Template
Declare @bVarMinFeeFlag		decimal(1,0)
Declare @nVarBaseUnits		smallint
Declare @nVarMaxUnits 		smallint

declare @nDisbAmount		decimal(11,2)
declare @nDisbBillAmount	decimal(11,2)
declare @nDisbHomeAmount	decimal(11,2)
declare @nDisbTaxAmt		decimal(11,2)
declare @nDisbTaxBillAmt	decimal(11,2)
declare @nDisbTaxHomeAmt	decimal(11,2)

declare @nDisbDiscount 		decimal(11,2)
declare @nDisbHomeDiscount 	decimal(11,2)
declare @nDisbBillDiscount 	decimal(11,2)

declare @nServAmount		decimal(11,2)
declare @nServBillAmount	decimal(11,2)
declare @nServHomeAmount	decimal(11,2)
declare @nServTaxAmt		decimal(11,2)
declare @nServTaxBillAmt	decimal(11,2)
declare @nServTaxHomeAmt 	decimal(11,2)

declare @nServDiscount 		decimal(11,2)
declare @nServHomeDiscount 	decimal(11,2)
declare @nServBillDiscount 	decimal(11,2)

declare @nDisbMargin		decimal(11,2)
declare @nDisbHomeMargin	decimal(11,2)
declare @nDisbBillMargin	decimal(11,2)

declare @nServMargin		decimal(11,2)
declare @nServHomeMargin	decimal(11,2)
declare @nServBillMargin	decimal(11,2)

declare @nVarAmount		decimal(11,2)
declare @nVarBillAmount		decimal(11,2)
declare @nVarHomeAmount		decimal(11,2)
declare @nVarTaxAmt		decimal(11,2)
declare @nVarTaxBillAmt		decimal(11,2)
declare @nVarTaxHomeAmt 	decimal(11,2)

declare @sControlId 		nvarchar(20)
declare @sHomeCurrency 		nvarchar(3)
declare @nEnteredAmount 	decimal(11,2)
declare @nServDisbursement 	decimal(11,2)
declare @nDisbSubTotal 		decimal(11,2)
declare @nServSubTotal 		decimal(11,2)
declare @nQuantity 		int
declare @nChargeQuantity 	decimal(9,2)
declare @nRndChargeQuantity 	int
declare @nIPTaxRate 		decimal(11,4)
declare @nCaseTaxRate 		decimal(11,4)
declare @nDisbUnitSize 		decimal(9,2)	-- RFC12281 changed from SMALLINT to stop rounding error
declare @nServUnitSize 		decimal(9,2)	-- RFC12281 changed from SMALLINT to stop rounding error
Declare @nVarUnitSize		decimal(9,2)	-- RFC12281 changed from SMALLINT to stop rounding error

declare @nDisbBaseFee 		decimal(11,2)
declare @nDisbAddPercentage decimal(5,4)
declare @nDisbVariableFee 	decimal(11,2)
declare @nServBaseFee 		decimal(11,2)
declare @nServAddPercentage decimal(5,4)
declare @nServVariableFee 	decimal(11,2)
declare @nServDisbPercent 	decimal(5,4)
declare @nDisbExchRate 		decimal(11,4)
declare @nDisbTaxRate 		decimal(11,4)
declare @nServExchRate 		decimal(11,4)
declare @nServTaxRate 		decimal(11,4)
declare @nVarTaxRate 		decimal(11,4)
Declare @nVarBaseFee		decimal(11,2)
Declare @nVarVariableFee	decimal(11,2)
declare @nDiscountRate 		decimal(6,3)

declare @nBillExchRate 		decimal(11,4)
declare @nBillBuyRate 		decimal(11,4)
declare @nBillSellRate 		decimal(11,4)
declare @nDisbBuyRate 		decimal(11,4)
declare @nDisbSellRate 		decimal(11,4)
declare @nServBuyRate 		decimal(11,4)
declare @nServSellRate 		decimal(11,4)
declare @nDecimalPlaces		tinyint
declare @nDisbDecimalPlaces	tinyint
declare @nServDecimalPlaces	tinyint

declare @dDisbBaseFee 		decimal(11,2)
declare @dDisbAddPercentage 	decimal(5,4)
declare @dDisbVariableFee 	decimal(11,2)
declare @dServBaseFee 		decimal(11,2)
declare @dServAddPercentage 	decimal(5,4)
declare @dServVariableFee 	decimal(11,2)
declare @dServDisbPercent 	decimal(5,4)
Declare @dVarBaseFee		decimal(11,2)
Declare @dVarVariableFee	decimal(11,2)

declare	@bRoundLocalValue	bit
declare	@nRoundBilledValue	smallint
declare @nRoundValue		smallint

-- Cost calculation
declare @nCostPercent1		decimal(6,2)
declare @nCostPercent2		decimal(6,2)
declare	@nLocalDecimalPlaces	tinyint

declare @sFeeType		nvarchar(6)	-- RCT 07/03/2002	New variable added
declare @sFeeType2		nvarchar(6)	-- RFC6478

declare @sAltServProc		nvarchar(20)
declare @sAltDisbProc		nvarchar(20)
declare	@sAltVarProc		nvarchar(20)
declare	@bAltServCycleFlag	bit		-- RFC13050
declare	@bAltDisbCycleFlag	bit		-- RFC13050
declare	@bAltVarCycleFlag	bit		-- RFC13050
declare @sSQLString		nvarchar(max)
declare @nComponentType		smallint
declare @bResultBySelect	bit
declare @sTempTaxCode		nvarchar(3)	-- Temp holder for new tax code if there is one
declare @bSellRateOnly  	bit
declare @nDisbMarginAmt		decimal(10,2)	-- disbursement margin as a fixed amount
declare	@sDisbMarginCurr	nvarchar(3)	-- currency of @nDisbMarginAmt
declare @nServMarginAmt		decimal(10,2)	-- service margin as a fixed amount
declare	@sServMarginCurr	nvarchar(3)	-- currency of @nServMarginAmt
declare	@sDebtorCurrency	nvarchar(3)	-- billing currency of the debtor
declare @dtEffectiveDate	datetime	-- passed as parameter in best fit logic

-- SQA 11943 allowed the two components of a calculation (Service & Disbursement) to now be defined
--           with independent labels so that either component can be a Service Charge or a Disbursement
--	     as determined by the associated WIP Code.
declare @bServIsServiceCharge	bit		-- indicates that "service" part of calc is actually a service charge
declare @bDisbIsServiceCharge	bit		-- indicates that "disbursement" part of calc is actually a service charge
declare @bVarIsServiceCharge	bit		-- indicates that "variable" part of calc is actually a service charge

declare	@bExtractDiscount	bit

declare @nUserIdentityId	int
declare	@sCulture		nvarchar(10)
declare	@sPeriodType		nchar(1)
declare	@sPeriodType2		nchar(1)

declare @nPeriodCount	   	int
declare @nPeriodCount2	   	int

declare @nUnitCount	   	int
declare @nUnitCount2	   	int
declare	@nEnteredQuantity2	int

declare @bUseHistExchRateBill	bit
declare @bUseHistExchRateDisb	bit
declare @bUseHistExchRateServ	bit
declare @dtExchTransDate	datetime
declare @dtMarginTransDate	datetime

declare @ErrorCode		int
-- SQA15969
declare @nFCProductCode	 	int
declare @nProductCode	 	int

declare @nExchDetailNameKey	int

-- SQA14649
declare @bMultiTierTax			bit
declare @sDisbStateTaxCode		nvarchar(3) -- State Tax Code. Intially set using WIP Template
declare @sServStateTaxCode		nvarchar(3) -- State Tax Code. Intially set using WIP Template
declare @sVarStateTaxCode		nvarchar(3) -- State Tax Code. Intially set using WIP Template
declare @nDisbStateTaxAmt		decimal(11,2)
declare @nDisbStateTaxBillAmt	decimal(11,2)
declare @nDisbStateTaxHomeAmt	decimal(11,2)
declare @nServStateTaxAmt		decimal(11,2)
declare @nServStateTaxBillAmt	decimal(11,2)
declare @nServStateTaxHomeAmt 	decimal(11,2)
declare @nVarStateTaxAmt		decimal(11,2)
declare @nVarStateTaxBillAmt	decimal(11,2)
declare @nVarStateTaxHomeAmt 	decimal(11,2)
declare @nDisbStateTaxRate 		decimal(11,4)
declare @nServStateTaxRate 		decimal(11,4)
declare @nVarStateTaxRate 		decimal(11,4)
declare @bDisbStateTaxOnTax		bit
declare @bServStateTaxOnTax		bit
declare @bVarStateTaxOnTax		bit
declare @bDisbStateTaxHarmonised	bit
declare @bServStateTaxHarmonised	bit
declare @bVarStateTaxHarmonised		bit
declare @sDestinationCountryCode 	nvarchar(3)	
declare @sSourceCountryCode 		nvarchar(3)	
declare @sDestinationState		nvarchar(20)
declare @sSourceState			nvarchar(20)
declare @sCaseFederalTaxCode 		nvarchar(3)
declare @sCaseStateTaxCode 		nvarchar(3)
declare @sIPNameFederalTaxCode 		nvarchar(3)
declare @sIPNameStateTaxCode 		nvarchar(3)
declare @sHomeCountryCode 		nvarchar(3)
declare @sEUTaxCode 			nvarchar(10)
declare @nQuantityAsDec   		decimal(9,2) -- SQA16374
-- SQA18298
declare @nDisbMarginCap		decimal(10,2)
declare @nServMarginCap		decimal(10,2)

-- RFC7270
declare @bDisbDiscFeeFlag		bit
declare @bServDiscFeeFlag		bit
declare @bDiscRestriction		bit
-- SQA19145
declare @nTempUnrounded		decimal(11,4)

--RFC12005
declare @sCaseType		nchar(2)
-- R56172
declare @bMarginAsSeparateWip	bit
declare @bRenewalFlag		bit
declare @sMarginWipCode		nvarchar(6)
declare @sMarginRenewalWipCode	nvarchar(6)
declare @sMarginWipTypeKey	nvarchar(6)
declare @sMarginWipCategoryKey	nvarchar(6)
declare @nMarginDiscountPercent decimal(6,3)
declare @bIsMarginDiscountBasedOnAmount decimal(1,0)
declare @sCountryCode           nvarchar(3)
declare @bUseBankRate           bit
declare @nBankRate              dec(11,4)
declare @nServBankRate          dec(11,4)
declare @nDisbBankRate          dec(11,4)

Set	@ErrorCode	=0
Set	@nUserIdentityId=0
Set	@sCulture	=NULL
Set	@sPeriodType	=NULL

Set	@nDisbMarginRate=NULL
Set	@nDisbMarginAmt	=NULL
Set	@sDisbMarginCurr=NULL
Set	@nServMarginRate=NULL
Set	@nServMarginAmt	=NULL
Set	@sServMarginCurr=NULL
Set	@sDebtorCurrency=NULL
Set	@dtEffectiveDate=NULL		-- currently not being set but passed as param to best fit

If @pbAgentItem = 1 AND ( @pnAgentNo IS NOT NULL )
	Set @nExchDetailNameKey = @pnAgentNo
Else
	Set @nExchDetailNameKey = @pnBillToNo

--Default the date. 
--Using getdate as the default in the param specification causes errors.
If @pdtTransactionDate is NULL
Begin
	Set @pdtTransactionDate = getdate()
End

-- set effective date to the WIP transaction date
Set @dtEffectiveDate = @pdtTransactionDate

-- Is the 'Margin as Separate WIP' site control applicable?
-- R56172
If @ErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bMarginAsSeparateWip = isnull(S.COLBOOLEAN,0 )
	from	SITECONTROL S
	WHERE 	S.CONTROLID = 'Margin as Separate WIP'"

	exec @ErrorCode=sp_executesql @sSQLString,
			N'@bMarginAsSeparateWip	bit		OUTPUT',
			  @bMarginAsSeparateWip	= @bMarginAsSeparateWip	OUTPUT

        If @bMarginAsSeparateWip = 1
        Begin
			  
	        If (@ErrorCode = 0)
	        Begin
		        Set @sSQLString = "
		        select  @sMarginWipCode = S.COLCHARACTER
		        from	SITECONTROL S
		        WHERE 	S.CONTROLID = 'Margin WIP Code'"

		        exec @ErrorCode=sp_executesql @sSQLString,
				        N'@sMarginWipCode	nvarchar(6)	OUTPUT',
				          @sMarginWipCode	= @sMarginWipCode OUTPUT
	        End
	
	        If (@ErrorCode = 0)
	        Begin
		        Set @sSQLString = "
		        select  @sMarginRenewalWipCode = S.COLCHARACTER
		        from	SITECONTROL S
		        WHERE 	S.CONTROLID = 'Margin Renewal WIP Code'"

		        exec @ErrorCode=sp_executesql @sSQLString,
				        N'@sMarginRenewalWipCode	nvarchar(6)	OUTPUT',
				          @sMarginRenewalWipCode	= @sMarginRenewalWipCode OUTPUT
	        End

                If (@bRenewalFlag = 1)
                Begin	
	                Set @sMarginWipCode = @sMarginRenewalWipCode
                End
                        
                If (@ErrorCode = 0) and (@sMarginWipCode is not null)
	        Begin
                        Set @sSQLString = 
			                "select @sMarginWipTypeKey = T.WIPTYPEID, 
				                @sMarginWipCategoryKey = T.CATEGORYCODE
			                from WIPTEMPLATE W
			                left join WIPTYPE T 	on (T.WIPTYPEID = W.WIPTYPEID)
			                where W.WIPCODE = @sMarginWipCode"			

		        exec @ErrorCode=sp_executesql @sSQLString,
				                N'@sMarginWipCategoryKey	nvarchar(2)		OUTPUT,
				                  @sMarginWipTypeKey		nvarchar(6)		OUTPUT,
				                  @sMarginWipCode		nvarchar(6)',
				                  @sMarginWipCategoryKey= @sMarginWipCategoryKey	OUTPUT,
				                  @sMarginWipTypeKey	= @sMarginWipTypeKey		OUTPUT,
				                  @sMarginWipCode	= @sMarginWipCode
	        End
        End
End

-- Get the specific FeesCalculation row using a best fit search

If  @ErrorCode=0
Begin
	Set @sSQLString="

	SELECT 	@bIPOfficeFeeFlag	=FC.IPOFFICEFEEFLAG, 
		@nParameterSource	=FC.PARAMETERSOURCE,
		@nParameterSource2	=FC.PARAMETERSOURCE2,
		@sDisbTaxCode		=W2.TAXCODE, 
		@sServTaxCode		=W1.TAXCODE,
		@sVarTaxCode		=W3.TAXCODE,
		@sDisbStateTaxCode	=W2.STATETAXCODE, 
		@sServStateTaxCode	=W1.STATETAXCODE,
		@sVarStateTaxCode	=W3.STATETAXCODE,
		@bDisbMinFeeFlag	=FC.DISBMINFEEFLAG, 
		@bServMinFeeFlag	=FC.SERVMINFEEFLAG, 
		@bVarMinFeeFlag		=FC.VARMINFEEFLAG,
		@dDisbBaseFee		=FC.DISBBASEFEE, 
		@dServBaseFee		=FC.SERVBASEFEE,
		@dVarBaseFee		=FC.VARBASEFEE,
		@nDisbBaseUnits		=FC.DISBBASEUNITS, 
		@nServBaseUnits		=FC.SERVBASEUNITS,
		@nVarBaseUnits		=FC.VARBASEUNITS,
		@nDisbUnitSize		=FC.DISBUNITSIZE, 
		@nServUnitSize		=FC.SERVUNITSIZE, 
		@nVarUnitSize		=FC.VARUNITSIZE, 
		@dDisbAddPercentage	=FC.DISBADDPERCENTAGE, 
		@dServAddPercentage	=FC.SERVADDPERCENTAGE, 
		@dDisbVariableFee	=FC.DISBVARIABLEFEE, 
		@dServVariableFee	=FC.SERVVARIABLEFEE,
		@dVarVariableFee	=FC.VARVARIABLEFEE,
		@nDisbMaxUnits		=FC.DISBMAXUNITS, 
		@nServMaxUnits		=FC.SERVMAXUNITS, 
		@nVarMaxUnits		=FC.VARMAXUNITS, 
		@sDisbWIPCode		=FC.DISBWIPCODE, 
		@sDisbWIPType		=T2.WIPTYPEID,
		@sDisbCategory		=T2.CATEGORYCODE,
		@sServWIPCode		=FC.SERVWIPCODE, 
		@sServWIPType		=T1.WIPTYPEID,
		@sServCategory		=T1.CATEGORYCODE,
		@sVarWIPCode		=FC.VARWIPCODE,  
		@sDisbCurrency		=FC.DISBCURRENCY, 
		@sServCurrency		=FC.SERVICECURRENCY, 
		@nDisbNarrative		=FC.DISBNARRATIVE, 
		@nServNarrative		=FC.SERVICENARRATIVE, 
		@dServDisbPercent	=FC.SERVDISBPERCENTAGE,
		@nDisbEmployeeNo	=isnull(FC.DISBEMPLOYEENO, @pnEmployee),
		@nServEmployeeNo	=isnull(FC.SERVEMPLOYEENO, @pnEmployee),
		@prnFeeUniqueId		=FC.UNIQUEID,
		@sFeeType		=FC.FEETYPE,			-- RCT 07/03/2002	New variable added
		@sFeeType2		=FC.FEETYPE2,
		@nFCProductCode		=FC.PRODUCTCODE,
		@bServIsServiceCharge	=CASE WHEN(isnull(T1.CATEGORYCODE,'SC')='SC') THEN 1 ELSE 0 END,
		@bDisbIsServiceCharge	=CASE WHEN(isnull(T2.CATEGORYCODE,'PD')='SC') THEN 1 ELSE 0 END,
		@bVarIsServiceCharge	=CASE WHEN(isnull(T3.CATEGORYCODE,'SC')='SC') THEN 1 ELSE 0 END,
		@bDisbDiscFeeFlag	=isnull(FC.DISBDISCFEEFLAG,0),
		@bServDiscFeeFlag	=isnull(FC.SERVDISCFEEFLAG,0) 	
	From  FEESCALCULATION FC
	left join WIPTEMPLATE W1	on (W1.WIPCODE  =FC.SERVWIPCODE)
	left join WIPTYPE T1		on (T1.WIPTYPEID=W1.WIPTYPEID)
	left join WIPTEMPLATE W2	on (W2.WIPCODE  =FC.DISBWIPCODE)
	left join WIPTYPE T2		on (T2.WIPTYPEID=W2.WIPTYPEID)
	left join WIPTEMPLATE W3	on (W3.WIPCODE  =FC.VARWIPCODE)
	left join WIPTYPE T3		on (T3.WIPTYPEID=W3.WIPTYPEID)
	WHERE FC.CRITERIANO=@pnCriteria"
	
	If @prnFeeUniqueId is not null
	Begin
		Set @sSQLString=@sSQLString+"
		and FC.UNIQUEID=@prnFeeUniqueId"
	End
	Else Begin
		Set @sSQLString=@sSQLString+"
	and   FC.UNIQUEID= convert(smallint,
				substring (
				(SELECT max (	CASE WHEN F.AGENT	is null THEN '0' ELSE '1' END +
						CASE WHEN F.DEBTOR	is null THEN '0' ELSE '1' END +
						CASE WHEN F.DEBTORTYPE	is null THEN '0' ELSE '1' END +
						CASE WHEN F.OWNER	is null THEN '0' ELSE '1' END +
						CASE WHEN F.INSTRUCTOR	is null THEN '0' ELSE '1' END +
						space(5-isnull(len(convert(varchar,CYCLENUMBER)),1))+isnull(convert(varchar(5),CYCLENUMBER),space(1))+
						isnull(convert(char(8), VALIDFROMDATE,112),'00000000')+		-- valid from date in YYYYMMDD format
						convert(char(5),F.UNIQUEID) )
				FROM   FEESCALCULATION F 
				left join CASEEVENT CE	on (CE.CASEID=@pnCaseId
							and CE.EVENTNO=F.FROMEVENTNO
							and CE.CYCLE=	(select max(CE1.CYCLE)
									 from CASEEVENT CE1
									 where CE1.CASEID=CE.CASEID
									 and   CE1.EVENTNO=CE.EVENTNO
									 and   CE1.CYCLE in (@pnCycle,1)))
				WHERE  F.CRITERIANO	= FC.CRITERIANO
				AND    F.UNIQUEID       is not null
				AND   (CYCLENUMBER     <= @pnAgeOfCase	OR CYCLENUMBER	 IS NULL) -- RFC12213 Use the matching CycleNumber or next lowest
				AND   (AGENT		= @pnAgentNo	OR AGENT	 IS NULL ) 
				AND   (DEBTOR		= @pnBillToNo	OR DEBTOR	 IS NULL ) 
				AND   (DEBTORTYPE	= @pnDebtorType	OR DEBTORTYPE	 IS NULL ) 
				AND   (OWNER		= @pnOwner	OR OWNER 	 IS NULL ) 
				AND   (INSTRUCTOR	= @pnInstructor	OR INSTRUCTOR	 IS NULL ) 			
				AND   (VALIDFROMDATE   <=coalesce(CE.EVENTDATE,@pdtFromEventDate,@dtEffectiveDate,@pdtLetterDate) OR VALIDFROMDATE IS NULL ) ), 19,5))"
	End				

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bIPOfficeFeeFlag	decimal(1,0)	OUTPUT, 
				  @nParameterSource	smallint	OUTPUT,
				  @nParameterSource2	smallint	OUTPUT,
				  @sDisbTaxCode		nvarchar(3)	OUTPUT, 
				  @sServTaxCode		nvarchar(3)	OUTPUT, 
				  @sVarTaxCode		nvarchar(3)	OUTPUT, 
				  @sDisbStateTaxCode	nvarchar(3)	OUTPUT, 
				  @sServStateTaxCode	nvarchar(3)	OUTPUT, 
				  @sVarStateTaxCode	nvarchar(3)	OUTPUT, 	
				  @bDisbMinFeeFlag	decimal(1,0)	OUTPUT, 
				  @bServMinFeeFlag	decimal(1,0)	OUTPUT,  
				  @bVarMinFeeFlag	decimal(1,0)	OUTPUT,
				  @dDisbBaseFee		decimal(11,2)	OUTPUT, 
				  @dServBaseFee		decimal(11,2)	OUTPUT, 
				  @dVarBaseFee		decimal(11,2)	OUTPUT,
				  @nDisbBaseUnits	smallint	OUTPUT, 
				  @nServBaseUnits	smallint	OUTPUT,
				  @nVarBaseUnits	smallint	OUTPUT,
				  @nDisbUnitSize	smallint	OUTPUT, 
				  @nServUnitSize	smallint	OUTPUT,
				  @nVarUnitSize		smallint	OUTPUT, 
				  @dDisbAddPercentage	decimal(5,4)	OUTPUT, 
				  @dServAddPercentage	decimal(5,4)	OUTPUT, 
				  @dDisbVariableFee	decimal(11,2)	OUTPUT, 
				  @dServVariableFee	decimal(11,2)	OUTPUT,
				  @dVarVariableFee	decimal(11,2)	OUTPUT,
				  @nDisbMaxUnits	smallint	OUTPUT, 
				  @nServMaxUnits	smallint	OUTPUT,
				  @nVarMaxUnits		smallint	OUTPUT,
				  @sDisbWIPCode		nvarchar(6)	OUTPUT, 
				  @sDisbWIPType		nvarchar(6)	OUTPUT,
				  @sDisbCategory	nvarchar(3)	OUTPUT,
				  @sServWIPCode		nvarchar(6)	OUTPUT, 
				  @sServWIPType		nvarchar(6)	OUTPUT,
				  @sServCategory	nvarchar(3)	OUTPUT,
				  @sVarWIPCode		nvarchar(6)	OUTPUT, 
				  @sDisbCurrency	nvarchar(3)	OUTPUT, 
				  @sServCurrency	nvarchar(3)	OUTPUT, 
				  @nDisbNarrative	int		OUTPUT, 
				  @nServNarrative	int		OUTPUT, 
				  @dServDisbPercent	decimal(5,4)	OUTPUT,
				  @nDisbEmployeeNo	int		OUTPUT,
				  @nServEmployeeNo	int		OUTPUT,
				  @prnFeeUniqueId	int		OUTPUT,
				  @sFeeType		nvarchar(6)	OUTPUT,
				  @sFeeType2		nvarchar(6)	OUTPUT,
				  @nFCProductCode   int     OUTPUT,
				  @bServIsServiceCharge bit		OUTPUT,
				  @bDisbIsServiceCharge bit		OUTPUT,
				  @bVarIsServiceCharge bit		OUTPUT,
				  @bDisbDiscFeeFlag	bit		OUTPUT,
				  @bServDiscFeeFlag     bit		OUTPUT,
				  @pnCriteria		int,
				  @pnCaseId		int,
				  @pnCycle		smallint,
				  @pnAgeOfCase		int,
				  @pnAgentNo		int,
				  @pnBillToNo		int,
				  @pnDebtorType		int,
				  @pnOwner		int,
				  @pnInstructor		int,
				  @dtEffectiveDate	datetime,
				  @pdtLetterDate	datetime,
				  @pdtFromEventDate	datetime,
				  @pnEmployee		int',
				  @bIPOfficeFeeFlag			OUTPUT,
				  @nParameterSource			OUTPUT,
				  @nParameterSource2			OUTPUT,
				  @sDisbTaxCode				OUTPUT, 
				  @sServTaxCode				OUTPUT,
				  @sVarTaxCode				OUTPUT,
				  @sDisbStateTaxCode			OUTPUT, 
				  @sServStateTaxCode			OUTPUT, 
				  @sVarStateTaxCode			OUTPUT, 
				  @bDisbMinFeeFlag			OUTPUT, 
				  @bServMinFeeFlag			OUTPUT, 
				  @bVarMinFeeFlag			OUTPUT,
				  @dDisbBaseFee				OUTPUT, 
				  @dServBaseFee				OUTPUT,
				  @dVarBaseFee				OUTPUT,
				  @nDisbBaseUnits			OUTPUT, 
				  @nServBaseUnits			OUTPUT,
				  @nVarBaseUnits			OUTPUT,
				  @nDisbUnitSize			OUTPUT, 
				  @nServUnitSize			OUTPUT, 
				  @nVarUnitSize				OUTPUT,
				  @dDisbAddPercentage			OUTPUT, 
				  @dServAddPercentage			OUTPUT, 
				  @dDisbVariableFee			OUTPUT, 
				  @dServVariableFee			OUTPUT,
				  @dVarVariableFee			OUTPUT,
				  @nDisbMaxUnits			OUTPUT, 
				  @nServMaxUnits			OUTPUT, 
				  @nVarMaxUnits				OUTPUT,
				  @sDisbWIPCode				OUTPUT, 
				  @sDisbWIPType				OUTPUT,
				  @sDisbCategory			OUTPUT,
				  @sServWIPCode				OUTPUT, 
				  @sServWIPType				OUTPUT,
				  @sServCategory			OUTPUT, 
				  @sVarWIPCode				OUTPUT,
				  @sDisbCurrency			OUTPUT, 
				  @sServCurrency			OUTPUT, 
				  @nDisbNarrative			OUTPUT, 
				  @nServNarrative			OUTPUT, 
				  @dServDisbPercent			OUTPUT,
				  @nDisbEmployeeNo			OUTPUT,
				  @nServEmployeeNo			OUTPUT,
				  @prnFeeUniqueId			OUTPUT,
				  @sFeeType				OUTPUT,
				  @sFeeType2				OUTPUT,
				  @nFCProductCode		OUTPUT,
				  @bServIsServiceCharge			OUTPUT,
				  @bDisbIsServiceCharge			OUTPUT,
				  @bVarIsServiceCharge			OUTPUT,
				  @bDisbDiscFeeFlag			OUTPUT,
				  @bServDiscFeeFlag     		OUTPUT,
				  @pnCriteria,
				  @pnCaseId,
				  @pnCycle,
				  @pnAgeOfCase,
				  @pnAgentNo,
				  @pnBillToNo,
				  @pnDebtorType,
				  @pnOwner,
				  @pnInstructor,
				  @dtEffectiveDate,
				  @pdtLetterDate,
				  @pdtFromEventDate,
				  @pnEmployee

	-- If no FEESCALCULATION row is found set the error code
	If  @prnFeeUniqueId is null
	and @ErrorCode=0
		Select @ErrorCode=-3

End

If @ErrorCode=0
Begin
	Set @nDisbBaseFee       = isnull(@dDisbBaseFee      ,0)
	Set @nServBaseFee       = isnull(@dServBaseFee      ,0)
	Set @nVarBaseFee        = isnull(@dVarBaseFee       ,0)
	Set @nDisbVariableFee   = isnull(@dDisbVariableFee  ,0)
	Set @nServVariableFee   = isnull(@dServVariableFee  ,0)
	Set @nVarVariableFee    = isnull(@dVarVariableFee   ,0)
	Set @nServDisbPercent   = isnull(@dServDisbPercent  ,0)
	Set @nDisbAddPercentage = @dDisbAddPercentage
	Set @nServAddPercentage = @dServAddPercentage
End

-- 15969 default the Product code from fee calculation row if not set
If @ErrorCode=0
Begin
	If (@pnProductCode is null)
       Set @nProductCode = @nFCProductCode
    Else
       Set @nProductCode = @pnProductCode
End

-- CR 11/09/2002 check to see if any Alternate Stored procedures have been specified.
if @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT @sAltServProc = A.PROCEDURENAME,
	       @bAltServCycleFlag = cast(P.ORDINAL_POSITION as bit)
	FROM FEESCALCALT A
	left join INFORMATION_SCHEMA.PARAMETERS P on (P.SPECIFIC_NAME=A.PROCEDURENAME
						  and P.PARAMETER_NAME='@pnCycle')
	WHERE A.CRITERIANO = @pnCriteria AND
	A.UNIQUEID = @prnFeeUniqueId AND
	A.COMPONENTTYPE = 0"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAltServProc		nvarchar(20)	OUTPUT,
				  @bAltServCycleFlag	bit		OUTPUT,
				  @pnCriteria		int,
				  @prnFeeUniqueId	int',
				  @sAltServProc				OUTPUT,
				  @bAltServCycleFlag			OUTPUT,
				  @pnCriteria,
				  @prnFeeUniqueId
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT @sAltDisbProc = A.PROCEDURENAME,
	       @bAltDisbCycleFlag = cast(P.ORDINAL_POSITION as bit)
	FROM FEESCALCALT A
	left join INFORMATION_SCHEMA.PARAMETERS P on (P.SPECIFIC_NAME=A.PROCEDURENAME
						  and P.PARAMETER_NAME='@pnCycle')
	WHERE A.CRITERIANO = @pnCriteria AND
	A.UNIQUEID = @prnFeeUniqueId AND
	A.COMPONENTTYPE = 1"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAltDisbProc		nvarchar(20)	OUTPUT,
				  @bAltDisbCycleFlag	bit		OUTPUT,
				  @pnCriteria		int,
				  @prnFeeUniqueId	int',
				  @sAltDisbProc				OUTPUT,
				  @bAltDisbCycleFlag			OUTPUT,
				  @pnCriteria,
				  @prnFeeUniqueId
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT @sAltVarProc = A.PROCEDURENAME,
	       @bAltVarCycleFlag = cast(P.ORDINAL_POSITION as bit)
	FROM FEESCALCALT A
	left join INFORMATION_SCHEMA.PARAMETERS P on (P.SPECIFIC_NAME=A.PROCEDURENAME
						  and P.PARAMETER_NAME='@pnCycle')
	WHERE A.CRITERIANO = @pnCriteria AND
	A.UNIQUEID = @prnFeeUniqueId AND
	A.COMPONENTTYPE = 2"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAltVarProc	nvarchar(20)	OUTPUT,
				  @bAltVarCycleFlag	bit		OUTPUT,
				  @pnCriteria		int,
				  @prnFeeUniqueId	int',
				  @sAltVarProc			OUTPUT,
				  @bAltVarCycleFlag			OUTPUT,
				  @pnCriteria,
				  @prnFeeUniqueId
End

-- MF 08/01/2001 Change the test of @pnEnteredQuantity and @pnEnteredAmount to also test for zero

If  @ErrorCode=0
Begin
	Set @nEnteredQuantity2=@pnEnteredQuantity

	If @nParameterSource is not null
		exec @ErrorCode=pt_GetQuantity 
				@nParameterSource, 
				@pnEnteredQuantity, 
				@pnCaseId, 
				@pnNoInSeries, 
				@pnNoOfClasses, 
				@pnCycle, 
				@pnEventNo, 
				@pdtFromDateDisb,
				@pdtUntilDate,
				@pnEnteredQuantity output,
				@sPeriodType	   output,
				@nPeriodCount	   output,
				@nUnitCount	   output
End

-- A second source of quantity parameter is now used for the second component of the calculation  (service charge)
If @ErrorCode=0
Begin
	If  @nParameterSource2=@nParameterSource
	or (@nParameterSource2 is null and @nParameterSource is null)
	Begin
		-- DR-47444 Service Charge component of Renewal Fee not including amount for additional classes
		if @nEnteredQuantity2 is null or @nEnteredQuantity2 = 0
			Set @nEnteredQuantity2 = @pnEnteredQuantity 
		Set @sPeriodType2     =@sPeriodType
		Set @nPeriodCount2    =@nPeriodCount
		Set @nUnitCount2      =@nUnitCount
	End
	Else If @nParameterSource2 is not null
		exec @ErrorCode=pt_GetQuantity 
				@nParameterSource2, 
				@nEnteredQuantity2, 
				@pnCaseId, 
				@pnNoInSeries, 
				@pnNoOfClasses, 
				@pnCycle, 
				@pnEventNo,
				@pdtFromDateServ,
				@pdtUntilDate,
				@nEnteredQuantity2 output,
				@sPeriodType2	   output,
				@nPeriodCount2	   output,
				@nUnitCount2	   output
End

If @ErrorCode=0
Begin	
	If isnull(@pnEnteredAmount,0) = 0
		Set @pnEnteredAmount = isnull(@pnARAmount,0)
		
	If @pnEnteredQuantity is null
		Set @pnEnteredQuantity = 0
	If @nEnteredQuantity2 is null
		Set @nEnteredQuantity2 = 0
	If @pnEnteredAmount   is null
		Set @pnEnteredAmount   = 0
	If @nDisbBaseFee      is null
		Set @nDisbBaseFee      = 0
	If @nServBaseFee      is null
		Set @nServBaseFee      = 0
	If @nVarBaseFee       is null
		Set @nVarBaseFee       = 0
	If @nDisbBaseUnits    is null
		Set @nDisbBaseUnits    = 0
	If @nServBaseUnits    is null
		Set @nServBaseUnits    = 0
	If @nVarBaseUnits     is null
		Set @nVarBaseUnits     = 0
	If @nDisbUnitSize     is null
		Set @nDisbUnitSize     = 0
	If @nServUnitSize     is null
		Set @nServUnitSize     = 0
	If @nVarUnitSize      is null
		Set @nVarUnitSize      = 0
	If @nDisbVariableFee  is null
		Set @nDisbVariableFee  = 0
	If @nServVariableFee  is null
		Set @nServVariableFee  = 0
	If @nVarVariableFee   is null
		Set @nVarVariableFee  = 0
	If @nDisbMaxUnits     is null
		Set @nDisbMaxUnits     = 0
	If @nServMaxUnits     is null
		Set @nServMaxUnits     = 0	
	If @nVarMaxUnits      is null
		Set @nVarMaxUnits      = 0	
	If @nServDisbPercent  is null
		Set @nServDisbPercent  = 0
End

-- Discounts required?
If @ErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bExtractDiscount =
		CASE WHEN(D.COLBOOLEAN = 1)
			Then
				-- Suppress discounts in billing
				CASE  WHEN(@pbIsChargeGeneration = 0
					      and isnull(B.COLBOOLEAN,0) = 1)
					Then 0
					Else 1
				END
			Else 0
		END
	from SITECONTROL D
	left join SITECONTROL B	on (B.CONTROLID = 'DiscountNotInBilling')
	WHERE 	D.CONTROLID = 'Discounts'"

	exec @ErrorCode=sp_executesql @sSQLString,
			N'@pbIsChargeGeneration		bit,
			  @bExtractDiscount		bit		OUTPUT',
			  @pbIsChargeGeneration	= @pbIsChargeGeneration,
			  @bExtractDiscount	= @bExtractDiscount	OUTPUT
End

-- Double Discount Restriction Applied?
If @ErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bDiscRestriction = COLBOOLEAN		
	from SITECONTROL 
	WHERE 	CONTROLID = 'Double Discount Restriction'"

	exec @ErrorCode=sp_executesql @sSQLString,
			N'@bDiscRestriction	bit			OUTPUT',
			  @bDiscRestriction	= @bDiscRestriction	OUTPUT
End

-- Get the DISCOUNT rates
--=======================

-- Get the Discount for the Disbursement

If  @ErrorCode=0
and @pnBillToNo is not null
and @bExtractDiscount=1
Begin
	if (@psCaseType is null)
	Begin
		Set @sSQLString = "Select @sCaseType = CASETYPE from CASES where CASEID = @pnCaseId"
		
		exec @ErrorCode = sp_executesql @sSQLString,
				N'@sCaseType	nchar(2)	OUTPUT,
				@pnCaseId	int',
				@sCaseType	= @sCaseType	OUTPUT,
				@pnCaseId	= @pnCaseId
	End
	Else
	Begin
		Set @sCaseType = @psCaseType
	End

        if (@psCountryCode is null)
	Begin
		Set @sSQLString = "Select @sCountryCode = COUNTRYCODE from CASES where CASEID = @pnCaseId"
		
		exec @ErrorCode = sp_executesql @sSQLString,
				N'@sCountryCode	nvarchar(3)	OUTPUT,
				@pnCaseId	int',
				@sCountryCode	= @sCountryCode	OUTPUT,
				@pnCaseId	= @pnCaseId
	End
	Else
	Begin
		Set @sCountryCode = @psCountryCode
	End
End
		
If  @ErrorCode=0
and @pnBillToNo is not null
and @bExtractDiscount=1
Begin	
	-- Get discount if its already not apllied on the Disbursment fee
	If (@bDiscRestriction = 1 and @bDisbDiscFeeFlag = 0) or @bDiscRestriction = 0
	Begin
	exec @ErrorCode=dbo.pt_GetDiscountRate 
				@pnBillToNo, 
				@sDisbWIPType,
				@sDisbCategory,
				@psPropertyType,
				@psAction,
				@nDisbEmployeeNo,
				@nProductCode,
				@nDisbDiscountRate output,
				@nDisbBaseOnAmount output,
				@pnOwner,
				@sDisbWIPCode,
				@sCaseType,
                                @sCountryCode
End
End

-- Get the Discount for the Service Charge

If  @ErrorCode=0
and @pnBillToNo is not null
and @bExtractDiscount=1
Begin
	-- Get discount if its already not apllied on the Service fee
	If (@bDiscRestriction = 1 and @bServDiscFeeFlag = 0) or @bDiscRestriction = 0
	Begin
	exec @ErrorCode=dbo.pt_GetDiscountRate 
				@pnBillToNo, 
				@sServWIPType,
				@sServCategory,
				@psPropertyType,
				@psAction,
				@nServEmployeeNo,
				@nProductCode,
				@nServDiscountRate output,
				@nServBaseOnAmount output,
				@pnOwner,
				@sServWIPCode,
				@sCaseType,
                                @sCountryCode
End
End

-- Get the MARGIN rates
--=====================

-- Get the Postal Country of the Instructor as it is required to determine the Margin

If  @ErrorCode=0
and @pnInstructor is not null
Begin
	Set @sSQLString="
	select	@sInstructorCountry=COUNTRYCODE
	from	NAME N
	join	ADDRESS	A on (A.ADDRESSCODE=N.POSTALADDRESS)
	where	N.NAMENO=@pnInstructor"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sInstructorCountry	nvarchar(3)	OUTPUT,
				  @pnInstructor		int',
				  @sInstructorCountry			OUTPUT,
				  @pnInstructor
End

-- Get the Postal Country and Billing Currency of the Debtor
If  @ErrorCode=0
and @pnBillToNo is not null
Begin
	Set @sSQLString="
	select	@sDebtorCountry =A.COUNTRYCODE,
		@sDebtorCurrency=IP.CURRENCY
	from	NAME N
	left join ADDRESS A on (A.ADDRESSCODE=N.POSTALADDRESS)
	left join IPNAME IP on (IP.NAMENO=N.NAMENO)
	where	N.NAMENO=@pnBillToNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sDebtorCountry	nvarchar(3)	OUTPUT,
				  @sDebtorCurrency	nvarchar(3)	OUTPUT,
				  @pnBillToNo		int',
				  @sDebtorCountry			OUTPUT,
				  @sDebtorCurrency			OUTPUT,
				  @pnBillToNo
End

-- Get the Margin rate to use for the disbursement.  
-- A Margin is only required if the Fees & Charges calculation does not have an uplift
-- factor built into it.

If @ErrorCode=0
Begin
	If  @sDisbCategory  is not NULL
	Begin
		exec @ErrorCode=dbo.pt_GetMargin
					@prnMarginPercentage	=@nDisbMarginRate OUTPUT,
					@prnMarginAmount	=@nDisbMarginAmt  OUTPUT,
					@prsMarginCurrency	=@sDisbMarginCurr OUTPUT,
					@psWIPCategory		=@sDisbCategory,
					@pnEntityNo		=@pnEntity,
					@psWIPType		=@sDisbWIPType,
					@pnCaseId		=@pnCaseId,
					@pnInstructor		=@pnInstructor,
					@pnDebtor		=@pnBillToNo,
					@psInstructorCountry	=@sInstructorCountry,
					@psDebtorCountry	=@sDebtorCountry,
					@psPropertyType		=@psPropertyType,
					@psAction		=@psAction,
					@pdtEffectiveDate	=@dtEffectiveDate,
					@psDebtorCurrency	=@sDebtorCurrency,
					@pnAgent		=@pnAgentNo,
					@psCountryCode		=@psCountryCode,
					@psCaseType		=@psCaseType,
					@psCaseCategory		=@psCaseCategory,
					@psSubType		=@psSubType,
					@prnMarginNo	=@prnDisbMarginNo OUTPUT,
					@prnMarginCap	=@nDisbMarginCap  OUTPUT,
					@psWIPCode		=@sDisbWIPCode
	end
	Else Begin
		Set @nDisbMarginRate =NULL
		Set @nDisbMarginAmt  =NULL
		Set @sDisbMarginCurr =NULL
	End

	If @nDisbAddPercentage is NULL
		Set @nDisbAddPercentage= 0
End

-- Get the Margin percentage to use for the service charge 
-- A Margin is only required if the Fees & Charges calculation does not have an uplift
-- factor built into it.

If @ErrorCode=0
Begin
	If  @sServCategory  is not NULL
	Begin
		exec @ErrorCode=dbo.pt_GetMargin
					@prnMarginPercentage	=@nServMarginRate OUTPUT,
					@prnMarginAmount	=@nServMarginAmt  OUTPUT,
					@prsMarginCurrency	=@sServMarginCurr OUTPUT,
					@psWIPCategory		=@sServCategory,
					@pnEntityNo		=@pnEntity,
					@psWIPType		=@sServWIPType,
					@pnCaseId		=@pnCaseId,
					@pnInstructor		=@pnInstructor,
					@pnDebtor		=@pnBillToNo,
					@psInstructorCountry	=@sInstructorCountry,
					@psDebtorCountry	=@sDebtorCountry,
					@psPropertyType		=@psPropertyType,
					@psAction		=@psAction,
					@pdtEffectiveDate	=@dtEffectiveDate,
					@psDebtorCurrency	=@sDebtorCurrency,
					@pnAgent		=@pnAgentNo,
					@psCountryCode		=@psCountryCode,
					@psCaseType		=@psCaseType,
					@psCaseCategory		=@psCaseCategory,
					@psSubType		=@psSubType,
					@prnMarginNo		=@prnServMarginNo OUTPUT,
					@prnMarginCap	=@nServMarginCap  OUTPUT,
					@psWIPCode		=@sServWIPCode

	end
	Else Begin
		Set @nServMarginRate =NULL
		Set @nServMarginAmt  =NULL
		Set @sServMarginCurr =NULL
	End

	If @nServAddPercentage is NULL
		Set @nServAddPercentage=0
End

-- Determine if Rounding of Decimal Places is required for Local Values and Local Tax
--======================

If @ErrorCode=0
Begin
	Set @sSQLString = "
	select  @nLocalDecimalPlaces = case when W.COLBOOLEAN = 1 then 0 else isnull(CY.DECIMALPLACES,2) end,
		@bRoundLocalValue = isnull(W.COLBOOLEAN,0)
	from	SITECONTROL C
	left join CURRENCY CY	on (CY.CURRENCY = C.COLCHARACTER
				-- Decimal places implemented in Charge Generation
				and isnull(@pbIsChargeGeneration,0) = 0 )
	left join SITECONTROL W on (W.CONTROLID = 'Currency Whole Units')
	WHERE 	C.CONTROLID = 'CURRENCY'"

	exec @ErrorCode=sp_executesql @sSQLString,
			N'@pbIsChargeGeneration	bit,
			  @nLocalDecimalPlaces	tinyint			OUTPUT,
			  @bRoundLocalValue	bit			OUTPUT',
			  @pbIsChargeGeneration	= @pbIsChargeGeneration,
			  @nLocalDecimalPlaces	= @nLocalDecimalPlaces	OUTPUT,
			  @bRoundLocalValue	= @bRoundLocalValue	OUTPUT
End
 
-- Get the CURRENCY details for the Currencies used
--=================

-- Get the Home Currency

If @ErrorCode=0
Begin
	Set @sSQLString="		
	SELECT 	@sHomeCurrency=COLCHARACTER 
	FROM	SITECONTROL 
	WHERE   CONTROLID = 'CURRENCY'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sHomeCurrency	nvarchar(3)	OUTPUT',
				  @sHomeCurrency	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@bSellRateOnly=COLBOOLEAN
	from	SITECONTROL
	where	CONTROLID = 'Sell Rate Only for New WIP'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bSellRateOnly	bit		OUTPUT',
				  @bSellRateOnly	OUTPUT
End	

If @ErrorCode=0
Begin
         Set @sSQLString = "
	 select  @bUseBankRate = isnull(COLBOOLEAN,0)
	 from	SITECONTROL
	 WHERE 	CONTROLID = 'Bank Rate In Use for Service Charges'"
		
	 exec @ErrorCode=sp_executesql @sSQLString,
				N'@bUseBankRate		bit			OUTPUT',
				@bUseBankRate		= @bUseBankRate		OUTPUT

			
End	

-- Get the exchange rate for the Billing Currency

If @ErrorCode=0
Begin
	If @pbUseTodaysExchangeRate=1
		Set @dtExchTransDate=getdate()
	Else
		Set @dtExchTransDate = @pdtBillDate

	Set @nBillBuyRate = null
	Set @nBillSellRate = null

	If @prsBillCurrency=@sHomeCurrency
	or @prsBillCurrency is null
	Begin
		Set @prsBillCurrency  = @sHomeCurrency
		Set @nBillExchRate    = 1
		Set @nBillBuyRate     = 1
		Set @nBillSellRate    = 1
		Set @nRoundBilledValue= 0
	end
	Else 
	begin
		-- Get the Use Historical Exchange Rate Flag for the disbursement.
		exec @ErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @bUseHistExchRateBill output,
			@pdtTransactionDate	= @dtExchTransDate output,
			@pnUserIdentityId	= @nUserIdentityId,
			@pbCalledFromCentura	= 1,
			@psWIPCategory		= NULL,
			@pnAccountingSystemID	= 2 --	2  Time and Billing

		exec @ErrorCode = dbo.ac_GetExchangeDetails
                                        @pnBankRate		= @nBankRate            output,
					@pnBuyRate		= @nBillBuyRate		output,
					@pnSellRate		= @nBillSellRate	output,
					@pnDecimalPlaces	= @nDecimalPlaces 	output,
					@pnUserIdentityId	= @nUserIdentityId,
					@pbCalledFromCentura	= 1,
					@psCurrencyCode		= @prsBillCurrency,
					@pdtTransactionDate	= @dtExchTransDate,
					@pbUseHistoricalRates	= @bUseHistExchRateBill,
					@pnCaseID		= @pnCaseId,
					@pnNameNo		= @pnBillToNo,
					@pbIsSupplier		= 0,
					@psCaseType     	= @psCaseType,
					@psCountryCode		= @psCountryCode,
					@psPropertyType		= @psPropertyType,
					@psCaseCategory		= @psCaseCategory,
					@psSubType		= @psSubType,
					@pnExchScheduleId	= @pnExchScheduleId,
					@pnRoundBilledValues	= @nRoundBilledValue output,
					@psWIPTypeId		= null

		Set @nBillExchRate = @nBillSellRate
	end
End

-- Get the exchange rate for the Disbursement Currency
-- Note: Even though all the code refers to this as a disbursement 
-- it is possible for the WIP Category of this WIP item to be something other 
-- than 'PD' i.e. paid disbursement. As a result both the 'Disbursement' and 'Service Charges'
-- sections need to work exactly the same when derving/calculating exchange rates, discounts and margins

If @ErrorCode=0
Begin

	If @pbUseTodaysExchangeRate=1
		Set @dtExchTransDate=getdate()
	Else
		Set @dtExchTransDate=@pdtTransactionDate

	Set @nDisbBuyRate = null
	Set @nDisbSellRate = null


	If @sDisbCurrency = @sHomeCurrency
	or @sDisbCurrency is null
	Begin
		Set @nDisbExchRate = 1
		Set @sDisbCurrency = @sHomeCurrency
	End
	Else
	Begin
		-- Get the Use Historical Exchange Rate Flag for the disbursement.
		exec @ErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @bUseHistExchRateDisb output,
			@pdtTransactionDate	= @dtExchTransDate output,
			@pnUserIdentityId	= @nUserIdentityId,
			@pbCalledFromCentura	= 1,
			@psWIPCategory		= @sDisbCategory,
			@pnAccountingSystemID	= 2 --	2  Time and Billing
	
			
		exec @ErrorCode = dbo.ac_GetExchangeDetails
                @pnBankRate             = @nDisbBankRate output,
		@pnBuyRate		= @nDisbBuyRate output,
		@pnSellRate		= @nDisbSellRate output,
		@pnDecimalPlaces	= @nDisbDecimalPlaces output,
		@pnUserIdentityId	= @nUserIdentityId,
		@pbCalledFromCentura	= 1,
		@psCurrencyCode		= @sDisbCurrency,
		@pdtTransactionDate	= @dtExchTransDate,
		@pbUseHistoricalRates	= @bUseHistExchRateDisb,
		@pnCaseID		= @pnCaseId,
		@pnNameNo		= @nExchDetailNameKey,
		@pbIsSupplier		= @pbAgentItem,
		@psCaseType     	= @psCaseType,
		@psCountryCode		= @psCountryCode,
		@psPropertyType		= @psPropertyType,
		@psCaseCategory		= @psCaseCategory,
		@psSubType		= @psSubType,
		@pnExchScheduleId	= @pnExchScheduleId,
		@pnRoundBilledValues	= @nRoundValue output,
		@psWIPTypeId		= @sDisbWIPType

		If @bUseBankRate = 1 and @sDisbCategory = 'SC'
		Begin
			Set @nDisbExchRate = @nDisbBankRate
		End
                Else If (@bSellRateOnly = 1) OR (@sDisbCategory = 'SC')
                Begin
			Set @nDisbExchRate = @nDisbSellRate
                End
		Else
			Set @nDisbExchRate = @nDisbBuyRate               
	End
End

-- Get the exchange rate for the Service Currency

If @ErrorCode=0
Begin
	If @pbUseTodaysExchangeRate=1
		Set @dtExchTransDate=getdate()
	Else
		Set @dtExchTransDate=@pdtTransactionDate

	Set @nServBuyRate = null
	Set @nServSellRate = null

	If @sServCurrency = @sHomeCurrency
	or @sServCurrency is null
	Begin
		Set @nServExchRate = 1
		Set @sServCurrency = @sHomeCurrency
	End
	Else 
	Begin
		-- Get the Use Historical Exchange Rate Flag for the Service Charge.
		exec @ErrorCode = dbo.ac_GetExchangeParameters
			@pbUseHistoricalRates	= @bUseHistExchRateServ output,
			@pdtTransactionDate	= @dtExchTransDate output,
			@pnUserIdentityId	= @nUserIdentityId,
			@pbCalledFromCentura	= 1,
			@psWIPCategory		= @sServCategory,
			@pnAccountingSystemID	= 2 --	2  Time and Billing

		exec @ErrorCode = dbo.ac_GetExchangeDetails
                                @pnBankRate             = @nServBankRate output,
				@pnBuyRate		= @nServBuyRate output,
				@pnSellRate		= @nServSellRate output,
				@pnDecimalPlaces	= @nServDecimalPlaces output,
				@pnUserIdentityId	= @nUserIdentityId,
				@pbCalledFromCentura	= 1,
				@psCurrencyCode		= @sServCurrency,
				@pdtTransactionDate	= @dtExchTransDate,
				@pbUseHistoricalRates	= @bUseHistExchRateServ,
				@pnCaseID		= @pnCaseId,
				@pnNameNo		= @nExchDetailNameKey,
				@pbIsSupplier		= @pbAgentItem,
				@psCaseType     	= @psCaseType,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType,
				@psCaseCategory		= @psCaseCategory,
				@psSubType		= @psSubType,
				@pnExchScheduleId	= @pnExchScheduleId,
				@pnRoundBilledValues	= @nRoundValue output,
				@psWIPTypeId		= @sServWIPType

                If @bUseBankRate = 1 and @sServCategory = 'SC'
		Begin
			Set @nServExchRate = @nServBankRate
		End
                Else If (@bSellRateOnly = 1) OR (@sServCategory = 'SC')
                Begin
			Set @nServExchRate = @nServSellRate
                End
		Else
			Set @nServExchRate = @nServBuyRate 
	End
		
End

-- Calculate the Disbursement Amount
--===========================
-- 11/09/2002 CR added alternate stored procedure logic


If @ErrorCode=0
Begin	
	if (@sAltDisbProc IS NOT NULL)
	Begin
		set @nComponentType = 1
		set @bResultBySelect= 0

		Set @sSQLString='Exec '+@sAltDisbProc+' '
		+isnull(convert(varchar,@pnCaseId) , 'NULL')+','
		+isnull(convert(varchar,@pnEnteredQuantity) , 'NULL')+','
		+isnull(convert(varchar,@pnEnteredAmount), 'NULL')+','
		+convert(varchar,@nComponentType)+','
		+convert(varchar,@pnCriteria)+','
		+convert(varchar,@prnFeeUniqueId)+ ','
		+convert(varchar,@bResultBySelect)+ ','
		+ '@nBasicAmount		OUTPUT,'
		+ '@nExtendedAmount		OUTPUT'

		---------------------------------------------------------------
		-- RFC13050
		-- If the user defined stored procedure has had the parameter
		-- @pnCycle defined then it will need to be pushed through to
		-- the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameter after the two OUTPUT parameters:
	
		-- @pnCycle			smallint	= null,
		---------------------------------------------------------------
		If @bAltDisbCycleFlag = 1
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@pnCycle is null) THEN 'NULL' ELSE convert(varchar,@pnCycle) END
		End

		---------------------------------------------------------------
		-- SQA15384
		-- If parameters for a simulated Case or simulated date range
		-- have been passed then these parameters will need to be pushed
		-- through to the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameters after the two OUTPUT parameters:
	
		-- @psCaseType			nchar(1)	= null,
		-- @psPropertyType		nchar(1)	= null,
		-- @psCountryCode		nvarchar(3)	= null,
		-- @psCaseCategory		nvarchar(2)	= null,
		-- @psSubType			nvarchar(2)	= null,
		-- @pnEntitySize		int		= null,
		-- @pnInstructor		int		= null,
		-- @pnBillToNo			int		= null,
		-- @pnDebtorType		int		= null,
		-- @pnAgentNo			int		= null,
		-- @psCurrency			nvarchar(3)	= null,
		-- @pnExchScheduleId		int		= null,
		-- @pdtFromDate			datetime	= null,
		-- @pdtUntilDate		datetime	= null
		---------------------------------------------------------------
		If(@psCaseType	     is not NULL
		or @psCountryCode    is not NULL
		or @psCaseCategory   is not NULL
		or @psSubType	     is not NULL
		or @pnInstructor     is not NULL
		or @pnBillToNo       is not NULL
		or @pnDebtorType     is not NULL
		or @pnAgentNo        is not NULL
		or @psCurrency       is not NULL
		or @pnExchScheduleId is not NULL
		or @pdtFromDateDisb  is not NULL
		or @pdtUntilDate     is not NULL)
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@psCaseType is null)       THEN 'NULL' ELSE ''''+@psCaseType+''''     END+','
			+CASE WHEN(@psPropertyType is null)   THEN 'NULL' ELSE ''''+@psPropertyType+'''' END+','
			+CASE WHEN(@psCountryCode is null)    THEN 'NULL' ELSE ''''+@psCountryCode+''''  END+','
			+CASE WHEN(@psCaseCategory is null)   THEN 'NULL' ELSE ''''+@psCaseCategory+'''' END+','
			+CASE WHEN(@psSubType is null)        THEN 'NULL' ELSE ''''+@psSubType+''''      END+','
			+CASE WHEN(@pnEntitySize is null)     THEN 'NULL' ELSE convert(varchar,@pnEntitySize) END+','
			+CASE WHEN(@pnInstructor is null)     THEN 'NULL' ELSE convert(varchar,@pnInstructor) END+','
			+CASE WHEN(@pnBillToNo is null)       THEN 'NULL' ELSE convert(varchar,@pnBillToNo)   END+','
			+CASE WHEN(@pnDebtorType is null)     THEN 'NULL' ELSE convert(varchar,@pnDebtorType) END+','
			+CASE WHEN(@pnAgentNo is null)        THEN 'NULL' ELSE convert(varchar,@pnAgentNo)    END+','
			+CASE WHEN(@psCurrency is null)       THEN 'NULL' ELSE ''''+@psCurrency+''''          END+','
			+CASE WHEN(@pnExchScheduleId is null) THEN 'NULL' ELSE convert(varchar,@pnExchScheduleId) END+','
			+CASE WHEN(@pdtFromDateDisb is null)  THEN 'NULL' ELSE ''''+convert(varchar,@pdtFromDateDisb,112)+'''' END+','
			+CASE WHEN(@pdtUntilDate is null)     THEN 'NULL' ELSE ''''+convert(varchar,@pdtUntilDate,112)+''''    END
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBasicAmount		decimal(11,2)	  OUTPUT,
						  @nExtendedAmount	decimal(11,2)	  OUTPUT',
						  @nBasicAmount=@prnDisbBasicAmount	  OUTPUT,
						  @nExtendedAmount=@prnDisbExtendedAmount OUTPUT		
	End

-- If the Quantity exceeds the Maximum allowed in the calculation then set it to the Maximum.
	Else Begin
		If @nPeriodCount>0
		Begin
			If ( @nDisbMaxUnits > 0) AND ( @nPeriodCount > @nDisbMaxUnits)
			Begin
				Set @nQuantity = @nDisbMaxUnits
			End
			Else Begin
				Set @nQuantity = @nPeriodCount
			End
		End
		Else Begin
			Set @nUnitCount =1 

			If ( @nDisbMaxUnits > 0) AND ( @pnEnteredQuantity > @nDisbMaxUnits)
			Begin
				Set @nQuantity = @nDisbMaxUnits
			End
			Else Begin
				Set @nQuantity = @pnEnteredQuantity
			End
		End

		-- If there is a minimum disbursement charge then set the Basic Amount to the minimum
		-- otherwise calculate the Basic Amount as a pro-rata of the Quantity.

		If @bDisbMinFeeFlag = 1
		Begin
			If @sPeriodType is null
				Set @prnDisbBasicAmount = @nDisbBaseFee * @nUnitCount
			Else
				-- Note that if a Period between dates is part of the calculation
				-- then a zero period should result in a zero Basic Amount
				If @nQuantity = 0
					Set @prnDisbBasicAmount = 0
				Else
					Set @prnDisbBasicAmount = @nDisbBaseFee * @nUnitCount
		End
		Else begin
			If @nQuantity >= @nDisbBaseUnits
			Begin
				Set @prnDisbBasicAmount = @nDisbBaseFee * @nUnitCount
			End
			Else begin	
				If ( @nDisbBaseUnits != 0)
					Set @prnDisbBasicAmount = @nQuantity * @nUnitCount * @nDisbBaseFee/ @nDisbBaseUnits
				Else
					Set @prnDisbBasicAmount = 0
			end
		end
	
		-- Now calculate the Extended Amount where the Quantity has exceeded the number allowed
		-- in the Base Amount.
		If @nQuantity <= @nDisbBaseUnits
		Begin
			Set @prnDisbExtendedAmount = 0
		End
		Else Begin		
			-- need to use a decimal to avoid automatic rounding to integer (SQA16374)
			Set @nQuantityAsDec = @nQuantity

			If @nDisbUnitSize = 0
			Begin
				Set @nChargeQuantity = @nQuantityAsDec - @nDisbBaseUnits
			End
			Else Begin
				Set @nChargeQuantity = (@nQuantityAsDec - @nDisbBaseUnits)/@nDisbUnitSize
			End

			Set @nRndChargeQuantity = @nChargeQuantity
			If  @nRndChargeQuantity < @nChargeQuantity
			Begin
				Set @nRndChargeQuantity = @nRndChargeQuantity + 1
			End
	
			Set @prnDisbExtendedAmount = @nDisbVariableFee * @nRndChargeQuantity * @nUnitCount
		End
	End	
End

if @ErrorCode=0
Begin
	-- Increase the Entered Amount by a disbursement uplift percentage.
	-- Note that DisbAddPercentage will be 100% if only the amount entered is to be billed.  

	Set @nEnteredAmount  = @pnEnteredAmount * @nDisbAddPercentage

	-- Now the Disbursement Amount is calculated by adding the Basic, Extended and uplifted Entered Amounts
	
	Set @nDisbAmount = @prnDisbBasicAmount + @prnDisbExtendedAmount + @nEnteredAmount

	
	-- Perform Adjustment if Separate Debtor Logic Used (9114)
	If (@pnDebtorPercentage > 0) and (@pnDebtorPercentage < 100)
	begin
		Set @nDisbAmount = @pnDebtorPercentage * @nDisbAmount /100

		-- always round up
		If @nDisbAmount > Round (@nDisbAmount, 2)
		begin	
			Set @nDisbAmount = Round (@nDisbAmount, 2) + 0.01
		end
		Else Begin
			Set @nDisbAmount = Round (@nDisbAmount, 2)
		end
	end		


	-- If the Disburesment exchange rate is 1 (indicating it is the same as the Home Currency)
	-- and the RoundLocalValue flag is on then round the DisbAmount to remove decimals
	
	if  (@nDisbExchRate   =1
	and @bRoundLocalValue=1)
		Set @nDisbAmount = Round (@nDisbAmount, 0)

	
	-- Convert the  Disbursement Amount into the Home Currency
	-- Round the result to remove decimals if required

	If @bRoundLocalValue = 1
		Set @nDisbHomeAmount = Round((@nDisbAmount/ @nDisbExchRate),0)
	Else
	Begin
		-- SQA19145 guard against rounding error
		--Set @nDisbHomeAmount = @nDisbAmount/ @nDisbExchRate
		Set @nTempUnrounded = @nDisbAmount/ @nDisbExchRate
		Set @nDisbHomeAmount = Round( @nTempUnrounded, 2)
	End
	-- Convert the Disbursement Amount into the Billing Currency

	If @prsBillCurrency=@sDisbCurrency
		Set @nDisbBillAmount = @nDisbAmount
	Else
		Set @nDisbBillAmount = @nDisbHomeAmount * @nBillExchRate

	-- Round the Billing amount to the nearest unit size as specified against the Billing Currency

	If @nRoundBilledValue <> 0
		exec @ErrorCode=pt_RoundToNearestUnitSize 
					@nDisbBillAmount,
					@nRoundBilledValue,
					@nDisbBillAmount	output
					
End	

-- Calculate the Service Charges
--==============================
-- 11/09/2002 CR added alternate stored procedure logic

If @ErrorCode=0
Begin			
	if (@sAltServProc IS NOT NULL)
	Begin
		set @nComponentType = 0
		set @bResultBySelect= 0

		Set @sSQLString='Exec '+@sAltServProc+' '
		+isnull(convert(varchar,@pnCaseId) , 'NULL')+','
		+isnull(convert(varchar,@nEnteredQuantity2) , 'NULL')+','
		+isnull(convert(varchar,@pnEnteredAmount), 'NULL')+','
		+convert(varchar,@nComponentType)+','
		+convert(varchar,@pnCriteria)+','
		+convert(varchar,@prnFeeUniqueId)+ ','
		+convert(varchar,@bResultBySelect)+ ','
		+ '@nBasicAmount		OUTPUT,'
		+ '@nExtendedAmount		OUTPUT'

		---------------------------------------------------------------
		-- RFC13050
		-- If the user defined stored procedure has had the parameter
		-- @pnCycle defined then it will need to be pushed through to
		-- the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameter after the two OUTPUT parameters:
	
		-- @pnCycle			smallint	= null,
		---------------------------------------------------------------
		If @bAltServCycleFlag = 1
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@pnCycle is null) THEN 'NULL' ELSE convert(varchar,@pnCycle) END
		End

		---------------------------------------------------------------
		-- SQA15384
		-- If parameters for a simulated Case or simulated date range
		-- have been passed then these parameters will need to be pushed
		-- through to the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameters:
	
		-- @psCaseType			nchar(1)	= null,
		-- @psPropertyType		nchar(1)	= null,
		-- @psCountryCode		nvarchar(3)	= null,
		-- @psCaseCategory		nvarchar(2)	= null,
		-- @psSubType			nvarchar(2)	= null,
		-- @pnEntitySize		int		= null,
		-- @pnInstructor		int		= null,
		-- @pnBillToNo			int		= null,
		-- @pnDebtorType		int		= null,
		-- @pnAgentNo			int		= null,
		-- @psCurrency			nvarchar(3)	= null,
		-- @pnExchScheduleId		int		= null,
		-- @pdtFromDate			datetime	= null,
		-- @pdtUntilDate		datetime	= null
		---------------------------------------------------------------
		If(@psCaseType	     is not NULL
		or @psCountryCode    is not NULL
		or @psCaseCategory   is not NULL
		or @psSubType	     is not NULL
		or @pnInstructor     is not NULL
		or @pnBillToNo       is not NULL
		or @pnDebtorType     is not NULL
		or @pnAgentNo        is not NULL
		or @psCurrency       is not NULL
		or @pnExchScheduleId is not NULL
		or @pdtFromDateServ  is not NULL
		or @pdtUntilDate     is not NULL)
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@psCaseType is null)       THEN 'NULL' ELSE ''''+@psCaseType+''''     END+','
			+CASE WHEN(@psPropertyType is null)   THEN 'NULL' ELSE ''''+@psPropertyType+'''' END+','
			+CASE WHEN(@psCountryCode is null)    THEN 'NULL' ELSE ''''+@psCountryCode+''''  END+','
			+CASE WHEN(@psCaseCategory is null)   THEN 'NULL' ELSE ''''+@psCaseCategory+'''' END+','
			+CASE WHEN(@psSubType is null)        THEN 'NULL' ELSE ''''+@psSubType+''''      END+','
			+CASE WHEN(@pnEntitySize is null)     THEN 'NULL' ELSE convert(varchar,@pnEntitySize) END+','
			+CASE WHEN(@pnInstructor is null)     THEN 'NULL' ELSE convert(varchar,@pnInstructor) END+','
			+CASE WHEN(@pnBillToNo is null)       THEN 'NULL' ELSE convert(varchar,@pnBillToNo)   END+','
			+CASE WHEN(@pnDebtorType is null)     THEN 'NULL' ELSE convert(varchar,@pnDebtorType) END+','
			+CASE WHEN(@pnAgentNo is null)        THEN 'NULL' ELSE convert(varchar,@pnAgentNo)    END+','
			+CASE WHEN(@psCurrency is null)       THEN 'NULL' ELSE ''''+@psCurrency+''''          END+','
			+CASE WHEN(@pnExchScheduleId is null) THEN 'NULL' ELSE convert(varchar,@pnExchScheduleId) END+','
			+CASE WHEN(@pdtFromDateServ is null)  THEN 'NULL' ELSE ''''+convert(varchar,@pdtFromDateServ,112)+'''' END+','
			+CASE WHEN(@pdtUntilDate is null)     THEN 'NULL' ELSE ''''+convert(varchar,@pdtUntilDate,112)+''''    END
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBasicAmount		decimal(11,2)		OUTPUT,
						  @nExtendedAmount	decimal(11,2)		OUTPUT',
						  @nBasicAmount=@prnServBasicAmount		OUTPUT,
						  @nExtendedAmount=@prnServExtendedAmount	OUTPUT
		
	End
	-- If the Quantity exceeds the maximum allowed in the calculation then set it to the maximum.
	Else Begin
		If @nPeriodCount2>0
		Begin
			If ( @nServMaxUnits > 0) AND ( @nPeriodCount2 > @nServMaxUnits)
			Begin
				Set @nQuantity = @nServMaxUnits
			End
			Else Begin
				Set @nQuantity = @nPeriodCount2
			End
		End
		Else Begin
			Set @nUnitCount2 =1 

			If ( @nServMaxUnits > 0) AND ( @nEnteredQuantity2 > @nServMaxUnits)
			Begin
				Set @nQuantity = @nServMaxUnits
			End
			Else Begin
				Set @nQuantity = @nEnteredQuantity2
			End
		End
		
		-- If there is a minimum service charge then set the Basic Amount to the minimum
		-- otherwise calculate the Basic Amount as a pro-rata of the Quantity.
			
		If @bServMinFeeFlag = 1
		Begin
			If @sPeriodType2 is null
				Set @prnServBasicAmount = @nServBaseFee * @nUnitCount2
			Else
				-- Note that if a Period between dates is part of the calculation
				-- then a zero period should result in a zero Basic Amount
				If @nQuantity=0
					Set @prnServBasicAmount = 0
				Else
					Set @prnServBasicAmount = @nServBaseFee * @nUnitCount2
		End
		Else begin
			If @nQuantity >= @nServBaseUnits
			Begin
				Set @prnServBasicAmount = @nServBaseFee * @nUnitCount2
			End
			Else begin	
				If @nQuantity = 0
					Set @prnServBasicAmount = 0
				Else
					If @nServBaseUnits != 0
						Set @prnServBasicAmount = @nQuantity * @nUnitCount2 * @nServBaseFee/ @nServBaseUnits
					Else
						Set @prnServBasicAmount = 0
			end
		End
	
		-- Now calculate the Extended Amount where the Quantity has exceeded the number allowed
			
		If @nQuantity <= @nServBaseUnits
		Begin
			Set @prnServExtendedAmount = 0
		End
		Else begin
			-- need to use a decimal to avoid automatic rounding to integer (SQA16374)
			Set @nQuantityAsDec = @nQuantity

			If ( @nServUnitSize = 0)
				Set @nChargeQuantity = @nQuantityAsDec - @nServBaseUnits
			Else
				Set @nChargeQuantity = (@nQuantityAsDec - @nServBaseUnits)/@nServUnitSize
					
			Set @nRndChargeQuantity = @nChargeQuantity

			If @nRndChargeQuantity < @nChargeQuantity
				Set @nRndChargeQuantity = @nRndChargeQuantity + 1

			Set @prnServExtendedAmount = @nServVariableFee * @nRndChargeQuantity * @nUnitCount2
				
		End
	End
End

If @ErrorCode=0
Begin		
	-- Increase the Entered Amount by a Service Charge uplift percentage.
	-- The Service Add Percentage is likely to be at least 100% to ensure that the full entered
	-- service charge is taken up.  
		
	Set @nEnteredAmount = @pnEnteredAmount * @nServAddPercentage
	
	-- Note that ServDisbPercentage will probably be less than 100% as the intention here is to 
	-- calculate the Service Charge as a percentage of the previously calculated Disbursement.
	-- If the Source of Quantity is one that has a Period Type used for calculating the period
	-- between two events, then if the calculated period (@nEnteredQuantity2) is less than 1
	-- then the Service Disbursement Percentage will be set to zero.  This is to allow for Fines
	-- that apply when an Event is later than another Event that are calculated as a percentage of
	-- the official fee (disbursement)
	If  @sPeriodType2 is not null
	and isnull(@nEnteredQuantity2,0)<1
		Set @nServDisbPercent=0

	If @nDisbExchRate = @nServExchRate
		Set @nServDisbursement = @nDisbAmount * @nServDisbPercent
	Else
		Set @nServDisbursement = @nDisbHomeAmount * @nServDisbPercent * @nServExchRate
	
	Set @prnServBasicAmount = @prnServBasicAmount + @nServDisbursement
	Set @nServAmount        = @prnServBasicAmount + @prnServExtendedAmount + @nEnteredAmount


	-- Perform Adjustment if Separate Debtor Logic Used (9114)
	If (@pnDebtorPercentage > 0) and (@pnDebtorPercentage < 100)
	begin
		Set @nServAmount = @pnDebtorPercentage * @nServAmount /100

		-- always round up
		If @nServAmount > Round (@nServAmount, 2)
		begin	
			Set @nServAmount = Round (@nServAmount, 2) + 0.01
		end
		Else begin
			Set @nServAmount = Round (@nServAmount, 2)
		end
	end
	
	-- If the Service exchange rate is 1 (indicating it is the same as the Home Currency)
	-- and the RoundLocalValue flag is on then round the ServAmount to remove decimals

	If  @nServExchRate   =1
	and @bRoundLocalValue=1
		Set @nServAmount = Round (@nServAmount, 0)
		
	
	-- Convert the Service Amount to it home currency.
	-- Round the result to remove decimals if required

	If @bRoundLocalValue = 1
		Set @nServHomeAmount = Round((@nServAmount/@nServExchRate), 0)
	Else
	Begin
		-- SQA19145 guard against rounding error
		-- Set @nServHomeAmount = @nServAmount/ @nServExchRate
		Set @nTempUnrounded = @nServAmount/ @nServExchRate
		Set @nServHomeAmount = Round( @nTempUnrounded, 2)
	End

	-- Convert the Service Amount to the billing currency

	If @prsBillCurrency=@sServCurrency
		Set @nServBillAmount = @nServAmount
	Else
		Set @nServBillAmount = @nServHomeAmount * @nBillExchRate

	-- Round the Billing amount to the nearest unit size as specified against the Billing Currency

	If @nRoundBilledValue <> 0
		exec @ErrorCode=pt_RoundToNearestUnitSize 
					@nServBillAmount,
					@nRoundBilledValue,
					@nServBillAmount	output

End


-- Calculate the "Variable" Charges that establish if a Write Up is required
--==========================================================================

If @ErrorCode=0
Begin			
	if (@sAltVarProc IS NOT NULL)
	Begin
		set @nComponentType = 0
		set @bResultBySelect= 0

		Set @sSQLString='Exec '+@sAltVarProc+' '
		+isnull(convert(varchar,@pnCaseId) , 'NULL')+','
		+isnull(convert(varchar,@nEnteredQuantity2) , 'NULL')+','
		+isnull(convert(varchar,@pnEnteredAmount), 'NULL')+','
		+convert(varchar,@nComponentType)+','
		+convert(varchar,@pnCriteria)+','
		+convert(varchar,@prnFeeUniqueId)+ ','
		+convert(varchar,@bResultBySelect)+ ','
		+ '@nBasicAmount		OUTPUT,'
		+ '@nExtendedAmount		OUTPUT'

		---------------------------------------------------------------
		-- RFC13050
		-- If the user defined stored procedure has had the parameter
		-- @pnCycle defined then it will need to be pushed through to
		-- the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameter after the two OUTPUT parameters:
	
		-- @pnCycle			smallint	= null,
		---------------------------------------------------------------
		If @bAltVarCycleFlag = 1
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@pnCycle is null) THEN 'NULL' ELSE convert(varchar,@pnCycle) END
		End

		---------------------------------------------------------------
		-- SQA15384
		-- If parameters for a simulated Case have been passed
		-- then these parameters will need to be pushed through
		-- to the Alternate Stored procedure.  Note that the
		-- alternate stored procedure will require the following
		-- additional input parameters after the two OUTPUT parameters:
	
		-- @psCaseType			nchar(1)	= null,
		-- @psPropertyType		nchar(1)	= null,
		-- @psCountryCode		nvarchar(3)	= null,
		-- @psCaseCategory		nvarchar(2)	= null,
		-- @psSubType			nvarchar(2)	= null,
		-- @pnEntitySize		int		= null,
		-- @pnInstructor		int		= null,
		-- @pnBillToNo			int		= null,
		-- @pnDebtorType		int		= null,
		-- @pnAgentNo			int		= null,
		-- @psCurrency			nvarchar(3)	= null,
		-- @pnExchScheduleId		int		= null,
		-- @pdtFromDateServ		datetime	= null,
		-- @pdtUntilDate		datetime	= null
		---------------------------------------------------------------
		If @pnCaseId is NULL AND
		  (@psCaseType	     is not NULL
		or @psCountryCode    is not NULL
		or @psCaseCategory   is not NULL
		or @psSubType	     is not NULL
		or @pnInstructor     is not NULL
		or @pnBillToNo       is not NULL
		or @pnDebtorType     is not NULL
		or @pnAgentNo        is not NULL
		or @psCurrency       is not NULL
		or @pnExchScheduleId is not NULL
		or @pdtFromDateServ  is not NULL
		or @pdtUntilDate     is not NULL)
		Begin
			Set @sSQLString=@sSQLString+','
			+CASE WHEN(@psCaseType is null)       THEN 'NULL' ELSE ''''+@psCaseType+''''     END+','
			+CASE WHEN(@psPropertyType is null)   THEN 'NULL' ELSE ''''+@psPropertyType+'''' END+','
			+CASE WHEN(@psCountryCode is null)    THEN 'NULL' ELSE ''''+@psCountryCode+''''  END+','
			+CASE WHEN(@psCaseCategory is null)   THEN 'NULL' ELSE ''''+@psCaseCategory+'''' END+','
			+CASE WHEN(@psSubType is null)        THEN 'NULL' ELSE ''''+@psSubType+''''      END+','
			+CASE WHEN(@pnEntitySize is null)     THEN 'NULL' ELSE convert(varchar,@pnEntitySize) END+','
			+CASE WHEN(@pnInstructor is null)     THEN 'NULL' ELSE convert(varchar,@pnInstructor) END+','
			+CASE WHEN(@pnBillToNo is null)       THEN 'NULL' ELSE convert(varchar,@pnBillToNo)   END+','
			+CASE WHEN(@pnDebtorType is null)     THEN 'NULL' ELSE convert(varchar,@pnDebtorType) END+','
			+CASE WHEN(@pnAgentNo is null)        THEN 'NULL' ELSE convert(varchar,@pnAgentNo)    END+','
			+CASE WHEN(@psCurrency is null)       THEN 'NULL' ELSE ''''+@psCurrency+''''          END+','
			+CASE WHEN(@pnExchScheduleId is null) THEN 'NULL' ELSE convert(varchar,@pnExchScheduleId) END+','
			+CASE WHEN(@pdtFromDateServ is null)  THEN 'NULL' ELSE ''''+convert(varchar,@pdtFromDateServ,112)+'''' END+','
			+CASE WHEN(@pdtUntilDate is null)     THEN 'NULL' ELSE ''''+convert(varchar,@pdtUntilDate,112)+''''    END
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBasicAmount		decimal(11,2)		OUTPUT,
						  @nExtendedAmount	decimal(11,2)		OUTPUT',
						  @nBasicAmount=@prnVarBasicAmount		OUTPUT,
						  @nExtendedAmount=@prnVarExtendedAmount	OUTPUT
		
	End
	-- If the Quantity exceeds the maximum allowed in the calculation then set it to the maximum.
	Else Begin
		If ( @nVarMaxUnits > 0) AND ( @nEnteredQuantity2 > @nVarMaxUnits)
		Begin
			Set @nQuantity = @nVarMaxUnits
		End
		Else Begin
			Set @nQuantity = @nEnteredQuantity2
		End
		
		-- If there is a minimum Service charge then set the Basic Amount to the minimum
		-- otherwise calculate the Basic Amount as a pro-rata of the Quantity.
			
		If @bVarMinFeeFlag = 1
		Begin
			Set @prnVarBasicAmount = @nVarBaseFee
		End
		Else begin
			If @nQuantity >= @nVarBaseUnits
			Begin
				Set @prnVarBasicAmount = @nVarBaseFee
			End
			Else begin	
				If @nQuantity = 0
					Set @prnVarBasicAmount = 0
				Else
					If @nVarBaseUnits != 0
						Set @prnVarBasicAmount = @nQuantity * @nVarBaseFee/ @nVarBaseUnits
					Else
						Set @prnVarBasicAmount = 0
			end
		End
	
		-- Now calculate the Extended Amount where the Quantity has exceeded the number allowed
			
		If @nQuantity <= @nVarBaseUnits
		Begin
			Set @prnVarExtendedAmount = 0
		End
		Else begin
			-- need to use a decimal to avoid automatic rounding to integer (SQA16374)
			Set @nQuantityAsDec = @nQuantity

			If ( @nVarUnitSize = 0)
				Set @nChargeQuantity = @nQuantityAsDec - @nVarBaseUnits
			Else
				Set @nChargeQuantity = (@nQuantityAsDec - @nVarBaseUnits)/@nVarUnitSize
					
			Set @nRndChargeQuantity = @nChargeQuantity

			If @nRndChargeQuantity < @nChargeQuantity
				Set @nRndChargeQuantity = @nRndChargeQuantity + 1

			Set @prnVarExtendedAmount = @nVarVariableFee * @nRndChargeQuantity
				
		End
	End
End

-- Continue processing if a minimum fee has been calculated.
If   @ErrorCode=0
and (@prnVarBasicAmount + @prnVarExtendedAmount>0)
Begin	
	
	Set @nVarAmount = @prnVarBasicAmount + @prnVarExtendedAmount

	-- Perform Adjustment if Separate Debtor Logic Used (9114)
	If (@pnDebtorPercentage > 0) and (@pnDebtorPercentage < 100)
	begin
		Set @nVarAmount = @pnDebtorPercentage * @nVarAmount /100

		-- always round up
		If @nVarAmount > Round (@nVarAmount, 2)
		begin	
			Set @nVarAmount = Round (@nVarAmount, 2) + 0.01
		end
		Else begin
			Set @nVarAmount = Round (@nVarAmount, 2)
		end
	end

	-- Now that we have calculated a minimum value we need to check if a Service Fee
	-- has previously been calculated.  If there is a Service Fee then we will return
	-- the Variable Fee otherwise the Variable Fee will be set to zero.
	If @nServAmount=0
		Set @nVarAmount = 0
	
	-- If the Service exchange rate is 1 (indicating it is the same as the Home Currency)
	-- and the RoundLocalValue flag is on then round the VarAmount to remove decimals

	If  @nServExchRate   =1
	and @bRoundLocalValue=1
	and @nVarAmount<>0
		Set @nVarAmount = Round (@nVarAmount, 0)
		
	
	-- Convert the Service Amount to it home currency.
	-- Round the result to remove decimals if required

	If @bRoundLocalValue = 1
		Set @nVarHomeAmount = Round((@nVarAmount/@nServExchRate), 0)
	Else
	Begin
		-- SQA19145 guard against rounding error
		-- Set @nVarHomeAmount = @nVarAmount/ @nServExchRate
		Set @nTempUnrounded = @nVarAmount/ @nServExchRate
		Set @nVarHomeAmount = Round( @nTempUnrounded, 2)
	End

	-- Convert the Service Amount to the billing currency

	If @prsBillCurrency=@sServCurrency
		Set @nVarBillAmount = @nVarAmount
	Else
		Set @nVarBillAmount = @nVarHomeAmount * @nBillExchRate

	-- Round the Billing amount to the nearest unit size as specified against the Billing Currency

	If @nRoundBilledValue <> 0
		exec @ErrorCode=pt_RoundToNearestUnitSize 
					@nVarBillAmount,
					@nRoundBilledValue,
					@nVarBillAmount	output

End

-- Perform the MARGIN and DISCOUNT Calculations
--=============================================
If @ErrorCode=0
Begin	
	-- Save the base disbursement value before applying discounts and margins
	Set @pnDisbSourceAmt=@nDisbAmount
	
	-- SQA17452
	-- If procedure is being run with the option to use todays exchange rate,
	-- then also use margin calculation as at todays date if the transaction
	-- date is in the past. This way Fee Enquiry will at the very least use
	-- the current margin but will use any future margin for future dates.
	If  @pbUseTodaysExchangeRate=1
	and @pdtTransactionDate<getdate()
		Set @dtMarginTransDate=getdate()
	Else
		Set @dtMarginTransDate = @pdtTransactionDate

	--------------------------------------------------------------------------------------
	-- DISBURESMENTS
	-- Only calculate Discounts and Margins if a Disbursement was actually calculated or a
	-- Margin amount exists.
	--------------------------------------------------------------------------------------

	--**13955 Re-arrange to simplify logic --
	If @nDisbAmount<>0
		OR isnull(@nDisbMarginAmt,0)<>0
	Begin
		-- Is there a discount rate for the disbursement?
		
		If @nDisbDiscountRate <> 0
		Begin
			Set @nDiscountRate = @nDisbDiscountRate

                        Set @pnDisbPreMarginDiscount     = @nDiscountRate * @nDisbAmount    /100
			Set @pnDisbHomePreMarginDiscount = @nDiscountRate * @nDisbHomeAmount/100
			Set @pnDisbBillPreMarginDiscount = @nDiscountRate * @nDisbBillAmount/100
			
			-- Determine if the discount is to be applied before or after the margin is added			
			If @nDisbBaseOnAmount = 1
			Begin			
				Set @nDisbDiscount     = @pnDisbPreMarginDiscount
				Set @nDisbHomeDiscount = @pnDisbHomePreMarginDiscount
				Set @nDisbBillDiscount = @pnDisbBillPreMarginDiscount
			End
		End
		
		-- Is there a margin for the disbursement?
		
		If (@nDisbMarginRate is not null) or (@nDisbMarginAmt is not null)
		Begin
				
			-- Calculate the disbursement margin		
			-- In the currency of the Disbursement
			exec @ErrorCode = dbo.pt_CalculateMargin 
					@prnMarginValue 	= @nDisbMargin OUTPUT, 
					@pnUserIdentityId	= @nUserIdentityId,
					@psCulture		= @sCulture, 
					@pbServiceCharge	= @bDisbIsServiceCharge, 
					@pnWIPAmount		= @nDisbAmount,
					@psWIPCurrency		= @sDisbCurrency, 
					@pnWIPExchRate		= @nDisbExchRate, 
					@pnMarginPercentage	= @nDisbMarginRate, 
					@pnMarginAmount		= @nDisbMarginAmt, 
					@psMarginCurrency	= @sDisbMarginCurr, 
					@pnWIPDecimalPlaces	= @nDisbDecimalPlaces, 
					@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
					@pbCalledFromCentura	= 1, 
					@psWIPCategoryKey	= @sDisbCategory, 
					@pnNameKey		= @pnBillToNo, 
					@pnCaseKey		= @pnCaseId,
					@psCaseType     	= @psCaseType,
					@psCountryCode		= @psCountryCode,
					@psPropertyType		= @psPropertyType,
					@psCaseCategory		= @psCaseCategory,
					@psSubType		= @psSubType,
					@pnExchScheduleId	= @pnExchScheduleId, 
					@pbDebug		= 0,
					@pnSupplierKey		= @pnAgentNo,
				@pbAgentItem		= @pbAgentItem,
				@pnMarginCap		= @nDisbMarginCap,
				@psWIPTypeKey		= @sDisbWIPType
			
			If @ErrorCode=0
			begin	
				-- In home currency
				exec @ErrorCode = dbo.pt_CalculateMargin 
					@prnMarginValue 	= @nDisbHomeMargin OUTPUT, 
					@pnUserIdentityId	= @nUserIdentityId,
					@psCulture		= @sCulture, 
					@pbServiceCharge	= @bDisbIsServiceCharge, 
					@pnWIPAmount		= @nDisbHomeAmount, -- *** SQA13955 should this be HomeAmount @pbFixedInLocal		= 1,
					@psWIPCurrency		= NULL, 
					@pnWIPExchRate		= 1, 
					@pnMarginPercentage	= @nDisbMarginRate, 
					@pnMarginAmount		= @nDisbMarginAmt, 
					@psMarginCurrency	= @sDisbMarginCurr,  
					@pnWIPDecimalPlaces	= @nDisbDecimalPlaces, 
					@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
					@pbCalledFromCentura	= 1, 
					@psWIPCategoryKey	= @sDisbCategory, 
					@pnNameKey		= @pnBillToNo, 
					@pnCaseKey		= @pnCaseId, 
					@psCaseType     	= @psCaseType,
					@psCountryCode		= @psCountryCode,
					@psPropertyType		= @psPropertyType,
					@psCaseCategory		= @psCaseCategory,
					@psSubType		= @psSubType,
					@pnExchScheduleId	= @pnExchScheduleId, 
					@pbDebug		= 0,
					@pnSupplierKey		= @pnAgentNo,
					@pbAgentItem		= @pbAgentItem,
					@pnMarginCap		= @nDisbMarginCap,
					@psWIPTypeKey		= @sDisbWIPType
			end
			
			If @ErrorCode=0
			begin
				-- In Billing Currency
				exec @ErrorCode = dbo.pt_CalculateMargin 
					@prnMarginValue 	= @nDisbBillMargin OUTPUT, 
					@pnUserIdentityId	= @nUserIdentityId,
					@psCulture		= @sCulture, 
					@pbServiceCharge	= @bDisbIsServiceCharge, 
					@pnWIPAmount		= @nDisbBillAmount, -- *** SQA13955???
					@psWIPCurrency		= @prsBillCurrency, 
					@pnWIPExchRate		= @nBillExchRate, 
					@pnMarginPercentage	= @nDisbMarginRate, 
					@pnMarginAmount		= @nDisbMarginAmt, 
					@psMarginCurrency	= @sDisbMarginCurr, 
					@pnWIPDecimalPlaces	= @nDisbDecimalPlaces, 
					@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
					@pbCalledFromCentura	= 1, 
					@psWIPCategoryKey	= @sDisbCategory, 
					@pnNameKey		= @pnBillToNo, 
					@pnCaseKey		= @pnCaseId, 
					@psCaseType     	= @psCaseType,
					@psCountryCode		= @psCountryCode,
					@psPropertyType		= @psPropertyType,
					@psCaseCategory		= @psCaseCategory,
					@psSubType		= @psSubType,
					@pnExchScheduleId	= @pnExchScheduleId,
					@pbDebug		= 0,
					@pnSupplierKey		= @pnAgentNo,
					@pbAgentItem		= @pbAgentItem,
					@pnMarginCap		= @nDisbMarginCap,
					@psWIPTypeKey		= null
			end
			
			-- Perform any rounding required on the calculated Margin
			
			If  @nDisbExchRate   =1
			and @bRoundLocalValue=1
				Set @nDisbMargin = Round (@nDisbMargin, 0)
			
			If  @bRoundLocalValue = 1
				Set @nDisbHomeMargin = Round(@nDisbHomeMargin, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nDisbBillMargin,
							@nRoundBilledValue,
							@nDisbBillMargin	output
			
			----------------------------------------------------------------
			-- SQA16836
			-- If the base disbursement amount is zero and the Margin in
			-- the billing currency is not zero then switch the disbursement
			-- currency and exchange rate to be the same as for billing.
			-- This will avoid a value being converted between currencies
			-- which might result in a small exchange variation.
			----------------------------------------------------------------
			If  @nDisbAmount=0
			and @nDisbBillMargin<>0
			Begin
				set @nDisbMargin=@nDisbBillMargin
				set @sDisbCurrency=@prsBillCurrency
				set @nDisbExchRate=@nBillExchRate
			End
						
			-----------------------------------------------
			-- Calculate the Amount by adding in the Margin
			-----------------------------------------------			
			Set @nDisbAmount     = @nDisbAmount     + @nDisbMargin
			Set @nDisbHomeAmount = @nDisbHomeAmount + @nDisbHomeMargin
			Set @nDisbBillAmount = @nDisbBillAmount + @nDisbBillMargin
		End

                -- R56172 initialise the discount for the margin to be the same as the discount for the main item
	        If (@ErrorCode = 0)
	        Begin
		        Set @nMarginDiscountPercent = @nDiscountRate
	        End
		
	        -- R56172 check if a different discount applies to the margin item	
	        if (@ErrorCode=0) AND (@bMarginAsSeparateWip = 1) 
	        Begin                                                                                                                    
		        -- R56172 only derive the margin discount if the margin WIP Code is valid and of a different type	
		        If (@sMarginWipCode is not null) and (@sMarginWipTypeKey is not null)
		        and (@sMarginWipCode != @sDisbWIPCode)
		        Begin	
			        exec @ErrorCode=dbo.pt_GetDiscountRate 
				        @pnBillToNo		= @pnBillToNo, 
				        @psWIPType		= @sMarginWipTypeKey,
				        @psWIPCategory		= @sMarginWipCategoryKey,
				        @psPropertyType		= @psPropertyType, 
				        @psAction		= @psAction,
				        @pnEmployeeNo		= @nDisbEmployeeNo,
				        @pnProductCode		= @nProductCode,
				        @prnDiscountRate 	= @nMarginDiscountPercent output,
				        @prnBaseOnAmount	= @bIsMarginDiscountBasedOnAmount output,
				        @pnOwner		= @pnOwner,
				        @psWIPCode		= @sMarginWipCode,
				        @psCaseType		= @sCaseType
		        End
	        End
			
		-- Now calculate the discount after the Margin was added
		
		If ((@nDisbBaseOnAmount IS NULL) OR (@nDisbBaseOnAmount <> 1)) AND (@nDisbDiscountRate <> 0 )
		Begin
			Set @nDisbDiscount     = @nDiscountRate * @nDisbAmount    /100
			Set @nDisbHomeDiscount = @nDiscountRate * @nDisbHomeAmount/100
			Set @nDisbBillDiscount = @nDiscountRate * @nDisbBillAmount/100
		End

                If ((@nDisbBaseOnAmount IS NULL) OR (@nDisbBaseOnAmount <> 1)) AND (@nMarginDiscountPercent <> 0 )
		Begin
			Set @pnDisbDiscountForMargin	= @nMarginDiscountPercent * @nDisbMargin /100
			Set @pnDisbHomeDiscountForMargin = @nMarginDiscountPercent * @nDisbHomeMargin /100
			Set @pnDisbBillDiscountForMargin = @nMarginDiscountPercent * @nDisbBillMargin /100
		End		 

		-- Need to perform any rounding required on the calculated Discount
		
		If @nDisbDiscount<>0
		Begin
			If  @nDisbExchRate   =1
			and @bRoundLocalValue=1
				Set @nDisbDiscount = Round (@nDisbDiscount, 0)
			
			If  @bRoundLocalValue = 1
				Set @nDisbHomeDiscount = Round(@nDisbHomeDiscount, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nDisbBillDiscount,
							@nRoundBilledValue,
							@nDisbBillDiscount	output
		End
		
		If @pnDisbDiscountForMargin<>0
		Begin
			If  @nDisbExchRate   =1
			and @bRoundLocalValue=1
				Set @pnDisbDiscountForMargin = Round (@pnDisbDiscountForMargin, 0)
			
			If  @bRoundLocalValue = 1
				Set @pnDisbHomeDiscountForMargin = Round(@pnDisbHomeDiscountForMargin, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@pnDisbBillDiscountForMargin,
							@nRoundBilledValue,
							@pnDisbBillDiscountForMargin	output
		End

		
		-- Need to perform any rounding required on the Disbursement amount after Margin added
		
		If (@nDisbMarginRate is not null) or (@nDisbMarginAmt is not null)
		Begin
			If  @nDisbExchRate   =1
			and @bRoundLocalValue=1
				Set @nDisbAmount = Round (@nDisbAmount, 0)
				
			If  @bRoundLocalValue = 1
				Set @nDisbHomeAmount = Round(@nDisbHomeAmount, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nDisbBillAmount,
							@nRoundBilledValue,
							@nDisbBillAmount	output
		End
	End

	-- Save the base disbursement value before applying discounts and margins
	Set @pnServSourceAmt=@nServAmount

	-----------------------------------------------------------------------------------
	-- SERVICE CHARGE
	-- Only calculate Discounts and Margins if a Service Charge was actually calculated
	-- or a Margin amount exists.
	-----------------------------------------------------------------------------------

	If @nServAmount<>0
	OR @nVarAmount<>0
	OR isnull(@nServMarginAmt,0)<>0
	Begin
		-- Is there a discount rate for the Service Charge?
		
		If @nServDiscountRate <> 0
		Begin
			Set @nDiscountRate = @nServDiscountRate
				
			-- Determine if the discount is to be applied before or after the margin is added

                        -- SQA15820 user Variable Amount if greater than Service amount for discount calulation
			If abs(@nServAmount)>abs(isnull(@nVarAmount,0))
			Begin
				Set @pnServPreMarginDiscount     = @nDiscountRate * @nServAmount    /100
				Set @pnServHomePreMarginDiscount = @nDiscountRate * @nServHomeAmount/100
				Set @pnServBillPreMarginDiscount = @nDiscountRate * @nServBillAmount/100
			End
			Else Begin
				Set @pnServPreMarginDiscount     = @nDiscountRate * @nVarAmount    /100
				Set @pnServHomePreMarginDiscount = @nDiscountRate * @nVarHomeAmount/100
				Set @pnServBillPreMarginDiscount = @nDiscountRate * @nVarBillAmount/100
			End
			
			If @nServBaseOnAmount = 1
			Begin			
				Set @nServDiscount     = @pnServPreMarginDiscount
				Set @nServHomeDiscount = @pnServHomePreMarginDiscount
				Set @nServBillDiscount = @pnServBillPreMarginDiscount
			End
		End
		
		-- Is there a margin for the Service Charge?
		
		If (@nServMarginRate is not null) or (@nServMarginAmt is not null)
		Begin
			-- Calculate the Service Charge margin
			
			exec @ErrorCode = dbo.pt_CalculateMargin 
			@prnMarginValue 	= @nServMargin OUTPUT, 
			@pnUserIdentityId	= @nUserIdentityId,
			@psCulture		= @sCulture, 
			@pbServiceCharge	= @bServIsServiceCharge, 
			@pnWIPAmount		= @nServAmount, 
			@psWIPCurrency		= @sServCurrency, 
			@pnWIPExchRate		= @nServExchRate, 
			@pnMarginPercentage	= @nServMarginRate, 
			@pnMarginAmount		= @nServMarginAmt, 
			@psMarginCurrency	= @sServMarginCurr, 
			@pnWIPDecimalPlaces	= @nServDecimalPlaces, 
			@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
			@pbCalledFromCentura	= 1, 
			@psWIPCategoryKey	= @sServCategory, 
			@pnNameKey		= @pnBillToNo, 
			@pnCaseKey		= @pnCaseId, 
			@psCaseType     	= @psCaseType,
			@psCountryCode		= @psCountryCode,
			@psPropertyType		= @psPropertyType,
			@psCaseCategory		= @psCaseCategory,
			@psSubType		= @psSubType,
			@pnExchScheduleId	= @pnExchScheduleId,
			@pbDebug		= 0,
			@pnSupplierKey		= @pnAgentNo,
				@pbAgentItem		= @pbAgentItem,
				@pnMarginCap		= @nServMarginCap,
				@psWIPTypeKey		= @sServWIPType
			
			If @ErrorCode=0
			begin	
				exec @ErrorCode = dbo.pt_CalculateMargin 
				@prnMarginValue 	= @nServHomeMargin OUTPUT, 
				@pnUserIdentityId	= @nUserIdentityId,
				@psCulture		= @sCulture, 
				@pbServiceCharge	= @bServIsServiceCharge, 
				@pnWIPAmount		= @nServHomeAmount,	-- ** SQA13955?? 
				@psWIPCurrency		= NULL, 
				@pnWIPExchRate		= 1, 
				@pnMarginPercentage	= @nServMarginRate, 
				@pnMarginAmount		= @nServMarginAmt, 
				@psMarginCurrency	= @sServMarginCurr, 
				@pnWIPDecimalPlaces	= @nServDecimalPlaces, 
				@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
				@pbCalledFromCentura	= 1, 
				@psWIPCategoryKey	= @sServCategory, 
				@pnNameKey		= @pnBillToNo, 
				@pnCaseKey		= @pnCaseId, 
				@psCaseType     	= @psCaseType,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType,
				@psCaseCategory		= @psCaseCategory,
				@psSubType		= @psSubType,
				@pnExchScheduleId	= @pnExchScheduleId,
				@pbDebug		= 0,
				@pnSupplierKey		= @pnAgentNo,
					@pbAgentItem		= @pbAgentItem,
					@pnMarginCap		= @nServMarginCap,
					@psWIPTypeKey		= @sServWIPType
			end
			
			If @ErrorCode=0
			begin
				exec @ErrorCode = dbo.pt_CalculateMargin 
				@prnMarginValue 	= @nServBillMargin OUTPUT, 
				@pnUserIdentityId	= @nUserIdentityId,
				@psCulture		= @sCulture, 
				@pbServiceCharge	= @bServIsServiceCharge, 
				@pnWIPAmount		= @nServBillAmount,	-- ** SQA13955?? 
				@psWIPCurrency		= @prsBillCurrency, 
				@pnWIPExchRate		= @nBillExchRate, 
				@pnMarginPercentage	= @nServMarginRate, 
				@pnMarginAmount		= @nServMarginAmt, 
				@psMarginCurrency	= @sServMarginCurr, 
				@pnWIPDecimalPlaces	= @nServDecimalPlaces, 
				@pdtTransactionDate	= @dtMarginTransDate,	-- SQA17452
				@pbCalledFromCentura	= 1, 
				@psWIPCategoryKey	= @sServCategory, 
				@pnNameKey		= @pnBillToNo, 
				@pnCaseKey		= @pnCaseId, 
				@psCaseType     	= @psCaseType,
				@psCountryCode		= @psCountryCode,
				@psPropertyType		= @psPropertyType,
				@psCaseCategory		= @psCaseCategory,
				@psSubType		= @psSubType,
				@pnExchScheduleId	= @pnExchScheduleId,
				@pbDebug		= 0,
				@pnSupplierKey		= @pnAgentNo,
					@pbAgentItem		= @pbAgentItem,
					@pnMarginCap		= @nServMarginCap,
					@psWIPTypeKey		= null
			end
			
			-- Perform any rounding required on the calculated Margin
			
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @nServMargin = Round (@nServMargin, 0)
			
			If  @bRoundLocalValue = 1
				Set @nServHomeMargin = Round(@nServHomeMargin, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nServBillMargin,
							@nRoundBilledValue,
							@nServBillMargin	output
			
			----------------------------------------------------------------
			-- SQA16836
			-- If the base service amount is zero and the Margin in
			-- the billing currency is not zero then switch the service
			-- currency and exchange rate to be the same as for billing.
			-- This will avoid a value being converted between currencies
			-- which might result in a small exchange variation.
			----------------------------------------------------------------
			If  @nServAmount=0
			and @nServBillMargin<>0
			Begin
				set @nServMargin  =@nServBillMargin
				set @sServCurrency=@prsBillCurrency
				set @nServExchRate=@nBillExchRate
			End
			
			-- Calculate the Amount by adding in the Margin
						
			Set @nServAmount     = @nServAmount     + @nServMargin
			Set @nServHomeAmount = @nServHomeAmount + @nServHomeMargin
			Set @nServBillAmount = @nServBillAmount + @nServBillMargin
		End

                -- R56172 initialise the discount for the margin to be the same as the discount for the main item
	        If (@ErrorCode = 0)
	        Begin
		        Set @nMarginDiscountPercent = @nDiscountRate
	        End
		
	        -- R56172 check if a different discount applies to the margin item	
	        if (@ErrorCode=0) AND (@bMarginAsSeparateWip = 1) 
	        Begin
		        -- R56172 only derive the margin discount if the margin WIP Code is valid and of a different type	
		        If (@sMarginWipCode is not null) and (@sMarginWipTypeKey is not null)
		        and (@sMarginWipCode != @sServWIPCode)
		        Begin	
			        exec @ErrorCode=dbo.pt_GetDiscountRate 
				        @pnBillToNo		= @pnBillToNo, 
				        @psWIPType		= @sMarginWipTypeKey,
				        @psWIPCategory		= @sMarginWipCategoryKey,
				        @psPropertyType		= @psPropertyType, 
				        @psAction		= @psAction,
				        @pnEmployeeNo		= @nDisbEmployeeNo,
				        @pnProductCode		= @nProductCode,
				        @prnDiscountRate 	= @nMarginDiscountPercent output,
				        @prnBaseOnAmount	= @bIsMarginDiscountBasedOnAmount output,
				        @pnOwner		= @pnOwner,
				        @psWIPCode		= @sMarginWipCode,
				        @psCaseType		= @sCaseType
		        End
	        End
		
		-- Now calculate the discount after the Margin was added
	
		If ((@nServBaseOnAmount IS NULL) OR (@nServBaseOnAmount <> 1)) AND (@nServDiscountRate <> 0 )
		Begin
			-- SQA15820 user Variable Amount if greater than Service amount for discount calulation
			If abs(@nServAmount)>abs(isnull(@nVarAmount,0))
			Begin
			Set @nServDiscount    = @nDiscountRate * @nServAmount    /100
			Set @nServHomeDiscount= @nDiscountRate * @nServHomeAmount/100
			Set @nServBillDiscount= @nDiscountRate * @nServBillAmount/100
			End
			Else Begin
				Set @nServDiscount    = @nDiscountRate * @nVarAmount    /100
				Set @nServHomeDiscount= @nDiscountRate * @nVarHomeAmount/100
				Set @nServBillDiscount= @nDiscountRate * @nVarBillAmount/100
			End
		End

                If ((@nServBaseOnAmount IS NULL) OR (@nServBaseOnAmount <> 1)) AND (@nMarginDiscountPercent <> 0 )
		Begin
			Set @pnServDiscountForMargin	 = @nMarginDiscountPercent * @nServMargin /100
			Set @pnServHomeDiscountForMargin = @nMarginDiscountPercent * @nServHomeMargin /100
			Set @pnServBillDiscountForMargin = @nMarginDiscountPercent * @nServBillMargin /100
		End
		
		-- Need to perform any rounding required on the calculated Discount
		
		If @nServDiscount<>0
		Begin
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @nServDiscount = Round (@nServDiscount, 0)
			
			If  @bRoundLocalValue = 1
				Set @nServHomeDiscount = Round(@nServHomeDiscount, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nServBillDiscount,
							@nRoundBilledValue,
							@nServBillDiscount	output
		End
		
		If @pnServDiscountForMargin<>0
		Begin
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @pnServDiscountForMargin = Round (@pnServDiscountForMargin, 0)
			
			If  @bRoundLocalValue = 1
				Set @pnServHomeDiscountForMargin = Round(@pnServHomeDiscountForMargin, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@pnServBillDiscountForMargin,
							@nRoundBilledValue,
							@pnServBillDiscountForMargin	output
		End

		
		-- Need to perform any rounding required on the Service amount after Margin added

		If (@nDisbMarginRate is not null) or (@nDisbMarginAmt is not null)
		Begin
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @nServAmount = Round (@nServAmount, 0)
				
			If  @bRoundLocalValue = 1
				Set @nServHomeAmount = Round(@nServHomeAmount, 0)
			
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nServBillAmount,
							@nRoundBilledValue,
							@nServBillAmount	output
		End
	End	
End

-- Perform the TAX Calculations
--=============================

-- MF 02/11/2000 There is now only one SITECONTROL flag used to determine if
--               tax is to be calculated

If @ErrorCode=0
Begin			
	Set @sSQLString="
	SELECT 	@bTaxRequired=COLBOOLEAN 
	FROM 	SITECONTROL 
	WHERE   CONTROLID = 'TAXREQUIRED'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bTaxRequired		bit	output',
				  @bTaxRequired		OUTPUT

	If @bTaxRequired is null
		Set @bTaxRequired = 0

End

If @ErrorCode=0
Begin			
		

	Set @sSQLString="
	SELECT 	@bMultiTierTax=COLBOOLEAN 
	FROM 	SITECONTROL 
	WHERE   CONTROLID = 'Tax for HOMECOUNTRY Multi-Tier'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bMultiTierTax	bit	output',
				  @bMultiTierTax	OUTPUT

	If @bMultiTierTax is null
		Set @bMultiTierTax = 0
End

-- SS 25/11/2002 Determine the Tax Rates to use based on the following hierarchy
-- SQA7276	 (Note that the above hierarchy will be overridden)
--               If @bTaxRequired  = 0 then NO Tax
--		 If @psIPTaxCode   = 0 then NO Tax
--		 If @psCaseTaxCode = 0 then NO Tax
--		 If @sDisbTaxCode  = 0 then NO Tax for disbursements
--		 If @sServTaxCode  = 0 then NO Tax for service fees
--		 If @sDisbTaxCode <> 0 OR @sServTaxCode <> 0 then
--			If @psIPTaxCode is not null then use TaxRate for this code
--			Else If @psCaseTaxCode is not null then use TaxRate for this code
--			Else use the @sDisbTaxCode & @sServTaxCode if they exist

-- For Multi-Tier Tax determine the Tax Rates to use based on the following hierarchy
-- SQA14649	 (Note that the above hierarchy will be overridden)
--               If @bTaxRequired  = 0 then NO Tax
--		 If @psIPTaxCode   = 0 then NO Tax
--		 If @psCaseTaxCode = 0 then NO Tax
--		 If @sDisbTaxCode  = 0 then NO Tax for disbursements
--		 If @sServTaxCode  = 0 then NO Tax for service fees
--		 If @sDisbTaxCode <> 0 OR @sServTaxCode <> 0 then
--			If the @sDisbTaxCode & @sServTaxCode exist use
--			Else If @psCaseTaxCode is not null then use TaxRate for this code
--			Else use @psIPTaxCode is not null then use TaxRate for this code
-- Similarly for State Tax Codes.


If @ErrorCode=0
Begin			
	If @bTaxRequired = 0
	begin
		Set @nDisbTaxRate = 0
		Set @sDisbTaxCode = NULL
		Set @nServTaxRate = 0
		Set @sServTaxCode = NULL
		Set @nVarTaxRate  = 0
		Set @sVarTaxCode  = NULL

		Set @nDisbStateTaxRate = 0
		Set @sDisbStateTaxCode = NULL
		Set @nServStateTaxRate = 0
		Set @sServStateTaxCode = NULL
		Set @nVarStateTaxRate  = 0
		Set @sVarStateTaxCode  = NULL
	end

	If @bMultiTierTax = 1
	Begin

		Set @sDestinationCountryCode 	= null 
		Set @sSourceCountryCode 	= null 
		Set @sDestinationState		= null 
		Set @sSourceState		= null 	
		Set @sCaseFederalTaxCode 	= null 
		Set @sCaseStateTaxCode 		= null 
		Set @sIPNameFederalTaxCode 	= null 
		Set @sIPNameStateTaxCode 	= null 
		Set @sHomeCountryCode 		= null 
		Set @sEUTaxCode 		= null 

		-- Set Tax Codes and Look up Rates for Multi-Tier Tax
		-- Disb
		exec pt_DeriveMultiTierTax 
					@prnFederalTaxRate 		= @nDisbTaxRate			output, 
					@prnStateTaxRate		= @nDisbStateTaxRate		output, 
					@prsFederalTaxCode 		= @sDisbTaxCode  		output, -- Federal Tax Code
					@prsStateTaxCode 		= @sDisbStateTaxCode		output, -- State Tax Code
					@prbStateHarmonised		= @bDisbStateTaxHarmonised	output,
					@prbTaxOnTax			= @bDisbStateTaxOnTax		output,
					@prbMultiTierTax		= @bMultiTierTax		output,
					@prsDestinationCountryCode	= @sDestinationCountryCode	output, 
					@prsSourceCountryCode		= @sSourceCountryCode 		output, 
					@prsDestinationState		= @sDestinationState 		output, 
					@prsSourceState			= @sSourceState 		output, 	
					@prsCaseFederalTaxCode 		= @sCaseFederalTaxCode 		output, 
					@prsCaseStateTaxCode 		= @sCaseStateTaxCode		output, 
					@prsIPNameFederalTaxCode 	= @sIPNameFederalTaxCode	output, 
					@prsIPNameStateTaxCode 		= @sIPNameStateTaxCode		output, 
					@prsHomeCountryCode 		= @sHomeCountryCode 		output, 
					@prsEUTaxCode 			= @sEUTaxCode 			output, 
					@psWIPCode			= @prsDisbWIPCode, 
					@pnCaseId			= @pnCaseId,		-- The Case ID
					@pnDebtorNo 			= @pnBillToNo,		-- the NAMENO for the debtor
					@pnRaisedBy			= @pnEmployee
		-- This flag may have been reset due to the Source Country <> Destination Country <> Home Country
		-- Only continue if still TRUE
		If @bMultiTierTax = 1
		Begin
			-- Serv
			exec pt_DeriveMultiTierTax 
						@prnFederalTaxRate 		= @nServTaxRate			output, 
						@prnStateTaxRate		= @nServStateTaxRate		output, 
						@prsFederalTaxCode 		= @sServTaxCode  		output, -- Federal Tax Code
						@prsStateTaxCode 		= @sServStateTaxCode		output, -- State Tax Code
						@prbStateHarmonised		= @bServStateTaxHarmonised	output,
						@prbTaxOnTax			= @bServStateTaxOnTax		output,
						@prbMultiTierTax		= @bMultiTierTax		output,
						@prsDestinationCountryCode	= @sDestinationCountryCode	output, 
						@prsSourceCountryCode		= @sSourceCountryCode 		output, 
						@prsDestinationState		= @sDestinationState 		output, 
						@prsSourceState			= @sSourceState 		output, 	
						@prsCaseFederalTaxCode 		= @sCaseFederalTaxCode 		output, 
						@prsCaseStateTaxCode 		= @sCaseStateTaxCode		output, 
						@prsIPNameFederalTaxCode 	= @sIPNameFederalTaxCode	output, 
						@prsIPNameStateTaxCode 		= @sIPNameStateTaxCode		output, 
						@prsHomeCountryCode 		= @sHomeCountryCode 		output, 
						@prsEUTaxCode 			= @sEUTaxCode 			output, 
						@psWIPCode			= @prsServWIPCode, 
						@pnCaseId			= @pnCaseId,		-- The Case ID
						@pnDebtorNo 			= @pnBillToNo,		-- the NAMENO for the debtor
						@pnRaisedBy			= @pnEmployee
			
			-- Var
			exec pt_DeriveMultiTierTax 
						@prnFederalTaxRate 		= @nVarTaxRate			output, 
						@prnStateTaxRate		= @nVarStateTaxRate		output, 
						@prsFederalTaxCode 		= @sVarTaxCode  		output, -- Federal Tax Code
						@prsStateTaxCode 		= @sVarStateTaxCode		output, -- State Tax Code
						@prbStateHarmonised		= @bVarStateTaxHarmonised	output,
						@prbTaxOnTax			= @bVarStateTaxOnTax		output,
						@prbMultiTierTax		= @bMultiTierTax		output,
						@prsDestinationCountryCode	= @sDestinationCountryCode	output, 
						@prsSourceCountryCode		= @sSourceCountryCode 		output, 
						@prsDestinationState		= @sDestinationState 		output, 
						@prsSourceState			= @sSourceState 		output, 	
						@prsCaseFederalTaxCode 		= @sCaseFederalTaxCode 		output, 
						@prsCaseStateTaxCode 		= @sCaseStateTaxCode		output, 
						@prsIPNameFederalTaxCode 	= @sIPNameFederalTaxCode	output, 
						@prsIPNameStateTaxCode 		= @sIPNameStateTaxCode		output, 
						@prsHomeCountryCode 		= @sHomeCountryCode 		output, 
						@prsEUTaxCode 			= @sEUTaxCode 			output,  
						@psWIPCode			= @prsVarWIPCode, 
						@pnCaseId			= @pnCaseId,		-- The Case ID
						@pnDebtorNo 			= @pnBillToNo,		-- the NAMENO for the debtor
						@pnRaisedBy			= @pnEmployee
		End
	End

	-- As the Heirarchy is different for MultiTierTax leave existing logic intact
	If @bMultiTierTax = 0
	Begin
		If @psIPTaxCode = '0'
	begin
		-- Tax Exempt
		Set @nDisbTaxRate =  0
		Set @sDisbTaxCode = '0'
		Set @nServTaxRate =  0
		Set @sServTaxCode = '0'
		Set @nVarTaxRate  =  0
		Set @sVarTaxCode  = '0'
	end
	Else If @psCaseTaxCode = '0'
	begin
		-- Tax Exempt
		Set @nDisbTaxRate =  0
		Set @sDisbTaxCode = '0'
		Set @nServTaxRate =  0
		Set @sServTaxCode = '0'
		Set @nVarTaxRate  =  0
		Set @sVarTaxCode  = '0'
	end
	Else
	begin
			If @sServTaxCode = '0'
			begin
				-- Service Charges are Tax Exempt
				Set @nServTaxRate =  0
			End
				
		If @sDisbTaxCode = '0'
			Begin
				Set @nDisbTaxRate =  0
			End
			
			If @sVarTaxCode = '0'
			Begin
				Set @nVarTaxRate =  0
			End


		If @sDisbTaxCode <> '0' OR @sServTaxCode <> '0' OR @sVarTaxCode <> '0'
		begin
			If @psIPTaxCode is not NULL
			begin
				-- 8116 exec @ErrorCode=pt_GetTaxRate  @psIPTaxCode, @nIPTaxRate output
				exec @ErrorCode=pt_GetTaxRate  
						@prnTaxRate   = @nIPTaxRate   output,
						@psNewTaxCode = @sTempTaxCode output,
						@psTaxCode  = @psIPTaxCode, 
						@pnCaseId   = @pnCaseId,
							@pnDebtorNo = @pnBillToNo,
							@pdtCalculationDate = @pdtTransactionDate

				If @sDisbTaxCode <> '0'
				begin
					Set @nDisbTaxRate = @nIPTaxRate
					If @sTempTaxCode is not null
						Set @sDisbTaxCode = @sTempTaxCode
					Else
						Set @sDisbTaxCode = @psIPTaxCode
				end

				If @sServTaxCode <> '0'
				begin
					Set @nServTaxRate = @nIPTaxRate
					If @sTempTaxCode is not null
						Set @sServTaxCode = @sTempTaxCode
					Else
						Set @sServTaxCode = @psIPTaxCode
				end

				If @sVarTaxCode <> '0'
				begin
					Set @nVarTaxRate = @nIPTaxRate
					If @sTempTaxCode is not null
						Set @sVarTaxCode = @sTempTaxCode
					Else
						Set @sVarTaxCode = @psIPTaxCode
				end
			end
			Else If @psCaseTaxCode is not NULL
			begin
				 -- 8116 exec @ErrorCode=pt_GetTaxRate @psCaseTaxCode, @nCaseTaxRate output
				exec @ErrorCode=pt_GetTaxRate  
						@prnTaxRate   = @nCaseTaxRate output,
						@psNewTaxCode = @sTempTaxCode output,
						@psTaxCode  = @psCaseTaxCode, 
						@pnCaseId   = @pnCaseId,
							@pnDebtorNo = @pnBillToNo,
							@pdtCalculationDate = @pdtTransactionDate

				If @sDisbTaxCode <> '0'
				begin
					Set @nDisbTaxRate = @nCaseTaxRate
					If @sTempTaxCode is not null
						Set @sDisbTaxCode = @sTempTaxCode
					Else
						Set @sDisbTaxCode = @psCaseTaxCode
				end

				If @sServTaxCode <> '0'
				begin
					Set @nServTaxRate = @nCaseTaxRate
					If @sTempTaxCode is not null
						Set @sServTaxCode = @sTempTaxCode
					Else
						Set @sServTaxCode = @psCaseTaxCode
				end

				If @sVarTaxCode <> '0'
				begin
					Set @nVarTaxRate = @nCaseTaxRate
					If @sTempTaxCode is not null
						Set @sVarTaxCode = @sTempTaxCode
					Else
						Set @sVarTaxCode = @psCaseTaxCode
				end
			end
			Else 
			begin
				If @sDisbTaxCode <> '0' AND @sDisbTaxCode is not null
				begin
					-- exec @ErrorCode=pt_GetTaxRate  @sDisbTaxCode, @nDisbTaxRate output
					exec @ErrorCode=pt_GetTaxRate  
						@prnTaxRate   = @nDisbTaxRate output,
						@psNewTaxCode = @sTempTaxCode output,
						@psTaxCode  = @sDisbTaxCode, 
						@pnCaseId   = @pnCaseId,
							@pnDebtorNo = @pnBillToNo,
							@pdtCalculationDate = @pdtTransactionDate

					-- The tax code may have changed
					if @ErrorCode = 0 and @sTempTaxCode is not null
					Begin
						Set @sDisbTaxCode = @sTempTaxCode
					End
				End


				If @sServTaxCode <> '0' AND @sServTaxCode is not null
				begin
					-- 8116 exec @ErrorCode=pt_GetTaxRate  @sServTaxCode, @nServTaxRate output
					exec @ErrorCode=pt_GetTaxRate  
						@prnTaxRate   = @nServTaxRate output,
						@psNewTaxCode = @sTempTaxCode output,
						@psTaxCode  = @sServTaxCode, 
						@pnCaseId   = @pnCaseId,
							@pnDebtorNo = @pnBillToNo,
							@pdtCalculationDate = @pdtTransactionDate

					-- The tax code may have changed
					if @ErrorCode = 0 and @sTempTaxCode is not null
					Begin
						Set @sServTaxCode = @sTempTaxCode
					End
				End


				If @sVarTaxCode <> '0' AND @sVarTaxCode is not null
				begin
					exec @ErrorCode=pt_GetTaxRate  
						@prnTaxRate   = @nVarTaxRate output,
						@psNewTaxCode = @sTempTaxCode output,
						@psTaxCode  = @sVarTaxCode, 
						@pnCaseId   = @pnCaseId,
							@pnDebtorNo = @pnBillToNo,
							@pdtCalculationDate = @pdtTransactionDate

					-- The tax code may have changed
					if @ErrorCode = 0 and @sTempTaxCode is not null
					Begin
						Set @sVarTaxCode = @sTempTaxCode
					End
				End
			end
		end
	end
	End
End

-- Calculate the Tax on the Disbursement

If @ErrorCode=0
Begin	
	-- 7375 IB if Discounts are nulls then set them to 0
	if @nDisbDiscount is null
		Set @nDisbDiscount     = 0
	if @nDisbHomeDiscount is null
		Set @nDisbHomeDiscount = 0
	if @nDisbBillDiscount is null
		Set @nDisbBillDiscount = 0

	Set @nDisbTaxAmt     = @nDisbTaxRate * (@nDisbAmount    -@nDisbDiscount)    /100
	Set @nDisbTaxHomeAmt = @nDisbTaxRate * (@nDisbHomeAmount-@nDisbHomeDiscount)/100
	Set @nDisbTaxBillAmt = @nDisbTaxRate * (@nDisbBillAmount-@nDisbBillDiscount)/100

	-- Peform any Rounding on the calculated Tax on Disbursements

	If @nDisbTaxAmt<>0
	Begin
		If  @nDisbExchRate   =1
		and @bRoundLocalValue=1
			Set @nDisbTaxAmt = Round (@nDisbTaxAmt, 0)

		If  @bRoundLocalValue = 1
			Set @nDisbTaxHomeAmt = Round(@nDisbTaxHomeAmt, 0)

		If @nRoundBilledValue <> 0
			exec @ErrorCode=pt_RoundToNearestUnitSize 
						@nDisbTaxBillAmt,
						@nRoundBilledValue,
						@nDisbTaxBillAmt	output
	End

	-- Handle MultiTier Tax if required
	-- NOTE: If Federal Tax was harmonised the State Tax Code and Rate would be NULL
	If (@bMultiTierTax = 1) AND (@nDisbStateTaxRate <> 0) AND (@nDisbStateTaxRate IS NOT NULL)
	Begin
		-- If the State Tax Code is Harmonised ensure federal tax amounts are cleared
		If (@bDisbStateTaxHarmonised = 1)
		Begin
			Set @nDisbTaxAmt     = 0
			Set @nDisbTaxHomeAmt = 0
			Set @nDisbTaxBillAmt = 0
		End

		If (@bDisbStateTaxOnTax = 1)
		Begin
			Set @nDisbStateTaxAmt     = @nDisbStateTaxRate * (@nDisbAmount    -@nDisbDiscount + @nDisbTaxAmt)    /100
			Set @nDisbStateTaxHomeAmt = @nDisbStateTaxRate * (@nDisbHomeAmount-@nDisbHomeDiscount + @nDisbTaxHomeAmt)/100
			Set @nDisbStateTaxBillAmt = @nDisbStateTaxRate * (@nDisbBillAmount-@nDisbBillDiscount + @nDisbTaxBillAmt)/100
		End
		Else
		Begin
			Set @nDisbStateTaxAmt     = @nDisbStateTaxRate * (@nDisbAmount    -@nDisbDiscount)    /100
			Set @nDisbStateTaxHomeAmt = @nDisbStateTaxRate * (@nDisbHomeAmount-@nDisbHomeDiscount)/100
			Set @nDisbStateTaxBillAmt = @nDisbStateTaxRate * (@nDisbBillAmount-@nDisbBillDiscount)/100
		End

		-- Peform any Rounding on the calculated Tax on Disbursements

		If @nDisbStateTaxAmt<>0
		Begin
			If  @nDisbExchRate   =1
			and @bRoundLocalValue=1
				Set @nDisbStateTaxAmt = Round (@nDisbStateTaxAmt, 0)
	
			If  @bRoundLocalValue = 1
				Set @nDisbStateTaxHomeAmt = Round(@nDisbStateTaxHomeAmt, 0)
	
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nDisbStateTaxBillAmt,
							@nRoundBilledValue,
							@nDisbStateTaxBillAmt	output
		End
	End
	
End

-- Calculate the Tax on the Service Charges

If @ErrorCode=0
Begin
	-- 7375 IB if Discounts are nulls then set them to 0
	if @nServDiscount is null
		Set @nServDiscount     = 0
	if @nServHomeDiscount is null
		Set @nServHomeDiscount = 0
	if @nServBillDiscount is null
		Set @nServBillDiscount = 0

	Set @nServTaxAmt     = @nServTaxRate * (@nServAmount    -@nServDiscount)    /100
	Set @nServTaxHomeAmt = @nServTaxRate * (@nServHomeAmount-@nServHomeDiscount)/100
	Set @nServTaxBillAmt = @nServTaxRate * (@nServBillAmount-@nServBillDiscount)/100

	-- Peform any Rounding on the calculated Tax on Disbursements

	If @nServTaxAmt<>0
	Begin
		If  @nServExchRate   =1
		and @bRoundLocalValue=1
			Set @nServTaxAmt = Round (@nServTaxAmt, 0)

		If  @bRoundLocalValue = 1
			Set @nServTaxHomeAmt = Round(@nServTaxHomeAmt, 0)

		If @nRoundBilledValue <> 0
			exec @ErrorCode=pt_RoundToNearestUnitSize 
						@nServTaxBillAmt,
						@nRoundBilledValue,
						@nServTaxBillAmt	output
	End
	
	-- Handle MultiTier Tax if required. 
	-- NOTE: If Federal Tax was harmonised the State Tax Code and Rate would be NULL
	If (@bMultiTierTax = 1) AND (@nServStateTaxRate <> 0) AND (@nServStateTaxRate IS NOT NULL)
	Begin
		-- If the State Tax Code is Harmonised ensure federal tax amounts are cleared
		If (@bServStateTaxHarmonised = 1)
		Begin
			Set @nServTaxAmt     = 0
			Set @nServTaxHomeAmt = 0
			Set @nServTaxBillAmt = 0
		End

		If (@bServStateTaxOnTax = 1)
		Begin
			Set @nServStateTaxAmt     = @nServStateTaxRate * (@nServAmount    -@nServDiscount + @nServTaxAmt)    /100
			Set @nServStateTaxHomeAmt = @nServStateTaxRate * (@nServHomeAmount-@nServHomeDiscount + @nServTaxHomeAmt)/100
			Set @nServStateTaxBillAmt = @nServStateTaxRate * (@nServBillAmount-@nServBillDiscount + @nServTaxBillAmt)/100
		End
		Else
		Begin
			Set @nServStateTaxAmt     = @nServStateTaxRate * (@nServAmount    -@nServDiscount)    /100
			Set @nServStateTaxHomeAmt = @nServStateTaxRate * (@nServHomeAmount-@nServHomeDiscount)/100
			Set @nServStateTaxBillAmt = @nServStateTaxRate * (@nServBillAmount-@nServBillDiscount)/100
		End

		-- Peform any Rounding on the calculated Tax on Service Charges
	
		If @nServStateTaxAmt<>0
		Begin
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @nServStateTaxAmt = Round (@nServStateTaxAmt, 0)
	
			If  @bRoundLocalValue = 1
				Set @nServStateTaxHomeAmt = Round(@nServStateTaxHomeAmt, 0)
	
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nServStateTaxBillAmt,
							@nRoundBilledValue,
							@nServStateTaxBillAmt	output
		End
	End
End

-- Calculate the Tax on the Variable Charges

If @ErrorCode=0
Begin
	Set @nVarTaxAmt     = @nVarTaxRate * @nVarAmount    /100
	Set @nVarTaxHomeAmt = @nVarTaxRate * @nVarHomeAmount/100
	Set @nVarTaxBillAmt = @nVarTaxRate * @nVarBillAmount/100

	-- Peform any Rounding on the calculated Tax on Variable Charges

	If @nVarTaxAmt<>0
	Begin
		If  @nServExchRate   =1
		and @bRoundLocalValue=1
			Set @nVarTaxAmt = Round (@nVarTaxAmt, 0)

		If  @bRoundLocalValue = 1
			Set @nVarTaxHomeAmt = Round(@nVarTaxHomeAmt, 0)

		If @nRoundBilledValue <> 0
			exec @ErrorCode=pt_RoundToNearestUnitSize 
						@nVarTaxBillAmt,
						@nRoundBilledValue,
						@nVarTaxBillAmt	output
	End

	-- Handle MultiTier Tax if required
	-- NOTE: If Federal Tax was harmonised the State Tax Code and Rate would be NULL
	If (@bMultiTierTax = 1) AND (@nVarStateTaxRate <> 0) AND (@nVarStateTaxRate IS NOT NULL)
	Begin
		-- If the State Tax Code is Harmonised ensure federal tax amounts are cleared
		If (@bVarStateTaxHarmonised = 1)
		Begin
			Set @nVarTaxAmt     = 0
			Set @nVarTaxHomeAmt = 0
			Set @nVarTaxBillAmt = 0
		End

		If (@bVarStateTaxOnTax = 1)
		Begin
			Set @nVarStateTaxAmt     = @nVarStateTaxRate * (@nVarAmount + @nVarTaxAmt) /100
			Set @nVarStateTaxHomeAmt = @nVarStateTaxRate * (@nVarHomeAmount + @nVarTaxHomeAmt) /100
			Set @nVarStateTaxBillAmt = @nVarStateTaxRate * (@nVarBillAmount + @nVarTaxBillAmt) /100
		End
		Else
		Begin
			Set @nVarStateTaxAmt     = @nVarStateTaxRate * @nVarAmount /100
			Set @nVarStateTaxHomeAmt = @nVarStateTaxRate * @nVarHomeAmount /100
			Set @nVarStateTaxBillAmt = @nVarStateTaxRate * @nVarBillAmount /100
		End

		-- Peform any Rounding on the calculated Tax on Variable Charges
	
		If @nVarStateTaxAmt<>0
		Begin
			If  @nServExchRate   =1
			and @bRoundLocalValue=1
				Set @nVarStateTaxAmt = Round (@nVarStateTaxAmt, 0)
	
			If  @bRoundLocalValue = 1
				Set @nVarStateTaxHomeAmt = Round(@nVarStateTaxHomeAmt, 0)
	
			If @nRoundBilledValue <> 0
				exec @ErrorCode=pt_RoundToNearestUnitSize 
							@nVarStateTaxBillAmt,
							@nRoundBilledValue,
							@nVarStateTaxBillAmt	output
		End

	End
End


-- If called by Charge Generation then
-- calculate the Cost Values
If  @ErrorCode=0
-- (V13) and @pbIsChargeGeneration=1
Begin
	-- Calculate the Cost value for the first part of the calculation ("disbursement') only if 
	-- a value exists, a WIP Code has been supplied and the calculation is not a Service Charge
	If  @sDisbWIPCode is not null
	and @nDisbHomeAmount<>0
	and @bDisbIsServiceCharge=0
	-- (v13)  and @bServIsServiceCharge=0
	Begin
		Exec @ErrorCode=dbo.wp_GetWipCostingRates
			@pnUserIdentityId=-1,		-- Mandatory (but not actually referenced)
			-- Wip criteria
			@pdtTransactionDate=@pdtLetterDate,
			@pnStaffKey        =@nDisbEmployeeNo,
			@psWipCode         =@sDisbWIPCode,
			-- Cost Rates
			@pbExtractCost =1,
			@pnCostPercent1=@nCostPercent1 	output, 
			@pnCostPercent2=@nCostPercent2	output

		If @nCostPercent1 is not null
			Set @prnDisbCostCalculation1 = 
				round((@nDisbHomeAmount * @nCostPercent1 / 100),
					@nLocalDecimalPlaces)

		If @nCostPercent2 is not null
			Set @prnDisbCostCalculation2 = 
				round((@nDisbHomeAmount * @nCostPercent2 / 100),
					@nLocalDecimalPlaces)
	End

	-- Calculate the Cost value for the second part of the calculation ("service') only if 
	-- a value exists, a WIP Code has been supplied and the calculation is not actually a Service Charge
	If  @sServWIPCode is not null
	and @nServHomeAmount<>0
	-- (V13) and @bDisbIsServiceCharge=0
	and @bServIsServiceCharge=0
	and @ErrorCode=0
	Begin
		Set @nCostPercent1=null
		Set @nCostPercent2=null

		Exec @ErrorCode=dbo.wp_GetWipCostingRates
			@pnUserIdentityId=-1,		-- Mandatory (but not actually referenced)
			-- Wip criteria
			@pdtTransactionDate=@pdtLetterDate,
			@pnStaffKey        =@nServEmployeeNo,
			@psWipCode         =@sServWIPCode,
			-- Cost Rates
			@pbExtractCost =1,
			@pnCostPercent1=@nCostPercent1 	output, 
			@pnCostPercent2=@nCostPercent2	output

		If @nCostPercent1 is not null
			Set @prnServCostCalculation1 = 
				round((@nServHomeAmount * @nCostPercent1 / 100),
					@nLocalDecimalPlaces)

		If @nCostPercent2 is not null
			Set @prnServCostCalculation2 = 
				round((@nServHomeAmount * @nCostPercent2 / 100),
					@nLocalDecimalPlaces)
	End
End

-- Assign the values to be returned
--=================================

If @ErrorCode=0
Begin
	Set @prsDisbCurrency		= @sDisbCurrency
	Set @prnDisbExchRate		= @nDisbExchRate
	Set @prsServCurrency		= @sServCurrency
	Set @prnServExchRate		= @nServExchRate
	Set @prnBillExchRate		= @nBillExchRate

	Set @prsDisbTaxCode		= @sDisbTaxCode
	Set @prsServTaxCode		= @sServTaxCode
	Set @prsVarTaxCode		= @sVarTaxCode

	-- 14649 Multi-Tier Tax
	Set @prsDisbStateTaxCode	= @sDisbStateTaxCode
	Set @prsServStateTaxCode	= @sServStateTaxCode
	Set @prsVarStateTaxCode		= @sVarStateTaxCode

	Set @prnDisbNarrative		= @nDisbNarrative
	Set @prnServNarrative		= @nServNarrative
	Set @prsDisbWIPCode		= @sDisbWIPCode
	Set @prsServWIPCode		= @sServWIPCode
	Set @prsVarWIPCode		= @sVarWIPCode
		
	Set @prnDisbAmount		= @nDisbAmount
	Set @prnDisbHomeAmount		= @nDisbHomeAmount
	Set @prnDisbBillAmount		= @nDisbBillAmount
	Set @prnServAmount		= @nServAmount
	Set @prnServHomeAmount		= @nServHomeAmount
	Set @prnServBillAmount		= @nServBillAmount
	Set @prnVariableFeeAmt		= @nVarAmount
	Set @prnVarHomeFeeAmt		= @nVarHomeAmount
	Set @prnVarBillFeeAmt		= @nVarBillAmount
	Set @prnDisbDiscOriginal	= @nDisbDiscount
	Set @prnDisbHomeDiscount	= @nDisbHomeDiscount
	Set @prnDisbBillDiscount	= @nDisbBillDiscount
	Set @prnServDiscOriginal	= @nServDiscount
	Set @prnServHomeDiscount	= @nServHomeDiscount
	Set @prnServBillDiscount	= @nServBillDiscount
	Set @prnTotHomeDiscount		= @nServHomeDiscount + @nDisbHomeDiscount
	Set @prnTotBillDiscount		= @nServBillDiscount + @nDisbBillDiscount

	Set @prnDisbCostOriginal	= @nDisbAmount     - isnull(@nDisbMargin,0)
	Set @prnDisbCostHome		= @nDisbHomeAmount - isnull(@nDisbHomeMargin,0)

	Set @prnServCostOriginal	= @nServAmount     - isnull(@nServMargin,0)
	Set @prnServCostHome		= @nServHomeAmount - isnull(@nServHomeMargin,0)
		
	Set @prnDisbTaxAmt		= @nDisbTaxAmt
	Set @prnDisbTaxHomeAmt		= @nDisbTaxHomeAmt
	Set @prnDisbTaxBillAmt		= @nDisbTaxBillAmt
	Set @prnServTaxAmt		= @nServTaxAmt
	Set @prnServTaxHomeAmt		= @nServTaxHomeAmt
	Set @prnServTaxBillAmt		= @nServTaxBillAmt
	Set @prnVarTaxAmt		= @nServTaxAmt
	Set @prnVarTaxHomeAmt		= @nServTaxHomeAmt
	Set @prnVarTaxBillAmt		= @nServTaxBillAmt

	-- 14649 Multi-Tier Tax
	Set @prnDisbStateTaxAmt		= @nDisbStateTaxAmt
	Set @prnDisbStateTaxHomeAmt	= @nDisbStateTaxHomeAmt
	Set @prnDisbStateTaxBillAmt	= @nDisbStateTaxBillAmt
	Set @prnServStateTaxAmt		= @nServStateTaxAmt
	Set @prnServStateTaxHomeAmt	= @nServStateTaxHomeAmt
	Set @prnServStateTaxBillAmt	= @nServStateTaxBillAmt
	Set @prnVarStateTaxAmt		= @nServStateTaxAmt
	Set @prnVarStateTaxHomeAmt	= @nServStateTaxHomeAmt
	Set @prnVarStateTaxBillAmt	= @nServStateTaxBillAmt

	-- MF 02/11/2000 Add a new set of output parameters for use by FEESCALCEXTENDED

	Set @prnParameterSource		= @nParameterSource
	Set @prnDisbMaxUnits		= @nDisbMaxUnits
	Set @prnDisbBaseUnits		= @nDisbBaseUnits
	Set @prbDisbMinFeeFlag		= @bDisbMinFeeFlag
	Set @prnServMaxUnits		= @nServMaxUnits
	Set @prnServBaseUnits		= @nServBaseUnits
	Set @prbServMinFeeFlag		= @bServMinFeeFlag
	Set @prnDisbUnitSize		= @nDisbUnitSize
	Set @prnServUnitSize		= @nServUnitSize
	Set @prdDisbBaseFee		= @dDisbBaseFee
	Set @prdDisbAddPercentage 	= @dDisbAddPercentage
	Set @prdDisbVariableFee 	= @dDisbVariableFee
	Set @prdServBaseFee 		= @dServBaseFee
	Set @prdServAddPercentage 	= @dServAddPercentage
	Set @prdServVariableFee		= @dServVariableFee
	Set @prdServDisbPercent		= @dServDisbPercent
	Set @prnDisbMargin		= @nDisbMargin
	Set @prnDisbHomeMargin		= @nDisbHomeMargin
	Set @prnDisbBillMargin		= @nDisbBillMargin
	Set @prnServMargin		= @nServMargin
	Set @prnServHomeMargin		= @nServHomeMargin
	Set @prnServBillMargin		= @nServBillMargin

	Set @prsFeeType			= @sFeeType		-- RCT 07/03/2002	New output variable added
	Set @prsFeeType2		= @sFeeType2		-- RFC6478

	-- Return the quantity values used in the calculations

	Set @pnDisbQuantity 		= @pnEnteredQuantity
	Set @psDisbPeriodType		= @sPeriodType
	Set @pnDisbPeriodCount		= @nPeriodCount
	Set @pnServQuantity 		= @nEnteredQuantity2
	Set @psServPeriodType		= @sPeriodType2
	Set @pnServPeriodCount		= @nPeriodCount2

	-- SQA16376
	Set @prnParameterSource2 	= @nParameterSource2
End

Return (@ErrorCode)
go		
	
grant execute on dbo.pt_DoCalculation to public
go
