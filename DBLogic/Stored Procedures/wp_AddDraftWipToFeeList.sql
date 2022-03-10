-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_AddDraftWipToFeeList
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_AddDraftWipToFeeList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_AddDraftWipToFeeList.'
	Drop procedure [dbo].[wp_AddDraftWipToFeeList]
End
Print '**** Creating Stored Procedure dbo.wp_AddDraftWipToFeeList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_AddDraftWipToFeeList
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture			nvarchar(10) 	=null, 	
	@pnItemEntityNo		int,
	@pnItemTransNo		int,
	@pdtItemDate		datetime		= NULL
)
as
-- PROCEDURE:	wp_AddDraftWipToFeeList
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure inserts data into FeeList for draft wip items

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Dec 2016	MS	R47798	1	Procedure created
-- 26 Oct 2017  MS      R72501  2       Used Premargin amount for total fee
-- 30 May 2018  AK	R74222		3	Added logic to prevent looping if an error occur

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(max)
Declare @nCounter			int
Declare @nTotalRows			int

Declare @nRateNo			int
Declare	@nEnteredQuantity	int
Declare @nCaseKey			int
Declare @sWipCode			nvarchar(6)
Declare @sFeeType			nvarchar(6)
Declare @nBaseFeeAmount		decimal(11,2)
Declare	@nAdditionalFee		decimal(11,2)
Declare	@nLocalAmount		decimal(11,2)
Declare @nForeignAmount		decimal(11,2)
Declare @sCurrency			nvarchar(3)
Declare @nQuantityInCalc	int
Declare @sTaxCode			nvarchar(3)
Declare @nTaxAmount			decimal(11,2)
Declare @dtWhenRequested	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @nCounter = 1
Set @dtWhenRequested = getdate()

create table #wipTable (
						 ROWKEY int identity(1,1) not null,
						 CASEID int not null,
						 RATENO int NOT NULL,
					     WIPCODE nvarchar(6) null,
						 FOREIGNCURRENCY nvarchar(3) null,
						 FOREIGNVALUE decimal(11, 2) null,
						 LOCALVALUE decimal(11, 2) null,
						 FEECRITERIANO int null,
						 FEEUNIQUEID smallint null,
						 ENTEREDQUANTITY int null,
                                                 PREMARGINAMOUNT decimal(11,2)) 

create table #feesCalc (  
						DisbWIPCode nvarchar(6) null,
						ServWIPCode nvarchar(6) null, 
						DisbCurrency varchar(3) null, 
						ServCurrency  varchar(3) null, 
						DisbAmount decimal(11,2) null,
						DisbHomeAmount  decimal(11,2) null,
						ServAmount  decimal(11,2) null,
						ServHomeAmount  decimal(11,2) null,
						DisbTaxCode		nvarchar(6) null,
						ServTaxCode		nvarchar(6) null,
						DisbTaxAmount  decimal(11,2) null, 
						DisbTaxHomeAmount decimal(11,2) null,
						ServTaxAmount decimal(11,2) null, 
						ServTaxHomeAmount decimal(11,2) null, 	
						DisbBasicAmount decimal(11,2) null,
						DisbExtendedAmount decimal(11,2) null,
						ServBasicAmount decimal(11,2) null,
						ServExtendedAmount decimal(11,2) null,
						FeeCriteriaNo int null,
						FeeUniqueId int null,
						FeeType nvarchar(6) null,
						FeeType2 nvarchar(6) null,
						ServSourceType nchar(1) null,
						DisbSourceType nchar(1) null,
						CaseKey int null
						)

If @nErrorCode = 0
Begin

		Set @sSQLString = "
			INSERT INTO #wipTable(CASEID, RATENO, WIPCODE, FOREIGNCURRENCY, FOREIGNVALUE, LOCALVALUE,
				FEECRITERIANO, FEEUNIQUEID, ENTEREDQUANTITY, PREMARGINAMOUNT)
			SELECT  WIP.CASEID, WIP.RATENO, WIP.WIPCODE, WIP.FOREIGNCURRENCY, WIP.FOREIGNVALUE, WIP.LOCALVALUE,
				WIP.FEECRITERIANO, WIP.FEEUNIQUEID, WIP.ENTEREDQUANTITY, WIP.PREMARGINAMOUNT
			FROM WORKINPROGRESS WIP
			join BILLEDITEM BI on (BI.WIPENTITYNO = WIP.ENTITYNO
								and BI.WIPTRANSNO = WIP.TRANSNO
								and BI.WIPSEQNO = WIP.WIPSEQNO)
			join WORKHISTORY WH on (WH.ENTITYNO = WIP.ENTITYNO
								and WH.TRANSNO = WIP.TRANSNO
								and WH.WIPSEQNO = WIP.WIPSEQNO
								and WH.ITEMIMPACT = 1)
			Where BI.ITEMENTITYNO = @pnItemEntityNo
			and BI.ITEMTRANSNO = @pnItemTransNo
			and WIP.STATUS = 0
			and WIP.ADDTOFEELIST = 1
			"	
		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

