-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAccountingSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAccountingSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAccountingSummary.'
	Drop procedure [dbo].[naw_ListAccountingSummary]
	Print '**** Creating Stored Procedure dbo.naw_ListAccountingSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListAccountingSummary
(
	@pnUserIdentityId	int,
	@psCulture		nvarchar(10) 	= null,	
	@pnNameKey		int, 				-- The name the results are required for.  If left null, the results are extracted for the current UserIdentity.
	@psResultSetsRequired	nvarchar(500)   = null,  	-- A comma separated list of the result sets required.  
								-- Null will return all result sets.  
								-- Other values that may be requested are Summary,AccountsReceivableTotal,AccountsReceivableByCurrency,UnbilledWIPTotal,UnbilledWIPByCurrency,ListNameType,UnbilledDisbursementTotal,UnbilledDisbursementByCurrency,UnbilledExpensesTotal,UnbilledExpensesByCurrency,UnbilledTimeTotal,UnbilledTimeByCurrency,OtherDetails.
	@psNameTypeKey		nvarchar(3) 	= null,		-- The Name Type relationship the NameKey has to the cases to be reported.  If null, personal data is reported.
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	naw_ListAccountingSummary
-- VERSION:	3
-- SCOPE:	Inprotech Web
-- DESCRIPTION:	Returns Client and Case Summary. Calls a number of other SP.
-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 13 Dec 2011  vql	RFC10456	1	Procedure created.
-- 16 Jan 2012	vql	RFC10456	2	Return Prepayments as Money in Account.
-- 24 Aug 2017	MF	71721		3	Ethical Walls rules applied for logged on user.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
-- Table variable used to hold the names of the Result Set that stored procedure needs to calculate and return.
Declare @tblResultsRequired	table	(ResultSet	nvarchar(40) collate database_default) 
Declare @sLookupCulture		nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @dtBaseDate		datetime
Declare	@nAge0			smallint
Declare	@nAge1			smallint
Declare	@nAge2			smallint
Declare @sBillingCurrencyCode	nvarchar(3)
Declare @nBillingCurrencyRate	decimal(11,4)	

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Intialise Variables
Set     @nErrorCode = 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode = 0
Begin
	exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End

-- Get the BIlling Currency
If @nErrorCode = 0
Begin
	Select	@sBillingCurrencyCode=IP.CURRENCY,
		@nBillingCurrencyRate=C.SELLRATE
	from IPNAME IP
	join CURRENCY C on (C.CURRENCY=IP.CURRENCY)
	where IP.NAMENO = @pnNameKey
End

-- Use fn_Tokenise to extract the requested result sets into a @tblResultsRequired table variable 
If @nErrorCode = 0
and @psResultSetsRequired is not null
Begin
	Insert into @tblResultsRequired
	Select Parameter
	from fn_Tokenise(@psResultSetsRequired, ',')
End

-- Name result set
-- ListNameType result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('Name'))
or @psResultSetsRequired is null)
Begin 
	Set @sSQLString = "
	Select  N.NAMENO 		as 'NameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)	
			 		as 'Name',
		N.NAMECODE		as 'NameCode',
		@sLocalCurrencyCode 	as 'LocalCurrencyCode',
		isnull(@sBillingCurrencyCode,@sLocalCurrencyCode)	as 'BillingCurrencyCode',
		@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
		from dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") N	
		where N.NAMENO = @pnNameKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey 		int,
					  @sLocalCurrencyCode	nvarchar(3),
					  @sBillingCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',					 
					  @pnNameKey 		= @pnNameKey,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @sBillingCurrencyCode	= @sBillingCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
End

-- ListNameType result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('ListNameType'))
or @psResultSetsRequired is null)
and @psNameTypeKey is not null
Begin 
	exec @nErrorCode = dbo.naw_ListCasesForName
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psNameTypeKey		= @psNameTypeKey
End

