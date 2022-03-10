-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetEstimateAndSave
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetEstimateAndSave]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetEstimateAndSave.'
	drop procedure dbo.pt_GetEstimateAndSave
end
print '**** Creating procedure dbo.pt_GetEstimateAndSave...'
print ''
go

create proc dbo.pt_GetEstimateAndSave 
		@psEntryPoint		varchar(254)	=NULL, 
		@psWhenRequested	varchar(254)	=NULL,
		@psSqlUser		nvarchar(40)	=NULL, 
		@psCaseId		varchar(254)	=NULL,
		@psRateNo		varchar(12),
		@psEnteredQuantity	varchar(254)	=NULL, 
		@psEnteredAmount	varchar(254)	=NULL,
		@psAlwayRecalculate	char(1)		=0,	-- this flag forces a new calculation to be performed when set to '1'
		@psSaveTheEstimate	char(1)		=0,	-- this flag causes the estimate to be saved when set to '1'
		@psAction		varchar(2)	=NULL,
		@psQuestionNo		varchar(12)	=NULL,
		@psCycle		varchar(5)	=NULL,
		@psEventNo		varchar(12)	=NULL,
		@psLetterDate		datetime	=NULL,
		@psDebtor		varchar(254)	=NULL,   -- this parameter is only supplied when the 'WIP Split Multi Debtor' site control is ON.
		@pnUserIdentityId	int		=NULL
as

-- PROCEDURE :	pt_GetEstimateAndSave
-- VERSION :	22
-- DESCRIPTION:	Calculates or gets a previously saved estimate for a specific fee with the option of saving the estimate
-- COPYRIGHT	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12/02/2002	MF			Procedure created
-- 13/05/2002	VL	SQA7750		Changed the size of the @sIRN parameter from varchar(20) to varchar(30).
-- 19/08/2002	CR	SQA7629		Added new @bCalledFromCentura variable for use wht the call to pt_GetAgeOfCase.
-- 31/01/2003	MF	8255		When trying to get the estimate previously saved do not match on the entered 
--					quantity and value as normally this would not be known when trying to get a 
--					previous estimate.
-- 20/03/2003	JB	8116	
-- 12/05/2004	DW	9917		Modified procedure to allow it to be called for a specific debtor when the 
--                              	Charge Gen by All Debtors site control is ON.
-- 24 Feb 2005	MF	11066	7	The parameter @psQuestionNo was not being used.
-- 28 Feb 2005	DW	11071		adjusted to pass new parameter (@nProductCode) to FEESCALC
-- 03 Jun 2005	MF	11447	8	Home tax amounts for disbursements and service were incorrectly being saved.
-- 16 Nov 2005	vql	9704	4	When updating ACTIVITYHISTORY table insert @pnUserIdentityId. Create @pnUserIdentityId also.
-- 06 Nov 2006	MF	13647	9	The ACTIVITYHISTORY data that is created to hold the Estimate should also
--					keep the EventNo that originally raised the Estimate request.
-- 01 Dec 2006	MF	12361	10	Name the parameters in the call to FEESCALC to avoid problems when new
--					parameters are added to the procedure.
-- 28 Sep 2007	CR	14901	11	Changed Exchange Rate field sizes to (8,4)
-- 07 May 2008	Dw	11846	12	Fixed a bug that affected the values set into @prnDisbTaxAmt, @prnDisbTaxHomeAmt
--					@prnServTaxAmt, @prnServTaxHomeAmt. Note that A.DISBTAXAMOUNT is meant to hold a 
--					local value, however @prnDisbTaxAmt is meant to hold the value in the disbursement
--					currency. 
-- 18 Jul 2008	DL	16584	13	Save whenoccurred to ACTIVITYHISTORY.
-- 03 Oct 2008	Dw	16917	14	Added logic to return and select margin identifiers for fee1 and fee2.
-- 15 Dec 2008	MF	17136	15	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 19 Feb 2009	Dw	13940	16	Pass date to pt_GetTaxRate
-- 07 Jul 2010	MF	18880	17	Subtract discount before calculating tax
-- 15 Jul 2010	MF	18888	18	Return the AgeOfCase and Cycle if these values were used in the determination of the fee.
-- 29 Jul 2010	MF	18888	19	Revisited to Set the Action if it has not been provided as a parameter. This is required to calculate AgeOfCase.
-- 21 Oct 2011	DL	19708	20	Change @psSqlUser from varchar(20) to nvarchar(40) to match ACTIVITYREQUEST.SQLUSER
-- 20 Oct 2015  MS      R53933  21      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 20 Feb 2017  Dw      R70536  22      Replaced reference to obsolete site control 'Ch Gen by All Debtors' with 'WIP Split Multi Debtor'.

