-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameAccountsReceivableSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameAccountsReceivableSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameAccountsReceivableSummary.'
	Drop procedure [dbo].[naw_ListNameAccountsReceivableSummary]
	Print '**** Creating Stored Procedure dbo.naw_ListNameAccountsReceivableSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameAccountsReceivableSummary
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
	@pnAge0ARTotal		decimal(11,2) OUTPUT,
	@pnAge1ARTotal		decimal(11,2) OUTPUT,
	@pnAge2ARTotal		decimal(11,2) OUTPUT,
	@pnAge3ARTotal		decimal(11,2) OUTPUT,
	@pnARTotal		decimal(11,2) OUTPUT,
	@pnPrepayments		decimal(11,2) OUTPUT
)
AS 
-- PROCEDURE:	naw_ListNameAccountsReceivableSummary
-- VERSION:	3
-- SCOPE:	Inprotech Web
-- DESCRIPTION:	Returns summary WIP for this name
-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 13 Dec 2011  vql	RFC10456	1	Procedure created.
-- 05 Jul 2013	vql	R13629		2	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	3   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @bIsWIPAvailable	bit
Declare @dtToday		datetime
Declare @bBillRenewalDebtor	bit
Declare @nReceivableAvgValue	decimal(11,2)
Declare @nRowKey		int
Declare @nDaysOutStanding	decimal(11,2)
Declare @nDaysBeyondTerms	decimal(11,2)

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

If @nErrorCode=0
Begin
	-- Average value added to receivables per day. This average is to be calculated across DEBTORHISTORYs 
	-- for the staff member involved posted	in the past year as sum(LOCALVALUE)/days in last year.
	Set @sSQLString = "
	Select @nReceivableAverageValue = sum(isnull(DH.LOCALVALUE,0))/datediff(dd,dateadd(yy,-1,getdate()),getdate())
	from ASSOCIATEDNAME AN
	join DEBTORHISTORY DH	on (DH.ACCTDEBTORNO=AN.NAMENO)
	where AN.RELATEDNAME = @pnNameKey
	and   AN.RELATIONSHIP = 'RES'
	and   DH.MOVEMENTCLASS = 1
	and   DH.POSTDATE between  dateadd(yy,-1,getdate()) and getdate()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nReceivableAverageValue	decimal(11,2)	 	OUTPUT,
					  @pnNameKey			int',
					  @nReceivableAverageValue	= @nReceivableAvgValue 	OUTPUT,
					  @pnNameKey			= @pnNameKey
End

-- Local currency result set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	-- DaysOutstanding calculated as the current outstanding balance (sum(LOCALBALANCE)) divided by the average value 
	-- added to receivables per day. This average is to be calculated across all OPENITEMs posted 
	-- in the past year as sum(LOCALVALUE)/days in last year.
	Select
	-- it is unlikely Trading Tems will be set to -999999.  This is used as a row key.
	@nRowKey = ISNULL(SC.COLINTEGER, -999999),	
	@nDaysOutStanding = convert(int,	       
	CASE WHEN @nReceivableAverageValue = 0 
	     -- Avoid 'divide by zero' exception and set DaysOutstanding to null.
	     THEN null
	     ELSE (sum(isnull(O.LOCALBALANCE,0)))/@nReceivableAverageValue
	END),
	-- DaysBeyondTerms is calculated as sum(ReceivableBalance x Days OverDue)/Total Receivable Balance. 
	-- It should return null if the Trading Terms site control is set to null.
	@nDaysBeyondTerms = CASE WHEN SC.COLINTEGER is null
	     THEN null
	     ELSE convert(int,			  
		  CASE WHEN sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) = 0
		       -- Avoid 'divide by zero' exception and set DaysBeyondTerms to null.
		       THEN null 
     		       ELSE sum(CASE WHEN O.LOCALBALANCE > 0 
				     THEN (O.LOCALBALANCE* CASE WHEN (datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())) < 0 
			 					THEN 0
			 					ELSE isnull((datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())),0)
		    					   END)
				     ELSE 0
    	      			END)/sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) 	
		  END) 			  	
	END, 
	@nAge0ARTotal = sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0 and O.ITEMTYPE <> 523) 		      THEN O.LOCALBALANCE ELSE 0 END),
	@nAge1ARTotal = sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1 and O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END),
	@nAge2ARTotal = sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1 and O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END),
	@nAge3ARTotal = sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2 and O.ITEMTYPE <> 523) 		      THEN O.LOCALBALANCE ELSE 0 END),
	@nARTotal = sum(CASE WHEN(O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END),
	@nPrepayments = abs(sum(CASE WHEN(O.ITEMTYPE = 523) THEN O.LOCALBALANCE ELSE 0 END))
	from OPENITEM O
	left join SITECONTROL SC	on (SC.CONTROLID = 'Trading Terms') 	
	where O.ACCTDEBTORNO = @pnNameKey
	and O.STATUS<>0
	and O.ITEMDATE<=getdate()
	and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)
	group by SC.COLINTEGER"	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int,
					  @pnUserIdentityId		int,
					  @nAge0			smallint,
					  @nAge1			smallint,
					  @nAge2			smallint,
					  @dtBaseDate			datetime,
					  @nReceivableAverageValue	decimal(11,2),
					  @nRowKey			int OUTPUT,
					  @nDaysOutStanding		decimal(11,2) OUTPUT,
					  @nDaysBeyondTerms		decimal(11,2) OUTPUT,					  
					  @nAge0ARTotal			decimal(11,2) OUTPUT,
					  @nAge1ARTotal			decimal(11,2) OUTPUT,
					  @nAge2ARTotal			decimal(11,2) OUTPUT,
					  @nAge3ARTotal			decimal(11,2) OUTPUT,
					  @nARTotal			decimal(11,2) OUTPUT,
					  @nPrepayments			decimal(11,2) OUTPUT',
					  @pnNameKey			= @pnNameKey,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @nAge0         		= @pnAge0,
					  @nAge1         		= @pnAge1,
					  @nAge2         		= @pnAge2,
					  @dtBaseDate			= @pdtBaseDate,
					  @nReceivableAverageValue	= @nReceivableAvgValue,
					  @nRowKey			= @nRowKey OUTPUT,
					  @nDaysOutStanding		= @nDaysOutStanding OUTPUT,
					  @nDaysBeyondTerms		= @nDaysBeyondTerms OUTPUT,
					  @nAge0ARTotal			= @pnAge0ARTotal OUTPUT,
					  @nAge1ARTotal			= @pnAge1ARTotal OUTPUT,
					  @nAge2ARTotal			= @pnAge2ARTotal OUTPUT,
					  @nAge3ARTotal			= @pnAge3ARTotal OUTPUT,
					  @nARTotal			= @pnARTotal OUTPUT,
					  @nPrepayments			= @pnPrepayments OUTPUT
