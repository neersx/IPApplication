-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_GetExchangeParameters
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_GetExchangeParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_GetExchangeParameters.'
	Drop procedure [dbo].[ac_GetExchangeParameters]
End
Print '**** Creating Stored Procedure dbo.ac_GetExchangeParameters...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ac_GetExchangeParameters
(
	@pdtTransactionDate	datetime	= null	output, -- Transaction date to be used to obtain historical exchange rate
	@pbUseHistoricalRates	bit		= null	output, -- Determines whether to use historical exchange rate.
	@pnUserIdentityId	int,		-- Mandatory 	   
	@pbCalledFromCentura	bit		= 0,
	@psWIPCategory		nvarchar(2)	= null	output,	-- WIP Category for which the exchange rate to be determined.
	@pnAccountingSystemID	int
)
as
-- PROCEDURE:	ac_GetExchangeParameters
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Obtain information necessary for calculations in a foreign currency
--
--	Applicable System IDs
-- 	1  Inprotech (i.e. charge generation)
--	2  Time and Billing
--	4  Accounts Receivable
-- 	8  Accounts Payable
-- 	16 Cash Book
--	32 General Ledger
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jun 2006	KR	11702/	1	Procedure created.
--			12108		
-- 27 Jun 2006	KR	12108	2	Added description to the parameter.
-- 21 Jul 2006	KR	13096	3	Fixed bug
-- 18 Jan 2007	CR	12400	4	Extended Open Period logic to check for the 
--					Application
-- 24 Jan 2007	CR	12400	5	Changed the If @wpsWIPCategory is not null ... Else ...
--					Around to be If @wpsWIPCategory is null ... Else ...
-- 09 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare @sSQLString			nvarchar(4000)
declare @bHistoricalRatesForOpenPeriod	bit
declare	@dtOpenPeriodStart 		datetime
declare @nPeriodId			int

-- Initialise variables
Set @nErrorCode = 0

If @pdtTransactionDate is NULL
Begin
	set @pdtTransactionDate = getdate()
End

-- If the System Id is NULL assume periods closed for any application are not to be used.
If @pnAccountingSystemID is NULL
Begin
	Set @pnAccountingSystemID = 30
End

	
If (@psWIPCategory is null)
Begin
	-- Current transaction is not WIP related - get site control historical exch rate
	Set @sSQLString = "
	Select @pbUseHistoricalRates = isnull(COLBOOLEAN,0)
	From SITECONTROL
	Where CONTROLID = 'Historical Exch Rate'"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pbUseHistoricalRates	bit 			OUTPUT',
			  @pbUseHistoricalRates = @pbUseHistoricalRates	OUTPUT
End
Else
Begin
	-- get historical exchange rate for the particular WIPCategory
	Set @sSQLString = "Select  @pbUseHistoricalRates = Case When (HISTORICALEXCHRATE = 1) then 1
									  else 0
					       end
	From	WIPCATEGORY
	Where 	CATEGORYCODE = " + "'" + @psWIPCategory + "'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pbUseHistoricalRates  bit			OUTPUT',
					  @pbUseHistoricalRates = @pbUseHistoricalRates	OUTPUT
End

If (@nErrorCode = 0)
Begin
	-- get site control historical exchange rate for open period
	Set @sSQLString = "
	Select @bHistoricalRatesForOpenPeriod = isnull(COLBOOLEAN,0)
	From SITECONTROL
	Where CONTROLID = 'Hist Exch For Open Period'"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@bHistoricalRatesForOpenPeriod bit 					OUTPUT',
			  @bHistoricalRatesForOpenPeriod = @bHistoricalRatesForOpenPeriod	OUTPUT
End	
			
If (@nErrorCode = 0)
Begin
	If (@bHistoricalRatesForOpenPeriod = 1) 
	Begin
		-- Get the currently opened period
		Set @nPeriodId = dbo.fn_GetPostPeriod(@pdtTransactionDate, @pnAccountingSystemID)
			
		-- get start date for the currently open period.		
		Set @sSQLString = "
		select @dtOpenPeriodStart = max(STARTDATE) 
		from PERIOD 
		where PERIODID = @nPeriodId
		AND POSTINGCOMMENCED is not null"
			
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtOpenPeriodStart 	datetime		OUTPUT,
				  @nPeriodId		int',
				  @dtOpenPeriodStart	= @dtOpenPeriodStart 	OUTPUT,
				  @nPeriodId		= @nPeriodId 
		
		If (@pdtTransactionDate < @dtOpenPeriodStart)
		Begin
			Set @pdtTransactionDate = @dtOpenPeriodStart
				
		end
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ac_GetExchangeParameters to public
GO