set nocount on

declare	@sIRN 			varchar(30), 
	@nCycle 		smallint,
	@nCheckListType		smallint,
	@nQuestionNo		smallint,
	@sAction		varchar(2),
	@nEventNo		int,
	@nARQuantity		smallint,
	@nARAmount		decimal(11,2),
	@dtLetterDate		datetime,
	@prsDisbCurrency	varchar(3),
	@prnDisbExchRate	decimal(11,4),
	@prsServCurrency	varchar(3),
	@prnServExchRate	decimal(11,4),
	@prsBillCurrency	varchar(3),
	@prnBillExchRate	decimal(11,4),
	@prsDisbTaxCode		varchar(3),
	@prsServTaxCode		varchar(3),
	@prnDisbNarrative	int,
	@prnServNarrative	int,
	@prsDisbWIPCode		varchar(6),
	@prsServWIPCode		varchar(6),
	@prnDisbOrigAmount	decimal(11,2),
	@prnDisbHomeAmount	decimal(11,2),
	@prnDisbBillAmount	decimal(11,2),
	@prnServOrigAmount	decimal(11,2),
	@prnServHomeAmount	decimal(11,2),
	@prnServBillAmount	decimal(11,2),
	@prnTotHomeDiscount	decimal(11,2),
	@prnTotBillDiscount	decimal(11,2),
	@prnDisbTaxAmt		decimal(11,2),
	@prnDisbTaxHomeAmt	decimal(11,2),
	@prnDisbTaxBillAmt	decimal(11,2),
	@prnServTaxAmt		decimal(11,2),
	@prnServTaxHomeAmt	decimal(11,2),
	@prnServTaxBillAmt	decimal(11,2),

	-- MF 27/02/2002 Add new output parameters to return the new components of the calculation
	@prnDisbDiscOriginal	decimal(11,2),
	@prnDisbHomeDiscount 	decimal(11,2),
	@prnDisbBillDiscount 	decimal(11,2), 
	@prnServDiscOriginal	decimal(11,2),
	@prnServHomeDiscount 	decimal(11,2),
	@prnServBillDiscount 	decimal(11,2),
	@prnDisbCostHome	decimal(11,2),
	@prnDisbCostOriginal	decimal(11,2),
	@prnDisbMarginNo	int,
	@prnServMarginNo	int,

	@pnCaseId		int,
	@pnRateNo		int,
	@pnEnteredQuantity	int,
	@pnEnteredAmount	decimal(11,2),
	
	@nAgeOfCase		tinyint,
	@nRowCount		tinyint,
	@ErrorCode		int,
	@TranCountStart		int,
	@bCalledFromCentura	tinyint,			/* CR 19/08/2002	New variable added 	*/
	@dtCalculationDate      datetime	

-- Added in 8116
Declare @nTaxRate 		decimal(11,4)	-- Temp variable to hold tax rate for calculations
Declare @nDebtorNo		int
Declare @sTempTaxCode		nvarchar(3)

-- End 8116 variables
-- Added in 9917

Declare @pnDebtor		int
Declare @bWIPSplitMultiDebtor tinyint
Declare @bSeparateDebtorFlag 	tinyint

Declare @nProductCode	 	int			/* Dw 28/02/2005	New variable added      */


-- End 9917 variables

select @nRowCount		= 0
select @ErrorCode		= 0
select @pnCaseId		= convert(int, @psCaseId)
select @pnRateNo		= convert(int, @psRateNo)
select @pnDebtor		= convert(int, @psDebtor)
select @sIRN			= @psEntryPoint
Select @bCalledFromCentura 	= 0
Select @bWIPSplitMultiDebtor 	= 0
Select @bSeparateDebtorFlag 	= null
Select @nProductCode 		= null
Select @dtCalculationDate 	= convert(datetime, substring(@psWhenRequested,7,23),121) 

