-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_GetExchangeVariation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_GetExchangeVariation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_GetExchangeVariation.'
	Drop procedure [dbo].[ac_GetExchangeVariation]
End
Print '**** Creating Stored Procedure dbo.ac_GetExchangeVariation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ac_GetExchangeVariation
(

	@pnBankRate		dec(11,4)	= null output,	-- As supplied by the bank
	@pnBuyRate		dec(11,4)	= null output,	-- Used when buying the currency from the bank; e.g. accounts payable
	@pnSellRate		dec(11,4)	= null output,	-- Used when selling the currency from the bank; e.g. accounts receivable
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psCurrencyCode		nvarchar(5)	= null, -- The currency the information is required for
	@pdtTransactionDate	datetime	= null, -- Transaction date used to get the correct exchange rate variation
	@pnCaseID		int		= null, -- CaseID used to obtain the correct exchange rate variation
	@pnNameNo		int		= null, -- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier		bit		= null, -- Determines whether to get exchange rate variation from CREDITOR/IPNAME when NameNo is supplied
	@psCaseType		nchar(1)	= null,	-- SQA12361 User entered CaseType
	@psCountryCode		nvarchar(3)	= null, -- SQA12361 User entered Country
	@psPropertyType		nchar(1)	= null, -- SQA12361 User entered Property Type
	@psCaseCategory		nvarchar(2)	= null, -- SQA12361 User entered Category
	@psSubType		nvarchar(2)	= null, -- SQA12361 User entered Sub Type
	@pnExchScheduleId	int		= null,	-- SQA12361 User entered Exchange Rate Schedule
	@psWIPTypeId		nvarchar(6)	= null	-- WIPType used to obtain exch rate schedule.
)
as
-- PROCEDURE:	ac_GetExchangeVariation
-- VERSION:	11
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Wrapper stored procedure for ac_GetExchangeDetails to be used in Centura classes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Jun 2006	KR	12108	1	Procedure created
-- 27 Jun 2006	KR	12108	2	Added description to the parameters
-- 07 Jul 2006	MF	12361	3	Allow the Exchange Rate Schedule Id to be optionally passed as a parameter
-- 20 Jul 2006	KR	13054	4	Adjusted the formula for Buy Rate to use multiplication.
-- 21 Jul 2006 	KR	13096	5	Get the bank rate from EXCHANGERATEHIST
-- 31 Aug 2006	MF	12361	6	Revisit to correct upper case problem and integration merge issue
-- 01 Sep 2006	MF	12361	7	Revisit
-- 18 Jan 2007	CR	12400	8 	Removed unnecessary @pnDecimalPlaces parameter.
-- 27 Aug 2008	vql	16155	9	Fee calculation logic needs to be changed to handle lack of historical exchange rate data.
-- 04 Sep 2008	KR	16705	9	Added date to the best fit logic
-- 22 Dec 2011	AT	R9160	10	WIP Type used to get exch rate schedule.
-- 18 Dec 2017	AK	R72645	11	Make compatible with case sensitive server with case insensitive database.
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	 	int
declare @sSQLString	 	nvarchar(4000)
declare @nExchScheduleID 	int
declare @nExchVariationID	int
declare @sExchVariationID	nvarchar(11)
declare @nBuyFactor		decimal (11,4)
declare @nSellFactor		decimal (11,4)

-- Initialise variables
Set @nErrorCode = 0

If @pnExchScheduleId is not NULL
Begin
	Set @nExchScheduleID=@pnExchScheduleId
End
Else Begin
	If @pnNameNo is not null AND (@pbIsSupplier = 1) 
	Begin
		Set @sSQLString = "Select @nExchScheduleID = EXCHSCHEDULEID 
				   From CREDITOR
				   Where  NAMENO = @pnNameNo"
	 
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nExchScheduleID	int	OUTPUT,
						@pnNameNo		int',
						@nExchScheduleID =	@nExchScheduleID OUTPUT,
						@pnNameNo	 =	@pnNameNo
	End
	else if @pnNameNo is not null
	Begin
		Set @sSQLString = "Select @nExchScheduleID = EXCHSCHEDULEID 
				   From IPNAME
				   Where  NAMENO = @pnNameNo"
	 
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nExchScheduleID	int	OUTPUT,
						@pnNameNo		int',
						@nExchScheduleID =	@nExchScheduleID OUTPUT,
						@pnNameNo	 =	@pnNameNo
	end
	
	If @nErrorCode = 0 and @nExchScheduleID is null and @psWIPTypeId is not null
	Begin
		-- Get the Exch Schedule from the WIP Type.
		Set @sSQLString = "Select @nExchScheduleID = EXCHSCHEDULEID
					FROM WIPTYPE
					WHERE WIPTYPEID = @psWIPTypeId"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nExchScheduleID	int OUTPUT,
				  @psWIPTypeId		nvarchar(6)',
				  @nExchScheduleID	= @nExchScheduleID OUTPUT,
				  @psWIPTypeId		= @psWIPTypeId
	End
End

