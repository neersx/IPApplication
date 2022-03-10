-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameUnbilledExpensesSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameUnbilledExpensesSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameUnbilledExpensesSummary.'
	Drop procedure [dbo].[naw_ListNameUnbilledExpensesSummary]
	Print '**** Creating Stored Procedure dbo.naw_ListNameUnbilledExpensesSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameUnbilledExpensesSummary
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,	
	@pnNameKey		int,		-- Mandatory, the name the results are required for.
	@psLocalCurrencyCode	nvarchar(3)	= null,
	@pdtBaseDate		datetime	= null,
	@pnAge0			smallint	= null,
	@pnAge1			smallint	= null,
	@pnAge2			smallint	= null,
	@pnBillingCurrencyCode	nvarchar(3)	= null,
	@pnBillingCurrencyRate	decimal(11,4)	= null,	
	@pnAge0ExpTotal		decimal(11,2) OUTPUT,
	@pnAge1ExpTotal		decimal(11,2) OUTPUT,
	@pnAge2ExpTotal		decimal(11,2) OUTPUT,
	@pnAge3ExpTotal		decimal(11,2) OUTPUT,
	@pnExpTotal		decimal(11,2) OUTPUT
)
AS 
-- PROCEDURE:	naw_ListNameUnbilledExpensesSummary
-- VERSION:	2
-- SCOPE:	Inprotech Web
-- DESCRIPTION:	Returns summary WIP for this name
-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 13 Dec 2011  vql	RFC10456	1	Procedure created.
-- 24 Aug 2017	MF	71721		2	Ethical Walls rules applied for logged on user.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @bIsWIPAvailable	bit
Declare @dtToday		datetime
Declare @bBillRenewalDebtor	bit

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

-- Check Bill Rewnal Debotr site control
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bBillRenewalDebtor = COLBOOLEAN
	from SITECONTROL
	where CONTROLID like 'Bill Renewal Debtor'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bBillRenewalDebtor			bit	OUTPUT',
					  @bBillRenewalDebtor=@bBillRenewalDebtor	OUTPUT
End