-- 9917 Check if separate debtor functionality is required
	
If @ErrorCode = 0
Begin
	Select @bWIPSplitMultiDebtor=S.COLBOOLEAN
	from	SITECONTROL S
	where	S.CONTROLID='WIP Split Multi Debtor'
	
	Set @ErrorCode=@@Error


If (@pnDebtor is not null) and ((@bWIPSplitMultiDebtor = 0) or (@bWIPSplitMultiDebtor is null))
        Set @ErrorCode=9917
End

If  @psWhenRequested is not NULL
and @ErrorCode = 0
begin
	SELECT	@nCycle      =A.CYCLE, 
		@sAction     =A.ACTION, 
		@nQuestionNo =A.QUESTIONNO, 
		@nEventNo    =A.EVENTNO,
		@nARQuantity =A.ENTEREDQUANTITY, 
		@nARAmount   =A.ENTEREDAMOUNT, 
		@dtLetterDate=A.LETTERDATE,
		@nProductCode=A.PRODUCTCODE,
		@sIRN        =C.IRN
	FROM ACTIVITYREQUEST  A
	join CASES            C on (C.CASEID=A.CASEID)
	WHERE A.CASEID        = @pnCaseId
	AND   A.WHENREQUESTED = CONVERT(DATETIME, SUBSTRING(@psWhenRequested,7,23),121) 
	AND   A.SQLUSER       = @psSqlUser 

	Select @ErrorCode=@@Error
end
else If @ErrorCode=0
begin
	set @pnEnteredQuantity = convert(int,           @psEnteredQuantity) 
	set @pnEnteredAmount   = convert(decimal(11,2), @psEnteredAmount)
	set @nCycle            = convert(smallint,      @psCycle)
	set @nQuestionNo       = convert(int,           @psQuestionNo)
	set @nEventNo          = convert(int,		@psEventNo)
	

	Select @pnCaseId=C.CASEID
	from CASES C
	where C.IRN=@sIRN

	Select @ErrorCode=@@Error
end

-- Get the CheckListType from the QuestionNo passed.  This is required to determine
-- if the Age of Case is needed for the calculation.

if  @nQuestionNo is not null
and @ErrorCode = 0
begin
	exec @ErrorCode=pt_GetChecklistType 
				@pnCaseId, 
				@nQuestionNo, 
				@nCheckListType output
end

	

-- Determine the age of the Case where either the Rate, Action or Checklist is flagged as being for renewals
-- This is required for getting the appropriate estimate and for saving the estimate.

If @psAction is null
	Set @psAction=@sAction

If @ErrorCode=0
Begin	
	If   exists (Select * From RATES      Where RATENO=@pnRateNo               and RATETYPE=1601)
	or   exists (Select * From ACTIONS    Where ACTION=@psAction               and ACTIONTYPEFLAG=1)
	or   exists (Select * From CHECKLISTS Where CHECKLISTTYPE= @nCheckListType and CHECKLISTTYPEFLAG=1)
		If (@psAction is not NULL OR (@psAction is NULL and @nCycle is NULL))
			exec @ErrorCode=pt_GetAgeOfCase 
						@pnCaseId, 
						@nCycle, 
						@bCalledFromCentura,
						@nAgeOfCase output
		Else
			Select @nAgeOfCase = @nCycle
End

-- If the flag to always recalculate is NOT on then attempt to get the values from 
-- a previously saved estimate

