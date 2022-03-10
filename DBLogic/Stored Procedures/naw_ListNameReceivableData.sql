-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameReceivableData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameReceivableData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameReceivableData.'
	Drop procedure [dbo].[naw_ListNameReceivableData]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameReceivableData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameReceivableData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@pbCalledFromCentura	bit		= 0	
)
as
-- PROCEDURE:	naw_ListNameReceivableData
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Name Receivable information.  
--		Populates NameReceivableData dataset ("Header","ReceivableTotal, and "ReceivableByCurrency")

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 28 Aug 2006	SF	RFC4214	1	Procedure created. 
--					Moved from naw_ListNameDetail, Added RowKey.
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 15 Feb 2017	MF	70649	5	The last receipt details is currently reporting the last dissection rather than the last receipt.
-- 15 Jun 2018  MS      72099   6       Show receivable balance details even if all bills are cleared
-- 14 Nov 2018  AV  75198/DR-45358	7   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period
Declare @dtTransDate			datetime
Declare @sForeignCurrency		nvarchar(3)
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @nForeignReceiptAmount		decimal(11,2)
Declare @nLocalReceiptAmount		decimal(11,2)
Declare @bIsRcvblItmAvailable		bit -- @bIsRcvblItmAvailable = 1 if the topic is available
Declare @dtToday			datetime
Declare @sSQLString 			nvarchar(4000)

set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Check whether the relevant result sets need to be suppressed based on Receivable Items topic security (200).
If @nErrorCode = 0
Begin
	-- Is the Receivable Items topic available?
	Set @sSQLString = "
	Select @bIsRcvblItmAvailable = IsAvailable
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsRcvblItmAvailable		bit			OUTPUT,
					  @dtToday			datetime',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsRcvblItmAvailable		= @bIsRcvblItmAvailable	OUTPUT,
					  @dtToday			= @dtToday
End

-- Retrieve the Last Receipt details and store them into variables. The values stored 
-- in the variables are then used to populate the Name table 
If @nErrorCode = 0
and @bIsRcvblItmAvailable = 1
Begin
	Set @sSQLString = "
	Select TOP 1 @dtTransDate 		= CI.ITEMDATE,
		     @sForeignCurrency      	= CI.PAYMENTCURRENCY, 
		     @nLocalReceiptAmount 	= CI.BANKNET,
		     @nForeignReceiptAmount 	= CI.PAYMENTAMOUNT
	from CASHITEM CI
	join TRANSACTIONHEADER TH on (TH.ENTITYNO=CI.TRANSENTITYNO
				  and TH.TRANSNO =CI.TRANSNO)
	Where TH.TRANSTYPE=560 -- Receipt
	and CI.ACCTNAMENO=@pnNameKey
	and CI.STATUS in (0,1)
	Order By TH.ENTRYDATE DESC, CI.POSTDATE DESC" 
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int,
					  @dtTransDate			datetime		OUTPUT,
					  @sForeignCurrency		nvarchar(3)		OUTPUT,
				    	  @nLocalReceiptAmount		decimal(11,2)		OUTPUT,
				    	  @nForeignReceiptAmount 	decimal(11,2)		OUTPUT',

					  @pnNameKey			= @pnNameKey,
					  @dtTransDate			= @dtTransDate		OUTPUT,
					  @sForeignCurrency		= @sForeignCurrency	OUTPUT,
	  				  @nLocalReceiptAmount		= @nLocalReceiptAmount 	OUTPUT,
	  				  @nForeignReceiptAmount 	= @nForeignReceiptAmount OUTPUT
End

-- Populating ReceivableData Result Set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select cast(N.NAMENO as nvarchar(11))	as 'RowKey',"+CHAR(10)+
	"	N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
	"@sLocalCurrencyCode	as 'LocalCurrencyCode',"+CHAR(10)+ 
	"@nLocalDecimalPlaces	as 'LocalDecimalPlaces',"+CHAR(10)+ 
	"@sForeignCurrency	as 'LastReceiptCurrencyCode',"+CHAR(10)+ 
	"@nLocalReceiptAmount	as 'LastReceiptLocal',"+CHAR(10)+ 
	"@nForeignReceiptAmount	as 'LastReceiptForeign',"+CHAR(10)+ 
	"@dtTransDate		as 'LastReceiptDate'"+CHAR(10)+ 
     	"from NAME N"+CHAR(10)+   	
	"where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		 	int,
					  @pnUserIdentityId	 	int,
					  @dtTransDate		 	datetime,
					  @sLocalCurrencyCode	 	nvarchar(3),
					  @nLocalDecimalPlaces		tinyint,
					  @sForeignCurrency	 	nvarchar(3),
				    	  @nLocalReceiptAmount	 	decimal(11,2),
				    	  @nForeignReceiptAmount 	decimal(11,2)',
					  @pnNameKey		 	= @pnNameKey,
					  @pnUserIdentityId	 	= @pnUserIdentityId,
					  @dtTransDate		 	= @dtTransDate,
					  @sLocalCurrencyCode	 	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces		= @nLocalDecimalPlaces,
					  @sForeignCurrency	 	= @sForeignCurrency,
	  				  @nLocalReceiptAmount	 	= @nLocalReceiptAmount,
	  				  @nForeignReceiptAmount 	= @nForeignReceiptAmount
End



-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin

	exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture

End

-- Populating ReceivableByCurrency Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select
	CAST(O.ACCTDEBTORNO as nvarchar(11)) + '^' + CAST(O.ACCTENTITYNO as nvarchar(11)) + '^' + ISNULL(O.CURRENCY, SC.COLCHARACTER) as 'RowKey',	
	O.ACCTDEBTORNO	as 'NameKey', 
	O.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	ISNULL(O.CURRENCY, SC.COLCHARACTER)
			as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0) 		    	THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2) 		    	THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket3Total',
	sum(ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE)) 
			as 'Total',
	sum(CASE WHEN(O.ITEMTYPE = 520) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END)
			as 'UnallocatedCash'
	from OPENITEM O
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where O.ACCTDEBTORNO = @pnNameKey  
	and O.STATUS <> 0
	and O.ITEMDATE <= getdate()	
	-- An empty result set is required if the user has insufficient security
	and   @bIsRcvblItmAvailable = 1
	group by O.ACCTENTITYNO, N.NAME, O.CURRENCY, SC.COLCHARACTER,O.ACCTDEBTORNO 
	order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @bIsRcvblItmAvailable	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @nAge0,
					  @nAge1         	= @nAge1,
					  @nAge2         	= @nAge2,
					  @dtBaseDate		= @dtBaseDate,
					  @bIsRcvblItmAvailable	= @bIsRcvblItmAvailable 
