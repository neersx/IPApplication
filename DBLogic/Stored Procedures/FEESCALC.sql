-----------------------------------------------------------------------------------------------------------------------------
-- Creation of FEESCALC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[FEESCALC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.FEESCALC.'
	drop procedure dbo.FEESCALC
end
print '**** Creating Stored Procedure dbo.FEESCALC...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create proc dbo.FEESCALC 
	@psIRN 			nvarchar(30)	=NULL,	-- SQA12361 now optional
	@pnRateNo 		int, 
	@psAction 		nvarchar(2)	=NULL, 
	@pnCheckListType 	smallint	=NULL,
	@pnCycle 		smallint	=NULL,
	@pnEventNo 		int		=NULL,
	@pdtLetterDate 		datetime	=NULL,
	@pnProductCode	 	int		=NULL, 
	@pnEnteredQuantity 	int		=NULL, 
	@pnEnteredAmount 	decimal(11,2)	=NULL, 
	@pnARQuantity 		smallint	=NULL, 
	@pnARAmount 		decimal(11,2)	=NULL, 
	@pnDebtor	 	int		=NULL,
	@prsDisbCurrency 	nvarchar(3)	=NULL output,	
	@prnDisbExchRate 	decimal(11,4)	=NULL output, 
	@prsServCurrency 	nvarchar(3) 	=NULL output, 	
	@prnServExchRate 	decimal(11,4) 	=NULL output, 
	@prsBillCurrency 	nvarchar(3) 	=NULL output, 	
	@prnBillExchRate 	decimal(11,4) 	=NULL output, 
	@prsDisbTaxCode 	nvarchar(3) 	=NULL output, 	
	@prsServTaxCode 	nvarchar(3) 	=NULL output, 
	@prnDisbNarrative 	int 		=NULL output, 		
	@prnServNarrative 	int 		=NULL output, 
	@prsDisbWIPCode 	nvarchar(6) 	=NULL output, 	
	@prsServWIPCode 	nvarchar(6) 	=NULL output, 
	@prnDisbAmount 		decimal(11,2) 	=NULL output, 	
	@prnDisbHomeAmount 	decimal(11,2) 	=NULL output, 
	@prnDisbBillAmount 	decimal(11,2) 	=NULL output,
	@prnServAmount 		decimal(11,2) 	=NULL output, 
	@prnServHomeAmount 	decimal(11,2) 	=NULL output,
	@prnServBillAmount 	decimal(11,2) 	=NULL output, 
	@prnTotHomeDiscount 	decimal(11,2) 	=NULL output, 
	@prnTotBillDiscount 	decimal(11,2) 	=NULL output,
	@prnDisbTaxAmt 		decimal(11,2) 	=NULL output, 	
	@prnDisbTaxHomeAmt 	decimal(11,2) 	=NULL output, 
	@prnDisbTaxBillAmt 	decimal(11,2) 	=NULL output,
	@prnServTaxAmt 		decimal(11,2) 	=NULL output, 	
	@prnServTaxHomeAmt 	decimal(11,2) 	=NULL output,
	@prnServTaxBillAmt 	decimal(11,2) 	=NULL output,
	-- MF 27/02/2002 Add new output parameters to return the new components of the calculation
	@prnDisbDiscOriginal	decimal(11,2)	=NULL output,
	@prnDisbHomeDiscount 	decimal(11,2) 	=NULL output,
	@prnDisbBillDiscount 	decimal(11,2) 	=NULL output, 
	@prnServDiscOriginal	decimal(11,2)	=NULL output,
	@prnServHomeDiscount 	decimal(11,2) 	=NULL output,
	@prnServBillDiscount 	decimal(11,2) 	=NULL output,
	@prnDisbCostHome	decimal(11,2)	=NULL output,
	@prnDisbCostOriginal	decimal(11,2)	= NULL output,
	-- RT SQA15816 09/01/2008 Include output parameters from FEESCALCEXTENDED
	@prnParameterSource 	smallint 	=NULL output, 
	@prnDisbMaxUnits 	smallint 	=NULL output, 
	@prnDisbBaseUnits 	smallint 	=NULL output,
	@prbDisbMinFeeFlag 	decimal(1,0) 	=NULL output, 
	@prnServMaxUnits 	smallint 	=NULL output, 
	@prnServBaseUnits 	smallint 	=NULL output,
	@prbServMinFeeFlag 	decimal(1,0) 	=NULL output, 
	@prnDisbUnitSize 	smallint 	=NULL output, 
	@prnServUnitSize 	smallint 	=NULL output,
	@prdDisbBaseFee 	decimal(11,2) 	=NULL output, 
	@prdDisbAddPercentage 	decimal(5,2) 	=NULL output, 
	@prdDisbVariableFee 	decimal(11,2) 	=NULL output,
	@prdServBaseFee 	decimal(11,2) 	=NULL output, 
	@prdServAddPercentage 	decimal(5,2) 	=NULL output, 
	@prdServVariableFee 	decimal(11,2) 	=NULL output,
	@prdServDisbPercent 	decimal(5,2) 	=NULL output,
	@prsFeeType		nvarchar(6)	=NULL output,
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
	@prnFeeCriteriaNo		int		= NULL	output,
	@prnFeeUniqueId			int		= NULL	output,
	-- SQA12379 New INPUT Parameter
	@pbIsChargeGeneration		bit		= 1,
	@pdtTransactionDate		datetime	= NULL,
	@pdtFromEventDate		datetime	= NULL,
	--SQA12361 allow variables to be entered instead of a CaseId.
	--         This is to allow a "what if" style of enquiry
	@psCaseType			nchar(1)	= null,	-- User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- User entered Country
	@psPropertyType			nchar(1)	= null, -- User entered Property Type
	@psCaseCategory			nvarchar(2)	= null, -- User entered Category
	@psSubType			nvarchar(2)	= null, -- User entered Sub Type
	@pnEntitySize			int		= null, -- User entered Entity Size
	@pnInstructor			int		= null, -- User entered Instructor
	@pnForDebtor			int		= null, -- User entered Debtor the calculation is for
	@pnDebtorType			int		= null, -- User entered Debtor Type
	@pnAgent			int		= null, -- User entered Agent
	@psCurrency			nvarchar(3)	= null, -- User entered Currency
	@pnExchScheduleId		int		= null,	-- User entered Exchange Rate Schedule
	@pdtFromDateDisb		datetime	= NULL,	-- Simulated From date for Disbursements
	@pdtFromDateServ		datetime	= NULL,	-- Simulated From date for Service Charges
	@pdtUntilDate			datetime	= NULL,	-- Simulated Until date
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
	@pbAgentItem			bit		= 0,
	@pbUseTodaysExchangeRate	bit		= 0,
	-- 14649 Multi-tier Tax
	@prsDisbStateTaxCode 	nvarchar(3) 	= NULL	output, @prsServStateTaxCode 	nvarchar(3) 	= NULL	output, @prsVarStateTaxCode 	nvarchar(3) 	= NULL	output,
	@prnDisbStateTaxAmt 	decimal(11,2) 	= NULL	output, @prnDisbStateTaxHomeAmt decimal(11,2) 	= NULL	output, @prnDisbStateTaxBillAmt decimal(11,2)	= NULL	output, 
	@prnServStateTaxAmt 	decimal(11,2) 	= NULL	output, @prnServStateTaxHomeAmt decimal(11,2) 	= NULL	output, @prnServStateTaxBillAmt decimal(11,2)	= NULL	output, 
	@prnVarStateTaxAmt	decimal(11,2)	= NULL	output, @prnVarStateTaxHomeAmt	decimal(11,2)	= NULL	output, @prnVarStateTaxBillAmt	decimal(11,2)	= NULL	output,
	-- SQA16376
	@prnParameterSource2 		smallint	= NULL  output,
	@prnDisbMarginNo		int		= null output,
	@prnServMarginNo		int		= null output,
	-- RFC6478
	@prsFeeType2			nvarchar(6)	= null output,
	-- SQA9641
	@pnEmployee				int		= NULL,
--	,@pbDebug			bit		= 0,
	--RFC7269
	@pnDisbDiscountForMargin	decimal(11,2)	= null	output,
	@pnDisbHomeDiscountForMargin	decimal(11,2)	= null	output,
	@pnDisbBillDiscountForMargin	decimal(11,2)	= null	output,
	@pnServDiscountForMargin	decimal(11,2)	= null	output,
	@pnServHomeDiscountForMargin	decimal(11,2)	= null	output,
	@pnServBillDiscountForMargin	decimal(11,2)	= null	output,
	-- RFC13222 
	@pbCycleIsAgeOfCase		bit		= 0,
        -- RFC56172
        @pnDisbPreMarginDiscount	decimal(11,2)	= null	output,
	@pnDisbHomePreMarginDiscount	decimal(11,2)	= null	output,
	@pnDisbBillPreMarginDiscount	decimal(11,2)	= null	output,
	@pnServPreMarginDiscount	decimal(11,2)	= null	output,
	@pnServHomePreMarginDiscount	decimal(11,2)	= null	output,
	@pnServBillPreMarginDiscount	decimal(11,2)	= null	output	

as

-- PROCEDURE:	FEESCALC
-- VERSION:	39
-- DESCRIPTION:	
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- CALLED BY :	DOFEESCALC, FEESCALCDOCS
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 02/11/2000 	MF			16 new return parameters for DOCALCULATION
-- 22/02/2002	MF	7182		Calculate discounts on Disbursements and Overhead recoveries and also calculate margins.  This will
--					require the discount calculation to be moved into the DOCALCULATION procedure
-- 08/05/2002	IB	7590		Changed the size of the @psIRN parameter from varchar(12) to varchar(20).
-- 13/05/2002	VL	7750		Changed the size of the @psIRN parameter from varchar(20) to varchar(30).
-- 19/08/2002	CR	7629		Added new @bCalledFromCentura variable for use wht the call to pt_GetAgeOfCase.
-- 13/05/2004	Dw	9917 		Added @pnDebtor as a new input parameter.
-- 09/06/2004	DW			Added @nDebtorPercentage local variable.
-- 28/02/2005	Dw	11071	1	added new parameter Product Code
-- 07/07/2005	VL	11011	2	Change the CaseCategory size to nvarchar(2).
-- 08 Mar 2006	MF	12379	3	Add new parameters required by Charge Generation
-- 14 Mar 2006	MF	12379	4	Revisit.  Also return the Margin values 
-- 27 Mar 2006  KR 	12448   5	Added case office to the best fit logic
-- 28 Mar 2006	DW	12379	6	Fixed a typo associated with the variable @sIPTaxCode
-- 06 Jun 2006  DW      12326	7	If renewal debtor is optional fall back to using debtor
-- 14 Jun 2006 	KR	11702	8 	Added new parameters required by 11702 and 12108
-- 16 Jun 2006 	DL	12388	9 	Make all output parameters optional (@prsDisbCurrency TO @prnDisbCostHome).
-- 21 Jun 2006	MF	12347	10	If an explicit Action and Cycle are not provided then determine the
--					date of the law to use from the Action associated with the RATE and taking
--					the highest open action.
-- 04 Jul 2006	MF	12361	11	New case characteristic parameters may be passed in order to determine the
--					fees that match the profile instead of a specific Case.
-- 20 Nov 2006 	IB	13656	12	Defaulted @pbIsChargeGeneration parameter to 1.
-- 01 Dec 2006	MF	12361	13	Additional parameters for simulated dates to be used in calculations
--					that require the period between two dates.
-- 14 Feb 2007	CR	12400	14	Added new Bill Date parameter for use when deriving exchange rate for
--					Foreign Currency Bills.
-- 15 May 2007	MF	14726	15	Return the quantities used in the fee calculations
-- 06 Aug 2007	MF	15103	16	The simulated "from date" used for calculating the period of time between two
--					dates may in fact be different for the Disbursement and the Service components
--					of the calculation.
-- 28 Aug 2007	MF	15276	17	Do not default the @pdtTransactionDate parameter if no value was passed. 
-- 28 Sep 2007	CR	14901	18	Changed Exchange Rate field sizes to (8,4)
-- 01 OCT 2007	CR	14852	19	Changed logic that derives agent to refer to new RATES.AGENTNAMETYPE
-- 16 Oct 2007	CR	15383	20	Added new Agent Item parameter to indicate when an Agent Item is being processed.
-- 05 Dec 2007	CR	14649	21	Extended to include Multi-Tier Tax. 
-- 09 Jan 2008	RT	15816	22	Include output parameters from FEESCALCEXTENDED

-- 11 Feb 2008	MF	15943	23	Provide a parameter to indicate that the current exchange rate
--					is to be used instead of one matching the transaction date.
-- 13 May 2008	Dw	16376	24	Return @prnParameterSource2 as receive parameter.
-- 03 Oct 2008	Dw	16917	22	Added 2 new parameters to return margin identifiers for fee1 and fee2.
-- 14 Sep 2009	Dw	17867	23	Allow Debtor Type to be derived from instructor via new site control. 
-- 11 Dec 2008	MF	17136	25	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Mar 2009	MF	RFC6478	26	Return FEETYPE2 from FeesCalculation table as it is required to allow Fee List to be generated
-- 10 Jul 2009	MF	13811	27	Allow key of FEESCALCULATION table to be passed as input parameters so that Fee Calculation
--					is explicitly calculated for that particular row.
-- 21 Jul 2009	Dw	SQA9641	28	Added @pnEmployee as new input parameter
-- 23 Jun 2010	MS	RFC7269	29	Added output parameters for Discount For Margin
-- 19 Apr 2011	Dw	18457	30	Wrong annuity number used by Charge Generation in fee calculation.
-- 12 Jul 2011	Dw	19799	31	Reverses previous change (SQA18457)- So Version 31 is identical to version 29.
-- 22 Feb 2012	MF	R13222	32	Fee was failing to calculate becuase AgeOfCase was already known and passed in @pnCycle but then 
--					being recalculated incorrectly. New parameter introduced to indicate that ithe AgeOfCase is already known.
-- 04 Jul 2013	Dw	12904	33	Cater for new 'WIP Split Multi Debtor' site control
-- 22 Aug 2013	Dw	12904	34	Adjusted logic to derive Debtor Name Type from RATENO when provided as primary determinant.
-- 17 Dec 2014	MF	R42619	35	Ensure the USERDEFINEDRULE flag is considered when determining the best CRITERIA to use.
-- 20 Oct 2015  MS      R53933  36      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 04 Jan 2016  MS      R56172  37      Added premargin discounts for service fees and disbursments
-- 07 Jul 2016	MF	63861	38	A null LOCALCLIENTFLAG should default to 0.
-- 13 Jun 2017	MF	71704	39	Correction to logic introduced at 14852.  Use the specified AGENNAMETYPE if available, but fall back to use
--					Renewal Agent (for a Renewal rate) or Agent nametype until an Agent is found.

Set nocount on

declare	@sSQLString		nvarchar(4000)

declare @nCaseId 		int
declare @nQuestionNo 		smallint
declare @sCaseType 		nchar(1)
declare @sPropertyType 		nchar(1)
declare @sCountryCode 		nvarchar(3)
declare @sCaseCategory 		nvarchar(2)
declare @sSubType 		nvarchar(2)
declare @nLocalClientFlag 	decimal(1,0)
declare @nTypeOfMark 		int
declare @nBestfit 		int
declare @nTypeFlag 		int
declare @nAgentNo 		int
declare @nBillToNo 		int
declare @nUseDebtorType 	int
declare @nDebtorType 		int
declare @nOwner 		int
declare @nInstructor 		int
declare @nEmployee		int
declare @nEntity		int
declare @nUniqueId 		smallint
declare @nAgeOfCase 		int
declare @nEntitySize 		int
declare @nRegisteredFlag 	decimal(1,0)
declare @sBillCurrency 		nvarchar(3)
declare @sIPTaxCode 		nvarchar(3)
declare @sCaseTaxCode 		nvarchar(3)		/* MF 02/11/2000 	New variable added	*/
declare @nConsolidation 	decimal(1,0)
declare @nDiscountRate 		decimal(9,2)
declare @nNoInSeries 		smallint
declare @nNoOfClasses 		smallint
declare @dtDateForAct 		datetime		/* MF 03/08/2000	New variable added	*/
declare @nRateType 		int			/* MF 01/08/2000	New variable added	*/
declare @bCalledFromCentura	tinyint			/* CR 19/08/2002	New variable added 	*/
declare @bSeparateDebtorFlag 	tinyint			/* DW 13/05/2004	New variable added	*/
declare @nDebtorPercentage	decimal(5,2)		/* DW 07/06/2004	New variable added	*/
declare @sDebtorNameType	nchar(1)		/* DW 09/06/2004	'Z' or 'D'		*/
declare @nCaseOfficeId		int			/* KR 27/03/2006 	New variable added    	*/
declare @bRenewalNameTypeOptional tinyint		/* DW 06/06/2006	New variable added	*/
declare @sAgentNameType		nvarchar(3)		/* SQA14852 */
declare @bDebtorTypeBasedInstructor bit		/* DW 14/09/2009	New variable added	*/

declare @ErrorCode		int
-- 12904
declare @bWIPSplitMultiDebtor	bit

Select	@ErrorCode=0

If @pdtLetterDate is null
	Select @pdtLetterDate = getdate()
			
Set @nAgentNo    = null
Set @nBillToNo   = null
Set @nOwner      = null
Set @nInstructor = null
Set @nEmployee   = null
Set @bCalledFromCentura     = 0
Set @nDebtorPercentage      = 100
Set @bSeparateDebtorFlag    = null
Set @bWIPSplitMultiDebtor = 0

-- Is the 'WIP Split Multi Debtor' site control applicable?

If @ErrorCode = 0
Begin
	Set @sSQLString = "
	select  @bWIPSplitMultiDebtor = isnull(S.COLBOOLEAN,0 )
	from	SITECONTROL S
	WHERE 	S.CONTROLID = 'WIP Split Multi Debtor'"

	exec @ErrorCode=sp_executesql @sSQLString,
			N'@bWIPSplitMultiDebtor	bit		OUTPUT',
			  @bWIPSplitMultiDebtor	= @bWIPSplitMultiDebtor	OUTPUT
End

-- 9917 Check if separate debtor functionality is required
	
If @ErrorCode = 0
Begin
	If  @pnDebtor is not null
	and (@bWIPSplitMultiDebtor = 0)
	and @ErrorCode=0
		Set @ErrorCode=9917
End

-- 12326 Check if renewal debtor is optional
	
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select @bRenewalNameTypeOptional=S.COLBOOLEAN
	from	SITECONTROL S
	where	S.CONTROLID='Renewal Name Type Optional'"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bRenewalNameTypeOptional	bit	output',
			@bRenewalNameTypeOptional		output

/*	If @pbDebug = 1
	Begin
		print 'Renewal Name Type Optional'
		print @sSQLString
	End
*/

End


-- Get CASE attributes either from the Case itself or
-- use attributes that have been passed to get a fee for
-- that profile of Case.

If @ErrorCode=0
Begin
	If @psIRN is null
	Begin
		Set @sCaseType	    =@psCaseType
		Set @sPropertyType  =@psPropertyType
		Set @sCountryCode   =@psCountryCode
		Set @sCaseCategory  =@psCaseCategory
		Set @sSubType	    =@psSubType
		Set @nEntitySize    =@pnEntitySize
		Set @prsBillCurrency=@psCurrency
		Set @dtDateForAct   =getdate()
	End
	Else Begin
		Set @sSQLString="
		SELECT 	@nRegisteredFlag=S.REGISTEREDFLAG, 
			@nCaseId	=C.CASEID, 
			@nCaseOfficeId	=C.OFFICEID,
			@sCaseType	=C.CASETYPE, 
			@sPropertyType	=C.PROPERTYTYPE, 
			@sCountryCode	=C.COUNTRYCODE,
			@sCaseCategory	=C.CASECATEGORY,
			@sSubType	=C.SUBTYPE,
			@nLocalClientFlag=isnull(C.LOCALCLIENTFLAG,0),
			@nTypeOfMark	=C.TYPEOFMARK,
			@nEntitySize	=C.ENTITYSIZE, 
			@nNoInSeries	=C.NOINSERIES, 
			@nNoOfClasses	=C.NOOFCLASSES, 
			@sCaseTaxCode	=C.TAXCODE,
			@dtDateForAct	=isnull(O.DATEFORACT,GETDATE()),
			@sAgentNameType = R.AGENTNAMETYPE --SQA14852
		FROM 		CASES C
		     JOIN 	RATES R		on (R.RATENO=@pnRateNo)
		LEFT JOIN	STATUS S 	on (S.STATUSCODE=C.STATUSCODE)
		LEFT JOIN	OPENACTION O	on (O.CASEID=C.CASEID
						and O.ACTION=isnull(@psAction,R.ACTION)
						and O.CYCLE =isnull(@pnCycle,(	select min(O1.CYCLE)
										from OPENACTION O1
										where O1.CASEID=C.CASEID
										and O1.ACTION=O.ACTION
										and O1.POLICEEVENTS=1)))
		WHERE IRN = @psIRN"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nRegisteredFlag	decimal(1,0)	OUTPUT, 
					  @nCaseId		int		OUTPUT, 
					  @nCaseOfficeId	int		OUTPUT,
					  @sCaseType		nchar(1)	OUTPUT, 
					  @sPropertyType	nchar(1)	OUTPUT, 
					  @sCountryCode		nvarchar(3)	OUTPUT,
					  @sCaseCategory	nvarchar(2)	OUTPUT,
					  @sSubType		nvarchar(2)	OUTPUT,
					  @nLocalClientFlag	decimal(1,0)	OUTPUT,
					  @nTypeOfMark		int		OUTPUT,
					  @nEntitySize		int		OUTPUT, 
					  @nNoInSeries		smallint	OUTPUT, 
					  @nNoOfClasses		smallint	OUTPUT, 
					  @sCaseTaxCode		nvarchar(3)	OUTPUT,
					  @dtDateForAct		datetime	OUTPUT,
					  @sAgentNameType	nvarchar(3)	OUTPUT,
					  @psAction		nvarchar(2),
					  @pnCycle		smallint,
					  @psIRN		nvarchar(30),
					  @pnRateNo		int',
					  @nRegisteredFlag			OUTPUT, 
					  @nCaseId				OUTPUT, 
					  @nCaseOfficeId			OUTPUT,
					  @sCaseType				OUTPUT, 
					  @sPropertyType			OUTPUT, 
					  @sCountryCode				OUTPUT,
					  @sCaseCategory			OUTPUT,
					  @sSubType				OUTPUT,
					  @nLocalClientFlag			OUTPUT,
					  @nTypeOfMark				OUTPUT,
					  @nEntitySize				OUTPUT, 
					  @nNoInSeries				OUTPUT, 
					  @nNoOfClasses				OUTPUT, 
					  @sCaseTaxCode				OUTPUT,
					  @dtDateForAct				OUTPUT,
					  @sAgentNameType			OUTPUT,
					  @psAction,
					  @pnCycle,
					  @psIRN,
					  @pnRateNo
	
/*		If @pbDebug = 1
		Begin
			print 'Rate No'
			print @sSQLString
		End
*/

		If  @nCaseId is null
		and @ErrorCode=0
			Set @ErrorCode=-1
	End
End

------------------------------------------------
-- Get the CriteriaNo by using a best fit search
-- unless it has been explicitly supplied as an
-- input parameter.
------------------------------------------------
If  @ErrorCode = 0
and @prnFeeCriteriaNo is null
Begin
	Set @sSQLString="
	SELECT 	@prnFeeCriteriaNo =
			convert(int,
			Substring ( max(
			CASE WHEN CASEOFFICEID	  is null THEN '0' ELSE '1' END +
			CASE WHEN CASETYPE	  is null THEN '0' ELSE '1' END +
			CASE WHEN PROPERTYTYPE	  is null THEN '0' ELSE '1' END +
			CASE WHEN COUNTRYCODE	  is null THEN '0' ELSE '1' END +
			CASE WHEN CASECATEGORY	  is null THEN '0' ELSE '1' END +
			CASE WHEN SUBTYPE	  is null THEN '0' ELSE '1' END +
			CASE WHEN LOCALCLIENTFLAG is null THEN '0' ELSE '1' END +
			CASE WHEN TYPEOFMARK      is null THEN '0' ELSE '1' END +
			CASE WHEN TABLECODE	  is null THEN '0' ELSE '1' END +
			isnull(convert(char(8), DATEOFACT,112),'00000000')+		-- valid from date in YYYYMMDD format
			CASE WHEN (C.USERDEFINEDRULE is NULL
				OR C.USERDEFINEDRULE = 0) THEN '0' ELSE '1' END +
			convert(char(11),C.CRITERIANO)),19,11))
	FROM  CRITERIA C  
	WHERE C.RULEINUSE	= 1  
	AND   C.PURPOSECODE	= 'F'  
	AND   C.RATENO		= @pnRateNo  
	AND ( C.CASEOFFICEID	= @nCaseOfficeId	OR C.CASEOFFICEID	IS NULL) 
	AND ( C.CASETYPE	= @sCaseType		OR C.CASETYPE		IS NULL) 
	AND ( C.PROPERTYTYPE	= @sPropertyType	OR C.PROPERTYTYPE	IS NULL) 
	AND ( C.COUNTRYCODE	= @sCountryCode		OR C.COUNTRYCODE	IS NULL)  
	AND ( C.CASECATEGORY	= @sCaseCategory	OR C.CASECATEGORY	IS NULL) 
	AND ( C.SUBTYPE		= @sSubType		OR C.SUBTYPE		IS NULL) 
	AND ( C.LOCALCLIENTFLAG = @nLocalClientFlag	OR C.LOCALCLIENTFLAG	IS NULL) 
	AND ( C.TYPEOFMARK	= @nTypeOfMark		OR C.TYPEOFMARK		IS NULL) 
	AND ( C.TABLECODE	= @nEntitySize		OR C.TABLECODE		IS NULL) 
	AND ( C.DATEOFACT      <= @dtDateForAct		OR C.DATEOFACT		IS NULL)"


	exec @ErrorCode=sp_executesql @sSQLString,
				N'@prnFeeCriteriaNo	int		OUTPUT, 
				  @pnRateNo		int, 
				  @nCaseOfficeId	int,
				  @sCaseType		nchar(1), 
				  @sPropertyType	nchar(1), 
				  @sCountryCode		nvarchar(3),
				  @sCaseCategory	nvarchar(2),
				  @sSubType		nvarchar(2),
				  @nLocalClientFlag	decimal(1,0),
				  @nTypeOfMark		int,
				  @nEntitySize		int,
				  @dtDateForAct		datetime',
				  @prnFeeCriteriaNo			OUTPUT, 
				  @pnRateNo, 
				  @nCaseOfficeId,
				  @sCaseType, 
				  @sPropertyType, 
				  @sCountryCode,
				  @sCaseCategory,
				  @sSubType,
				  @nLocalClientFlag,
				  @nTypeOfMark,
				  @nEntitySize,
				  @dtDateForAct

	If  @prnFeeCriteriaNo is null
	and @ErrorCode=0
		Set @ErrorCode=-2

/*	If @pbDebug = 1
	Begin
		print 'Fee Criteria No'
		print @sSQLString
	End
*/

End



-- MF	1/8/2000	Change this code so that the @nTypeFlag is set to 1 if no ACTION or CHECKLISTTYPE is passed
--			as a parameter and the type of RATE is flagged as being for Renewals.
-- Dw	22/08/13	Adjusted logic to derive Debtor Name Type from RATETYPE then ACTIONTYPEFLAG then CHECKLISTTYPE
--					in that order, because MF considers this logic more correct and it is consistent with logic in  
--					Policing (change was done for RFC12904). 

If @ErrorCode=0
Begin	
	If @pnRateNo is not null
	begin
		Set @sSQLString="
		Select @nRateType = RATETYPE
		FROM RATES
		WHERE RATENO=@pnRateNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nRateType	int	OUTPUT,
					  @pnRateNo	int',
					  @nRateType		OUTPUT,
					  @pnRateNo

		If @nRateType = 1601
			Set @nTypeFlag = 1
		Else
			Set @nTypeFlag = 0

/*		If @pbDebug = 1
		Begin
			print 'Rate Type'
			print @sSQLString
		End
*/
	end
	else begin
		If @psAction is not null
		Begin
			Set @sSQLString="
			Select @nTypeFlag = ACTIONTYPEFLAG
			FROM ACTIONS
			WHERE ACTION = @psAction"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nTypeFlag	int	OUTPUT,
						  @psAction	nvarchar(2)',
						  @nTypeFlag		OUTPUT,
						  @psAction

/*			If @pbDebug = 1
			Begin
				print 'Action'
				print @sSQLString
			End
*/
		End
		else Begin
			Set @sSQLString="
			Select @nTypeFlag = CHECKLISTTYPEFLAG
			FROM CHECKLISTS
			WHERE CHECKLISTTYPE = @pnCheckListType"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nTypeFlag		int	OUTPUT,
						  @pnCheckListType	smallint',
						  @nTypeFlag			OUTPUT,
						  @pnCheckListType
	
/*			If @pbDebug = 1
			Begin
				print 'Checklist Type flag'
				print @sSQLString
			End
*/
		End
	end	
End		 

If @ErrorCode=0
Begin	
	If @nTypeFlag = 1
		Set @sDebtorNameType = 'Z'
	Else
		Set @sDebtorNameType = 'D'

        
	-- 9917 If the debtor is supplied then use the supplied debtor
	If  @pnDebtor is not null
	and @nCaseId is not null
	begin
		Set @nBillToNo=@pnDebtor
		Set @bSeparateDebtorFlag =1

		Set @sSQLString="
		SELECT	@nDebtorPercentage=C.BILLPERCENTAGE,
			@nUseDebtorType	=I.USEDEBTORTYPE, 
			@nDebtorType	=I.DEBTORTYPE,
			@prsBillCurrency=I.CURRENCY, 
			@sIPTaxCode	=I.TAXCODE, 
			@nConsolidation =I.CONSOLIDATION
			FROM CASENAME C
			join IPNAME I on (I.NAMENO=C.NAMENO)
			WHERE C.CASEID = @nCaseId
			AND C.NAMENO = @nBillToNo
			AND C.EXPIRYDATE is null
			AND C.NAMETYPE = @sDebtorNameType"
					
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDebtorPercentage	decimal(5,2)	OUTPUT,
					  @nUseDebtorType	int		OUTPUT, 
					  @nDebtorType		int		OUTPUT,
					  @prsBillCurrency	nvarchar(3)	OUTPUT, 
					  @sIPTaxCode		nvarchar(3)	OUTPUT, 
					  @nConsolidation	decimal(1,0)	OUTPUT,
					  @nCaseId		int,
					  @nBillToNo		int,
					  @sDebtorNameType	nchar(1)',
					  @nDebtorPercentage			OUTPUT,
					  @nUseDebtorType			OUTPUT, 
					  @nDebtorType				OUTPUT,
					  @prsBillCurrency			OUTPUT, 
					  @sIPTaxCode				OUTPUT, 
					  @nConsolidation			OUTPUT,
					  @nCaseId,
					  @nBillToNo,
					  @sDebtorNameType

/*		If @pbDebug = 1
		Begin
			print 'Debtor Details'
			print @sSQLString
		End
*/

	End
	Else If @pnForDebtor is not null
	Begin
		Set @nBillToNo=@pnForDebtor
		Set @bSeparateDebtorFlag=0

		Set @sSQLString="
		SELECT	@nDebtorPercentage=100,
			@nUseDebtorType	=I.USEDEBTORTYPE, 
			@nDebtorType	=isnull(@pnDebtorType,I.DEBTORTYPE),
			@prsBillCurrency=isnull(@psCurrency,I.CURRENCY), 
			@sIPTaxCode	=I.TAXCODE, 
			@nConsolidation =I.CONSOLIDATION
			FROM IPNAME I
			WHERE I.NAMENO = @nBillToNo"
					
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDebtorPercentage	decimal(5,2)	OUTPUT,
					  @nUseDebtorType	int		OUTPUT, 
					  @nDebtorType		int		OUTPUT,
					  @prsBillCurrency	nvarchar(3)	OUTPUT, 
					  @sIPTaxCode		nvarchar(3)	OUTPUT, 
					  @nConsolidation	decimal(1,0)	OUTPUT,
					  @psCurrency		nvarchar(3),
					  @pnDebtorType		int,
					  @nBillToNo		int',
					  @nDebtorPercentage			OUTPUT,
					  @nUseDebtorType			OUTPUT, 
					  @nDebtorType				OUTPUT,
					  @prsBillCurrency			OUTPUT, 
					  @sIPTaxCode				OUTPUT, 
					  @nConsolidation			OUTPUT,
					  @psCurrency,
					  @pnDebtorType,
					  @nBillToNo

/*		If @pbDebug = 1
		Begin
			print 'More Debtor Details'
			print @sSQLString
		End
*/
	End
	Else If @nCaseId is null
	     and @pnDebtorType is not null
	Begin
		Set @nDebtorType=@pnDebtorType
	End
	Else If @nCaseId is not null
	Begin
		Set @sSQLString="				
		SELECT	@nBillToNo	=C.NAMENO, 
			@nUseDebtorType	=I.USEDEBTORTYPE, 
			@nDebtorType	=I.DEBTORTYPE,
			@prsBillCurrency=I.CURRENCY, 
			@sIPTaxCode	=I.TAXCODE, 
			@nConsolidation =I.CONSOLIDATION
			FROM CASENAME C
			join IPNAME I on (I.NAMENO=C.NAMENO)
			WHERE C.CASEID = @nCaseId
			AND C.EXPIRYDATE is null
			AND C.NAMETYPE = @sDebtorNameType
			AND C.SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
						FROM CASENAME CN2
						WHERE CN2.CASEID = C.CASEID
						AND CN2.NAMETYPE = C.NAMETYPE
						AND CN2.EXPIRYDATE is null)"
					
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nBillToNo		int		OUTPUT,
					  @nUseDebtorType	int		OUTPUT, 
					  @nDebtorType		int		OUTPUT,
					  @prsBillCurrency	nvarchar(3)	OUTPUT, 
					  @sIPTaxCode		nvarchar(3)	OUTPUT, 
					  @nConsolidation	decimal(1,0)	OUTPUT,
					  @nCaseId		int,
					  @sDebtorNameType	nchar(1)',
					  @nBillToNo				OUTPUT,
					  @nUseDebtorType			OUTPUT, 
					  @nDebtorType				OUTPUT,
					  @prsBillCurrency			OUTPUT, 
					  @sIPTaxCode				OUTPUT, 
					  @nConsolidation			OUTPUT,
					  @nCaseId,
					  @sDebtorNameType

		Set @nDebtorPercentage = 100

		-- 12326 If there is no renewal debtor and renewal debtor is optional then use the debtor
                If (@sDebtorNameType = 'Z') AND (@nBillToNo is NULL) AND (@bRenewalNameTypeOptional = 1)
		begin
             		Set @sDebtorNameType = 'D'

			Set @sSQLString="				
			SELECT	@nBillToNo	=C.NAMENO, 
				@nUseDebtorType	=I.USEDEBTORTYPE, 
				@nDebtorType	=I.DEBTORTYPE,
				@prsBillCurrency=I.CURRENCY, 
				@sIPTaxCode	=I.TAXCODE, 
				@nConsolidation =I.CONSOLIDATION
				FROM CASENAME C
				join IPNAME I on (I.NAMENO=C.NAMENO)
				WHERE C.CASEID = @nCaseId
				AND C.EXPIRYDATE is null
				AND C.NAMETYPE = @sDebtorNameType
				AND C.SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
							FROM CASENAME CN2
							WHERE CN2.CASEID = C.CASEID
							AND CN2.NAMETYPE = C.NAMETYPE
							AND CN2.EXPIRYDATE is null)"
					
			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBillToNo		int		OUTPUT,
					  	@nUseDebtorType	int			OUTPUT, 
					  	@nDebtorType		int		OUTPUT,
					  	@prsBillCurrency	nvarchar(3)	OUTPUT, 
					  	@sIPTaxCode		nvarchar(3)	OUTPUT, 
					  	@nConsolidation	decimal(1,0)		OUTPUT,
					  	@nCaseId		int,
					  	@sDebtorNameType	nchar(1)',
					  	@nBillToNo				OUTPUT,
					  	@nUseDebtorType				OUTPUT, 
					  	@nDebtorType				OUTPUT,
					  	@prsBillCurrency			OUTPUT, 
					  	@sIPTaxCode				OUTPUT, 
					  	@nConsolidation				OUTPUT,
					  	@nCaseId,
					  	@sDebtorNameType
 		end