End

-- return local currency set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	If	(@pnAge0ARTotal		is null and
		@pnAge1ARTotal		is null and
		@pnAge2ARTotal		is null and
		@pnAge3ARTotal		is null and
		@pnARTotal		is null and
		@pnPrepayments		is null)
	Begin
		select	
		@pnNameKey			as NameKey,
		@psLocalCurrencyCode			as RowKey,
		@psLocalCurrencyCode			as CurrencyCode,
		0			as DaysOutstanding,
		0			as DaysBeyondTerms,
		0			as Bracket0Total,
		0			as Bracket1Total,
		0			as Bracket2Total,
		0			as Bracket3Total,			
		0			as Total,
		0			as Prepayments			
	End
	Else
	Begin
		select	
		@pnNameKey		as NameKey,
		@nRowKey		as RowKey,
		@psLocalCurrencyCode	as CurrencyCode,
		@nDaysOutStanding	as DaysOutstanding,
		@nDaysBeyondTerms	as DaysBeyondTerms,
		@pnAge0ARTotal		as Bracket0Total,
		@pnAge1ARTotal		as Bracket1Total,
		@pnAge2ARTotal		as Bracket2Total,
		@pnAge3ARTotal		as Bracket3Total,			
		@pnARTotal		as Total,
		@pnPrepayments		as Prepayments	
	End
End
						
-- Foreign currency balance result set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	Select
	@pnNameKey	as 'NameKey', 
	ISNULL(O.CURRENCY, @sLocalCurrencyCode)
			as 'RowKey',	
	ISNULL(O.CURRENCY, @sLocalCurrencyCode)
			as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0 and O.ITEMTYPE <> 523) 		      THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
			as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1 and O.ITEMTYPE <> 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
			as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1 and O.ITEMTYPE <> 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
			as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2 and O.ITEMTYPE <> 523) 		      THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
			as 'Bracket3Total',		
	sum(CASE WHEN(O.ITEMTYPE <> 523) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END)	
			as 'Total',
	abs(sum(CASE WHEN(O.ITEMTYPE = 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END))
			as 'Prepayments'
	from OPENITEM O
	where O.ACCTDEBTORNO = @pnNameKey
	and O.STATUS<>0
	and O.ITEMDATE<=getdate()
	and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)
	group by ISNULL(O.CURRENCY, @sLocalCurrencyCode)"	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @pnAge0,
					  @nAge1         	= @pnAge1,
					  @nAge2         	= @pnAge2,
					  @dtBaseDate		= @pdtBaseDate,
					  @sLocalCurrencyCode	= @psLocalCurrencyCode
End

-- return local currency set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	select	@pnNameKey						as NameKey,
		isnull(@pnBillingCurrencyCode,@psLocalCurrencyCode)	as RowKey,
		isnull(@pnBillingCurrencyCode,@psLocalCurrencyCode)	as CurrencyCode,
		@nDaysOutStanding					as DaysOutstanding,
		@nDaysBeyondTerms					as DaysBeyondTerms,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge0ARTotal,0)		as Bracket0Total,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge1ARTotal,0)		as Bracket1Total,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge2ARTotal,0)		as Bracket2Total,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnAge3ARTotal,0)		as Bracket3Total,			
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnARTotal,0)		as Total,
		isnull(@pnBillingCurrencyRate,1)*isnull(@pnPrepayments,0)		as Prepayments
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameAccountsReceivableSummary to public
GO