End	
	
-- Populating ReceivableTotal Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select
	CAST(O.ACCTDEBTORNO as nvarchar(11)) + '^' + CAST(O.ACCTENTITYNO as nvarchar(11)) + '^' + SC.COLCHARACTER as 'RowKey',
	O.ACCTDEBTORNO	as 'NameKey', 
	O.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	SC.COLCHARACTER	as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0) 		    	THEN O.LOCALBALANCE ELSE 0 END) 
			as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN O.LOCALBALANCE ELSE 0 END) 
			as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN O.LOCALBALANCE ELSE 0 END) 
			as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2) 		    	THEN O.LOCALBALANCE ELSE 0 END) 
			as 'Bracket3Total',
	sum(O.LOCALBALANCE)
			as 'Total',
	sum(CASE WHEN(O.ITEMTYPE = 520) THEN O.LOCALBALANCE ELSE 0 END)
			as 'UnallocatedCash'
	from OPENITEM O
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where O.ACCTDEBTORNO = @pnNameKey  
	and O.STATUS <> 0
	and O.ITEMDATE <= getdate()
	and O.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day, 1, getdate()),112) 
	-- An empty result set is required if the user has insufficient security
	and   @bIsRcvblItmAvailable = 1
	group by O.ACCTENTITYNO, N.NAME, SC.COLCHARACTER,O.ACCTDEBTORNO 
	order by 'EntityName', 'EntityKey'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @bIsRcvblItmAvailable	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @nAge0,
					  @nAge1         	= @nAge1,
					  @nAge2         	= @nAge2,
					  @dtBaseDate		= @dtBaseDate,
					  @bIsRcvblItmAvailable	= @bIsRcvblItmAvailable 
End	

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameReceivableData to public
GO