if  isnull(@psAlwayRecalculate,'0')<>'1' 
and @ErrorCode=0
begin
	-- Now try and get the estimate from a previously saved ACTIVITYHISTORY row

	select	
	@prsDisbCurrency	=A.DISBCURRENCY,
 	@prnDisbExchRate	=A.DISBEXCHANGERATE,
	@prsServCurrency	=A.SERVICECURRENCY,
 	@prnServExchRate	=A.SERVEXCHANGERATE,
	@prsBillCurrency	=A.BILLCURRENCY,
	@prnBillExchRate	=A.BILLEXCHANGERATE,
	@prsDisbTaxCode		=A.DISBTAXCODE,
	@prsServTaxCode		=A.SERVICETAXCODE,
	@prnDisbNarrative	=A.DISBNARRATIVE,
	@prnServNarrative	=A.SERVICENARRATIVE,
	@prsDisbWIPCode		=A.DISBWIPCODE,
	@prsServWIPCode		=A.SERVICEWIPCODE,
	@prnDisbOrigAmount	=A.DISBORIGINALAMOUNT,
	@prnDisbHomeAmount	=A.DISBAMOUNT,
	@prnDisbBillAmount	=A.DISBBILLAMOUNT,
	@prnServOrigAmount	=A.SERVORIGINALAMOUNT,
	@prnServHomeAmount	=A.SERVICEAMOUNT,
	@prnServBillAmount	=A.SERVBILLAMOUNT,
	@prnTotHomeDiscount	=A.TOTALDISCOUNT,
	@prnTotBillDiscount	=A.DISCBILLAMOUNT,
	@prnDisbTaxAmt		=A.DISBTAXAMOUNT * A.DISBEXCHANGERATE,
	@prnDisbTaxHomeAmt	=A.DISBTAXAMOUNT,
	-- @prnDisbTaxBillAmt	=A.DISBBILLAMOUNT * isnull(TD.RATE,0) / 100,
	@prnServTaxAmt		=A.SERVICETAXAMOUNT * A.SERVEXCHANGERATE,
	@prnServTaxHomeAmt	=A.SERVICETAXAMOUNT,
	-- @prnServTaxBillAmt	=A.SERVBILLAMOUNT * isnull(TS.RATE,0) / 100,
	@nARQuantity		=A.ENTEREDQUANTITY,
	@nARAmount		=A.ENTEREDAMOUNT,
	@prnDisbDiscOriginal	=A.DISBDISCORIGINAL,
	@prnDisbHomeDiscount 	=A.DISBDISCOUNT,
	@prnDisbBillDiscount 	=A.DISBBILLDISCOUNT,
	@prnServDiscOriginal	=A.SERVDISCORIGINAL,
	@prnServHomeDiscount 	=A.SERVDISCOUNT,
	@prnServBillDiscount 	=A.SERVBILLDISCOUNT,
	@prnDisbCostHome	=A.DISBCOSTLOCAL,
	@prnDisbCostOriginal	=A.DISBCOSTORIGINAL,
	@prnDisbMarginNo	=A.DISBMARGINNO,
	@prnServMarginNo	=A.SERVMARGINNO

	from	ACTIVITYHISTORY A
	-- left join TAXRATES TD	on (TD.TAXCODE=A.DISBTAXCODE)		-- get the current tax rate for the disbursement
	-- left join TAXRATES TS	on (TS.TAXCODE=A.SERVICETAXCODE)	-- get the current tax rate for the service chare
	where	A.CASEID	=@pnCaseId
	and	A.RATENO	=@pnRateNo
	and	A.ACTIVITYCODE	=3202
	and	A.ESTIMATEFLAG  =1
	and	A.PAYFEECODE	is null 
	and   ((A.SEPARATEDEBTORFLAG is null and @pnDebtor is null)		-- 9917
	    OR (A.DEBTOR 	=@pnDebtor and  A.SEPARATEDEBTORFLAG=1))	-- 9917
	and    (A.CYCLE	        =@nAgeOfCase OR (A.CYCLE is null and @nAgeOfCase is null))
	and    (A.EVENTNO       =@nEventNo   OR  @nEventNo is null)
	and	A.WHENREQUESTED	=(	select max(WHENREQUESTED)
					from	ACTIVITYHISTORY A1
					where	A1.CASEID      =A.CASEID
					and	A1.RATENO      =A.RATENO
					and	A1.ACTIVITYCODE=A.ACTIVITYCODE
					and	A1.ESTIMATEFLAG=1
					and	A1.PAYFEECODE  is null
					and    (A1.SEPARATEDEBTORFLAG=A.SEPARATEDEBTORFLAG or (A1.SEPARATEDEBTORFLAG is null and A.SEPARATEDEBTORFLAG is null))
			                and    (A1.DEBTOR = A.DEBTOR OR (A1.DEBTOR  is null and A.DEBTOR  is null))      -- 9917
					and    (A1.CYCLE=A.CYCLE     OR (A1.CYCLE   is null and A.CYCLE   is null)) 
					and    (A1.EVENTNO=A.EVENTNO OR (A1.EVENTNO is null and A.EVENTNO is null)))

	-- Save the row count to determine if a row was found
	Select @nRowCount=@@Rowcount,
	       @ErrorCode=@@Error

	-- 9917 If the debtor is supplied then use the supplied debtor
	If @pnDebtor is not null
	begin
		Set @nDebtorNo=@pnDebtor
		Set @bSeparateDebtorFlag = 1
	end
	Else
	begin

		-- Get the first debtor for the case
		Select @nDebtorNo = NAMENO
			from CASENAME 
			where CASEID = @pnCaseId
			and NAMETYPE = 'D'
			and SEQUENCE = (Select min(SEQUENCE) from CASENAME 
				where CASEID = @pnCaseId and NAMETYPE = 'D')
	end




        -- 8116 Start
	--	It is now a bit more complicated now to find out the tax rate so I have 
	--	taken it out of the Select Statement and put it into a seperate call


	-- Disbursement
	if @ErrorCode = 0
	begin
		exec @ErrorCode=pt_GetTaxRate 
			@prnTaxRate = @nTaxRate output,
			@psNewTaxCode = @sTempTaxCode output,
			@psTaxCode = @prsDisbTaxCode, 
			@pnCaseId = @pnCaseId,
			@pnDebtorNo = @nDebtorNo,
			@pdtCalculationDate = @dtCalculationDate

		-- The tax code may have changed
		if @sTempTaxCode is not null
			Set @prsDisbTaxCode = @sTempTaxCode

		Set @prnDisbTaxBillAmt = (@prnDisbBillAmount-@prnDisbBillDiscount) * isnull(@nTaxRate,0) / 100	--SQA18880
	end

	if @ErrorCode = 0
	begin
		-- Service Charge
		exec @ErrorCode=pt_GetTaxRate 
			@prnTaxRate = @nTaxRate output,
			@psNewTaxCode = @sTempTaxCode output,
			@psTaxCode = @prsServTaxCode, 
			@pnCaseId = @pnCaseId,
			@pnDebtorNo = @nDebtorNo,
			@pdtCalculationDate = @dtCalculationDate

		-- The tax code may have changed
		if @sTempTaxCode is not null
			Set @prsServTaxCode = @sTempTaxCode

		Set @prnServTaxBillAmt = (@prnServBillAmount-@prnServBillDiscount) * isnull(@nTaxRate,0) / 100	--SQA18880
	end
	--End of 8116 addition

