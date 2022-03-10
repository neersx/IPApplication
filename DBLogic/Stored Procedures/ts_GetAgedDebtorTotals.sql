-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetAgedDebtorTotals
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetAgedDebtorTotals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetAgedDebtorTotals.'
	Drop procedure [dbo].[ts_GetAgedDebtorTotals]
End
Print '**** Creating Stored Procedure dbo.ts_GetAgedDebtorTotals...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_GetAgedDebtorTotals
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int
)
as
-- PROCEDURE:	ts_GetAgedDebtorTotals
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 DEC 2011	SF	11551	1	Procedure created
-- 15 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	3	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	4   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = dbo.ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
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
			as 'Total'
	from OPENITEM O
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)
	join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY') 
	where O.ACCTDEBTORNO = @pnNameKey  
	and O.STATUS <> 0
	and O.ITEMDATE <= getdate()
	and O.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day, 1, getdate()),112) 
	group by O.ACCTENTITYNO, N.NAME, SC.COLCHARACTER,O.ACCTDEBTORNO 
	order by 'EntityName', 'EntityKey'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @dtBaseDate		datetime',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAge0         	= @nAge0,
					  @nAge1         	= @nAge1,
					  @nAge2         	= @nAge2,
					  @dtBaseDate		= @dtBaseDate
End	

Return @nErrorCode
GO

Grant execute on dbo.ts_GetAgedDebtorTotals to public
GO