If @nErrorCode = 0
Begin
			
	Set @sSQLString = "
	SELECT @sExchVariationID = Substring ( max(
	CASE WHEN E.CURRENCYCODE    is null THEN '0' ELSE '1' END +
	CASE WHEN E.EXCHSCHEDULEID  is null THEN '0' ELSE '1' END +
	CASE WHEN E.CASETYPE	    is null THEN '0' ELSE '1' END +
	CASE WHEN E.PROPERTYTYPE    is null THEN '0' ELSE '1' END +
	CASE WHEN E.COUNTRYCODE     is null THEN '0' ELSE '1' END +
	CASE WHEN E.CASECATEGORY    is null THEN '0' ELSE '1' END +
	CASE WHEN E.CASESUBTYPE	    is null THEN '0' ELSE '1' END +
	convert(char(8), E.EFFECTIVEDATE,112) +
	convert(char(11),E.EXCHVARIATIONID)),16,11)
	FROM  EXCHRATEVARIATION E
	Left Join  CASES C on (C.CASEID = @pnCaseID)
	WHERE E.EFFECTIVEDATE	 <= isnull(@pdtTransactionDate, getdate())
	AND	(E.CURRENCYCODE	= @psCurrencyCode	OR E.CURRENCYCODE	IS NULL)
	AND (E.EXCHSCHEDULEID	= @nExchScheduleID	OR E.EXCHSCHEDULEID	IS NULL)
	AND ( E.CASETYPE	= isnull(C.CASETYPE,    @psCaseType)	OR E.CASETYPE		IS NULL) 
	AND ( E.PROPERTYTYPE	= isnull(C.PROPERTYTYPE,@psPropertyType)OR E.PROPERTYTYPE	IS NULL) 
	AND ( E.COUNTRYCODE	= isnull(C.COUNTRYCODE, @psCountryCode)	OR E.COUNTRYCODE	IS NULL)  
	AND ( E.CASECATEGORY	= isnull(C.CASECATEGORY,@psCaseCategory)OR E.CASECATEGORY	IS NULL) 
	AND ( E.CASESUBTYPE	= isnull(C.SUBTYPE,     @psSubType)	OR E.CASESUBTYPE	IS NULL)"
	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sExchVariationID	nvarchar(11)	OUTPUT,
					  @pnCaseID		int,
					  @psCurrencyCode	nvarchar(3),
					  @psCaseType		nchar(1),
					  @psCountryCode	nvarchar(3),
					  @psPropertyType	nchar(1),
					  @psCaseCategory	nvarchar(2),
					  @psSubType		nvarchar(2),
					  @nExchScheduleID	int,
					  @pdtTransactionDate	datetime',
					  @sExchVariationID  =@sExchVariationID OUTPUT,
					  @pnCaseID          =@pnCaseID,
					  @psCurrencyCode    =@psCurrencyCode,
					  @psCaseType        =@psCaseType,
					  @psCountryCode     =@psCountryCode,
					  @psPropertyType    =@psPropertyType,
					  @psCaseCategory    =@psCaseCategory,
					  @psSubType	     =@psSubType,
					  @nExchScheduleID   =@nExchScheduleID,
					  @pdtTransactionDate=@pdtTransactionDate

	If ( @nErrorCode=0 ) and (@sExchVariationID is not null)
	Begin
		Set @nExchVariationID = convert(int,@sExchVariationID)

		Set @sSQLString = "
		Select 	@pnBuyRate = BUYRATE, 
			@pnSellRate = SELLRATE, 
			@nBuyFactor = BUYFACTOR, 
			@nSellFactor= SELLFACTOR
		From EXCHRATEVARIATION
		Where EXCHVARIATIONID = @nExchVariationID"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBuyRate	decimal(11,4)	OUTPUT,
						  @pnSellRate	decimal(11,4)	OUTPUT,
						  @nBuyFactor	decimal(11,4)	OUTPUT,
						  @nSellFactor	decimal(11,4)	OUTPUT,
						  @nExchVariationID	int',
						  @pnBuyRate=@pnBuyRate OUTPUT,
						  @pnSellRate=@pnSellRate OUTPUT,
						  @nBuyFactor=@nBuyFactor OUTPUT,
						  @nSellFactor=@nSellFactor OUTPUT,
						  @nExchVariationID=@nExchVariationID
	
		If (@nErrorCode=0) AND (@pnBuyRate is null or @pnSellRate is null)
		Begin
			Set @sSQLString = "
			Select @pnBankRate = dbo.fn_GetHistExchRate(@pdtTransactionDate, @psCurrencyCode, 1)"
			
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnBankRate decimal(11,4) OUTPUT,
							  @psCurrencyCode nvarchar(3),
							  @pdtTransactionDate datetime',
							  @pnBankRate=@pnBankRate OUTPUT,
							  @psCurrencyCode = @psCurrencyCode,
							  @pdtTransactionDate = @pdtTransactionDate
		End
		
		If (@nErrorCode=0) AND (@nBuyFactor is not null)
			Set @pnBuyRate = @pnBankRate*@nBuyFactor
		If (@nErrorCode=0) AND (@nSellFactor is not null)
			Set @pnSellRate = @pnBankRate*@nSellFactor
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ac_GetExchangeVariation to public
GO