end

-- 9917 delete any orphaned rows

if (@psAlwayRecalculate = '1' and @pnDebtor is not null)
and @ErrorCode=0
begin
	delete from	ACTIVITYHISTORY
	where	CASEID	=@pnCaseId
	and	RATENO	=@pnRateNo
	and	ACTIVITYCODE	=3202
	and	ESTIMATEFLAG  =1
	and	PAYFEECODE	is null 
	and     SEPARATEDEBTORFLAG=1
	and    (CYCLE	=@nAgeOfCase OR (CYCLE is null and @nAgeOfCase is null))
	and (DEBTOR = @pnDebtor      
         or (DEBTOR = (select A.DEBTOR
        	from ACTIVITYHISTORY A
		join RATES RT	on (RT.RATENO=A.RATENO)
		join CASENAME CN on (CN.CASEID=A.CASEID)
	    	where CN.EXPIRYDATE is null
		and ((CN.BILLPERCENTAGE=0) OR (CN.BILLPERCENTAGE is null))
		and CN.NAMETYPE=CASE WHEN(RT.RATETYPE=1601) THEN 'Z' ELSE 'D' END ))
         or (DEBTOR NOT IN (select A.DEBTOR
        	from ACTIVITYHISTORY A
		join RATES RT	on (RT.RATENO=A.RATENO)
		join CASENAME CN on (CN.CASEID=A.CASEID) 
	       	where CN.NAMETYPE=CASE WHEN(RT.RATETYPE=1601) THEN 'Z' ELSE 'D' END )))

	Select @ErrorCode=@@Error
end



