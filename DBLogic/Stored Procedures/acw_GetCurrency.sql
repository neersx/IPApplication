-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_GetCurrency
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_GetCurrency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_GetCurrency.'
	Drop procedure [dbo].[acw_GetCurrency]
End
Print '**** Creating Stored Procedure dbo.acw_GetCurrency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_GetCurrency
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psCurrencyCode			nvarchar(10) -- Mandatory
)
as
-- PROCEDURE:	acw_GetCurrency
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns Currency Data
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2010  DV		RFC7350		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  C.CURRENCY as Currency,
			C.BUYFACTOR as BuyFactor,
			C.SELLFACTOR as SellFactor,
			C.BANKRATE as BankRate,
			C.BUYRATE as BuyRate,
			"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as Description,
			C.SELLRATE as SellRate,
			C.DATECHANGED as DateChanged,
			C.ROUNDBILLEDVALUES as RoundBilledValues,
			C.LOGDATETIMESTAMP as LastUpdatedDate
	from 	CURRENCY C
	where CURRENCY = @psCurrencyCode"	
End

exec @nErrorCode = sp_executesql @sSQLString,
			N'@psCurrencyCode nvarchar(10)',
			@psCurrencyCode	= @psCurrencyCode

Set @pnRowCount = @@Rowcount

Return @nErrorCode
go

Grant exec on dbo.acw_GetCurrency to Public
go