If @nErrorCode = 0
Begin
	Select @nTotalRows = count(*) from #wipTable

	While @nCounter <= @nTotalRows and @nErrorCode = 0
	Begin
		
		Set @sSQLString = "Select @nCaseKey = CASEID, @nRateNo = RATENO, @sWipCode = WIPCODE, @nEnteredQuantity = ENTEREDQUANTITY
						from #wipTable where ROWKEY = @nCounter"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseKey	int	output,
					  @nRateNo	int	output,
					  @sWipCode	nvarchar(6)	output,
					  @nEnteredQuantity	int output,
					  @nCounter	int',
					  @nCaseKey = @nCaseKey output,
					  @nRateNo	= @nRateNo	output,
					  @sWipCode	= @sWipCode	output,
					  @nEnteredQuantity = @nEnteredQuantity output,
					  @nCounter	= @nCounter 

		If @nErrorCode = 0
		Begin
				
			Set @sSQLString = "Insert into #feesCalc (DisbWIPCode, ServWIPCode, DisbCurrency, ServCurrency, DisbAmount,
							DisbHomeAmount, ServAmount, ServHomeAmount, DisbTaxCode, ServTaxCode, DisbTaxAmount, DisbTaxHomeAmount,
							ServTaxAmount, ServTaxHomeAmount, DisbBasicAmount, DisbExtendedAmount,
							ServBasicAmount, ServExtendedAmount, FeeCriteriaNo, FeeUniqueId, FeeType, FeeType2,
							ServSourceType, DisbSourceType, CaseKey)
				exec dbo.wp_DOFEESCALC @pnUserIdentityId = @pnUserIdentityId,
								@psCulture = @psCulture,
								@psIRN = null,
								@pnRateNo = @nRateNo,
								@psAction = NULL,	
								@pnCheckListType = NULL, 
								@pnCycle = NULL, 
								@pnEventNo = NULL, 
								@pdtLetterDate = NULL, 
								@pnProductCode= NULL,
								@pnEnteredQuantity = @nEnteredQuantity, 
								@pnEnteredAmount= NULL, 
								@pnARQuantity= NULL, 
								@pnARAmount= NULL,
								@pnDebtor= NULL,
								@pbIsChargeGeneration= 1,
								@pdtTransactionDate = @pdtItemDate,
								@pdtBillDate = 	@pdtItemDate,
								@pbAgentItem= 0,
								@pbIsQtyAmtChange = 0,
								@pbCalledFromCentura = 0,
								@pnEmployee	= NULL,
								@pnCaseKey = @nCaseKey,
								@pbCalledFromBilling = 1"


				exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @psCulture		nvarchar(6),
					  @nCaseKey			int	output,
					  @nRateNo			int,
					  @nEnteredQuantity	int,
					  @pdtItemDate		datetime',
					  @pnUserIdentityId = @pnUserIdentityId,
					  @psCulture		= @psCulture,
					  @nCaseKey			= @nCaseKey,
					  @nRateNo			= @nRateNo,
					  @nEnteredQuantity = @nEnteredQuantity,
					  @pdtItemDate		= @pdtItemDate 
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Select @sFeeType = CASE WHEN f.ServWIPCode = w.WIPCODE THEN f.FeeType2 else f.FeeType end,
				   @nBaseFeeAmount = CASE WHEN f.ServWIPCode = w.WIPCODE THEN f.ServBasicAmount else f.DisbBasicAmount end,
				   @nAdditionalFee = CASE WHEN f.ServWIPCode = w.WIPCODE THEN f.ServExtendedAmount else f.DisbExtendedAmount end,
				   @nLocalAmount = CASE WHEN @sCurrency is null THEN ISNULL(w.PREMARGINAMOUNT, w.LOCALVALUE) ELSE NULL END,
				   @nForeignAmount = CASE WHEN @sCurrency is not null THEN ISNULL(w.PREMARGINAMOUNT, w.FOREIGNVALUE) ELSE NULL END,
				   @sCurrency = w.FOREIGNCURRENCY,
				   @sTaxCode = CASE WHEN f.ServWIPCode = w.WIPCODE THEN f.ServTaxCode else f.DisbTaxCode end,
				   @nTaxAmount = CASE WHEN f.ServWIPCode = w.WIPCODE THEN f.ServTaxAmount else f.DisbTaxAmount end
			FROM #feesCalc f join #wipTable w on (f.CaseKey = w.CASEID)
			where w.ROWKEY = @nCounter"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@sFeeType	nvarchar(6)	output,
					  @nBaseFeeAmount	decimal(11,2) output,
					  @nAdditionalFee	decimal(11,2) output,
					  @nLocalAmount	decimal(11,2) output,
					  @nForeignAmount	decimal(11,2) output,
					  @sCurrency	nvarchar(3) output,
					  @sTaxCode	    nvarchar(6) output,
					  @nTaxAmount	decimal(11,2)	output,
					  @nCounter	int',
					  @sFeeType = @sFeeType output,
					  @nBaseFeeAmount	= @nBaseFeeAmount	output,
					  @nAdditionalFee	= @nAdditionalFee	output,
					  @nLocalAmount = @nLocalAmount output,
					  @nForeignAmount = @nForeignAmount output,
					  @sCurrency = @sCurrency output,
					  @sTaxCode = @sTaxCode output,
					  @nTaxAmount = @nTaxAmount output,
					  @nCounter	= @nCounter 
		End

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.wp_AddToFeeList
							@pnUserIdentityId = @pnUserIdentityId,
							@psCulture = @psCulture,
							@psFeeType = @sFeeType,
							@pnCaseId = @nCaseKey,
							@pnBaseFeeAmount = @nBaseFeeAmount,
							@pnAdditionalFee = @nAdditionalFee,
							@pnLocalAmount = @nLocalAmount,
							@pnForeignAmount = @nForeignAmount,
							@psCurrency = @sCurrency,
							@pnQuantityInCalc = @nEnteredQuantity,
							@psTaxCode = @sTaxCode,
							@pnTaxAmount = @nTaxAmount,
							@pnEntityKey = @pnItemEntityNo,
							@pdtTransDate = @pdtItemDate,
							@pdtWhenRequested = @dtWhenRequested
		End

		delete from #feesCalc

		Set @nCounter = @nCounter + 1
	End

	delete from #wipTable
End

Return @nErrorCode
GO

Grant execute on dbo.wp_AddDraftWipToFeeList to public
GO