-- If the RowCount is zero then it means that either the estimate was not looked up
-- or no estimate was found
if  @nRowCount=0
and @ErrorCode=0
and @sIRN is not null
begin
	exec @ErrorCode=FEESCALC
				@psIRN			=@sIRN, 
				@pnRateNo		=@pnRateNo, 
				@psAction		=@sAction,
				@pnCheckListType	=@nCheckListType, 
				@pnCycle		=@nCycle, 
				@pnEventNo		=@nEventNo, 
				@pdtLetterDate		=@dtLetterDate,
				@pnProductCode		=@nProductCode, 
				@pnEnteredQuantity	=@pnEnteredQuantity, 
				@pnEnteredAmount	=@pnEnteredAmount, 
				@pnARQuantity		=@nARQuantity, 
				@pnARAmount		=@nARAmount, 
				@pnDebtor		=@pnDebtor,
				@prsDisbCurrency	=@prsDisbCurrency	output, 
				@prnDisbExchRate	=@prnDisbExchRate	output, 
				@prsServCurrency	=@prsServCurrency	output, 
				@prnServExchRate	=@prnServExchRate	output,
				@prsBillCurrency	=@prsBillCurrency	output, 
				@prnBillExchRate	=@prnBillExchRate	output, 
				@prsDisbTaxCode		=@prsDisbTaxCode	output, 
				@prsServTaxCode		=@prsServTaxCode	output, 
				@prnDisbNarrative	=@prnDisbNarrative	output, 
				@prnServNarrative	=@prnServNarrative	output,
				@prsDisbWIPCode		=@prsDisbWIPCode	output, 
				@prsServWIPCode		=@prsServWIPCode	output,
				@prnDisbAmount		=@prnDisbOrigAmount	output, 
				@prnDisbHomeAmount	=@prnDisbHomeAmount	output, 
				@prnDisbBillAmount	=@prnDisbBillAmount	output, 
				@prnServAmount		=@prnServOrigAmount	output, 
				@prnServHomeAmount	=@prnServHomeAmount	output, 
				@prnServBillAmount	=@prnServBillAmount	output, 
				@prnTotHomeDiscount	=@prnTotHomeDiscount	output, 
				@prnTotBillDiscount	=@prnTotBillDiscount	output,
				@prnDisbTaxAmt		=@prnDisbTaxAmt		output, 
				@prnDisbTaxHomeAmt	=@prnDisbTaxHomeAmt	output, 
				@prnDisbTaxBillAmt	=@prnDisbTaxBillAmt	output, 
				@prnServTaxAmt		=@prnServTaxAmt		output, 
				@prnServTaxHomeAmt	=@prnServTaxHomeAmt	output, 
				@prnServTaxBillAmt	=@prnServTaxBillAmt	output,
				@prnDisbDiscOriginal	=@prnDisbDiscOriginal	output,
				@prnDisbHomeDiscount	=@prnDisbHomeDiscount 	output,
				@prnDisbBillDiscount	=@prnDisbBillDiscount 	output, 
				@prnServDiscOriginal	=@prnServDiscOriginal	output,
				@prnServHomeDiscount	=@prnServHomeDiscount 	output,
				@prnServBillDiscount	=@prnServBillDiscount 	output,
				@prnDisbCostHome	=@prnDisbCostHome	output,
				@prnDisbCostOriginal	=@prnDisbCostOriginal	output,
				@prnDisbMarginNo	=@prnDisbMarginNo	output,
				@prnServMarginNo	=@prnServMarginNo	output
end

-- If the amount calculated (or just extracted) is to be saved as an
-- estimate then insert the details into ACTIVITYHISTORY

If  @psSaveTheEstimate='1'
and @ErrorCode=0
begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