/*		If @pbDebug = 1
		Begin
			print 'More Debtor Details'
			print @sSQLString
		End
*/

	end
	
	-- Get the Agent to use.  
	-- Use Agent passed otherwise
	-- Use Case Name for the specfied Agent Name Type for the current Rate Calculation otherwise
	-- Use Renewal Agent '&' for Renewal Fees otherwise normal Agent 'A'
	If @ErrorCode=0
	Begin
		If @pnAgent is not null
		Begin
			Set @nAgentNo=@pnAgent
		End
		Else Begin
			If @sAgentNameType is not null
			Begin
				--------------------------------
				-- Use the Agent Type specified
				-- for the RATENO if available.
				--------------------------------
				Set @sSQLString="
				SELECT 	@nAgentNo=NAMENO
				FROM CASENAME
				WHERE CASEID = @nCaseId
				AND EXPIRYDATE is null
				AND NAMETYPE =  @sAgentNameType
				AND SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
							FROM CASENAME CN2
							WHERE CN2.CASEID = @nCaseId
							AND CN2.NAMETYPE =  @sAgentNameType
							AND CN2.EXPIRYDATE is null)"
	
				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nAgentNo		int	OUTPUT,
							  @nCaseId		int,
							  @sAgentNameType	NVARCHAR(3)',
							  @nAgentNo			OUTPUT,
							  @nCaseId,
							  @sAgentNameType
			End

			if  @nAgentNo is null
			and @nTypeFlag=1
			and @ErrorCode=0
			Begin
				--------------------------------
				-- If Agent still not known and
				-- Rate Type indicates Renewals,
				-- then use Renewal Agent "&"
				--------------------------------
				Set @sSQLString="
				SELECT 	@nAgentNo=NAMENO
				FROM CASENAME
				WHERE CASEID = @nCaseId
				AND EXPIRYDATE is null
				AND NAMETYPE =  '&' 
				AND SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
							FROM CASENAME CN2
							WHERE CN2.CASEID = @nCaseId
							AND CN2.NAMETYPE =  '&'
							AND CN2.EXPIRYDATE is null)"
	
				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nAgentNo	int	OUTPUT,
							  @nCaseId	int,
							  @nTypeFlag	int',
							  @nAgentNo		OUTPUT,
							  @nCaseId,
							  @nTypeFlag
			End

			if @nAgentNo is null
			and @ErrorCode=0
			Begin
				--------------------------------
				-- If Agent still not known then
				-- use the default Agent name
				-- type "A"
				--------------------------------
				Set @sSQLString="
				SELECT 	@nAgentNo=NAMENO
				FROM CASENAME
				WHERE CASEID = @nCaseId
				AND EXPIRYDATE is null
				AND NAMETYPE = 'A' 
				AND SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
							FROM CASENAME CN2
							WHERE CN2.CASEID = @nCaseId
							AND CN2.NAMETYPE =  'A' 
							AND CN2.EXPIRYDATE is null)"
	
				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nAgentNo	int	OUTPUT,
							  @nCaseId	int',
							  @nAgentNo		OUTPUT,
							  @nCaseId
			End
		End
	End
