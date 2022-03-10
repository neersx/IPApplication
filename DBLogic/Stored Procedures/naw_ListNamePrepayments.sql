-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNamePrepayments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNamePrepayments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNamePrepayments.'
	Drop procedure [dbo].[naw_ListNamePrepayments]
End
Print '**** Creating Stored Procedure dbo.naw_ListNamePrepayments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNamePrepayments
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@pbCanViewPrepayments	bit		= 0,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListNamePrepayments
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Name Prepayment information.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-----	-------	-------	----------------------------------------------- 
-- 28 Aug 2006	SF	RFC4214	1	Procedure created. 
--					Moved from naw_ListNameDetail, Added RowKey.
-- 14 Jun 2011	JC	RFC100151	2	Improve performance by removing fn_GetTopicSecurity: authorisation is now given by the caller
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @sSQLString 			nvarchar(4000)

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

-- Populating Prepayment Result Set
If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select
	CAST(O.ACCTDEBTORNO as nvarchar(11)) + '^' + CAST(O.ACCTENTITYNO as nvarchar(11)) + '^' + O.CURRENCY as 'RowKey',
	O.ACCTDEBTORNO	as 'NameKey', 
	O.ACCTENTITYNO	as 'EntityKey',
	N.NAME		as 'EntityName',
	O.CURRENCY	as 'CurrencyCode',
	sum(O.LOCALBALANCE)*-1
			as 'AvailableLocalBalance',
	case when O.CURRENCY IS NULL then NULL else sum(O.FOREIGNBALANCE)*-1 END
			as 'AvailableForeignBalance',
	-- Avoid 'divide by zero' by substituting 0 with 1
	convert(int,
	round(
	(sum(O.LOCALVALUE - O.LOCALBALANCE)/
	CASE WHEN sum(O.LOCALVALUE)<>0 
	     THEN sum(O.LOCALVALUE)
	     ELSE 1 
	END)*100, 0)) 	as 'UtilisedPercentage'
	from OPENITEM O
	join NAME N 	 	on (N.NAMENO = O.ACCTENTITYNO)	
	where 	O.ACCTDEBTORNO = @pnNameKey
	and 	O.STATUS in (1,2)
	and 	O.ITEMTYPE = 523
	-- An empty result set is required if the user does not have access to the Prepayments topic
	and	@pbCanViewPrepayments = 1
	group by O.ACCTENTITYNO, N.NAME, O.CURRENCY, O.ACCTDEBTORNO
	order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @pbCanViewPrepayments	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pbCanViewPrepayments	= @pbCanViewPrepayments

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNamePrepayments to public
GO