-- Check whether the WIP Items information is available.
-- The result set should only be published if the Work In Progress Items information security topic (120) is available.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bIsWIPAvailable = IsAvailable
	from	dbo.fn_GetTopicSecurity(null, 120, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @bIsWIPAvailable	bit			OUTPUT,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bIsWIPAvailable	= @bIsWIPAvailable 	OUTPUT,
					  @dtToday		= @dtToday
End

-- Local currency result set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin	
	Set @sSQLString = "
	Select
	@nAge0ExpTotal = SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		         THEN ISNULL(W.BALANCE,0) ELSE 0 END),
	@nAge1ExpTotal = SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(W.BALANCE,0) ELSE 0 END),
	@nAge2ExpTotal = SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(W.BALANCE,0) ELSE 0 END),
	@nAge3ExpTotal = SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		         THEN ISNULL(W.BALANCE,0) ELSE 0 END),
	@nExpTotal = SUM(ISNULL(W.BALANCE,0))
	from WORKINPROGRESS W
	left join CASENAME CN	on (CN.CASEID = W.CASEID"

	If @bBillRenewalDebtor = 1
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'Z'"								
	End
	Else
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'D'"
	End

	Set @sSQLString = @sSQLString + char(10) + 	"
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C on (C.CASEID=W.CASEID)
	join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
	where isnull(CN.NAMENO,W.ACCTCLIENTNO) = @pnNameKey
	and W.STATUS <> 0
	and WT.CATEGORYCODE in ('OR')
	and  W.TRANSDATE <= getdate()
	and (W.CASEID is null OR C.CASEID is not null)"		

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int,
					  @pnUserIdentityId		int,
					  @dtBaseDate			datetime,
					  @nAge0			smallint,
					  @nAge1			smallint,
					  @nAge2			smallint,
					  @sLocalCurrencyCode		nvarchar(3),
					  @nAge0ExpTotal		decimal(11,2) OUTPUT,
					  @nAge1ExpTotal		decimal(11,2) OUTPUT,
					  @nAge2ExpTotal		decimal(11,2) OUTPUT,
					  @nAge3ExpTotal		decimal(11,2) OUTPUT,
					  @nExpTotal			decimal(11,2) OUTPUT',
					  @pnNameKey			= @pnNameKey,
					  @pnUserIdentityId		= @pnUserIdentityId,
				          @dtBaseDate			= @pdtBaseDate,
					  @nAge0			= @pnAge0,
					  @nAge1			= @pnAge1,
					  @nAge2			= @pnAge2,
					  @sLocalCurrencyCode		= @psLocalCurrencyCode,
					  @nAge0ExpTotal		= @pnAge0ExpTotal OUTPUT,
					  @nAge1ExpTotal		= @pnAge1ExpTotal OUTPUT,
					  @nAge2ExpTotal		= @pnAge2ExpTotal OUTPUT,
					  @nAge3ExpTotal		= @pnAge3ExpTotal OUTPUT,
					  @nExpTotal			= @pnExpTotal OUTPUT
					  
End

-- return local currency set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	If (	@pnAge0ExpTotal is null and
		@pnAge1ExpTotal is null and
		@pnAge2ExpTotal is null and
		@pnAge3ExpTotal is null and
		@pnExpTotal	is null)
	Begin	
		select	@pnNameKey as NameKey, 
			@psLocalCurrencyCode as RowKey, 
			@psLocalCurrencyCode as CurrencyCode,
			0 as Bracket0Total,
			0 as Bracket1Total, 
			0 as Bracket2Total, 
			0 as Bracket3Total, 
			0 as Total	
	End
	Else
	Begin
		select	@pnNameKey		as NameKey, 
			@psLocalCurrencyCode	as RowKey, 
			@psLocalCurrencyCode	as CurrencyCode,
			@pnAge0ExpTotal		as Bracket0Total,
			@pnAge1ExpTotal		as Bracket1Total, 
			@pnAge2ExpTotal		as Bracket2Total, 
			@pnAge3ExpTotal		as Bracket3Total, 
			@pnExpTotal		as Total
	End
End

-- Foreign currency balance result set
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin	
	Set @sSQLString = "
	Select
	@pnNameKey as NameKey,
	ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)	
			as RowKey,
	ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)	
			as CurrencyCode,
	SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		         THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
			as Bracket0Total,
	SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
			as Bracket1Total,
	SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
			as Bracket2Total,
	SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		         THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
			as Bracket3Total,
	SUM(coalesce(W.FOREIGNBALANCE, W.BALANCE,0))
		 	as Total						
	from WORKINPROGRESS W
	left join CASENAME CN	on (CN.CASEID = W.CASEID"
	
	If @bBillRenewalDebtor = 1
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'Z'"								
	End
	Else
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'D'"
	End

	Set @sSQLString = @sSQLString + char(10) + "
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C on (C.CASEID=W.CASEID)
	join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)				
	where isnull(CN.NAMENO,W.ACCTCLIENTNO) = @pnNameKey		
	and W.STATUS <> 0
	and W.TRANSDATE <= getdate()
	and WT.CATEGORYCODE in ('OR')
	and (W.CASEID is null OR C.CASEID is not null)
	group by ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)"		

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
				          @dtBaseDate		= @pdtBaseDate,
					  @nAge0		= @pnAge0,
					  @nAge1		= @pnAge1,
					  @nAge2		= @pnAge2,
					  @sLocalCurrencyCode	= @psLocalCurrencyCode
End

-- return billing currency set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	select	@pnNameKey						as NameKey, 
		isnull(@pnBillingCurrencyCode,@psLocalCurrencyCode)	as RowKey, 
		isnull(@pnBillingCurrencyCode,@psLocalCurrencyCode)	as CurrencyCode,		
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge0ExpTotal,0)	as Bracket0Total,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge1ExpTotal,0)	as Bracket1Total, 
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge2ExpTotal,0)	as Bracket2Total, 
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge3ExpTotal,0)	as Bracket3Total, 
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnExpTotal,0)		as Total
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameUnbilledExpensesSummary to public
GO