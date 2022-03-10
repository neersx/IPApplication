-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNamePayableData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNamePayableData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNamePayableData.'
	Drop procedure [dbo].[naw_ListNamePayableData]
End
Print '**** Creating Stored Procedure dbo.naw_ListNamePayableData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNamePayableData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListNamePayableData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Name Payable information.  
--		Populates NamePayableData dataset ("Header","PayableTotal, and "PayableByCurrency")

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 28 Aug 2006	SF	RFC4214	1	Procedure created. 
--					Moved from naw_ListNameDetail, Added RowKey.
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer	
-- 05 Jul 2013	vql	R13629	4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	5  Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period




Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @bIsPayableAvailable		bit -- @bIsPayableAvailable = 1 if the topic is available
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

-- Check whether the relevant result sets need to be suppressed based on Payable Items topic security (300).
If @nErrorCode = 0
Begin
	-- Is the Payable Items topic available?
	Set @sSQLString = "
	Select @bIsPayableAvailable = IsAvailable
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 300, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsPayableAvailable		bit			OUTPUT,
					  @dtToday			datetime',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsPayableAvailable		= @bIsPayableAvailable	OUTPUT,
					  @dtToday			= @dtToday
End

-- Populate Header Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = 
	"Select " + CHAR(10)+
	"cast(@pnNameKey as nvarchar(11))	as 'RowKey',"+CHAR(10)+
	"@pnNameKey				as 'NameKey',"+CHAR(10)+
	"@sLocalCurrencyCode			as 'LocalCurrencyCode',"+CHAR(10)+ 
	"@nLocalDecimalPlaces			as 'LocalDecimalPlaces'"+CHAR(10)+ 
	"where 1=1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey			int,
					  @sLocalCurrencyCode	 	nvarchar(3),
					  @nLocalDecimalPlaces		tinyint',

					  @pnNameKey			= @pnNameKey,
					  @sLocalCurrencyCode	 	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces		= @nLocalDecimalPlaces

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


-- Populating PayableByCurrency Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select
	CAST(C.ACCTCREDITORNO as nvarchar(11)) + '^' + CAST(C.ACCTENTITYNO as nvarchar(11)) + '^' + ISNULL(C.CURRENCY, SC.COLCHARACTER) as 'RowKey',	
	C.ACCTCREDITORNO as 'NameKey', 
	C.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	ISNULL(C.CURRENCY, SC.COLCHARACTER)
			as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) <  @nAge0) 		    	THEN ISNULL(C.FOREIGNBALANCE, C.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(C.FOREIGNBALANCE, C.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(C.FOREIGNBALANCE, C.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) >= @nAge2) 		    	THEN ISNULL(C.FOREIGNBALANCE, C.LOCALBALANCE) ELSE 0 END) 
			as 'Bracket3Total',
	sum(ISNULL(C.FOREIGNBALANCE, C.LOCALBALANCE)) 
			as 'Total'
	from CREDITORITEM C	
	join NAME N 	 	on (N.NAMENO = C.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where C.ACCTCREDITORNO = @pnNameKey  
	and C.STATUS <> 0
	and C.ITEMDATE <= getdate()
	and C.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day, 1, getdate()),112) 
	-- An empty result set is required if the user does not have access to the the Payable Items topic
	and @bIsPayableAvailable = 1
	group by C.ACCTENTITYNO, N.NAME, C.CURRENCY, SC.COLCHARACTER,C.ACCTCREDITORNO 
	order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @bIsPayableAvailable	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @nAge0,
					  @nAge1         	= @nAge1,
					  @nAge2         	= @nAge2,
					  @dtBaseDate		= @dtBaseDate,
					  @bIsPayableAvailable	= @bIsPayableAvailable 	
End	

-- Populating PayableTotal Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select
	CAST(C.ACCTCREDITORNO as nvarchar(11)) + '^' + CAST(C.ACCTENTITYNO as nvarchar(11)) + '^' + SC.COLCHARACTER as 'RowKey',	
	C.ACCTCREDITORNO 	as 'NameKey', 
	C.ACCTENTITYNO		as 'EntityKey',
	N.NAME			as 'EntityName',
	SC.COLCHARACTER		as 'CurrencyCode',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) <  @nAge0) 		    	THEN C.LOCALBALANCE ELSE 0 END) 
				as 'Bracket0Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN C.LOCALBALANCE ELSE 0 END) 
				as 'Bracket1Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN C.LOCALBALANCE ELSE 0 END) 
				as 'Bracket2Total',
	sum(CASE WHEN(datediff(day,C.ITEMDATE,@dtBaseDate) >= @nAge2) 		    	THEN C.LOCALBALANCE ELSE 0 END) 
				as 'Bracket3Total',
	sum(C.LOCALBALANCE)
				as 'Total'
	from CREDITORITEM C	
	join NAME N 	 	on (N.NAMENO = C.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where C.ACCTCREDITORNO = @pnNameKey  
	and C.STATUS <> 0
	and C.ITEMDATE <= getdate()
	and C.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day, 1, getdate()),112) 
	-- An empty result set is required if the user does not have access to the the Payable Items topic
	and @bIsPayableAvailable = 1
	group by C.ACCTENTITYNO, N.NAME, SC.COLCHARACTER,C.ACCTCREDITORNO 
	order by 'EntityName', 'EntityKey'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime,
					  @bIsPayableAvailable	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @nAge0,
					  @nAge1         	= @nAge1,
					  @nAge2         	= @nAge2,
					  @dtBaseDate		= @dtBaseDate,
					  @bIsPayableAvailable	= @bIsPayableAvailable 
End	

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNamePayableData to public
GO