End

If  @ErrorCode=0
and @nCaseId is null
and @pnInstructor is not null
Begin
	Set @nInstructor=@pnInstructor
End
-- Get other Case related details
Else If  @ErrorCode=0
     and @nCaseId is not null
Begin
	-- Get the first Owner
	Set @sSQLString="
	SELECT 	@nOwner=C.NAMENO
	FROM CASENAME C
	WHERE C.CASEID = @nCaseId
	AND C.NAMETYPE = 'O'
	AND C.EXPIRYDATE is null
	AND C.SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
				FROM CASENAME CN2
				WHERE CN2.CASEID = C.CASEID
				AND CN2.NAMETYPE = 'O'
				AND CN2.EXPIRYDATE is null)"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nOwner	int	OUTPUT,
				  @nCaseId	int',
				  @nOwner		OUTPUT,
				  @nCaseId

/*	If @pbDebug = 1
	Begin
		print 'Owner'
		print @sSQLString
	End
*/

	-- Get the Instructor
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT	@nInstructor=C.NAMENO
		FROM CASENAME C
		WHERE C.CASEID = @nCaseId
		AND C.NAMETYPE = 'I'
		AND C.EXPIRYDATE is null
		AND C.SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
					FROM CASENAME CN2
					WHERE CN2.CASEID = C.CASEID
					AND CN2.NAMETYPE = 'I'
					AND CN2.EXPIRYDATE is null)"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nInstructor	int	OUTPUT,
					  @nCaseId	int',
					  @nInstructor		OUTPUT,
					  @nCaseId