-- Accounts Receivable result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('AccountsReceivableTotal','AccountsReceivableByCurrency'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- summary totals in local currency.
	declare	@nAge0ARTotal	decimal(11,2)	
	declare	@nAge1ARTotal	decimal(11,2)	
	declare	@nAge2ARTotal	decimal(11,2)
	declare	@nAge3ARTotal	decimal(11,2)	
	declare	@nARTotal	decimal(11,2)
	declare	@nPrepayments	decimal(11,2)	
	
	exec @nErrorCode = dbo.naw_ListNameAccountsReceivableSummary
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnBillingCurrencyCode	= @sBillingCurrencyCode,
		@pnBillingCurrencyRate	= @nBillingCurrencyRate,
		@pnAge0ARTotal		= @nAge0ARTotal	OUTPUT,
		@pnAge1ARTotal 		= @nAge1ARTotal	OUTPUT,
		@pnAge2ARTotal		= @nAge2ARTotal	OUTPUT,
		@pnAge3ARTotal		= @nAge3ARTotal	OUTPUT,
		@pnARTotal 		= @nARTotal	OUTPUT,
		@pnPrepayments		= @nPrepayments OUTPUT
End

-- UnbilledWIP result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('UnbilledWIPTotal','UnbilledWIPByCurrency'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- summary totals in local currency.
	declare	@nAge0WIPTotal	decimal(11,2)	
	declare	@nAge1WIPTotal	decimal(11,2)	
	declare	@nAge2WIPTotal	decimal(11,2)
	declare	@nAge3WIPTotal	decimal(11,2)	
	declare	@nWIPTotal	decimal(11,2)
		
	exec @nErrorCode = dbo.naw_ListNameUnbilledWorkInProgressSummary
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnBillingCurrencyCode	= @sBillingCurrencyCode,
		@pnBillingCurrencyRate	= @nBillingCurrencyRate,
		@pnAge0WIPTotal		= @nAge0WIPTotal	OUTPUT,
		@pnAge1WIPTotal 	= @nAge1WIPTotal	OUTPUT,
		@pnAge2WIPTotal		= @nAge2WIPTotal	OUTPUT,
		@pnAge3WIPTotal 	= @nAge3WIPTotal	OUTPUT,
		@pnWIPTotal 		= @nWIPTotal		OUTPUT
End

-- UnbilledDisbursement result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('UnbilledDisbursementTotal','UnbilledDisbursementByCurrency'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- summary totals in local currency.
	declare	@nAge0DisTotal	decimal(11,2)	
	declare	@nAge1DisTotal	decimal(11,2)	
	declare	@nAge2DisTotal	decimal(11,2)
	declare	@nAge3DisTotal	decimal(11,2)	
	declare	@nDisTotal	decimal(11,2)

	exec @nErrorCode = dbo.naw_ListNameUnbilledDisbursementSummary
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnBillingCurrencyCode	= @sBillingCurrencyCode,
		@pnBillingCurrencyRate	= @nBillingCurrencyRate,
		@pnAge0DisTotal		= @nAge0DisTotal	OUTPUT,
		@pnAge1DisTotal 	= @nAge1DisTotal	OUTPUT,
		@pnAge2DisTotal		= @nAge2DisTotal	OUTPUT,
		@pnAge3DisTotal 	= @nAge3DisTotal	OUTPUT,
		@pnDisTotal 		= @nDisTotal		OUTPUT
End

-- UnbilledExpenses result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('UnbilledExpensesTotal','UnbilledExpensesByCurrency'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- summary totals in local currency.
	declare	@nAge0ExpTotal	decimal(11,2)	
	declare	@nAge1ExpTotal	decimal(11,2)	
	declare	@nAge2ExpTotal	decimal(11,2)
	declare	@nAge3ExpTotal	decimal(11,2)	
	declare	@nExpTotal	decimal(11,2)
	
	exec @nErrorCode = dbo.naw_ListNameUnbilledExpensesSummary
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnBillingCurrencyCode	= @sBillingCurrencyCode,
		@pnBillingCurrencyRate	= @nBillingCurrencyRate,
		@pnAge0ExpTotal		= @nAge0ExpTotal	OUTPUT,
		@pnAge1ExpTotal 	= @nAge1ExpTotal	OUTPUT,
		@pnAge2ExpTotal		= @nAge2ExpTotal	OUTPUT,
		@pnAge3ExpTotal 	= @nAge3ExpTotal	OUTPUT,
		@pnExpTotal 		= @nExpTotal		OUTPUT
End

-- UnbilledTime result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('UnbilledTimeTotal','UnbilledTimeByCurrency'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- summary totals in local currency.
	declare	@nAge0TimeTotal	decimal(11,2)	
	declare	@nAge1TimeTotal	decimal(11,2)	
	declare	@nAge2TimeTotal	decimal(11,2)
	declare	@nAge3TimeTotal	decimal(11,2)	
	declare	@nTimeTotal	decimal(11,2)
	
	exec @nErrorCode = dbo.naw_ListNameUnbilledTimeSummary
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnBillingCurrencyCode	= @sBillingCurrencyCode,
		@pnBillingCurrencyRate	= @nBillingCurrencyRate,
		@pnAge0TimeTotal	= @nAge0TimeTotal	OUTPUT,
		@pnAge1TimeTotal 	= @nAge1TimeTotal	OUTPUT,
		@pnAge2TimeTotal	= @nAge2TimeTotal	OUTPUT,
		@pnAge3TimeTotal 	= @nAge3TimeTotal	OUTPUT,
		@pnTimeTotal 		= @nTimeTotal		OUTPUT
End

-- OtherDetails result set.
If (exists(select * from @tblResultsRequired where ResultSet in ('OtherDetails'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	Declare @nMoneyInAccount decimal(11,2)
	
	exec @nErrorCode = dbo.naw_ListNameOtherDetails
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@psLocalCurrencyCode	= @sLocalCurrencyCode,
		@pdtBaseDate		= @dtBaseDate,
		@pnAge0			= @nAge0,
		@pnAge1			= @nAge1,
		@pnAge2			= @nAge2,
		@pnMoneyInAccount	= @nMoneyInAccount OUTPUT
End

-- Summary result set (currency local).
If (exists(select * from @tblResultsRequired where ResultSet in ('Summary'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 
	-- unbilled Time totals (local currency)
	select	@pnNameKey as NameKey,
		isnull(@nAge0TimeTotal,0) as Age0TimeTotal, 
		isnull(@nAge1TimeTotal,0) as Age1TimeTotal, 
		isnull(@nAge2TimeTotal,0) as Age2TimeTotal, 
		isnull(@nAge3TimeTotal,0) as Age3TimeTotal, 
		isnull(@nTimeTotal,0) as TimeTotal	
	-- unbilled Disbursement totals (local currency)
	select	@pnNameKey as NameKey,
		isnull(@nAge0DisTotal,0) as Age0DisTotal, 
		isnull(@nAge1DisTotal,0) as Age1DisTotal, 
		isnull(@nAge2DisTotal,0) as Age2DisTotal, 
		isnull(@nAge3DisTotal,0) as Age3DisTotal, 
		isnull(@nDisTotal,0) as DisTotal
	-- unbilled Expenses totals (local currency)
	select	@pnNameKey as NameKey,
		isnull(@nAge0ExpTotal,0) as Age0ExpTotal, 
		isnull(@nAge1ExpTotal,0) as Age1ExpTotal, 
		isnull(@nAge2ExpTotal,0) as Age2ExpTotal, 
		isnull(@nAge3ExpTotal,0) as Age3ExpTotal, 
		isnull(@nExpTotal,0) as ExpTotal
	-- unbilled WIP totals (local currency)
	select	@pnNameKey as NameKey,
		isnull(@nAge0WIPTotal,0) as Age0WIPTotal, 
		isnull(@nAge1WIPTotal,0) as Age1WIPTotal, 
		isnull(@nAge2WIPTotal,0) as Age2WIPTotal, 
		isnull(@nAge3WIPTotal,0) as Age3WIPTotal, 
		isnull(@nWIPTotal,0) as WIPTotal
	-- AR totals (Debtors) (local currency)
	select	@pnNameKey as NameKey,
		isnull(@nAge0ARTotal,0) as Age0ARTotal, 
		isnull(@nAge1ARTotal,0) as Age1ARTotal, 
		isnull(@nAge2ARTotal,0) as Age2ARTotal, 
		isnull(@nAge3ARTotal,0) as Age3ARTotal, 
		isnull(@nARTotal,0) as ARTotal
	-- money in account (local currency)
	select	@pnNameKey as NameKey,
			isnull(@nPrepayments,0) as MoneyInAccount
	-- gross exposure (local currency)
	select	@pnNameKey as NameKey,
		isnull(isnull(@nAge0WIPTotal,0)+isnull(@nAge0ARTotal,0),0)	as Age0GrossExposureTotal, 
		isnull(isnull(@nAge1WIPTotal,0)+isnull(@nAge1ARTotal,0),0)	as Age1GrossExposureTotal, 
		isnull(isnull(@nAge2WIPTotal,0)+isnull(@nAge2ARTotal,0),0)	as Age2GrossExposureTotal, 
		isnull(isnull(@nAge3WIPTotal,0)+isnull(@nAge3ARTotal,0),0)	as Age3GrossExposureTotal, 
		isnull(isnull(@nWIPTotal,0)+isnull(@nARTotal,0),0)		as GrossExposureTotal
	-- net exposure (local currency)
	select	@pnNameKey as NameKey,
		isnull(isnull(@nAge0WIPTotal,0)+isnull(@nAge0ARTotal,0)-isnull(@nPrepayments,0),0)	as Age0NetExposureTotal, 
		isnull(isnull(@nAge1WIPTotal,0)+isnull(@nAge1ARTotal,0)-isnull(@nPrepayments,0),0)	as Age1NetExposureTotal, 
		isnull(isnull(@nAge2WIPTotal,0)+isnull(@nAge2ARTotal,0)-isnull(@nPrepayments,0),0)	as Age2NetExposureTotal, 
		isnull(isnull(@nAge3WIPTotal,0)+isnull(@nAge3ARTotal,0)-isnull(@nPrepayments,0),0)	as Age3NetExposureTotal, 
		isnull(isnull(@nWIPTotal,0)+isnull(@nARTotal,0)-isnull(@nPrepayments,0),0)		as NetExposureTotal
End		
		
-- Summary result set (currency billing).
If (exists(select * from @tblResultsRequired where ResultSet in ('Summary'))
or @psResultSetsRequired is null)
and @nErrorCode = 0
Begin 		
	-- unbilled Time totals (billing currency)
	select @pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge0TimeTotal,0) as Age0TimeBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge1TimeTotal,0) as Age1TimeBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge2TimeTotal,0) as Age2TimeBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge3TimeTotal,0) as Age3TimeBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nTimeTotal,0)	as TimeBillCurrencyTotal	
	-- unbilled Disbursement totals (billing currency)
	select @pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge0DisTotal,0)	as Age0DisBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge1DisTotal,0)	as Age1DisBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge2DisTotal,0)	as Age2DisBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge3DisTotal,0)	as Age3DisBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nDisTotal,0)	as DisBillCurrencyTotal
	-- unbilled Expenses totals (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge0ExpTotal,0)	as Age0ExpBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge1ExpTotal,0)	as Age1ExpBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge2ExpTotal,0)	as Age2ExpBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge3ExpTotal,0)	as Age3ExpBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nExpTotal,0)	as ExpBillCurrencyTotal
	-- unbilled WIP totals (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge0WIPTotal,0)	as Age0WIPBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge1WIPTotal,0)	as Age1WIPBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge2WIPTotal,0)	as Age2WIPBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge3WIPTotal,0)	as Age3WIPBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nWIPTotal,0)	as WIPBillCurrencyTotal
	-- AR totals (Debtors) (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge0ARTotal,0)	as Age0ARBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge1ARTotal,0)	as Age1ARBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge2ARTotal,0)	as Age2ARBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nAge3ARTotal,0)	as Age3ARBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(@nARTotal,0)	as ARBillCurrencyTotal
	-- money in account (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(@nPrepayments,0) as BillCurrencyMoneyInAccount
	-- gross exposure (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge0WIPTotal,0)+isnull(@nAge0ARTotal,0),0)	as Age0GrossExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge1WIPTotal,0)+isnull(@nAge1ARTotal,0),0)	as Age1GrossExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge2WIPTotal,0)+isnull(@nAge2ARTotal,0),0)	as Age2GrossExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge3WIPTotal,0)+isnull(@nAge3ARTotal,0),0)	as Age3GrossExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nWIPTotal,0)+isnull(@nARTotal,0),0)		as GrossExposureBillCurrencyTotal
	-- net exposure (billing currency)
	select	@pnNameKey as NameKey,
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge0WIPTotal,0)+isnull(@nAge0ARTotal,0)-isnull(@nPrepayments,0),0)	as Age0NetExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge1WIPTotal,0)+isnull(@nAge1ARTotal,0)-isnull(@nPrepayments,0),0)	as Age1NetExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge2WIPTotal,0)+isnull(@nAge2ARTotal,0)-isnull(@nPrepayments,0),0)	as Age2NetExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nAge3WIPTotal,0)+isnull(@nAge3ARTotal,0)-isnull(@nPrepayments,0),0)	as Age3NetExposureBillCurrencyTotal, 
		isnull(@nBillingCurrencyRate,1)*isnull(isnull(@nWIPTotal,0)+isnull(@nARTotal,0)-isnull(@nPrepayments,0),0)		as NetExposureBillCurrencyTotal		
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListAccountingSummary to public
GO