SaveEstimate:
	insert into ACTIVITYHISTORY (	CASEID, WHENREQUESTED, WHENOCCURRED, SQLUSER, PROGRAMID, EVENTNO, CYCLE, HOLDFLAG, ACTIVITYTYPE, ACTIVITYCODE ,PROCESSED, ESTIMATEFLAG, RATENO,
					ENTEREDQUANTITY, ENTEREDAMOUNT, DEBTOR, SEPARATEDEBTORFLAG, PRODUCTCODE, DISBCURRENCY, DISBEXCHANGERATE, SERVICECURRENCY, SERVEXCHANGERATE, BILLCURRENCY, 
					BILLEXCHANGERATE, DISBTAXCODE, SERVICETAXCODE, DISBNARRATIVE, SERVICENARRATIVE, DISBAMOUNT, SERVICEAMOUNT, 
					DISBTAXAMOUNT, SERVICETAXAMOUNT, TOTALDISCOUNT, DISBWIPCODE, SERVICEWIPCODE, DISBORIGINALAMOUNT, SERVORIGINALAMOUNT, 
					DISBBILLAMOUNT, SERVBILLAMOUNT, DISCBILLAMOUNT,
					DISBDISCOUNT, SERVDISCOUNT, DISBBILLDISCOUNT, SERVBILLDISCOUNT, DISBCOSTLOCAL, DISBCOSTORIGINAL, DISBDISCORIGINAL, 
					SERVDISCORIGINAL, DISBMARGINNO, SERVMARGINNO, IDENTITYID  )

	select	
	C.CASEID,
	getdate(),
	getdate(),
	SYSTEM_USER,
	'DocSvr',
	@nEventNo, 
	@nAgeOfCase,
	0,
	32, 3202, 1, 1,
	@pnRateNo,
	@pnEnteredQuantity, 
	@pnEnteredAmount, 
        @pnDebtor,
        @bSeparateDebtorFlag,
	@nProductCode,
	@prsDisbCurrency,
 	@prnDisbExchRate,
	@prsServCurrency,
 	@prnServExchRate,
	@prsBillCurrency,
	@prnBillExchRate,
	@prsDisbTaxCode,
	@prsServTaxCode,
	@prnDisbNarrative,
	@prnServNarrative,
	@prnDisbHomeAmount,
	@prnServHomeAmount,
	@prnDisbTaxHomeAmt, 	--@prnDisbTaxAmt
	@prnServTaxHomeAmt,	--@prnServTaxAmt
	@prnTotHomeDiscount,
	@prsDisbWIPCode,
	@prsServWIPCode,
	@prnDisbOrigAmount, 
	@prnServOrigAmount, 
	@prnDisbBillAmount,
	@prnServBillAmount,
	@prnTotBillDiscount,
	@prnDisbHomeDiscount,
	@prnServHomeDiscount,
	@prnDisbBillDiscount,
	@prnServBillDiscount,
	@prnDisbCostHome,
	@prnDisbCostOriginal,
	@prnDisbDiscOriginal,
	@prnServDiscOriginal,
	@prnDisbMarginNo,
	@prnServMarginNo,
	@pnUserIdentityId
	from	CASES C
	where	C.CASEID=@pnCaseId
	
	Select @ErrorCode=@@Error

	-- Check for duplicate errors
	If @ErrorCode=2601
	   Goto SaveEstimate

	-- Commit or Rollback the transaction

	Else If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

end
-- Return the values either extracted from a previously saved estimate 
-- or just calculated.

select 	@prsDisbCurrency, 	@prnDisbExchRate,
	@prsServCurrency, 	@prnServExchRate,
	@prsBillCurrency,	@prnBillExchRate,
	@prsDisbTaxCode,	@prsServTaxCode,
	@prnDisbNarrative,	@prnServNarrative,
	@prsDisbWIPCode,	@prsServWIPCode,
	@prnDisbOrigAmount,	@prnDisbHomeAmount, @prnDisbBillAmount,
	@prnServOrigAmount,	@prnServHomeAmount, @prnServBillAmount,
	@prnTotHomeDiscount,	@prnTotBillDiscount,
	@prnDisbTaxAmt,		@prnDisbTaxHomeAmt, @prnDisbTaxBillAmt,
	@prnServTaxAmt,		@prnServTaxHomeAmt, @prnServTaxBillAmt,

	@prnDisbDiscOriginal,
	@prnDisbHomeDiscount,
	@prnDisbBillDiscount,
	@prnServDiscOriginal,
	@prnServHomeDiscount,
	@prnServBillDiscount,
	@prnDisbCostHome,
	@prnDisbCostOriginal,
	@prnDisbMarginNo,
	@prnServMarginNo,
	@nAgeOfCase	as AgeOfCase,
	@nCycle		as Cycle

Return @ErrorCode
go

grant execute on dbo.pt_GetEstimateAndSave to public
go