/*		If @pbDebug = 1
		Begin
			print 'Instructor'
			print @sSQLString
		End
*/
	End

	-- SQA9641
	-- Use the Staff member supplied in parameter
	If @ErrorCode=0 and (@pnEmployee is not null)
	Begin
		Set @nEmployee=@pnEmployee
	End
	-- otherwise get the Staff member for the case
	Else If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT	@nEmployee=C.NAMENO
		FROM CASENAME C
		WHERE C.CASEID = @nCaseId
		AND C.NAMETYPE = 'EMP'
		AND C.EXPIRYDATE is null
		AND C.SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
					FROM CASENAME CN2
					WHERE CN2.CASEID = C.CASEID
					AND CN2.NAMETYPE = 'EMP'
					AND CN2.EXPIRYDATE is null)"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nEmployee	int	OUTPUT,
					  @nCaseId	int',
					  @nEmployee		OUTPUT,
					  @nCaseId

/*		If @pbDebug = 1
		Begin
			print 'Employee'
			print @sSQLString
		End
*/
	End
End

-- SQA17867 derive Debtor Type from instructor if site control set
If @ErrorCode = 0
Begin
	
	Set @sSQLString="
	Select @bDebtorTypeBasedInstructor=S.COLBOOLEAN
	from	SITECONTROL S
	where	S.CONTROLID ='DebtorType based on Instructor'"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bDebtorTypeBasedInstructor	bit	output',
				  @bDebtorTypeBasedInstructor		output


	If  (@pnDebtorType is null
		and @bDebtorTypeBasedInstructor = 1
		and @ErrorCode=0)
	Begin
		  
		Set @sSQLString="
		SELECT	@nUseDebtorType	=I.USEDEBTORTYPE, 
		@nDebtorType	=I.DEBTORTYPE
		FROM IPNAME I
		WHERE I.NAMENO = @nInstructor"
					
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nUseDebtorType	int		OUTPUT, 
						@nDebtorType int		OUTPUT,
						@nInstructor int',
						@nUseDebtorType			OUTPUT, 
						@nDebtorType 			OUTPUT,
						@nInstructor
	End
End


-- The Entity No is required by the Calculation to determine any Margin to be added.
-- There is currently no method of determining the Entity if all you know is the Case so we will 
-- default the Entity to the Home Name.

If @ErrorCode=0
Begin	
	Set @sSQLString="
	select	@nEntity=SN.NAMENO
	from 	SITECONTROL S
	join 	SPECIALNAME SN	on (SN.NAMENO    =S.COLINTEGER
				and SN.ENTITYFLAG=1)
	where 	S.CONTROLID='HOMENAMENO'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nEntity	int	OUTPUT',
				  @nEntity		OUTPUT

/*	If @pbDebug = 1
	Begin
		print 'Entity'
		print @sSQLString
	End
*/
End
		
	
-- MF 19/07/2001 If the Action was not passed as a parameter but the CYCLE was passed then instead of calculating
--               the age of the Case just use the CYCLE


If @ErrorCode=0
Begin	
	-------------------------------------------------------
	-- RFC13222
	-- New parameter that indicates the @pnCycle is in fact
	-- the Age Of Case.
	-------------------------------------------------------
	If  @pbCycleIsAgeOfCase=1
	and @pnCycle is not null
	Begin
		Set @nAgeOfCase = @pnCycle
	End
	Else Begin	
		If   @nTypeFlag = 1
		and  @nCaseId is not null
		and (@psAction is not NULL OR (@psAction is NULL and @pnCycle is NULL))
			exec @ErrorCode=pt_GetAgeOfCase 
						@nCaseId, 
						@pnCycle,
						@bCalledFromCentura, 
						@nAgeOfCase output
		Else
			Set @nAgeOfCase = @pnCycle
	End
End


If @ErrorCode=0
Begin
	-- If Debtor Type is only to be used for Registered Cases and the
	-- Case is not registered then clear out the debtor type
	If (@nUseDebtorType = 2003) AND (@nRegisteredFlag != 1)
		Set @nDebtorType = null

	-- If the Debtor Type is only to be used before a Case is registered
	-- and the Case is already Registered then clear out the debtor type
	Else If (@nUseDebtorType = 2002) AND (@nRegisteredFlag = 1)
		Set @nDebtorType = null

/*	If @pbDebug = 1
		print 'Run pt_DoCalculation'
*/

	exec @ErrorCode=pt_DoCalculation
				@prnFeeCriteriaNo, 
				@nAgentNo, 
				@nBillToNo,
				@nDebtorType, 
				@nOwner, 
				@nInstructor,
				@nEmployee,
				@nEntity,
				@nAgeOfCase, 
				@pdtLetterDate,
				@pnProductCode,  
				@sIPTaxCode,
				@sCaseTaxCode,
				@pnEnteredQuantity,
				@pnEnteredAmount, 
				@nCaseId, 
				@sPropertyType, 
				@psAction, 
				@nNoInSeries, 
				@nNoOfClasses, 
				@pnCycle, 
				@pnEventNo, 
				@pnARQuantity, 
				@pnARAmount, 
				@nDebtorPercentage,
				@prsDisbCurrency	output, 
				@prnDisbExchRate 	output, 
				@prsServCurrency 	output, 
				@prnServExchRate 	output, 
				@prsBillCurrency 	output, 
				@prnBillExchRate 	output, 
				@prsDisbTaxCode 	output, 
				@prsServTaxCode 	output, 
				@prnDisbNarrative 	output, 	
				@prnServNarrative 	output, 
				@prsDisbWIPCode 	output, 
				@prsServWIPCode 	output, 
				@prnDisbAmount 		output, 
				@prnDisbHomeAmount 	output, 
				@prnDisbBillAmount 	output, 
				@prnServAmount 		output, 
				@prnServHomeAmount 	output, 
				@prnServBillAmount 	output, 
				@prnTotHomeDiscount 	output, 
				@prnTotBillDiscount 	output, 
				@prnDisbTaxAmt 		output, 
				@prnDisbTaxHomeAmt 	output, 
				@prnDisbTaxBillAmt 	output, 
				@prnServTaxAmt 		output, 
				@prnServTaxHomeAmt 	output, 
				@prnServTaxBillAmt 	output,

				-- MF 27/02/2002 Add new output parameters to return the new components of the calculation

				@prnDisbDiscOriginal	output,
				@prnDisbHomeDiscount 	output,
				@prnDisbBillDiscount 	output, 
				@prnServDiscOriginal	output,
				@prnServHomeDiscount 	output,
				@prnServBillDiscount 	output,
				@prnDisbCostHome	output,
				@prnDisbCostOriginal	output, 
	
				-- MF 02/11/2000 16 new output parameters added to DOCALCULATION for use by the new
				--		 FEESCALCEXTENDED procedure
				@prnParameterSource  	output, 
				@prnDisbMaxUnits  	output, 
				@prnDisbBaseUnits  	output,
				@prbDisbMinFeeFlag  	output, 
				@prnServMaxUnits  	output, 
				@prnServBaseUnits  	output,
				@prbServMinFeeFlag  	output, 
				@prnDisbUnitSize  	output, 
				@prnServUnitSize  	output,
				@prdDisbBaseFee 	output, 
				@prdDisbAddPercentage	output, 
				@prdDisbVariableFee	output,
				@prdServBaseFee		output, 
				@prdServAddPercentage	output, 
				@prdServVariableFee	output,
				@prdServDisbPercent	output,
				@prsFeeType		output,
				-- SQA12379 Add new output parameters required by Charge Generation
				@prnDisbBasicAmount		output,
				@prnDisbExtendedAmount 		output,
				@prnDisbCostCalculation1	output,
				@prnDisbCostCalculation2	output,
				@prnServBasicAmount		output,
				@prnServExtendedAmount 		output,
				@prnServCostCalculation1	output,
				@prnServCostCalculation2	output,
				@prnVarBasicAmount		output,
				@prnVarExtendedAmount 		output,
				@prnVariableFeeAmt		output,
				@prnVarHomeFeeAmt		output,
				@prnVarBillFeeAmt		output,
				@prnVarTaxAmt			output,
				@prnVarTaxHomeAmt		output,
				@prnVarTaxBillAmt		output,
				@prsVarWIPCode			output,
				@prsVarTaxCode 			output,
				@prnDisbMargin			output,
				@prnDisbHomeMargin		output,
				@prnDisbBillMargin		output,
				@prnServMargin			output,
				@prnServHomeMargin		output,
				@prnServBillMargin		output,
				@prnServCostOriginal		output,
				@prnServCostHome		output,
				@prnFeeUniqueId			output,
				@pbIsChargeGeneration,		-- SQA12379 New INPUT parameter
				@pdtTransactionDate,		-- SQA11702 New INPUT parameter
				@pdtFromEventDate,		-- SQA15276 New INPUT parameter
				@psCaseType,			-- SQA12361 User entered CaseType
				@psCountryCode,			-- SQA12361 User entered Country
				@psCaseCategory,		-- SQA12361 User entered Category
				@psSubType,			-- SQA12361 User entered Sub Type
				@pnExchScheduleId,		-- SQA12361 User entered ExchScheduleId
				@pdtFromDateDisb,		-- SQA12361 Simulated From date for disbursments
				@pdtFromDateServ,		-- SQA12361 Simulated From date for service charge
				@pdtUntilDate,			-- SQA12361 Simulated Until date
				@pdtBillDate,
				-- Return quantity values used in calculations
				@pnDisbQuantity 		output,
				@psDisbPeriodType		output,
				@pnDisbPeriodCount		output,
				@pnServQuantity 		output,
				@psServPeriodType		output,
				@pnServPeriodCount		output,
				-- Return pre discount and marging adjusted value
				@pnDisbSourceAmt		output,
				@pnServSourceAmt		output,
				-- Additional user entered parameters for simulated Case
				@pnEntitySize, 			-- SQA15384 User entered Entity Size
				@psCurrency, 			-- SQA15384 User entered Currency
				@pbAgentItem,
				@pbUseTodaysExchangeRate,
				-- SQA14649 Additional parameters for Multi-Tier Tax 
				@prsDisbStateTaxCode 		output, 
				@prsServStateTaxCode 		output, 
				@prsVarStateTaxCode 		output,
				@prnDisbStateTaxAmt 		output, 
				@prnDisbStateTaxHomeAmt 	output, 
				@prnDisbStateTaxBillAmt 	output, 
				@prnServStateTaxAmt 		output, 
				@prnServStateTaxHomeAmt 	output,
				@prnServStateTaxBillAmt 	output,
				@prnVarStateTaxAmt		output,
				@prnVarStateTaxHomeAmt		output,
				@prnVarStateTaxBillAmt		output,
				-- SQA16376
				@prnParameterSource2 		output,
				@prnDisbMarginNo		output,
				@prnServMarginNo		output,
				-- RFC6478
				@prsFeeType2			output,
				--RFC7269
				@pnDisbDiscountForMargin	output,				
				@pnDisbHomeDiscountForMargin	output,
				@pnDisbBillDiscountForMargin	output,
				@pnServDiscountForMargin	output,
				@pnServHomeDiscountForMargin	output,
				@pnServBillDiscountForMargin	output,
                                null,
                                -- RFC56172
                                @pnDisbPreMarginDiscount        output,
                                @pnDisbHomePreMarginDiscount    output,
                                @pnDisbBillPreMarginDiscount    output,
                                @pnServPreMarginDiscount        output,
                                @pnServHomePreMarginDiscount    output,
                                @pnServBillPreMarginDiscount    output

/*
		If @pbDebug = 1
			print 'pt_DoCalculation Done'
*/


End
Return (@ErrorCode)
go

grant execute on dbo.FEESCALC to public
go
